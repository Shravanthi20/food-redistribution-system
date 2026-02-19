import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/tracking/location_tracking_model.dart';
import 'background_tracking_service.dart';

// Manages geofence entry/exit detection in background
class GeofenceBackgroundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackgroundTrackingService _backgroundTrackingService;

  // Cache of active geofences to reduce Firestore queries
  final Map<String, Geofence> _geofenceCache = {};
  
  // Track last notification sent for each geofence to avoid spam
  final Map<String, DateTime> _lastNotificationTime = {};

  GeofenceBackgroundService({
    required BackgroundTrackingService backgroundTrackingService,
  }) : _backgroundTrackingService = backgroundTrackingService;

  /// Initialize geofence monitoring (should be called on app start)
  Future<void> initialize() async {
    try {
      await loadActiveGeofences();
      debugPrint('GeofenceBackgroundService initialized with ${_geofenceCache.length} geofences');
    } catch (e) {
      debugPrint('Error initializing GeofenceBackgroundService: $e');
    }
  }

  /// Load all active geofences from Firestore
  Future<void> loadActiveGeofences() async {
    try {
      final snapshot = await _firestore
          .collection('geofences')
          .where('isActive', isEqualTo: true)
          .get();

      _geofenceCache.clear();
      
      for (var doc in snapshot.docs) {
        final geofence = Geofence.fromMap(doc.data(), id: doc.id);
        _geofenceCache[doc.id] = geofence;
        
        // Register with background tracking service
        await _backgroundTrackingService.addGeofence(
          geofenceId: doc.id,
          latitude: geofence.latitude,
          longitude: geofence.longitude,
          radiusMeters: geofence.radius,
          taskId: geofence.taskId,
        );
      }
      
      debugPrint('Loaded ${_geofenceCache.length} active geofences');
    } catch (e) {
      debugPrint('Error loading geofences: $e');
    }
  }

  /// Create geofence for pickup location
  Future<bool> createPickupGeofence({
    required String taskId,
    required String pickupLocationId,
    required double latitude,
    required double longitude,
    double radiusMeters = 100,
  }) async {
    try {
      final geofenceId = '${taskId}_pickup_$pickupLocationId';

      final geofence = Geofence(
        id: geofenceId,
        type: GeofenceType.pickup,
        latitude: latitude,
        longitude: longitude,
        radius: radiusMeters,
        taskId: taskId,
        label: 'Pickup Location',
        metadata: {
          'locationId': pickupLocationId,
          'type': 'pickup',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Store in cache and Firestore
      _geofenceCache[geofenceId] = geofence;

      await _firestore.collection('geofences').doc(geofenceId).set({
        'id': geofenceId,
        'type': GeofenceType.pickup.name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'taskId': taskId,
        'label': 'Pickup Location',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': geofence.metadata,
      });

      // Register with background tracking
      await _backgroundTrackingService.addGeofence(
        geofenceId: geofenceId,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        taskId: taskId,
      );

      debugPrint('Created pickup geofence: $geofenceId');
      return true;
    } catch (e) {
      debugPrint('Error creating pickup geofence: $e');
      return false;
    }
  }

  /// Create geofence for delivery location
  Future<bool> createDeliveryGeofence({
    required String taskId,
    required String ngoId,
    required double latitude,
    required double longitude,
    double radiusMeters = 150,
  }) async {
    try {
      final geofenceId = '${taskId}_delivery_$ngoId';

      final geofence = Geofence(
        id: geofenceId,
        type: GeofenceType.checkpoint,
        latitude: latitude,
        longitude: longitude,
        radius: radiusMeters,
        taskId: taskId,
        label: 'Delivery Location',
        metadata: {
          'ngoId': ngoId,
          'type': 'delivery',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      _geofenceCache[geofenceId] = geofence;

      await _firestore.collection('geofences').doc(geofenceId).set({
        'id': geofenceId,
        'type': GeofenceType.checkpoint.name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'taskId': taskId,
        'label': 'Delivery Location',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': geofence.metadata,
      });

      await _backgroundTrackingService.addGeofence(
        geofenceId: geofenceId,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        taskId: taskId,
      );

      debugPrint('Created delivery geofence: $geofenceId');
      return true;
    } catch (e) {
      debugPrint('Error creating delivery geofence: $e');
      return false;
    }
  }

  /// Handle geofence entry event
  Future<void> handleGeofenceEntry(String geofenceId) async {
    try {
      final geofence = _geofenceCache[geofenceId];
      if (geofence == null) return;

      debugPrint('Geofence entry: $geofenceId (${geofence.label})');

      // Check if we should send notification (rate limit: 1 per 5 minutes)
      final lastNotification = _lastNotificationTime[geofenceId];
      if (lastNotification != null &&
          DateTime.now().difference(lastNotification).inMinutes < 5) {
        debugPrint('Geofence notification throttled for $geofenceId');
        return;
      }

      // Store event
      await _firestore.collection('geofence_events').add({
        'geofenceId': geofenceId,
        'taskId': geofence.taskId,
        'type': geofence.type.name,
        'action': 'entry',
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': geofence.latitude,
          'longitude': geofence.longitude,
        },
      });

      // Create notification based on geofence type
      String eventMessage = '';
      String eventType = '';

      if (geofence.type == GeofenceType.pickup) {
        eventMessage = 'You have arrived at the pickup location';
        eventType = 'pickup_arrival';
      } else if (geofence.type == GeofenceType.checkpoint) {
        eventMessage = 'You have arrived at the delivery location';
        eventType = 'delivery_arrival';
      } else {
        eventMessage = 'You have arrived at the location: ${geofence.label}';
        eventType = 'location_arrival';
      }

      // Send notification to task
      await _firestore.collection('notifications').add({
        'taskId': geofence.taskId,
        'type': eventType,
        'title': 'Location Reached',
        'message': eventMessage,
        'geofenceId': geofenceId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'high',
      });

      // Update task status if applicable
      await _updateTaskOnGeofenceEntry(geofence);

      _lastNotificationTime[geofenceId] = DateTime.now();
      debugPrint('Geofence entry event processed: $geofenceId');
    } catch (e) {
      debugPrint('Error handling geofence entry: $e');
    }
  }

  /// Handle geofence exit event
  Future<void> handleGeofenceExit(String geofenceId) async {
    try {
      final geofence = _geofenceCache[geofenceId];
      if (geofence == null) return;

      debugPrint('Geofence exit: $geofenceId (${geofence.label})');

      // Store event
      await _firestore.collection('geofence_events').add({
        'geofenceId': geofenceId,
        'taskId': geofence.taskId,
        'type': geofence.type.name,
        'action': 'exit',
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': geofence.latitude,
          'longitude': geofence.longitude,
        },
      });

      // Create notification
      String eventMessage = '';
      String eventType = '';

      if (geofence.type == GeofenceType.pickup) {
        eventMessage = 'You have left the pickup location';
        eventType = 'left_pickup';
      } else if (geofence.type == GeofenceType.checkpoint) {
        eventMessage = 'You have left the delivery location';
        eventType = 'left_delivery';
      } else {
        eventMessage = 'You have left the location: ${geofence.label}';
        eventType = 'left_location';
      }

      await _firestore.collection('notifications').add({
        'taskId': geofence.taskId,
        'type': eventType,
        'title': 'Location Left',
        'message': eventMessage,
        'geofenceId': geofenceId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'medium',
      });

      debugPrint('Geofence exit event processed: $geofenceId');
    } catch (e) {
      debugPrint('Error handling geofence exit: $e');
    }
  }

  /// Update task status when entering pickup/delivery area
  Future<void> _updateTaskOnGeofenceEntry(Geofence geofence) async {
    try {
      final taskDoc = await _firestore
          .collection('delivery_tasks')
          .doc(geofence.taskId)
          .get();

      if (!taskDoc.exists) return;

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final currentStatus = taskData['status'] as String?;

      // Update status based on geofence type
      if (geofence.type == GeofenceType.pickup && currentStatus == 'assigned') {
        await _firestore.collection('delivery_tasks').doc(geofence.taskId).update({
          'status': 'arrived_at_pickup',
          'arrivedAtPickupTime': FieldValue.serverTimestamp(),
        });
      } else if (geofence.type == GeofenceType.checkpoint &&
          (currentStatus == 'picked_up' || currentStatus == 'in_transit')) {
        await _firestore.collection('delivery_tasks').doc(geofence.taskId).update({
          'status': 'arrived_at_delivery',
          'arrivedAtDeliveryTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating task on geofence entry: $e');
    }
  }

  /// Remove geofence when task is completed
  Future<void> removeGeofenceForTask(String taskId) async {
    try {
      final geofencesToRemove = _geofenceCache.entries
          .where((e) => e.value.taskId == taskId)
          .map((e) => e.key)
          .toList();

      for (var geofenceId in geofencesToRemove) {
        await _firestore
            .collection('geofences')
            .doc(geofenceId)
            .update({'isActive': false});

        await _backgroundTrackingService.removeGeofence(geofenceId);
        _geofenceCache.remove(geofenceId);
        _lastNotificationTime.remove(geofenceId);
      }

      debugPrint('Removed ${geofencesToRemove.length} geofences for task $taskId');
    } catch (e) {
      debugPrint('Error removing geofences for task: $e');
    }
  }

  /// Get all active geofences for a task
  List<Geofence> getGeofencesForTask(String taskId) {
    return _geofenceCache.values
        .where((g) => g.taskId == taskId)
        .toList();
  }

  /// Clear all geofences (cleanup)
  Future<void> clearAllGeofences() async {
    try {
      for (var geofenceId in _geofenceCache.keys.toList()) {
        await _backgroundTrackingService.removeGeofence(geofenceId);
      }
      _geofenceCache.clear();
      _lastNotificationTime.clear();
      debugPrint('All geofences cleared');
    } catch (e) {
      debugPrint('Error clearing geofences: $e');
    }
  }

  /// Get geofence cache stats
  Map<String, dynamic> getCacheStats() {
    return {
      'totalGeofences': _geofenceCache.length,
      'pickupGeofences': _geofenceCache.values
          .where((g) => g.type == GeofenceType.pickup)
          .length,
      'deliveryGeofences': _geofenceCache.values
          .where((g) => g.type == GeofenceType.checkpoint)
          .length,
      'recentNotifications': _lastNotificationTime.entries
          .where((e) => DateTime.now().difference(e.value).inMinutes < 10)
          .length,
    };
  }
}
