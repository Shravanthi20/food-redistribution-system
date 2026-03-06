import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/tracking/location_tracking_model.dart';
import '../../models/enums.dart';

// Handles background location tracking using geolocator (works on web, Android & iOS)
class BackgroundTrackingService {
  static const String backgroundLocationTaskId = 'background_location_tracking';
  static const String geofenceTaskId = 'geofence_monitoring';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  StreamSubscription<Position>? _positionSubscription;
  String? _currentVolunteerId;
  String? _currentTaskId;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = true;
      debugPrint('BackgroundTrackingService initialized');
    } catch (e) {
      debugPrint('Error initializing BackgroundTrackingService: $e');
    }
  }

  /// Start background location tracking for a volunteer
  Future<bool> startBackgroundTracking({
    required String volunteerId,
    required String taskId,
    int updateIntervalSeconds = 30,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      _currentVolunteerId = volunteerId;
      _currentTaskId = taskId;

      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return false;
        }
      }

      // Start listening to position updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // update every 10 meters
        ),
      ).listen(
        (Position position) => _onPositionUpdate(position),
        onError: (e) => debugPrint('Location stream error: $e'),
      );

      debugPrint('Background tracking started for volunteer: $volunteerId');
      return true;
    } catch (e) {
      debugPrint('Error starting background tracking: $e');
      return false;
    }
  }

  void _onPositionUpdate(Position position) {
    debugPrint('Location update: ${position.latitude}, ${position.longitude}');
    _storeLocationUpdate(position);
  }

  /// Stop background location tracking
  Future<bool> stopBackgroundTracking(String volunteerId) async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _currentVolunteerId = null;
      _currentTaskId = null;
      debugPrint('Background tracking stopped for volunteer: $volunteerId');
      return true;
    } catch (e) {
      debugPrint('Error stopping background tracking: $e');
      return false;
    }
  }

  /// Store a location update to Firestore
  Future<void> _storeLocationUpdate(Position position) async {
    try {
      final locationUpdate = LocationUpdate(
        id: 'bg_loc_${DateTime.now().millisecondsSinceEpoch}',
        volunteerId: _currentVolunteerId ?? 'unknown',
        taskId: _currentTaskId ?? 'pending',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
        status: TrackingStatus.inTransit,
        metadata: {
          'isBackground': true,
          'altitude': position.altitude,
          'speedAccuracy': position.speedAccuracy,
        },
      );

      await _firestore
          .collection('location_updates')
          .doc(locationUpdate.id)
          .set(locationUpdate.toMap());
    } catch (e) {
      debugPrint('Error storing background location: $e');
    }
  }

  /// Add geofence — stored in Firestore; entry/exit detection done via distance checks
  Future<void> addGeofence({
    required String geofenceId,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String taskId,
  }) async {
    try {
      await _firestore.collection('geofences').doc(geofenceId).set({
        'taskId': taskId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      debugPrint('Geofence added: $geofenceId');
    } catch (e) {
      debugPrint('Error adding geofence: $e');
    }
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    try {
      await _firestore
          .collection('geofences')
          .doc(geofenceId)
          .update({'isActive': false});
      debugPrint('Geofence removed: $geofenceId');
    } catch (e) {
      debugPrint('Error removing geofence: $e');
    }
  }

  /// Clear all geofences
  Future<void> clearAllGeofences() async {
    try {
      final snapshot = await _firestore
          .collection('geofences')
          .where('isActive', isEqualTo: true)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.update({'isActive': false});
      }
      debugPrint('All geofences cleared');
    } catch (e) {
      debugPrint('Error clearing geofences: $e');
    }
  }

  /// Get current tracking state
  Future<Map<String, dynamic>> getCurrentState() async {
    try {
      final isRunning = _positionSubscription != null;
      return {
        'isRunning': isRunning,
        'enabled': isRunning,
        'volunteerId': _currentVolunteerId,
        'taskId': _currentTaskId,
      };
    } catch (e) {
      debugPrint('Error getting state: $e');
      return {};
    }
  }
}

/// Stub for workmanager compatibility (kept for potential future use)
void callbackDispatcher() {}
