import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_redistribution_app/services/firestore_service.dart';
import 'package:food_redistribution_app/services/location_service.dart';
import 'package:food_redistribution_app/services/real_time_tracking_service.dart';
import 'package:food_redistribution_app/services/tracking_service.dart';

// Mock classes for testing
class MockFirestoreService extends Mock implements FirestoreService {}

class MockLocationService extends Mock implements LocationService {}

class MockRealTimeTrackingService extends Mock implements RealTimeTrackingService {}

class MockTrackingService extends Mock implements TrackingService {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

// Helper class for creating test data
class TestDataBuilder {
  static Map<String, dynamic> createLocationUpdateMap({
    String? id,
    String? volunteerId,
    String? taskId,
    double latitude = 28.6139,
    double longitude = 77.2090,
    double accuracy = 5.0,
    double speed = 0.0,
    double heading = 0.0,
    String status = 'in_transit',
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'test_loc_${DateTime.now().millisecondsSinceEpoch}',
      'volunteerId': volunteerId ?? 'test_volunteer',
      'taskId': taskId ?? 'test_task',
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.now(),
      'status': status,
      'metadata': metadata ?? {},
    };
  }

  static Map<String, dynamic> createDelayAlertMap({
    String? id,
    String? taskId,
    String delayType = 'pickup_delay',
    String severity = 'high',
    String? reason,
  }) {
    return {
      'id': id ?? 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
      'taskId': taskId ?? 'test_task',
      'delayType': delayType,
      'severity': severity,
      'reason': reason,
      'detectedAt': Timestamp.now(),
    };
  }

  static Map<String, dynamic> createGeofenceEventMap({
    String? id,
    String? volunteerId,
    String? taskId,
    double latitude = 28.6139,
    double longitude = 77.2090,
    double radius = 100,
    String eventType = 'entry',
  }) {
    return {
      'id': id ?? 'test_geofence_${DateTime.now().millisecondsSinceEpoch}',
      'volunteerId': volunteerId ?? 'test_volunteer',
      'taskId': taskId ?? 'test_task',
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'eventType': eventType,
      'timestamp': Timestamp.now(),
    };
  }

  static Map<String, dynamic> createTrackingMetricsMap({
    String? volunteerId,
    double distanceKm = 15.5,
    int durationMinutes = 60,
    int pickupWaitMinutes = 10,
    int deliveryWaitMinutes = 5,
    double averageSpeed = 15.5,
  }) {
    return {
      'volunteerId': volunteerId ?? 'test_volunteer',
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'pickupWaitMinutes': pickupWaitMinutes,
      'deliveryWaitMinutes': deliveryWaitMinutes,
      'averageSpeed': averageSpeed,
      'locationUpdateCount': 120,
      'geofenceEventCount': 2,
    };
  }

  static Map<String, dynamic> createVolunteerStatsMap({
    String? volunteerId,
    int totalDeliveries = 50,
    double totalDistanceKm = 750,
    int totalDurationMinutes = 3000,
  }) {
    return {
      'volunteerId': volunteerId ?? 'test_volunteer',
      'totalDeliveries': totalDeliveries,
      'totalDistanceKm': totalDistanceKm,
      'totalDurationMinutes': totalDurationMinutes,
      'avgPickupTime': 12,
      'avgDeliveryTime': 8,
      'lastDelivery': Timestamp.now(),
    };
  }

  static Map<String, dynamic> createNGOStatsMap({
    String? ngoId,
    int totalDeliveries = 200,
    int totalMeals = 5000,
    int totalPeopleServed = 2500,
  }) {
    return {
      'ngoId': ngoId ?? 'test_ngo',
      'totalDeliveries': totalDeliveries,
      'totalMeals': totalMeals,
      'totalPeopleServed': totalPeopleServed,
      'avgDeliveryTime': 45,
      'successRate': 98.5,
    };
  }
}

// Test scenario builder for common flows
class TrackingTestScenarios {
  static Map<String, dynamic> completeDeliveryScenario() {
    return {
      'volunteerId': 'scenario_volunteer_001',
      'taskId': 'scenario_task_001',
      'pickupLocation': {'latitude': 28.6139, 'longitude': 77.2090},
      'deliveryLocation': {'latitude': 28.5355, 'longitude': 77.3910},
      'estimatedDurationMinutes': 60,
      'events': [
        {'type': 'assignment', 'timeMinute': 0},
        {'type': 'accepted', 'timeMinute': 1},
        {'type': 'pickup_arrived', 'timeMinute': 12},
        {'type': 'food_picked', 'timeMinute': 15},
        {'type': 'delivery_arrived', 'timeMinute': 65},
        {'type': 'delivery_complete', 'timeMinute': 67},
      ],
    };
  }

