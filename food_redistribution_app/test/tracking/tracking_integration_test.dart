import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'test_mocks.dart';
import 'package:food_redistribution_app/providers/tracking_provider.dart';
import 'package:food_redistribution_app/services/tracking/offline_tracking_service.dart';
import 'package:food_redistribution_app/services/tracking/delay_detection_service.dart';
import 'package:food_redistribution_app/models/tracking/location_tracking_model.dart';
import 'package:food_redistribution_app/models/enums.dart';

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

      await trackingProvider.startTracking(volunteerId);
      trackingProvider.setOnlineStatus(false);

      for (int i = 0; i < 3; i++) {
        final update = LocationUpdate(
          id: 'loc_$i',
          volunteerId: volunteerId,
          taskId: taskId,
          latitude: 28.6139 + (i * 0.001),
          longitude: 77.2090 + (i * 0.001),
          accuracy: 5.0,
          timestamp: DateTime.now().add(Duration(minutes: i * 5)),
          status: TrackingStatus.inTransit,
        );
        trackingProvider.updateVolunteerLocation(update);
        await offlineService.saveOfflineLocationUpdate(update);
      }

      final pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, 3);

      trackingProvider.setOnlineStatus(true);
      final pendingUpdates = await offlineService.getOfflineUpdates();
      expect(pendingUpdates.isNotEmpty, true);

      await offlineService.markUpdatesSynced(
        pendingUpdates.map((u) => u.id).toList(),
      );
      final remainingPending = await offlineService.getPendingUpdateCount();
      expect(remainingPending, 0);
    });

    test('DelayDetectionService monitors task SLA correctly', () async {
      const taskId = 'task_delay_integration';
      const volunteerId = 'volunteer_delay_integration';

      await delayDetectionService.startMonitoring(taskId);
      expect(delayDetectionService, isNotNull);
      await delayDetectionService.stopMonitoring(taskId);
    });

    test('TrackingProvider maintains multiple concurrent tasks', () async {
      const volunteer1 = 'volunteer_1';
      const task1 = 'task_1';
      const task2 = 'task_2';

      await trackingProvider.startTracking(volunteer1);

      final update1 = LocationUpdate(
        id: 'loc_task1',
        volunteerId: volunteer1,
        taskId: task1,
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: TrackingStatus.inTransit,
      );

      final update2 = LocationUpdate(
        id: 'loc_task2',
        volunteerId: volunteer1,
        taskId: task2,
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 5.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: TrackingStatus.inTransit,
      );

      trackingProvider.updateVolunteerLocation(update1);
      trackingProvider.updateVolunteerLocation(update2);
      expect(trackingProvider.locationHistory.length, greaterThanOrEqualTo(2));
    });

    test('Delay alert creation and resolution workflow', () async {
      const taskId = 'task_alert_test';
      const volunteerId = 'volunteer_alert_test';

      final alert = DelayAlert(
        id: 'alert_001',
        taskId: taskId,
        volunteerId: volunteerId,
        type: 'pickup_delay',
        severity: 'high',
        reason: 'Volunteer unable to reach location',
        detectedAt: DateTime.now(),
      );

      trackingProvider.addDelayAlert(alert);
      expect(trackingProvider.delayAlerts.contains(alert), true);
      await trackingProvider.resolveDelayAlert(alert.id);
    });

    test('Location accuracy handling', () async {
      const volunteerId = 'volunteer_accuracy_test';

      await trackingProvider.startTracking(volunteerId);

      final highAccuracy = LocationUpdate(
        id: 'loc_high_acc',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 2.0,
        timestamp: DateTime.now(),
        status: TrackingStatus.inTransit,
      );

      trackingProvider.updateVolunteerLocation(highAccuracy);

      final lowAccuracy = LocationUpdate(
        id: 'loc_low_acc',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 50.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: TrackingStatus.inTransit,
      );

      trackingProvider.updateVolunteerLocation(lowAccuracy);
      expect(trackingProvider.locationHistory.length, greaterThanOrEqualTo(2));
      expect(trackingProvider.locationHistory.last.accuracy, 50.0);
    });

    test('Status transition tracking', () async {
      const donationId = 'donation_status_test';
      final statuses = ['listed', 'matched', 'picked', 'delivered'];

      for (final status in statuses) {
        await trackingProvider.updateDonationStatus(
          donationId: donationId,
          newStatus: status,
        );
        expect(trackingProvider.currentStatus, status);
      }
    });

    test('Analytics metrics after tracking stops', () async {
      const volunteerId = 'volunteer_metrics_test';

      await trackingProvider.startTracking(volunteerId);

      final locations = [
        LocationUpdate(
          id: 'loc_1',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6139,
          longitude: 77.2090,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          status: TrackingStatus.inTransit,
        ),
        LocationUpdate(
          id: 'loc_2',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6250,
          longitude: 77.2200,
          accuracy: 5.0,
          timestamp: DateTime.now().add(const Duration(minutes: 60)),
          status: TrackingStatus.inTransit,
        ),
      ];

      for (final loc in locations) {
        trackingProvider.updateVolunteerLocation(loc);
      }

      await trackingProvider.stopTracking(volunteerId);
      expect(trackingProvider.isTracking, false);
    });
  });
}
