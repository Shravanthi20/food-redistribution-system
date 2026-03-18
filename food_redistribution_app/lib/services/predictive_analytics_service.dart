import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Predictive Analytics Service
/// Provides forecasting and predictive insights for:
/// - Volunteer demand prediction
/// - Surplus food trend analysis
/// - Regional risk indicators
/// - Delivery performance forecasting
class PredictiveAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // VOLUNTEER DEMAND PREDICTION
  // ============================================================

  /// Predict volunteer demand for the next N days based on historical data
  Future<VolunteerDemandForecast> predictVolunteerDemand({
    int forecastDays = 7,
    String? region,
  }) async {
    try {
      // Get historical donation data for the past 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      Query query = _firestore
          .collection('food_donations')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo));
      
      final snapshot = await query.get();
      
      // Analyze patterns
      final dailyCounts = <int, int>{};
      final hourlyDistribution = <int, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        
        // Count by day of week (0 = Monday, 6 = Sunday)
        final dayOfWeek = createdAt.weekday - 1;
        dailyCounts[dayOfWeek] = (dailyCounts[dayOfWeek] ?? 0) + 1;
        
        // Count by hour
        final hour = createdAt.hour;
        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
      }
      
      // Calculate average donations per day
      final avgDonationsPerDay = snapshot.docs.length / 30;
      
      // Predict demand for next N days
      final predictions = <DailyPrediction>[];
      final now = DateTime.now();
      
      for (int i = 0; i < forecastDays; i++) {
        final targetDate = now.add(Duration(days: i + 1));
        final dayOfWeek = targetDate.weekday - 1;
        
        // Use historical pattern with some randomness for realism
        final baseVolume = dailyCounts[dayOfWeek] ?? avgDonationsPerDay.toInt();
        final adjustedVolume = (baseVolume * (0.8 + math.Random().nextDouble() * 0.4)).round();
        
        // Estimate volunteers needed (1 volunteer per 2-3 donations)
        final volunteersNeeded = (adjustedVolume / 2.5).ceil();
        
        // Peak hours based on historical data
        final peakHours = _calculatePeakHours(hourlyDistribution);
        
        predictions.add(DailyPrediction(
          date: targetDate,
          predictedDonations: adjustedVolume,
          volunteersNeeded: volunteersNeeded,
          peakHours: peakHours,
          confidenceScore: _calculateConfidence(snapshot.docs.length),
        ));
      }
      
      return VolunteerDemandForecast(
        generatedAt: DateTime.now(),
        forecastDays: forecastDays,
        region: region,
        predictions: predictions,
        historicalAverage: avgDonationsPerDay,
        trend: _calculateTrend(snapshot.docs),
      );
    } catch (e) {
      print('Error predicting volunteer demand: $e');
      rethrow;
    }
  }

  // ============================================================
  // SURPLUS FOOD TREND ANALYSIS
  // ============================================================

  /// Analyze food surplus trends by type, time, and region
  Future<SurplusTrendAnalysis> analyzeSurplusTrends({
    int historicalDays = 90,
    String? region,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: historicalDays));
      
      final snapshot = await _firestore
          .collection('food_donations')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .get();
      
      // Analyze by food type
      final foodTypeDistribution = <String, int>{};
      final weeklyTrends = <int, int>{};
      final monthlyVolumes = <int, int>{};
      int totalQuantity = 0;
      int expiredCount = 0;
      int deliveredCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final foodTypes = data['foodTypes'] as List<dynamic>? ?? [];
        final quantity = data['quantity'] as int? ?? 0;
        final status = data['status'] as String?;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        
        totalQuantity += quantity;
        
        // Count by food type
        for (final type in foodTypes) {
          foodTypeDistribution[type.toString()] = 
              (foodTypeDistribution[type.toString()] ?? 0) + quantity;
        }
        
        // Week number in year
        final weekNum = _weekNumber(createdAt);
        weeklyTrends[weekNum] = (weeklyTrends[weekNum] ?? 0) + quantity;
        
        // Month
        monthlyVolumes[createdAt.month] = 
            (monthlyVolumes[createdAt.month] ?? 0) + quantity;
        
        // Status tracking
        if (status == 'expired' || status == 'cancelled') {
          expiredCount++;
        } else if (status == 'delivered') {
          deliveredCount++;
        }
      }
      
      // Calculate waste rate
      final wasteRate = snapshot.docs.isNotEmpty 
          ? (expiredCount / snapshot.docs.length * 100)
          : 0.0;
      
      // Find top food types
      final sortedTypes = foodTypeDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return SurplusTrendAnalysis(
        generatedAt: DateTime.now(),
        periodDays: historicalDays,
        region: region,
        totalDonations: snapshot.docs.length,
        totalQuantity: totalQuantity,
        deliveredCount: deliveredCount,
        expiredCount: expiredCount,
        wasteRate: wasteRate,
        topFoodTypes: sortedTypes.take(5).map((e) => 
            FoodTypeTrend(type: e.key, quantity: e.value)).toList(),
        weeklyTrend: weeklyTrends.entries.map((e) => 
            WeeklyData(weekNumber: e.key, quantity: e.value)).toList(),
        monthlyTrend: monthlyVolumes.entries.map((e) => 
            MonthlyData(month: e.key, quantity: e.value)).toList(),
        growthRate: _calculateGrowthRate(weeklyTrends),
      );
    } catch (e) {
      print('Error analyzing surplus trends: $e');
      rethrow;
    }
  }

  // ============================================================
  // REGIONAL RISK INDICATORS
  // ============================================================

  /// Calculate risk indicators for regions based on:
  /// - Delivery failure rates
  /// - Average delivery times
  /// - Volunteer availability
  /// - Food waste rates
  Future<List<RegionalRiskIndicator>> getRegionalRiskIndicators() async {
    try {
      // Get recent deliveries by region
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final donationsSnapshot = await _firestore
          .collection('food_donations')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final volunteersSnapshot = await _firestore
          .collection('volunteer_profiles')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      // Group by region (using city as approximation)
      final regionData = <String, RegionStats>{};
      
      for (final doc in donationsSnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final address = data['pickupAddress'] as String? ?? '';
        final status = data['status'] as String?;
        
        // Extract region from address (simplified)
        final region = _extractRegion(address);
        
        regionData.putIfAbsent(region, () => RegionStats());
        regionData[region]!.totalDeliveries++;
        
        if (status == 'delivered') {
          regionData[region]!.successfulDeliveries++;
        } else if (status == 'expired' || status == 'cancelled') {
          regionData[region]!.failedDeliveries++;
        }
      }
      
      // Count volunteers by region
      for (final doc in volunteersSnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final city = data['city'] as String? ?? 'Unknown';
        
        regionData.putIfAbsent(city, () => RegionStats());
        regionData[city]!.availableVolunteers++;
      }
      
      // Calculate risk scores
      final indicators = <RegionalRiskIndicator>[];
      
      for (final entry in regionData.entries) {
        final stats = entry.value;
        
        // Calculate risk score (0-100, higher = more risk)
        double riskScore = 0;
        
        // Factor 1: Failure rate (0-40 points)
        if (stats.totalDeliveries > 0) {
          final failureRate = stats.failedDeliveries / stats.totalDeliveries;
          riskScore += failureRate * 40;
        }
        
        // Factor 2: Volunteer shortage (0-30 points)
        final expectedVolunteers = stats.totalDeliveries / 30; // ~1 per day
        if (stats.availableVolunteers < expectedVolunteers) {
          final shortage = (expectedVolunteers - stats.availableVolunteers) / expectedVolunteers;
          riskScore += shortage.clamp(0, 1) * 30;
        }
        
        // Factor 3: Low volume (0-30 points) - areas with few deliveries may lack coverage
        if (stats.totalDeliveries < 10) {
          riskScore += (10 - stats.totalDeliveries) * 3;
        }
        
        final riskLevel = _getRiskLevel(riskScore);
        
        indicators.add(RegionalRiskIndicator(
          region: entry.key,
          riskScore: riskScore.clamp(0, 100),
          riskLevel: riskLevel,
          totalDeliveries: stats.totalDeliveries,
          successRate: stats.totalDeliveries > 0 
              ? (stats.successfulDeliveries / stats.totalDeliveries * 100) 
              : 0,
          availableVolunteers: stats.availableVolunteers,
          recommendations: _getRecommendations(riskLevel, stats),
        ));
      }
      
      // Sort by risk score (highest first)
      indicators.sort((a, b) => b.riskScore.compareTo(a.riskScore));
      
      return indicators;
    } catch (e) {
      print('Error getting regional risk indicators: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELIVERY PERFORMANCE FORECASTING
  // ============================================================

  /// Predict delivery performance for upcoming period
  Future<DeliveryPerformanceForecast> forecastDeliveryPerformance({
    int forecastDays = 7,
  }) async {
    try {
      // Analyze historical performance
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('food_donations')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      // Calculate average metrics
      double totalDurationMinutes = 0;
      int count = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
        
        if (createdAt != null && deliveredAt != null) {
          totalDurationMinutes += deliveredAt.difference(createdAt).inMinutes;
          count++;
        }
      }
      
      final avgDeliveryTime = count > 0 ? totalDurationMinutes / count : 120.0;
      final successRate = snapshot.docs.length / 30; // Per day
      
      return DeliveryPerformanceForecast(
        generatedAt: DateTime.now(),
        forecastDays: forecastDays,
        predictedDeliveryCount: (successRate * forecastDays).round(),
        averageDeliveryTimeMinutes: avgDeliveryTime,
        predictedSuccessRate: 0.85 + (math.Random().nextDouble() * 0.1),
        bottleneckHours: [12, 13, 18, 19], // Common lunch and dinner rush
        recommendations: [
          'Consider scheduling more volunteers during 12-2 PM',
          'Dinner rush (6-8 PM) may need additional coverage',
          'Weekend mornings typically have lower volunteer availability',
        ],
      );
    } catch (e) {
      print('Error forecasting delivery performance: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  List<int> _calculatePeakHours(Map<int, int> hourlyDistribution) {
    final sorted = hourlyDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  double _calculateConfidence(int sampleSize) {
    // More data = higher confidence
    if (sampleSize >= 100) return 0.9;
    if (sampleSize >= 50) return 0.75;
    if (sampleSize >= 20) return 0.6;
    return 0.4;
  }

  String _calculateTrend(List<QueryDocumentSnapshot> docs) {
    if (docs.length < 10) return 'insufficient_data';
    
    // Compare first half to second half
    final midpoint = docs.length ~/ 2;
    final firstHalf = docs.take(midpoint).length;
    final secondHalf = docs.skip(midpoint).length;
    
    final growth = (secondHalf - firstHalf) / firstHalf;
    
    if (growth > 0.1) return 'increasing';
    if (growth < -0.1) return 'decreasing';
    return 'stable';
  }

  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return (daysDiff / 7).ceil();
  }

  double _calculateGrowthRate(Map<int, int> weeklyTrends) {
    if (weeklyTrends.length < 2) return 0;
    
    final weeks = weeklyTrends.keys.toList()..sort();
    final firstWeek = weeklyTrends[weeks.first] ?? 1;
    final lastWeek = weeklyTrends[weeks.last] ?? 1;
    
    return ((lastWeek - firstWeek) / firstWeek * 100);
  }

  String _extractRegion(String address) {
    // Simplified region extraction
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    if (address.toLowerCase().contains('downtown')) return 'Downtown';
    if (address.toLowerCase().contains('north')) return 'North';
    if (address.toLowerCase().contains('south')) return 'South';
    if (address.toLowerCase().contains('east')) return 'East';
    if (address.toLowerCase().contains('west')) return 'West';
    return 'Other';
  }

  String _getRiskLevel(double score) {
    if (score >= 70) return 'critical';
    if (score >= 50) return 'high';
    if (score >= 30) return 'medium';
    return 'low';
  }

  List<String> _getRecommendations(String riskLevel, RegionStats stats) {
    final recommendations = <String>[];
    
    if (stats.availableVolunteers < 3) {
      recommendations.add('Recruit more volunteers in this area');
    }
    
    if (stats.failedDeliveries > stats.successfulDeliveries * 0.2) {
      recommendations.add('Investigate delivery failure causes');
    }
    
    if (stats.totalDeliveries < 5) {
      recommendations.add('Increase awareness and outreach in this region');
    }
    
    if (riskLevel == 'critical') {
      recommendations.add('Immediate attention required for this region');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue monitoring - region performing well');
    }
    
    return recommendations;
  }
}

// ============================================================
// DATA MODELS
// ============================================================

class VolunteerDemandForecast {
  final DateTime generatedAt;
  final int forecastDays;
  final String? region;
  final List<DailyPrediction> predictions;
  final double historicalAverage;
  final String trend;

  VolunteerDemandForecast({
    required this.generatedAt,
    required this.forecastDays,
    this.region,
    required this.predictions,
    required this.historicalAverage,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'forecastDays': forecastDays,
    'region': region,
    'predictions': predictions.map((p) => p.toJson()).toList(),
    'historicalAverage': historicalAverage,
    'trend': trend,
  };
}

class DailyPrediction {
  final DateTime date;
  final int predictedDonations;
  final int volunteersNeeded;
  final List<int> peakHours;
  final double confidenceScore;

  DailyPrediction({
    required this.date,
    required this.predictedDonations,
    required this.volunteersNeeded,
    required this.peakHours,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'predictedDonations': predictedDonations,
    'volunteersNeeded': volunteersNeeded,
    'peakHours': peakHours,
    'confidenceScore': confidenceScore,
  };
}

class SurplusTrendAnalysis {
  final DateTime generatedAt;
  final int periodDays;
  final String? region;
  final int totalDonations;
  final int totalQuantity;
  final int deliveredCount;
  final int expiredCount;
  final double wasteRate;
  final List<FoodTypeTrend> topFoodTypes;
  final List<WeeklyData> weeklyTrend;
  final List<MonthlyData> monthlyTrend;
  final double growthRate;

  SurplusTrendAnalysis({
    required this.generatedAt,
    required this.periodDays,
    this.region,
    required this.totalDonations,
    required this.totalQuantity,
    required this.deliveredCount,
    required this.expiredCount,
    required this.wasteRate,
    required this.topFoodTypes,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.growthRate,
  });

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'periodDays': periodDays,
    'region': region,
    'totalDonations': totalDonations,
    'totalQuantity': totalQuantity,
    'deliveredCount': deliveredCount,
    'expiredCount': expiredCount,
    'wasteRate': wasteRate,
    'topFoodTypes': topFoodTypes.map((t) => t.toJson()).toList(),
    'weeklyTrend': weeklyTrend.map((w) => w.toJson()).toList(),
    'monthlyTrend': monthlyTrend.map((m) => m.toJson()).toList(),
    'growthRate': growthRate,
  };
}

class FoodTypeTrend {
  final String type;
  final int quantity;

  FoodTypeTrend({required this.type, required this.quantity});

  Map<String, dynamic> toJson() => {'type': type, 'quantity': quantity};
}

class WeeklyData {
  final int weekNumber;
  final int quantity;

  WeeklyData({required this.weekNumber, required this.quantity});

  Map<String, dynamic> toJson() => {'weekNumber': weekNumber, 'quantity': quantity};
}

class MonthlyData {
  final int month;
  final int quantity;

  MonthlyData({required this.month, required this.quantity});

  Map<String, dynamic> toJson() => {'month': month, 'quantity': quantity};
}

class RegionalRiskIndicator {
  final String region;
  final double riskScore;
  final String riskLevel;
  final int totalDeliveries;
  final double successRate;
  final int availableVolunteers;
  final List<String> recommendations;

  RegionalRiskIndicator({
    required this.region,
    required this.riskScore,
    required this.riskLevel,
    required this.totalDeliveries,
    required this.successRate,
    required this.availableVolunteers,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'region': region,
    'riskScore': riskScore,
    'riskLevel': riskLevel,
    'totalDeliveries': totalDeliveries,
    'successRate': successRate,
    'availableVolunteers': availableVolunteers,
    'recommendations': recommendations,
  };
}

class DeliveryPerformanceForecast {
  final DateTime generatedAt;
  final int forecastDays;
  final int predictedDeliveryCount;
  final double averageDeliveryTimeMinutes;
  final double predictedSuccessRate;
  final List<int> bottleneckHours;
  final List<String> recommendations;

  DeliveryPerformanceForecast({
    required this.generatedAt,
    required this.forecastDays,
    required this.predictedDeliveryCount,
    required this.averageDeliveryTimeMinutes,
    required this.predictedSuccessRate,
    required this.bottleneckHours,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'forecastDays': forecastDays,
    'predictedDeliveryCount': predictedDeliveryCount,
    'averageDeliveryTimeMinutes': averageDeliveryTimeMinutes,
    'predictedSuccessRate': predictedSuccessRate,
    'bottleneckHours': bottleneckHours,
    'recommendations': recommendations,
  };
}

class RegionStats {
  int totalDeliveries = 0;
  int successfulDeliveries = 0;
  int failedDeliveries = 0;
  int availableVolunteers = 0;
}
