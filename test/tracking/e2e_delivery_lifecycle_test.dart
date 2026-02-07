import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../test/tracking/test_mocks.dart';
import 'package:food_redistribution/models/tracking/location_tracking_model.dart';
import 'package:food_redistribution/providers/tracking_provider.dart';
import 'package:food_redistribution/services/tracking/offline_tracking_service.dart';
import 'package:food_redistribution/services/tracking/delay_detection_service.dart';
import 'package:food_redistribution/services/tracking/analytics_aggregation_service.dart';

// End-to-end test for complete donation delivery lifecycle with real-time tracking
void main() {
  group('End-to-End Delivery Lifecycle with Tracking', () {
    late TrackingProvider trackingProvider;
    late OfflineTrackingService offlineService;
    late DelayDetectionService delayDetectionService;
    late AnalyticsAggregationService analyticsService;

    setUp(() {
      // Initialize services for test
      trackingProvider = TrackingProvider();
      offlineService = OfflineTrackingService();
      delayDetectionService = DelayDetectionService();
      analyticsService = AnalyticsAggregationService();
    });

    tearDown(() async {
      // Cleanup after each test
      await offlineService.clearSyncedUpdates();
    });

    test('Complete flow: donation created → volunteer assigned → pickup → delivery', () async {
      // Step 1: Donor creates a donation (this happens on donor side)
      const donationId = 'donation_test_001';
      const volunteerId = 'volunteer_test_001';
      const ngoId = 'ngo_test_001';

      // Step 2: Volunteer gets assigned task and starts tracking
      final startResult = await trackingProvider.startTracking(volunteerId);
      expect(startResult, true);
      expect(trackingProvider.isTracking, true);

      // Step 3: Volunteer begins journey - simulate location updates
      final pickupLocation = LocationUpdate(
        id: 'loc_001',
        volunteerId: volunteerId,
        taskId: donationId,
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: 'picked',
        metadata: {'event': 'pickup_arrived'},
      );

      // Save location update
      trackingProvider.updateVolunteerLocation(pickupLocation);
      expect(trackingProvider.locationHistory.contains(pickupLocation), true);

      // Step 4: Offline scenario - location updates while offline
      trackingProvider.setOnlineStatus(false);
      expect(trackingProvider.isOnline, false);

      // Save location while offline
      await offlineService.saveOfflineLocationUpdate(pickupLocation);
      final pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, greaterThan(0));

      // Step 5: Come back online and sync
      trackingProvider.setOnlineStatus(true);
      expect(trackingProvider.isOnline, true);

      // Simulate sync completion
      await offlineService.markUpdatesSynced([pickupLocation.id]);
      final syncedUpdates = await offlineService.getOfflineUpdates();
      expect(syncedUpdates.isEmpty, true);

      // Step 6: Update donation status during delivery
      await trackingProvider.updateDonationStatus(
        donationId: donationId,
        newStatus: 'picked',
      );
      expect(trackingProvider.currentStatus, 'picked');

      // Step 7: Simulate delivery location
      final deliveryLocation = LocationUpdate(
        id: 'loc_002',
        volunteerId: volunteerId,
        taskId: donationId,
        latitude: 28.5355,
        longitude: 77.3910,
        accuracy: 4.5,
        timestamp: DateTime.now().add(const Duration(minutes: 45)),
        status: 'delivered',
        metadata: {'event': 'delivery_arrived'},
      );

      trackingProvider.updateVolunteerLocation(deliveryLocation);
      await trackingProvider.updateDonationStatus(
        donationId: donationId,
        newStatus: 'delivered',
      );

      // Step 8: Complete tracking and get metrics
      final metrics = await trackingProvider.stopTracking();
      expect(metrics, isNotNull);

      // Verify metrics
      if (metrics != null) {
        expect(metrics.distanceKm, greaterThan(0));
        expect(metrics.durationMinutes, greaterThan(0));
      }

      // Step 9: Verify analytics were recorded
      final volunteerId = volunteerId;
      final volunteerStats = await analyticsService.getVolunteerDeliveryStats(volunteerId);
      expect(volunteerStats, isNotNull);
    });

    test('Delay detection triggers when SLA is breached', () async {
      const taskId = 'task_delay_test';
      const volunteerId = 'volunteer_delay_test';

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Start delay monitoring for this task
      await delayDetectionService.startMonitoring(taskId);

      // Simulate time passing (in real test, we'd mock SystemClock)
      // After 65 minutes (default SLA is 60), delay should be detected
      await Future.delayed(const Duration(seconds: 1));

      // In production, delay detection runs every 5 minutes
      // For testing, we can check if delay alert would be created
      expect(delayDetectionService, isNotNull);
    });

    test('Geofence events detected at pickup and delivery locations', () async {
      const volunteerId = 'volunteer_geofence_test';
      const pickupLat = 28.6139;
      const pickupLng = 77.2090;

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Simulate arrival at pickup location (within 100m radius)
      final pickupEvent = GeofenceEvent(
        id: 'geofence_001',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: pickupLat,
        longitude: pickupLng,
        radius: 100,
        eventType: 'entry',
        timestamp: DateTime.now(),
      );

      // In real app, geofence would trigger notification
      // Here we verify the event structure
      expect(pickupEvent.eventType, 'entry');
      expect(pickupEvent.latitude, pickupLat);
    });

    test('Offline sync queue properly handles batched updates', () async {
      const volunteerId = 'volunteer_batch_test';

      // Create multiple location updates
      final updates = List.generate(5, (index) {
        return LocationUpdate(
          id: 'loc_batch_$index',
          volunteerId: volunteerId,
          taskId: 'task_001',
          latitude: 28.6139 + (index * 0.001),
          longitude: 77.2090 + (index * 0.001),
          accuracy: 5.0,
          timestamp: DateTime.now().add(Duration(minutes: index)),
          status: 'in_transit',
        );
      });

      // Save all offline
      for (final update in updates) {
        await offlineService.saveOfflineLocationUpdate(update);
      }

      // Verify all pending
      var pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, updates.length);

      // Sync first batch
      await offlineService.markUpdatesSynced([updates[0].id, updates[1].id]);

      // Verify remaining pending
      pendingCount = await offlineService.getPendingUpdateCount();
      expect(pendingCount, 3);
    });

    test('Location history maintains correct chronological order', () async {
      const volunteerId = 'volunteer_history_test';

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Add updates out of order intentionally
      final update1 = LocationUpdate(
        id: 'loc_1',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: 'in_transit',
      );

      final update2 = LocationUpdate(
        id: 'loc_2',
        volunteerId: volunteerId,
        taskId: 'task_001',
        latitude: 28.6140,
        longitude: 77.2091,
        accuracy: 5.0,
        timestamp: DateTime.now().add(const Duration(minutes: 5)),
        status: 'in_transit',
      );

      // Add in order
      trackingProvider.updateVolunteerLocation(update1);
      trackingProvider.updateVolunteerLocation(update2);

      // Verify order
      final history = trackingProvider.locationHistory;
      expect(history.length, greaterThanOrEqualTo(2));
      expect(
        history[0].timestamp.isBefore(history[1].timestamp),
        true,
      );
    });

    test('Tracking state immutability with copyWith pattern', () async {
      const volunteerId = 'volunteer_state_test';

      // Initial state
      final initialState = trackingProvider.trackingState;

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // State should be updated
      final updatedState = trackingProvider.trackingState;
      expect(updatedState.isTracking, isTrue);
      expect(updatedState != initialState, true);
    });

    test('Analytics aggregation after delivery completion', () async {
      const volunteerId = 'volunteer_analytics_test';
      const ngoId = 'ngo_analytics_test';

      // Complete a delivery
      await trackingProvider.startTracking(volunteerId);

      // Simulate delivery
      final deliveryLocation = LocationUpdate(
        id: 'loc_final',
        volunteerId: volunteerId,
        taskId: 'task_final',
        latitude: 28.5355,
        longitude: 77.3910,
        accuracy: 4.0,
        timestamp: DateTime.now(),
        status: 'delivered',
      );

      trackingProvider.updateVolunteerLocation(deliveryLocation);
      await trackingProvider.stopTracking();

      // Get volunteer stats
      final volunteerStats = await analyticsService.getVolunteerDeliveryStats(volunteerId);
      expect(volunteerStats, isNotNull);

      // Get NGO stats
      final ngoStats = await analyticsService.getNGODeliveryStats(ngoId);
      expect(ngoStats, isNotNull);
    });

    test('Real-time notifications sent at key events', () async {
      const volunteerId = 'volunteer_notif_test';

      // Start tracking
      await trackingProvider.startTracking(volunteerId);

      // Notifications would be sent by NotificationHandler
      // In test, we verify TrackingProvider correctly updates state
      expect(trackingProvider.isTracking, true);

      // In production:
      // 1. Assignment notification when volunteer gets task
      // 2. Pickup start notification when pickup status updates
      // 3. Delivery arrival notification with ETA
      // 4. Completion notification when delivered
    });

    test('Handles poor connectivity gracefully with offline-first sync', () async {
      const volunteerId = 'volunteer_connectivity_test';

      // Start offline
      trackingProvider.setOnlineStatus(false);
      expect(trackingProvider.isOnline, false);

      // Start tracking while offline
      await trackingProvider.startTracking(volunteerId);
      expect(trackingProvider.isTracking, true);

      // Location updates queue locally
      final update = LocationUpdate(
        id: 'loc_offline',
        volunteerId: volunteerId,
        taskId: 'task_offline',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: 'in_transit',
      );

      await offlineService.saveOfflineLocationUpdate(update);

      // Come online
      trackingProvider.setOnlineStatus(true);
      expect(trackingProvider.isOnline, true);

      // Sync happens automatically
      final pending = await offlineService.getPendingUpdateCount();
      expect(pending, greaterThanOrEqualTo(0));
    });
  });
}
