import 'dart:async';
import 'package:background_geolocation/background_geolocation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/tracking/location_tracking_model.dart';
import '../../models/enums.dart';

// Handles background location tracking on Android & iOS
class BackgroundTrackingService {
  static const String backgroundLocationTaskId = 'background_location_tracking';
  static const String geofenceTaskId = 'geofence_monitoring';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize workmanager for periodic tasks
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Configure background_geolocation
      await _configureBackgroundGeolocation();
      
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
      if (!_isInitialized) {
        await initialize();
      }

      // Schedule periodic location updates via workmanager
      await Workmanager().registerPeriodicTask(
        '${backgroundLocationTaskId}_$volunteerId',
        backgroundLocationTaskId,
        frequency: Duration(seconds: updateIntervalSeconds),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'volunteerId': volunteerId,
          'taskId': taskId,
        },
      );

      // Enable background geolocation
      await BackgroundGeolocation.start();
      
      debugPrint('Background tracking started for volunteer: $volunteerId');
      return true;
    } catch (e) {
      debugPrint('Error starting background tracking: $e');
      return false;
    }
  }

  /// Stop background location tracking
  Future<bool> stopBackgroundTracking(String volunteerId) async {
    try {
      // Cancel workmanager task
      await Workmanager().cancelByUniqueName(
        '${backgroundLocationTaskId}_$volunteerId',
      );

      // Stop background geolocation if no other tasks running
      final tasks = await Workmanager().getInstanceInfo();
      if (tasks.isEmpty) {
        await BackgroundGeolocation.stop();
      }

      debugPrint('Background tracking stopped for volunteer: $volunteerId');
      return true;
    } catch (e) {
      debugPrint('Error stopping background tracking: $e');
      return false;
    }
  }

  /// Configure background geolocation for iOS and Android
  Future<void> _configureBackgroundGeolocation() async {
    try {
      await BackgroundGeolocation.ready(
        BackgroundGeolocationConfig(
          desiredAccuracy: Config.DESIRED_ACCURACY_HIGH,
          stationaryRadius: 50,
          distanceFilter: 10, // Update every 10 meters
          locationUpdateInterval: 30000, // 30 seconds
          fastestLocationUpdateInterval: 15000, // 15 seconds
          
          // iOS-specific
          showsBackgroundLocationIndicator: true,
          pausesLocationUpdatesAutomatically: false,
          
          // Android-specific
          foregroundService: true,
          enableHeadless: true,
          startOnBoot: false,
          
          // Stopping options
          stopOnStationary: false,
          stopAfterElapsedMinutes: 0,
          
          // Geofencing
          geofenceInitialTriggerEntry: true,
          geofenceProximityRadius: 100,
          
          // Notifications
          notificationTitle: '📍 Food Redistribution Tracking',
          notificationText: 'We\'re tracking your delivery location',
          notificationSmallIcon: 'ic_launcher',
          notificationChannelName: 'BackgroundLocation',
          notificationPriority: Config.NOTIFICATION_PRIORITY_DEFAULT,
          
          // HTTP logging
          debug: kDebugMode,
          logLevel: Config.LOG_LEVEL_VERBOSE,
        ),
      );

      // Handle location updates
      BackgroundGeolocation.onLocation((Location location) async {
        debugPrint('Background location update: ${location.coords.latitude}, ${location.coords.longitude}');
        await _storeLocationUpdate(location);
      });

      // Handle geofence events
      BackgroundGeolocation.onGeofence((GeofenceEvent event) async {
        debugPrint('Geofence event: ${event.identifier} - ${event.action}');
        await _handleGeofenceEvent(event);
      });

      // Handle errors
      BackgroundGeolocation.onError((error) {
        debugPrint('BackgroundGeolocation error: $error');
      });

      // Handle state changes
      BackgroundGeolocation.onProviderChange((ProviderChangeEvent event) {
        debugPrint('Provider change: GPS=${event.gps}, Network=${event.network}');
      });
    } catch (e) {
      debugPrint('Error configuring background geolocation: $e');
      rethrow;
    }
  }

  /// Store a location update to Firestore
  Future<void> _storeLocationUpdate(Location location) async {
    try {
      final locationUpdate = LocationUpdate(
        id: 'bg_loc_${DateTime.now().millisecondsSinceEpoch}',
        volunteerId: location.uuid ?? 'unknown',
        taskId: 'pending', // Will be matched by user ID
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        accuracy: location.coords.accuracy,
        speed: location.coords.speed,
        heading: location.coords.heading,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          location.timestamp.toInt(),
        ),
        status: TrackingStatus.inTransit,
        metadata: {
          'isBackground': true,
          'provider': location.provider,
          'altitude': location.coords.altitude,
          'speedAccuracy': location.coords.speedAccuracy,
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

  /// Handle geofence entry/exit events
  Future<void> _handleGeofenceEvent(GeofenceEvent event) async {
    try {
      debugPrint('Processing geofence: ${event.identifier}, action: ${event.action}');

      // Store geofence event to Firestore
      await _firestore.collection('geofence_events').add({
        'geofenceId': event.identifier,
        'action': event.action, // 'ENTER' or 'EXIT'
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': event.location.coords.latitude,
          'longitude': event.location.coords.longitude,
        },
      });

      // Trigger notification if entering/exiting key location
      if (event.action == 'ENTER') {
        await _notifyGeofenceEntry(event.identifier);
      } else if (event.action == 'EXIT') {
        await _notifyGeofenceExit(event.identifier);
      }
    } catch (e) {
      debugPrint('Error handling geofence event: $e');
    }
  }

  /// Add geofence for pickup/delivery location
  Future<void> addGeofence({
    required String geofenceId,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String taskId,
  }) async {
    try {
      await BackgroundGeolocation.addGeofence(
        Geofence(
          identifier: geofenceId,
          latitude: latitude,
          longitude: longitude,
          radius: radiusMeters,
          notifyOnEntry: true,
          notifyOnExit: true,
          loiteringDelay: 0,
        ),
      );

      // Store geofence config
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
      await BackgroundGeolocation.removeGeofence(geofenceId);

      await _firestore
          .collection('geofences')
          .doc(geofenceId)
          .update({'isActive': false});

      debugPrint('Geofence removed: $geofenceId');
    } catch (e) {
      debugPrint('Error removing geofence: $e');
    }
  }

  /// Notify on geofence entry
  Future<void> _notifyGeofenceEntry(String geofenceId) async {
    try {
      final geofence = await _firestore
          .collection('geofences')
          .doc(geofenceId)
          .get();

      if (!geofence.exists) return;

      final taskId = geofence.data()?['taskId'] as String?;
      if (taskId != null) {
        await _firestore.collection('notifications').add({
          'taskId': taskId,
          'type': 'geofence_entry',
          'message': 'You have arrived at the pickup location',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Error notifying geofence entry: $e');
    }
  }

  /// Notify on geofence exit
  Future<void> _notifyGeofenceExit(String geofenceId) async {
    try {
      final geofence = await _firestore
          .collection('geofences')
          .doc(geofenceId)
          .get();

      if (!geofence.exists) return;

      final taskId = geofence.data()?['taskId'] as String?;
      if (taskId != null) {
        await _firestore.collection('notifications').add({
          'taskId': taskId,
          'type': 'geofence_exit',
          'message': 'You have left the location',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Error notifying geofence exit: $e');
    }
  }

  /// Clear all geofences
  Future<void> clearAllGeofences() async {
    try {
      await BackgroundGeolocation.removeGeofences();
      debugPrint('All geofences cleared');
    } catch (e) {
      debugPrint('Error clearing geofences: $e');
    }
  }

  /// Get current background geolocation state
  Future<Map<String, dynamic>> getCurrentState() async {
    try {
      final state = await BackgroundGeolocation.state;
      return {
        'isRunning': state.isRunning,
        'enabled': state.enabled,
        'trackingMode': state.trackingMode,
        'lastLocation': state.lastLocation?.toMap(),
      };
    } catch (e) {
      debugPrint('Error getting state: $e');
      return {};
    }
  }
}

/// Callback dispatcher for workmanager background tasks
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'background_location_tracking') {
        final volunteerId = inputData?['volunteerId'] as String?;
        final taskId = inputData?['taskId'] as String?;

        if (volunteerId != null && taskId != null) {
          debugPrint('Executing background task for $volunteerId');
          // Location updates are handled by background_geolocation
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}
