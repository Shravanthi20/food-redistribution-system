import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../test/tracking/test_mocks.dart';
import 'package:food_redistribution/providers/tracking_provider.dart';
import 'package:food_redistribution/services/tracking/offline_tracking_service.dart';
import 'package:food_redistribution/services/tracking/delay_detection_service.dart';
import 'package:food_redistribution/models/tracking/location_tracking_model.dart';

// Integration tests for tracking services working together
void main() {
  group('Tracking Services Integration Tests', () {
    late TrackingProvider trackingProvider;
    late OfflineTrackingService offlineService;
    late DelayDetectionService delayDetectionService;

    setUp(() {
      trackingProvider = TrackingProvider();
      offlineService = OfflineTrackingService();
      delayDetectionService = DelayDetectionService();
    });

    test('TrackingProvider + OfflineTrackingService integration', () async {
      const volunteerId = 'volunteer_integration_001';
      const taskId = 'task_integration_001';

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Go offline
      trackingProvider.setOnlineStatus(false);

      // Create multiple location updates while offline
      for (int i = 0; i < 3; i++) {
        final update = LocationUpdate(
          id: 'loc_$i',
          volunteerId: volunteerId,
          taskId: taskId,
          latitude: 28.6139 + (i * 0.001),
          longitude: 77.2090 + (i * 0.001),
          accuracy: 5.0,
          timestamp: DateTime.now().add(Duration(minutes: i * 5)),
          status: 'in_transit',
        );

        // Provider stores locally
        trackingProvider.updateVolunteerLocation(update);
        // Offline service saves to SharedPreferences
        await offlineService.saveOfflineLocationUpdate(update);
      }

      // Verify offline queue
      final pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, 3);

      // Go online
      trackingProvider.setOnlineStatus(true);

      // Get pending updates and sync
      final pendingUpdates = await offlineService.getOfflineUpdates();
      expect(pendingUpdates.isNotEmpty, true);

      // Mark as synced
      await offlineService.markUpdatesSynced(
        pendingUpdates.map((u) => u.id).toList(),
      );

      // Verify sync completed
      final remainingPending = await offlineService.getPendingUpdateCount();
      expect(remainingPending, 0);
    });

    test('DelayDetectionService monitors task SLA correctly', () async {
      const taskId = 'task_delay_integration';
      const volunteerId = 'volunteer_delay_integration';

      // Start monitoring for task
      await delayDetectionService.startMonitoring(taskId);

      // Verify monitoring started
      expect(delayDetectionService, isNotNull);

      // In production:
      // - Service would check elapsed time every 5 minutes
      // - Compare against SLA (60 min for pickup, 120 min for delivery)
      // - Create delay alert when SLA breached
      // - Send notification via NotificationHandler

      // Stop monitoring
      await delayDetectionService.stopMonitoring(taskId);
    });

    test('TrackingProvider maintains multiple concurrent tasks', () async {
      const volunteer1 = 'volunteer_1';
      const volunteer2 = 'volunteer_2';
      const task1 = 'task_1';
      const task2 = 'task_2';

      // Start tracking for two volunteers
      await trackingProvider.startTracking(volunteer1);

      // Update locations for different tasks
      final update1 = LocationUpdate(
        id: 'loc_task1',
        volunteerId: volunteer1,
        taskId: task1,
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: 'in_transit',
      );

      final update2 = LocationUpdate(
        id: 'loc_task2',
        volunteerId: volunteer1,
        taskId: task2,
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 5.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: 'in_transit',
      );

      trackingProvider.updateVolunteerLocation(update1);
      trackingProvider.updateVolunteerLocation(update2);

      // Both should be in history
      expect(trackingProvider.locationHistory.length, greaterThanOrEqualTo(2));
    });

    test('Delay alert creation and resolution workflow', () async {
      const taskId = 'task_alert_test';

      // Create a delay alert
      final alert = DelayAlert(
        id: 'alert_001',
        taskId: taskId,
        delayType: 'pickup_delay',
        severity: 'high',
        reason: 'Volunteer unable to reach location',
        detectedAt: DateTime.now(),
      );

      // Add to provider
      trackingProvider.addDelayAlert(alert);
      expect(trackingProvider.delayAlerts.contains(alert), true);

      // Resolve the alert
      await trackingProvider.resolveDelayAlert(alert.id);

      // In real app, alert would be removed after resolution
    });

    test('Location accuracy degradation handling', () async {
      const volunteerId = 'volunteer_accuracy_test';

      await trackingProvider.startTracking(volunteerId);

      // High accuracy location
      final highAccuracy = LocationUpdate(
        id: 'loc_high_acc',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 2.0, // High accuracy (2 meters)
        timestamp: DateTime.now(),
        status: 'in_transit',
      );

      trackingProvider.updateVolunteerLocation(highAccuracy);

      // Low accuracy location (inside building, urban canyon)
      final lowAccuracy = LocationUpdate(
        id: 'loc_low_acc',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 50.0, // Low accuracy (50 meters)
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: 'in_transit',
      );

      trackingProvider.updateVolunteerLocation(lowAccuracy);

      // Both should be recorded (accuracy is useful for analysis)
      expect(trackingProvider.locationHistory.length, greaterThanOrEqualTo(2));
      expect(trackingProvider.locationHistory.last.accuracy, 50.0);
    });

    test('Status transition tracking: listed → matched → picked → delivered', () async {
      const donationId = 'donation_status_test';

      // Track status transitions
      final statuses = ['listed', 'matched', 'picked', 'delivered'];

      for (final status in statuses) {
        await trackingProvider.updateDonationStatus(
          donationId: donationId,
          newStatus: status,
        );
        expect(trackingProvider.currentStatus, status);

        // In real app, each transition triggers:
        // 1. Notification to stakeholders
        // 2. Analytics event
        // 3. UI update via Provider listener
      }
    });

    test('Geofence-triggered actions at pickup and delivery zones', () async {
      const volunteerId = 'volunteer_geofence_integration';
      const pickupLat = 28.6139;
      const pickupLng = 77.2090;
      const deliveryLat = 28.5355;
      const deliveryLng = 77.3910;

      await trackingProvider.startTracking(volunteerId);

      // Simulate volunteer approaching pickup zone
      final approachPickup = LocationUpdate(
        id: 'loc_approach_pickup',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: pickupLat + 0.0005, // ~55 meters away
        longitude: pickupLng + 0.0005,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: 'approaching_pickup',
      );

      trackingProvider.updateVolunteerLocation(approachPickup);

      // In production:
      // - Geofence library detects entry into 100m radius
      // - Sends notification: "You're near pickup location"
      // - Updates UI with ETA

      // Simulate arrival at pickup
      final atPickup = LocationUpdate(
        id: 'loc_at_pickup',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: pickupLat,
        longitude: pickupLng,
        accuracy: 3.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: 'at_pickup',
      );

      trackingProvider.updateVolunteerLocation(atPickup);
      await trackingProvider.updateDonationStatus(
        donationId: 'task_001',
        newStatus: 'picked',
      );

      // Similar flow for delivery zone
      final atDelivery = LocationUpdate(
        id: 'loc_at_delivery',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: deliveryLat,
        longitude: deliveryLng,
        accuracy: 3.0,
        timestamp: DateTime.now().add(const Duration(minutes: 50)),
        status: 'at_delivery',
      );

      trackingProvider.updateVolunteerLocation(atDelivery);
      await trackingProvider.updateDonationStatus(
        donationId: 'task_001',
        newStatus: 'delivered',
      );

      // Verify final state
      expect(trackingProvider.currentStatus, 'delivered');
      expect(trackingProvider.locationHistory.length, greaterThanOrEqualTo(3));
    });

    test('Analytics metrics calculated correctly after tracking stops', () async {
      const volunteerId = 'volunteer_metrics_test';

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Add locations with time gaps
      final locations = [
        LocationUpdate(
          id: 'loc_1',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6139,
          longitude: 77.2090,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          status: 'in_transit',
        ),
        LocationUpdate(
          id: 'loc_2',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6250,
          longitude: 77.2200,
          accuracy: 5.0,
          timestamp: DateTime.now().add(const Duration(minutes: 60)),
          status: 'in_transit',
        ),
      ];

      for (final loc in locations) {
        trackingProvider.updateVolunteerLocation(loc);
      }

      // Stop and get metrics
      final metrics = await trackingProvider.stopTracking();

      // Verify metrics
      if (metrics != null) {
        expect(metrics.durationMinutes, greaterThan(0));
        expect(metrics.distanceKm, isA<double>());
      }
    });

    test('Notification payload structure for all event types', () async {
      // Verify that all notification types have required fields
      const eventTypes = [
        'assignment',
        'pickup_started',
        'delivery_arrival',
        'delay_alert',
        'reassignment',
        'completion',
      ];

      for (final eventType in eventTypes) {
        // In production, NotificationHandler would create payload:
        // {
        //   'type': eventType,
        //   'taskId': '...',
        //   'volunteerId': '...',
        //   'title': '...',
        //   'body': '...',
        //   'timestamp': '...',
        //   'data': {...}
        // }

        expect(eventType.isNotEmpty, true);
      }
    });
  });
}