  static Map<String, dynamic> delayedDeliveryScenario() {
    return {
      'volunteerId': 'scenario_volunteer_delay',
      'taskId': 'scenario_task_delay',
      'pickupLocation': {'latitude': 28.6139, 'longitude': 77.2090},
      'deliveryLocation': {'latitude': 28.5355, 'longitude': 77.3910},
      'pickupSLA': 60,
      'deliverySLA': 120,
      'actualPickupTime': 75,
      'actualDeliveryTime': 135,
      'delayReasons': ['Heavy traffic', 'Volunteer got stuck in traffic'],
    };
  }

  static Map<String, dynamic> offlineSyncScenario() {
    return {
      'volunteerId': 'scenario_volunteer_offline',
      'taskId': 'scenario_task_offline',
      'offlineDuration': Duration(minutes: 15),
      'updatesWhileOffline': 6,
      'syncTimeTakenSeconds': 3,
      'expectedSyncedUpdates': 6,
    };
  }

  static Map<String, dynamic> multipleConcurrentDeliveriesScenario() {
    return {
      'volunteerId': 'scenario_volunteer_multi',
      'assignedTasks': [
        {
          'taskId': 'scenario_task_multi_1',
          'order': 1,
          'pickupLocation': {'latitude': 28.6139, 'longitude': 77.2090},
          'deliveryLocation': {'latitude': 28.6200, 'longitude': 77.2150},
        },
        {
          'taskId': 'scenario_task_multi_2',
          'order': 2,
          'pickupLocation': {'latitude': 28.6250, 'longitude': 77.2200},
          'deliveryLocation': {'latitude': 28.5355, 'longitude': 77.3910},
        },
        {
          'taskId': 'scenario_task_multi_3',
          'order': 3,
          'pickupLocation': {'latitude': 28.5300, 'longitude': 77.3800},
          'deliveryLocation': {'latitude': 28.5200, 'longitude': 77.3700},
        },
      ],
      'expectedCompletionTime': 180,
    };
  }
}

// Assertion helpers
extension TrackingAssertions on dynamic {
  void expectValidLocationUpdate() {
    assert(this is Map<String, dynamic>);
    final map = this as Map<String, dynamic>;
    assert(map.containsKey('id'));
    assert(map.containsKey('volunteerId'));
    assert(map.containsKey('latitude'));
    assert(map.containsKey('longitude'));
    assert(map.containsKey('timestamp'));
    final lat = map['latitude'] as double;
    final lng = map['longitude'] as double;
    assert(lat >= -90 && lat <= 90, 'Invalid latitude');
    assert(lng >= -180 && lng <= 180, 'Invalid longitude');
  }

  void expectValidDelayAlert() {
    assert(this is Map<String, dynamic>);
    final map = this as Map<String, dynamic>;
    assert(map.containsKey('id'));
    assert(map.containsKey('taskId'));
    assert(map.containsKey('delayType'));
    assert(map.containsKey('severity'));
    final severity = map['severity'] as String;
    assert(
      ['low', 'medium', 'high', 'critical'].contains(severity),
      'Invalid severity level',
    );
  }

  void expectValidGeofenceEvent() {
    assert(this is Map<String, dynamic>);
    final map = this as Map<String, dynamic>;
    assert(map.containsKey('id'));
    assert(map.containsKey('volunteerId'));
    assert(map.containsKey('latitude'));
    assert(map.containsKey('longitude'));
    assert(map.containsKey('radius'));
    assert(map.containsKey('eventType'));
    final eventType = map['eventType'] as String;
    assert(['entry', 'exit'].contains(eventType), 'Invalid event type');
  }
}
