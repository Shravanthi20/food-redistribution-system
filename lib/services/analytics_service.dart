import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track donation metrics
  Future<void> trackDonationCreated({
    required String donorId,
    required String donationType,
    required int quantity,
  }) async {
    try {
      await _firestore.collection('analytics_events').add({
        'event': 'donation_created',
        'donorId': donorId,
        'donationType': donationType,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error tracking donation created: $e');
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
      await _firestore.collection('analytics_events').add({
        'event': 'donation_completed',
        'donationId': donationId,
        'donorId': donorId,
        'ngoId': ngoId,
        'volunteerId': volunteerId,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error tracking donation completed: $e');
    }
  }

  // Get donation statistics
  Future<Map<String, dynamic>> getDonationStatistics(String userId) async {
    try {
      final completedQuery = await _firestore
          .collection('analytics_events')
          .where('donorId', isEqualTo: userId)
          .where('event', isEqualTo: 'donation_completed')
          .get();

      final createdQuery = await _firestore
          .collection('analytics_events')
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
      print('Error getting donation statistics: $e');
      return {};
    }
  }

  // Get system-wide analytics (Admin)
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final recentDonations = await _firestore
          .collection('food_donations')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      final completedDonations = await _firestore
          .collection('food_donations')
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
      print('Error getting system analytics: $e');
      return {};
    }
  }

  Future<int> _getActiveUsersCount() async {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final activeUsers = await _firestore
        .collection('users')
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
      final donations = await _firestore.collection('food_donations').get();
      Map<String, int> counts = {};
      
      for (var doc in donations.docs) {
        final address = (doc.data()['pickupAddress'] as String? ?? 'Unknown').toLowerCase();
        String region = 'Other';
        if (address.contains('downtown')) region = 'Downtown';
        else if (address.contains('uptown')) region = 'Uptown';
        else if (address.contains('north')) region = 'North Side';
        else if (address.contains('south')) region = 'South Side';
        
        counts[region] = (counts[region] ?? 0) + 1;
      }

      int total = donations.docs.length;
      if (total == 0) return {};

      return counts.map((key, value) => MapEntry(key, value / total));
    } catch (e) {
      print('Error getting regional analytics: $e');
      return {};
    }
  }

  // Get Delivery Performance
  Future<Map<String, dynamic>> getDeliveryPerformance() async {
    try {
      final snapshot = await _firestore.collection('food_donations').get();
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
      print('Error getting delivery performance: $e');
      return {};
    }
  }
}