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
}