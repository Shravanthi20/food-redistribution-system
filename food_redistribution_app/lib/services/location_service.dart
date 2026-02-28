import 'dart:async'; // [NEW]
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoHasher _geoHasher = GeoHasher();

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Request location permission
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Convert address to coordinates
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final geohash = _geoHasher.encode(location.latitude, location.longitude);
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'geopoint': GeoPoint(location.latitude, location.longitude),
          'geohash': geohash,
        };
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  // Convert coordinates to address
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  // Find nearby donations for NGO
  Future<List<Map<String, dynamic>>> findNearbyDonations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // NOTE: Client-side finding is limited. Use Cloud Functions for scalable Geo-queries.
      final donations = await _firestore
          .collection('food_donations')
          .where('status', isEqualTo: 'listed')
          .get();

      List<Map<String, dynamic>> nearbyDonations = [];
      
      for (var doc in donations.docs) {
        final data = doc.data();
        final location = data['pickupLocation'] as Map<String, dynamic>?;
        
        if (location != null && location.containsKey('latitude') && location.containsKey('longitude')) {
          final distance = calculateDistance(
            latitude,
            longitude,
            location['latitude'],
            location['longitude'],
          );
          
          if (distance <= radiusKm) {
            nearbyDonations.add({
              'id': doc.id,
              'distance': distance,
              ...data,
            });
          }
        }
      }
      
      // Sort by distance
      nearbyDonations.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyDonations;
    } catch (e) {
      print('Error finding nearby donations: $e');
      return [];
    }
  }

  // Update user location
  Future<void> updateUserLocation(String userId, Position position) async {
    try {
      final geohash = _geoHasher.encode(position.latitude, position.longitude);
      
      await _firestore.collection('user_locations').doc(userId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geopoint': GeoPoint(position.latitude, position.longitude),
        'geohash': geohash,
        'accuracy': position.accuracy,
        'timestamp': Timestamp.now(),
      });
      
    } catch (e) {
      print('Error updating user location: $e');
    }
  }
  // LIVE TRACKING

  final Map<String, StreamSubscription<Position>> _trackingSubscriptions = {};
  StreamSubscription? _locationRequestSubscription;

  // Start tracking user location
  Future<void> startLocationTracking(String userId) async {
    try {
      // check/request permission again just in case
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      final stream = Geolocator.getPositionStream(locationSettings: locationSettings);
      
      _trackingSubscriptions[userId]?.cancel(); // Cancel existing if any

      _trackingSubscriptions[userId] = stream.listen((Position position) {
        updateUserLocation(userId, position);
      });
      
      print('Started location tracking for $userId');

    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Listen for one-off location requests written to Firestore by donors/admins.
  /// When a request is received, obtain current location and write it to
  /// `user_locations/{userId}` and append to `location_updates` so other clients can read it.
  void listenForLocationRequests(String userId) {
    // cancel existing
    _locationRequestSubscription?.cancel();

    _locationRequestSubscription = _firestore
        .collection('location_requests')
        .where('volunteerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var docChange in snapshot.docChanges) {
        final doc = docChange.doc;
        final data = doc.data();
        if (data == null) continue;
        final handled = data['handled'] == true;
        if (handled) continue;

        try {
          final pos = await getCurrentLocation();
          if (pos != null) {
            final geohash = _geoHasher.encode(pos.latitude, pos.longitude);

            final normalized = {
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'geopoint': GeoPoint(pos.latitude, pos.longitude),
              'geohash': geohash,
              'accuracy': pos.accuracy,
              'timestamp': Timestamp.now(),
            };

            // Write canonical latest location
            await _firestore.collection('user_locations').doc(userId).set(normalized, SetOptions(merge: true));

            // Append to location_updates for history/consumers
            await _firestore.collection('location_updates').add({
              'volunteerId': userId,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'geopoint': GeoPoint(pos.latitude, pos.longitude),
              'accuracy': pos.accuracy,
              'timestamp': Timestamp.now(),
            });
          }

          // Mark request handled to avoid duplicate processing
          await doc.reference.update({'handled': true, 'handledAt': Timestamp.now()});
        } catch (e) {
          // Log but don't rethrow
          print('Error handling location request for $userId: $e');
        }
      }
    });
  }

  /// Stop listening for location requests
  Future<void> stopListeningForLocationRequests() async {
    await _locationRequestSubscription?.cancel();
    _locationRequestSubscription = null;
  }

  // Stop tracking
  Future<void> stopLocationTracking(String userId) async {
    await _trackingSubscriptions[userId]?.cancel();
    _trackingSubscriptions.remove(userId);
    print('Stopped location tracking for $userId');
  }

  // Stream of specific user's location
  Stream<Map<String, dynamic>> getUserLocationStream(String userId) {
    // Merge two possible sources: realtime `user_locations/{userId}` doc
    // (preferred) and fallback to latest `location_updates` entry for the user.
    final controller = StreamController<Map<String, dynamic>>();

    StreamSubscription? docSub;
    StreamSubscription? updatesSub;

    void emitIfNotEmpty(Map<String, dynamic>? data) {
      if (data != null && data.isNotEmpty) controller.add(data);
    }

    // Listen to canonical user_locations document
    docSub = _firestore.collection('user_locations').doc(userId).snapshots().listen((doc) {
      if (doc.exists) {
        emitIfNotEmpty(doc.data() as Map<String, dynamic>);
      }
    }, onError: (e) {
      // ignore errors but keep stream alive
    });

    // Also listen to latest location_updates as a fallback (some background services write here)
    updatesSub = _firestore
        .collection('location_updates')
        .where('volunteerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        // Normalize fields to match user_locations doc shape
        final normalized = <String, dynamic>{
          'latitude': data['latitude'] ?? data['lat'],
          'longitude': data['longitude'] ?? data['lng'],
          'geopoint': data['geopoint'] ?? data['location'] ?? null,
          'timestamp': data['timestamp'] ?? data['ts'] ?? FieldValue.serverTimestamp(),
          ...data,
        };
        emitIfNotEmpty(normalized);
      }
    }, onError: (e) {
      // ignore
    });

    controller.onCancel = () async {
      await docSub?.cancel();
      await updatesSub?.cancel();
      await controller.close();
    };

    return controller.stream;
  }
}
