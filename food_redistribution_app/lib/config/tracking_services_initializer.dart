import 'package:flutter/foundation.dart';
import '../services/tracking/background_tracking_service.dart';
import '../services/tracking/geofence_background_service.dart';
import '../services/notification_service.dart';
import '../services/real_time_tracking_service.dart';

/// Initializes all background tracking and monitoring services
/// Call this in main.dart after Firebase initialization
class TrackingServicesInitializer {
  static late BackgroundTrackingService _backgroundTrackingService;
  static late GeofenceBackgroundService _geofenceBackgroundService;
  static late NotificationService _notificationService;

  /// Initialize all tracking services
  static Future<void> initialize({
    required RealTimeTrackingService realTimeTrackingService,
  }) async {
    try {
      debugPrint('🚀 Initializing Tracking Services...');

      // 1. Initialize notification service
      _notificationService = NotificationService();
      await _notificationService.initialize();
      debugPrint('✅ Notification Service initialized');

      // 2. Initialize background tracking service (handles GPS + workmanager)
      _backgroundTrackingService = BackgroundTrackingService();
      await _backgroundTrackingService.initialize();
      debugPrint('✅ Background Tracking Service initialized');

      // 3. Initialize geofence monitoring (depends on background tracking)
      _geofenceBackgroundService = GeofenceBackgroundService(
        backgroundTrackingService: _backgroundTrackingService,
      );
      await _geofenceBackgroundService.initialize();
      debugPrint('✅ Geofence Background Service initialized');

      debugPrint('🎉 All Tracking Services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing tracking services: $e');
      rethrow;
    }
  }

  /// Start background tracking for a volunteer
  /// 
  /// This should be called when volunteer accepts a delivery task
  static Future<bool> startVolunteerTracking({
    required String volunteerId,
    required String taskId,
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    try {
      debugPrint('▶️ Starting tracking for volunteer: $volunteerId, task: $taskId');

      // 1. Start background GPS tracking
      final trackingStarted = await _backgroundTrackingService.startBackgroundTracking(
        volunteerId: volunteerId,
        taskId: taskId,
        updateIntervalSeconds: 30, // Update every 30 seconds
      );

      if (!trackingStarted) {
        debugPrint('❌ Failed to start background tracking');
        return false;
      }

      // 2. Create pickup location geofence
      await _geofenceBackgroundService.createPickupGeofence(
        taskId: taskId,
        pickupLocationId: '${taskId}_pickup',
        latitude: pickupLat,
        longitude: pickupLng,
        radiusMeters: 100, // 100m radius for pickup
      );

      // 3. Create delivery location geofence
      await _geofenceBackgroundService.createDeliveryGeofence(
        taskId: taskId,
        ngoId: taskId, // Would be actual NGO ID
        latitude: deliveryLat,
        longitude: deliveryLng,
        radiusMeters: 150, // 150m radius for delivery
      );

      debugPrint('✅ Volunteer tracking started with geofences');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting volunteer tracking: $e');
      return false;
    }
  }

  /// Stop background tracking for a volunteer
  /// 
  /// This should be called when delivery is completed or cancelled
  static Future<bool> stopVolunteerTracking({
    required String volunteerId,
    required String taskId,
  }) async {
    try {
      debugPrint('⏹️ Stopping tracking for volunteer: $volunteerId');

      // 1. Stop background GPS tracking
      await _backgroundTrackingService.stopBackgroundTracking(volunteerId);

      // 2. Remove geofences
      await _geofenceBackgroundService.removeGeofenceForTask(taskId);

      debugPrint('✅ Volunteer tracking stopped');
      return true;
    } catch (e) {
      debugPrint('❌ Error stopping volunteer tracking: $e');
      return false;
    }
  }

  /// Get tracking statistics
  static Map<String, dynamic> getTrackingStats() {
    return {
      'geofenceStats': _geofenceBackgroundService.getCacheStats(),
    };
  }

  /// Cleanup and dispose of services
  static Future<void> dispose() async {
    try {
      debugPrint('🧹 Disposing Tracking Services...');
      await _geofenceBackgroundService.clearAllGeofences();
      await _backgroundTrackingService.stopBackgroundTracking('all');
      debugPrint('✅ Tracking Services disposed');
    } catch (e) {
      debugPrint('❌ Error disposing services: $e');
    }
  }
}

/// Example usage in main.dart:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize Firebase
///   await Firebase.initializeApp();
///   
///   // Initialize tracking services
///   final realTimeTrackingService = RealTimeTrackingService(...);
///   await TrackingServicesInitializer.initialize(
///     realTimeTrackingService: realTimeTrackingService,
///   );
///   
///   runApp(const MyApp());
/// }
/// ```
/// 
/// Example usage when starting a delivery:
/// 
/// ```dart
/// onVolunteerAcceptsTask() {
///   await TrackingServicesInitializer.startVolunteerTracking(
///     volunteerId: 'volunteer_123',
///     taskId: 'task_456',
///     pickupLat: 28.6139,
///     pickupLng: 77.2090,
///     deliveryLat: 28.6300,
///     deliveryLng: 77.2100,
///   );
/// }
/// ```
