import 'package:flutter/foundation.dart';
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
      debugPrint('Error getting current location: $e');
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
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  // Convert address to coordinates
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    final parsedCoordinates = _tryParseCoordinates(address);
    if (parsedCoordinates != null) {
      return buildLocationData(
        latitude: parsedCoordinates.$1,
        longitude: parsedCoordinates.$2,
        address: address,
      );
    }

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return buildLocationData(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }
      return null;
    } catch (e) {
      // Web geocoding can fail with opaque null errors; callers handle null.
      return null;
    }
  }

  // Convert coordinates to address
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    if (latitude.isNaN ||
        longitude.isNaN ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String?>[
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
      return _formatCoordinates(latitude, longitude);
    } catch (e) {
      // Reverse geocoding is optional; fall back to coordinates without noisy logs.
      return _formatCoordinates(latitude, longitude);
    }
  }

  Map<String, dynamic> buildLocationData({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final geohash = _geoHasher.encode(latitude, longitude);
    return {
      'latitude': latitude,
      'longitude': longitude,
      'geopoint': GeoPoint(latitude, longitude),
      'geohash': geohash,
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    };
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  (double, double)? _tryParseCoordinates(String input) {
    final normalized = input.trim();
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(normalized);

    if (match == null) return null;

    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);

    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;

    return (latitude, longitude);
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
        ) /
        1000; // Convert to kilometers
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

        if (location != null &&
            location.containsKey('latitude') &&
            location.containsKey('longitude')) {
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
      debugPrint('Error finding nearby donations: $e');
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
      debugPrint('Error updating user location: $e');
    }
  }
  // LIVE TRACKING

  final Map<String, StreamSubscription<Position>> _trackingSubscriptions = {};

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

      final stream =
          Geolocator.getPositionStream(locationSettings: locationSettings);

      _trackingSubscriptions[userId]?.cancel(); // Cancel existing if any

      _trackingSubscriptions[userId] = stream.listen((Position position) {
        updateUserLocation(userId, position);
      });

      debugPrint('Started location tracking for $userId');
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  // Stop tracking
  Future<void> stopLocationTracking(String userId) async {
    await _trackingSubscriptions[userId]?.cancel();
    _trackingSubscriptions.remove(userId);
    debugPrint('Stopped location tracking for $userId');
  }

  // Stream of specific user's location
  Stream<Map<String, dynamic>> getUserLocationStream(String userId) {
    return _firestore
        .collection('user_locations')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {};
      return doc.data() as Map<String, dynamic>;
    });
  }
}
