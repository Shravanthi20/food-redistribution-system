import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_schema.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track donation metrics
  Future<void> trackDonationCreated({
    required String donorId,
    required String donationType,
    required int quantity,
  }) async {
    try {
      await _firestore.collection(Collections.analytics).add({
        'event': 'donation_created',
        'donorId': donorId,
        'donationType': donationType,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error tracking donation created: $e');
    }
  }

  // Track donation completion
  Future<void> trackDonationCompleted({
    required String donationId,
    required String donorId,
    required String ngoId,
    required String? volunteerId,
    required int quantity,
  }) async {
    try {
      await _firestore.collection(Collections.analytics).add({
        'event': 'donation_completed',
        'donationId': donationId,
        'donorId': donorId,
        'ngoId': ngoId,
        'volunteerId': volunteerId,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error tracking donation completed: $e');
    }
  }

  // Get donation statistics
  Future<Map<String, dynamic>> getDonationStatistics(String userId) async {
    try {
      final completedQuery = await _firestore
          .collection(Collections.analytics)
          .where('donorId', isEqualTo: userId)
          .where('event', isEqualTo: 'donation_completed')
          .get();

      final createdQuery = await _firestore
          .collection(Collections.analytics)
          .where('donorId', isEqualTo: userId)
          .where('event', isEqualTo: 'donation_created')
          .get();

      int totalQuantityDonated = 0;
      for (var doc in completedQuery.docs) {
        totalQuantityDonated += (doc.data()['quantity'] as int? ?? 0);
      }

      return {
        'totalDonations': createdQuery.docs.length,
        'completedDonations': completedQuery.docs.length,
        'totalQuantityDonated': totalQuantityDonated,
        'successRate': createdQuery.docs.isNotEmpty
            ? (completedQuery.docs.length / createdQuery.docs.length) * 100
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting donation statistics: $e');
      return {};
    }
  }

  // Get system-wide analytics (Admin)
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final recentDonations = await _firestore
          .collection(Collections.donations)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      final completedDonations = await _firestore
          .collection(Collections.donations)
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      return {
        'totalDonationsThisMonth': recentDonations.docs.length,
        'completedDonationsThisMonth': completedDonations.docs.length,
        'activeUsers': await _getActiveUsersCount(),
        'wasteReduced': _calculateWasteReduced(completedDonations.docs),
      };
    } catch (e) {
      debugPrint('Error getting system analytics: $e');
      return {};
    }
  }

  Future<int> _getActiveUsersCount() async {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final activeUsers = await _firestore
        .collection(Collections.users)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(monthAgo))
        .get();
    return activeUsers.docs.length;
  }

  double _calculateWasteReduced(List<QueryDocumentSnapshot> donations) {
    double totalWeight = 0;
    for (var doc in donations) {
      final data = doc.data() as Map<String, dynamic>;
      final quantity = data['quantity'] as int? ?? 0;
      // Estimate 0.5 kg per serving
      totalWeight += quantity * 0.5;
    }
    return totalWeight;
  }

  // Get Regional Activity (Donations by District/Area approximated from Address)
  Future<Map<String, double>> getRegionalAnalytics() async {
    try {
      final donations =
          await _firestore.collection(Collections.donations).get();
      Map<String, int> counts = {};

      for (var doc in donations.docs) {
        final address =
            (doc.data()['pickupAddress'] as String? ?? 'Unknown').toLowerCase();
        String region = 'Other';
        if (address.contains('downtown')) {
          region = 'Downtown';
        } else if (address.contains('uptown')) {
          region = 'Uptown';
        } else if (address.contains('north')) {
          region = 'North Side';
        } else if (address.contains('south')) {
          region = 'South Side';
        }

        counts[region] = (counts[region] ?? 0) + 1;
      }

      int total = donations.docs.length;
      if (total == 0) return {};

      return counts.map((key, value) => MapEntry(key, value / total));
    } catch (e) {
      debugPrint('Error getting regional analytics: $e');
      return {};
    }
  }

  // Get Delivery Performance
  Future<Map<String, dynamic>> getDeliveryPerformance() async {
    try {
      final snapshot = await _firestore.collection(Collections.donations).get();
      int success = 0;
      int failed = 0;
      int total = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'];
        if (status == 'delivered') {
          success++;
          total++;
        } else if (status == 'cancelled' || status == 'expired') {
          failed++;
          total++;
        }
      }

      return {
        'successRate': total > 0 ? (success / total) * 100 : 0.0,
        'failureRate': total > 0 ? (failed / total) * 100 : 0.0,
        'totalCompleted': total,
      };
    } catch (e) {
      debugPrint('Error getting delivery performance: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMonthlyPlatformTrends({
    int months = 12,
  }) async {
    try {
      final now = DateTime.now();
      final startMonth = DateTime(now.year, now.month - months + 1, 1);

      final donationsSnapshot = await _firestore
          .collection(Collections.donations)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth))
          .get();
      final requestsSnapshot = await _firestore
          .collection(Collections.requests)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth))
          .get();

      final monthlyBuckets = <String, Map<String, dynamic>>{};
      for (var i = 0; i < months; i++) {
        final monthDate = DateTime(startMonth.year, startMonth.month + i, 1);
        final monthKey = _monthKey(monthDate);
        monthlyBuckets[monthKey] = {
          'monthKey': monthKey,
          'monthStart': monthDate,
          'donations': 0,
          'requests': 0,
          'matchedDonations': 0,
          'deliveredDonations': 0,
        };
      }

      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        final bucket = monthlyBuckets[
            _monthKey(DateTime(createdAt.year, createdAt.month, 1))];
        if (bucket == null) continue;

        bucket['donations'] = (bucket['donations'] as int) + 1;

        final status = data['status']?.toString();
        if (status == 'matched') {
          bucket['matchedDonations'] = (bucket['matchedDonations'] as int) + 1;
        }
        if (status == 'delivered') {
          bucket['deliveredDonations'] =
              (bucket['deliveredDonations'] as int) + 1;
        }
      }

      for (final doc in requestsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        final bucket = monthlyBuckets[
            _monthKey(DateTime(createdAt.year, createdAt.month, 1))];
        if (bucket == null) continue;

        bucket['requests'] = (bucket['requests'] as int) + 1;
      }

      final history = monthlyBuckets.values.toList()
        ..sort((a, b) => (a['monthStart'] as DateTime)
            .compareTo(b['monthStart'] as DateTime));

      return {
        'history': history,
        'months': months,
      };
    } catch (e) {
      debugPrint('Error getting monthly platform trends: $e');
      return {
        'history': <Map<String, dynamic>>[],
        'months': months,
      };
    }
  }

  Future<Map<String, dynamic>> getDemandForecast({
    int historyMonths = 6,
    int forecastMonths = 6,
  }) async {
    try {
      final trendData = await getMonthlyPlatformTrends(months: historyMonths);
      final history = List<Map<String, dynamic>>.from(
          trendData['history'] as List? ?? const []);

      final donationSeries = history
          .map((month) => (month['donations'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final requestSeries = history
          .map((month) => (month['requests'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final donationForecast =
          _forecastSeries(donationSeries, forecastMonths: forecastMonths);
      final requestForecast =
          _forecastSeries(requestSeries, forecastMonths: forecastMonths);

      final lastMonth = history.isNotEmpty
          ? history.last['monthStart'] as DateTime
          : DateTime(DateTime.now().year, DateTime.now().month, 1);

      final forecast = <Map<String, dynamic>>[];
      for (var i = 0; i < forecastMonths; i++) {
        final monthDate = DateTime(lastMonth.year, lastMonth.month + i + 1, 1);
        forecast.add({
          'monthKey': _monthKey(monthDate),
          'monthStart': monthDate,
          'predictedDonations': donationForecast[i].round(),
          'predictedRequests': requestForecast[i].round(),
        });
      }

      return {
        'forecast': forecast,
        'historyMonths': historyMonths,
        'forecastMonths': forecastMonths,
      };
    } catch (e) {
      debugPrint('Error getting demand forecast: $e');
      return {
        'forecast': <Map<String, dynamic>>[],
        'historyMonths': historyMonths,
        'forecastMonths': forecastMonths,
      };
    }
  }

  List<double> _forecastSeries(
    List<double> series, {
    required int forecastMonths,
  }) {
    if (series.isEmpty) {
      return List<double>.filled(forecastMonths, 0);
    }

    final recentWindow =
        series.length >= 3 ? series.sublist(series.length - 3) : series;
    final baseline =
        recentWindow.reduce((a, b) => a + b) / recentWindow.length.toDouble();

    double averageChange = 0;
    if (series.length > 1) {
      for (var i = 1; i < series.length; i++) {
        averageChange += series[i] - series[i - 1];
      }
      averageChange /= (series.length - 1);
    }

    final predictions = <double>[];
    var priorValue = series.last;
    for (var step = 1; step <= forecastMonths; step++) {
      final projected = ((priorValue + averageChange) * 0.6) + (baseline * 0.4);
      final clamped =
          projected.isFinite ? projected.clamp(0, 1000000).toDouble() : 0.0;
      predictions.add(clamped);
      priorValue = clamped;
    }

    return predictions;
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}
