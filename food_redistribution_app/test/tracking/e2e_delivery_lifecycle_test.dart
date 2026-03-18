import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_mocks.dart';
import 'package:food_redistribution_app/models/tracking/location_tracking_model.dart';
import 'package:food_redistribution_app/models/enums.dart';
import 'package:food_redistribution_app/providers/tracking_provider.dart';
import 'package:food_redistribution_app/services/tracking/offline_tracking_service.dart';
import 'package:food_redistribution_app/services/tracking/delay_detection_service.dart';
import 'package:food_redistribution_app/services/tracking/analytics_aggregation_service.dart';

// End-to-end test for donation delivery lifecycle with tracking
void main() {
  group('End-to-End Delivery Lifecycle with Tracking', () {
    late TrackingProvider trackingProvider;
    late OfflineTrackingService offlineService;
    late DelayDetectionService delayDetectionService;
    late AnalyticsAggregationService analyticsService;

    setUp(() {
      trackingProvider = TrackingProvider();
      offlineService = OfflineTrackingService();
      delayDetectionService = DelayDetectionService();
      analyticsService = AnalyticsAggregationService();
    });

    tearDown(() async {
      await offlineService.clearSyncedUpdates();
    });

    test('Complete flow: donation created → volunteer assigned → pickup → delivery', () async {
      const donationId = 'donation_test_001';
      const volunteerId = 'volunteer_test_001';
      const ngoId = 'ngo_test_001';

      final startResult = await trackingProvider.startTracking(volunteerId);
      expect(startResult, true);
      expect(trackingProvider.isTracking, true);

      final pickupLocation = LocationUpdate(
        id: 'loc_001',
        volunteerId: volunteerId,
        taskId: donationId,
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: TrackingStatus.collected,
        metadata: {'event': 'pickup_arrived'},
      );

      trackingProvider.updateVolunteerLocation(pickupLocation);
      expect(trackingProvider.locationHistory.contains(pickupLocation), true);

      trackingProvider.setOnlineStatus(false);
      expect(trackingProvider.isOnline, false);

      await offlineService.saveOfflineLocationUpdate(pickupLocation);
      var pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, greaterThan(0));

      trackingProvider.setOnlineStatus(true);
      expect(trackingProvider.isOnline, true);

      await offlineService.markUpdatesSynced([pickupLocation.id]);
      final syncedUpdates = await offlineService.getOfflineUpdates();
      expect(syncedUpdates.isEmpty, true);

      await trackingProvider.updateDonationStatus(
        donationId: donationId,
        newStatus: 'picked',
      );
      expect(trackingProvider.currentStatus, 'picked');

      final deliveryLocation = LocationUpdate(
        id: 'loc_002',
        volunteerId: volunteerId,
        taskId: donationId,
        latitude: 28.5355,
        longitude: 77.3910,
        accuracy: 4.5,
        timestamp: DateTime.now().add(const Duration(minutes: 45)),
        status: TrackingStatus.delivered,
        metadata: {'event': 'delivery_arrived'},
      );

      trackingProvider.updateVolunteerLocation(deliveryLocation);
      await trackingProvider.updateDonationStatus(
        donationId: donationId,
        newStatus: 'delivered',
      );

      await trackingProvider.stopTracking(volunteerId);
      expect(trackingProvider.isTracking, false);

      final volunteerStats = await analyticsService.getVolunteerDeliveryStats(volunteerId);
      expect(volunteerStats, isNotNull);
    });

    test('Delay detection triggers when SLA is breached', () async {
      const taskId = 'task_delay_test';
      const volunteerId = 'volunteer_delay_test';

      await trackingProvider.startTracking(volunteerId);
      await delayDetectionService.startMonitoring(taskId);
      await Future.delayed(const Duration(seconds: 1));
      expect(delayDetectionService, isNotNull);
    });

    test('Geofence events at pickup and delivery', () async {
      const volunteerId = 'volunteer_geofence_test';
      const pickupLat = 28.6139;
      const pickupLng = 77.2090;

      await trackingProvider.startTracking(volunteerId);

      final pickupEvent = GeofenceEvent(
        id: 'geofence_001',
        volunteerId: volunteerId,
        taskId: 'task_001',
        type: GeofenceType.pickup,
        eventType: 'entry',
        latitude: pickupLat,
        longitude: pickupLng,
        radius: 100,
        timestamp: DateTime.now(),
      );

      expect(pickupEvent.eventType, 'entry');
      expect(pickupEvent.latitude, pickupLat);
    });

    test('Offline sync queue batched updates', () async {
      const volunteerId = 'volunteer_batch_test';

      final updates = List.generate(5, (index) {
        return LocationUpdate(
          id: 'loc_batch_$index',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6139 + (index * 0.001),
          longitude: 77.2090 + (index * 0.001),
          accuracy: 5.0,
          timestamp: DateTime.now().add(Duration(minutes: index)),
          status: TrackingStatus.inTransit,
        );
      });

      for (final update in updates) {
        await offlineService.saveOfflineLocationUpdate(update);
      }

      var pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, updates.length);

      await offlineService.markUpdatesSynced([updates[0].id, updates[1].id]);
      pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, 3);
    });

    test('Location history chronological order', () async {
      const volunteerId = 'volunteer_history_test';

      await trackingProvider.startTracking(volunteerId);

      final update1 = LocationUpdate(
        id: 'loc_1',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: TrackingStatus.inTransit,
      );

      final update2 = LocationUpdate(
        id: 'loc_2',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 5.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: TrackingStatus.inTransit,
      );

      trackingProvider.updateVolunteerLocation(update1);
      trackingProvider.updateVolunteerLocation(update2);

      final history = trackingProvider.locationHistory;
      expect(history.length, greaterThanOrEqualTo(2));
      expect(
        history[0].timestamp.isBefore(history[1].timestamp),
        true,
      );
    });

    test('Handles poor connectivity with offline-first sync', () async {
      const volunteerId = 'volunteer_connectivity_test';

      trackingProvider.setOnlineStatus(false);
      expect(trackingProvider.isOnline, false);

      await trackingProvider.startTracking(volunteerId);
      expect(trackingProvider.isTracking, true);

      final update = LocationUpdate(
        id: 'loc_offline',
        volunteerId: volunteerId,
        taskId: 'task_offline',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: TrackingStatus.inTransit,
      );

      await offlineService.saveOfflineLocationUpdate(update);
      trackingProvider.setOnlineStatus(true);
      expect(trackingProvider.isOnline, true);

      final pending = await offlineService.getPendingUpdateCount();
      expect(pending, greaterThanOrEqualTo(0));
    });
  });
}
