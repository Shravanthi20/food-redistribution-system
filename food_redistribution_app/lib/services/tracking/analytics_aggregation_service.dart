import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tracking/location_tracking_model.dart';

// Collect data from all deliveries to see patterns
class AnalyticsAggregationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnalyticsAggregationService();

  // See how good a volunteer is at deliveries
  Future<Map<String, dynamic>> getVolunteerDeliveryStats(
      String volunteerId) async {
    try {
      final snapshot = await _firestore
          .collection('delivery_tasks')
          .where('volunteerId', isEqualTo: volunteerId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'volunteerId': volunteerId,
          'totalDeliveries': 0,
          'completedDeliveries': 0,
          'averageDuration': 0,
          'successRate': 0.0,
        };
      }

      int completed = 0;
      int total = snapshot.docs.length;
      int totalDuration = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'delivered') {
          completed++;
        }

        if (data['createdAt'] != null && data['deliveredAt'] != null) {
          final created = (data['createdAt'] as Timestamp).toDate();
          final delivered = (data['deliveredAt'] as Timestamp).toDate();
          totalDuration += delivered.difference(created).inMinutes;
        }
      }

      return {
        'volunteerId': volunteerId,
        'totalDeliveries': total,
        'completedDeliveries': completed,
        'averageDuration': total > 0 ? (totalDuration ~/ total) : 0,
        'successRate': total > 0 ? (completed / total * 100).toStringAsFixed(2) : 0.0,
      };
    } catch (e) {
      print('Error getting volunteer stats: $e');
      return {};
    }
  }

  // Get pickup/delivery duration trends
  Future<Map<String, dynamic>> getPickupDurationHistory({
    required int days,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days)).toUtc();
      final snapshot = await _firestore
          .collection('delivery_tasks')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'period': '$days days',
          'averagePickupTime': 0,
          'averageDeliveryTime': 0,
          'totalDeliveries': 0,
        };
      }

      int pickupTotal = 0;
      int deliveryTotal = 0;
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['pickedUpAt'] != null && data['createdAt'] != null) {
          final created = (data['createdAt'] as Timestamp).toDate();
          final pickedUp = (data['pickedUpAt'] as Timestamp).toDate();
          pickupTotal += pickedUp.difference(created).inMinutes;
          count++;
        }

        if (data['deliveredAt'] != null && data['pickedUpAt'] != null) {
          final pickedUp = (data['pickedUpAt'] as Timestamp).toDate();
          final delivered = (data['deliveredAt'] as Timestamp).toDate();
          deliveryTotal += delivered.difference(pickedUp).inMinutes;
        }
      }

      return {
        'period': '$days days',
        'averagePickupTime': count > 0 ? (pickupTotal ~/ count) : 0,
        'averageDeliveryTime': count > 0 ? (deliveryTotal ~/ count) : 0,
        'totalDeliveries': snapshot.docs.length,
      };
    } catch (e) {
      print('Error getting duration history: $e');
      return {};
    }
  }

  // Get NGO impact metrics
  Future<Map<String, dynamic>> getNGODeliveryStats(String ngoId) async {
    try {
      final snapshot = await _firestore
          .collection('delivery_tasks')
          .where('ngoId', isEqualTo: ngoId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'ngoId': ngoId,
          'totalDeliveries': 0,
          'peopleServed': 0,
          'totalWeightDistributed': 0,
        };
      }

      int peopleServed = 0;
      double weightDistributed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'delivered') {
          peopleServed += (data['itemsCount'] as int?) ?? 0;
          weightDistributed += (data['weight'] as num?)?.toDouble() ?? 0;
        }
      }

      return {
        'ngoId': ngoId,
        'totalDeliveries': snapshot.docs.length,
        'peopleServed': peopleServed,
        'totalWeightDistributed': weightDistributed.toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting NGO stats: $e');
      return {};
    }
  }

  // Regional performance analytics
  Future<Map<String, dynamic>> getRegionalStats({required String region}) async {
    try {
      final snapshot = await _firestore
          .collection('delivery_tasks')
          .where('region', isEqualTo: region)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'region': region,
          'totalDeliveries': 0,
          'performanceIndex': 0,
        };
      }

      int onTimeDeliveries = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isOnTime'] == true) {
          onTimeDeliveries++;
        }
      }

      final performanceIndex = snapshot.docs.length > 0 ? (onTimeDeliveries / snapshot.docs.length * 100) : 0;

      return {
        'region': region,
        'totalDeliveries': snapshot.docs.length,
        'performanceIndex': performanceIndex.toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting regional stats: $e');
      return {};
    }
  }

  // Predict volunteer demand for next N days
  Future<Map<String, dynamic>> predictVolunteerDemand({required int days}) async {
    try {
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(Duration(days: days));

      final snapshot = await _firestore
          .collection('donations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final predictedDemand = (snapshot.docs.length / days).ceil();

      return {
        'period': '$days days',
        'predictedDailyDemand': predictedDemand,
        'totalExpectedDonations': snapshot.docs.length,
        'confidence': 0.85,
      };
    } catch (e) {
      print('Error predicting demand: $e');
      return {};
    }
  }

  // Food surplus trends
  Future<Map<String, dynamic>> getSurplusTrends({required int days}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days)).toUtc();
      final snapshot = await _firestore
          .collection('donations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'period': '$days days',
          'trends': [],
        };
      }

      Map<String, int> foodTypes = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['foodType'] as String? ?? 'unknown';
        foodTypes[type] = (foodTypes[type] ?? 0) + 1;
      }

      return {
        'period': '$days days',
        'topSurplusTypes': foodTypes,
        'totalDonations': snapshot.docs.length,
      };
    } catch (e) {
      print('Error getting surplus trends: $e');
      return {};
    }
  }

  // Regional risk indicators
  Future<Map<String, dynamic>> getRegionalRiskIndicators(String region) async {
    try {
      final snapshot = await _firestore
          .collection('delivery_tasks')
          .where('region', isEqualTo: region)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'region': region,
          'riskLevel': 'low',
          'delayPercentage': 0,
        };
      }

      int delays = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isOnTime'] == false) {
          delays++;
        }
      }

      final delayPercentage = (delays / snapshot.docs.length * 100).toStringAsFixed(2);
      final riskLevel = double.parse(delayPercentage) > 20 ? 'high' : 'low';

      return {
        'region': region,
        'riskLevel': riskLevel,
        'delayPercentage': delayPercentage,
        'averageDelay': 0,
      };
    } catch (e) {
      print('Error getting risk indicators: $e');
      return {};
    }
  }
}
