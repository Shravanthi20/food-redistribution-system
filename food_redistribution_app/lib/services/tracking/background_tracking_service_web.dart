import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tracking/location_tracking_model.dart';
import '../../models/enums.dart';

/// Stub version of BackgroundTrackingService used on web.
/// All plugin APIs are replaced with no-ops to keep the web build clean.
class BackgroundTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // nothing needed on web
  }

  Future<bool> startBackgroundTracking({
    required String volunteerId,
    required String taskId,
    int updateIntervalSeconds = 30,
  }) async {
    // simply return success
    return true;
  }

  Future<bool> stopBackgroundTracking(String volunteerId) async {
    return true;
  }

  Future<void> addGeofence({
    required String geofenceId,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String taskId,
  }) async {
    // record in Firestore for other services if needed
    try {
      await _firestore.collection('geofences').doc(geofenceId).set({
        'taskId': taskId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (_) {}
  }

  Future<void> removeGeofence(String geofenceId) async {
    try {
      await _firestore.collection('geofences').doc(geofenceId).update({'isActive': false});
    } catch (_) {}
  }

  Future<void> clearAllGeofences() async {}

  Future<Map<String, dynamic>> getCurrentState() async {
    return {
      'isRunning': false,
      'enabled': false,
      'trackingMode': null,
      'lastLocation': null,
    };
  }
}

void callbackDispatcher() {
  // no-op on web
}
