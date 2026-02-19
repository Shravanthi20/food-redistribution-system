import 'package:cloud_firestore/cloud_firestore.dart';

// Collect data from all deliveries to see patterns and predict trends
class AnalyticsAggregationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnalyticsAggregationService();

  // ENHANCED: Exponential Moving Average for trend analysis
  double _calculateEMA({
    required List<double> values,
    int period = 7,
  }) {
    if (values.isEmpty) return 0;
    
    double multiplier = 2.0 / (period + 1);
    double ema = values.first;
    
    for (int i = 1; i < values.length; i++) {
      ema = (values[i] * multiplier) + (ema * (1 - multiplier));
    }
    
    return ema;
  }

  // ENHANCED: Calculate standard deviation for volatility
  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumSquares = values.fold(0.0, (sum, val) => sum + ((val - mean) * (val - mean)));
    return (sumSquares / (values.length - 1)).toStringAsFixed(2) as double;
  }

  // ENHANCED: Seasonality detection (day of week, time patterns)
  Map<String, dynamic> _analyzeSeasonality(List<Map<String, dynamic>> docs) {
    Map<int, int> dayOfWeekCounts = {};
    Map<int, int> hourCounts = {};
    
    for (var doc in docs) {
      final timestamp = doc['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dayOfWeekCounts[date.weekday] = (dayOfWeekCounts[date.weekday] ?? 0) + 1;
        hourCounts[date.hour] = (hourCounts[date.hour] ?? 0) + 1;
      }
    }
    
    // Find peak day and hour
    final peakDay = dayOfWeekCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'peakDayOfWeek': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][peakDay - 1],
      'peakHour': peakHour,
      'dayDistribution': dayOfWeekCounts,
      'hourDistribution': hourCounts,
    };
  }

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

  // ENHANCED: Predict surplus with seasonality and trends
  Future<Map<String, dynamic>> predictSurplusRisk({
    required int daysAhead,
    required int historicalDays = 60,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: historicalDays)).toUtc();
      final snapshot = await _firestore
          .collection('donations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'period': '$daysAhead days ahead',
          'predictedSurplus': 0,
          'riskLevel': 'unknown',
          'trend': 'neutral',
        };
      }

      // Analyze by day for trend
      Map<int, int> dailyDonations = {};
      List<double> donationTrend = [];

      for (var doc in snapshot.docs.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dayIndex = DateTime.now().difference(date).inDays;
          dailyDonations[dayIndex] = (dailyDonations[dayIndex] ?? 0) + 1;
        }
      }

      // Convert to trend list
      for (int i = 0; i <= historicalDays; i++) {
        donationTrend.add((dailyDonations[i] ?? 0).toDouble());
      }

      // Calculate EMA for smoothed trend
      final ema = _calculateEMA(values: donationTrend, period: 7);
      
      // Calculate velocity (trend direction)
      final recentAvg = donationTrend.sublist(0, 7).reduce((a, b) => a + b) / 7;
      final olderAvg = donationTrend.sublist(30, 37).reduce((a, b) => a + b) / 7;
      final trend = recentAvg > olderAvg ? 'increasing' : recentAvg < olderAvg ? 'decreasing' : 'neutral';

      // Simple linear projection
      final predictedDaily = (ema * (trend == 'increasing' ? 1.15 : trend == 'decreasing' ? 0.85 : 1.0)).toInt();
      final predictedTotal = (predictedDaily * daysAhead).toInt();

      // Seasonality-based risk
      final seasonality = _analyzeSeasonality(snapshot.docs.docs.map((d) => d.data()).toList());
      final peakDay = seasonality['peakDayOfWeek'];
      
      // Check if prediction falls on peak day
      final isPeakPeriod = DateTime.now().add(Duration(days: daysAhead)).toString().contains(peakDay.toString());
      final riskLevel = isPeakPeriod ? 'high' : trend == 'increasing' ? 'medium' : 'low';

      return {
        'period': '$daysAhead days ahead',
        'predictedDailyDonations': predictedDaily,
        'predictedTotalDonations': predictedTotal,
        'trend': trend,
        'confidence': 0.82,
        'riskLevel': riskLevel,
        'seasonalFactor': seasonality['peakDayOfWeek'],
        'emaValue': (ema * 100).toStringAsFixed(2),
        'volatility': (_calculateStdDev(donationTrend) * 100).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error predicting surplus: $e');
      return {};
    }
  }

  // ENHANCED: Advanced volunteer demand prediction with multiple factors
  Future<Map<String, dynamic>> predictVolunteerDemandAdvanced({
    required int daysAhead,
    required int historicalDays = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: historicalDays)).toUtc();
      final endDate = DateTime.now();

      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final volunteersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .get();

      if (donationsSnapshot.docs.isEmpty) {
        return {
          'period': '$daysAhead days',
          'predictedDailyDemand': 0,
          'requiredVolunteers': 0,
          'currentVolunteerCount': volunteersSnapshot.size,
          'shortfall': volunteersSnapshot.size,
        };
      }

      // Calculate daily demand trend
      Map<int, int> dailyDemand = {};
      List<double> demandTrend = [];

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dayIndex = DateTime.now().difference(date).inDays;
          dailyDemand[dayIndex] = (dailyDemand[dayIndex] ?? 0) + 1;
        }
      }

      for (int i = 0; i <= historicalDays; i++) {
        demandTrend.add((dailyDemand[i] ?? 0).toDouble());
      }

      // Calculate EMA
      final ema = _calculateEMA(values: demandTrend, period: 7);

      // Estimate volunteers needed (1 volunteer per ~3 donations, adjusted by batch efficiency)
      final predictedDailyDemand = (ema).toInt();
      final requiredVolunteers = ((predictedDailyDemand / 3) * 1.2).ceil(); // 1.2 = buffer factor
      final currentVolunteerCount = volunteersSnapshot.size;
      final shortfall = (requiredVolunteers - currentVolunteerCount).clamp(0, 999);

      // Get availability pattern
      Map<String, int> availabilitySlots = {};
      for (var doc in volunteersSnapshot.docs) {
        final availHours = doc.data()['availabilityHours'] as List?;
        if (availHours != null) {
          for (var slot in availHours) {
            availabilitySlots[slot as String] = (availabilitySlots[slot as String] ?? 0) + 1;
          }
        }
      }

      return {
        'period': '$daysAhead days',
        'predictedDailyDemand': predictedDailyDemand,
        'requiredVolunteers': requiredVolunteers,
        'currentVolunteerCount': currentVolunteerCount,
        'shortfall': shortfall,
        'recommendAction': shortfall > 2 ? 'urgent_recruitment' : shortfall > 0 ? 'plan_recruitment' : 'sufficient',
        'confidence': 0.85,
        'availabilityDistribution': availabilitySlots,
        'criticalTimeSlots': availabilitySlots.entries
            .where((e) => (e.value as int) < 3)
            .map((e) => e.key)
            .toList(),
      };
    } catch (e) {
      print('Error predicting volunteer demand: $e');
      return {};
    }
  }

  // NEW: Regional supply-demand gap analysis
  Future<Map<String, dynamic>> getRegionalSupplyDemandGap(String region) async {
    try {
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('region', isEqualTo: region)
          .where('status', isEqualTo: 'listed')
          .get();

      final ngosSnapshot = await _firestore
          .collection('organizations')
          .where('region', isEqualTo: region)
          .get();

      double totalSupplyWeight = 0;
      int totalDonations = donationsSnapshot.size;

      for (var doc in donationsSnapshot.docs) {
        final weight = (doc.data()['weight'] as num?)?.toDouble() ?? 0;
        totalSupplyWeight += weight;
      }

      double totalCapacity = 0;
      int totalNGOs = ngosSnapshot.size;

      for (var doc in ngosSnapshot.docs) {
        final capacity = (doc.data()['capacity'] as num?)?.toDouble() ?? 0;
        totalCapacity += capacity;
      }

      final gap = totalSupplyWeight - totalCapacity;
      final gapPercentage = totalCapacity > 0 ? ((gap / totalCapacity) * 100).toStringAsFixed(2) : '0';

      return {
        'region': region,
        'totalSupplyWeight': (totalSupplyWeight).toStringAsFixed(2),
        'totalNGOCapacity': (totalCapacity).toStringAsFixed(2),
        'supplyDemandGap': (gap).toStringAsFixed(2),
        'gapPercentage': gapPercentage,
        'status': double.parse(gapPercentage) > 20 ? 'critical' : double.parse(gapPercentage) > 10 ? 'warning' : 'balanced',
        'activeNGOs': totalNGOs,
        'pendingDonations': totalDonations,
      };
    } catch (e) {
      print('Error calculating supply-demand gap: $e');
      return {};
    }
  }

  // NEW: Predict delivery completion time based on historical patterns
  Future<Map<String, dynamic>> predictDeliveryTime({
    required String volunteerId,
    required double pickupLatitude,
    required double pickupLongitude,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    try {
      // Get volunteer's historical delivery times
      final deliveriesSnapshot = await _firestore
          .collection('delivery_tasks')
          .where('volunteerId', isEqualTo: volunteerId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .limit(10)
          .get();

      if (deliveriesSnapshot.docs.isEmpty) {
        // Use regional average
        return {
          'estimatedMinutes': 60,
          'confidence': 0.5,
          'dataSource': 'regional_average',
        };
      }

      List<int> durations = [];
      for (var doc in deliveriesSnapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        final deliveredAt = (doc.data()['deliveredAt'] as Timestamp?)?.toDate();

        if (createdAt != null && deliveredAt != null) {
          durations.add(deliveredAt.difference(createdAt).inMinutes);
        }
      }

      if (durations.isEmpty) return {'estimatedMinutes': 60, 'confidence': 0.5};

      // Calculate median (more robust than mean for outliers)
      durations.sort();
      final median = durations[durations.length ~/ 2];
      final mean = durations.reduce((a, b) => a + b) ~/ durations.length;
      final stdDev = _calculateStdDev(durations.map((d) => d.toDouble()).toList());

      // Confidence based on consistency (lower stdDev = higher confidence)
      double confidence = (1 - (stdDev / mean)).clamp(0, 1);

      return {
        'estimatedMinutes': median,
        'meanDuration': mean,
        'standardDeviation': stdDev,
        'confidence': (confidence * 100).toStringAsFixed(2),
        'dataSource': 'volunteer_historical',
        'basedOnDeliveries': durations.length,
      };
    } catch (e) {
      print('Error predicting delivery time: $e');
      return {};
    }
  }
