import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_donation.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time donation status updates
  Stream<DonationStatus> trackDonationStatus(String donationId) {
    return _firestore
        .collection('food_donations')
        .doc(donationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final statusString = data['status'] as String;
        return DonationStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => DonationStatus.listed,
        );
      }
      return DonationStatus.cancelled;
    });
  }

  // Update donation status with location tracking
  Future<void> updateDonationStatus({
    required String donationId,
    required DonationStatus status,
    required String userId,
    Map<String, dynamic>? locationData,
    String? notes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update donation status
      final donationRef = _firestore.collection('food_donations').doc(donationId);
      batch.update(donationRef, {
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });

      // Create tracking entry
      final trackingRef = _firestore.collection('donation_tracking').doc();
      batch.set(trackingRef, {
        'donationId': donationId,
        'status': status.name,
        'userId': userId,
        'timestamp': Timestamp.now(),
        'location': locationData,
        'notes': notes,
      });

      await batch.commit();

      // Send real-time notification
      await _notifyStakeholders(donationId, status);
    } catch (e) {
      print('Error updating donation status: $e');
      rethrow;
    }
  }

  // Get donation tracking history
  Future<List<Map<String, dynamic>>> getDonationTrackingHistory(String donationId) async {
    try {
      final query = await _firestore
          .collection('donation_tracking')
          .where('donationId', isEqualTo: donationId)
          .orderBy('timestamp')
          .get();

      return query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting tracking history: $e');
      return [];
    }
  }

  // Track volunteer location during pickup/delivery
  Future<void> updateVolunteerLocation({
    required String volunteerId,
    required String donationId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('volunteer_tracking').doc(volunteerId).set({
        'donationId': donationId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating volunteer location: $e');
    }
  }

  // Get real-time volunteer location
  Stream<Map<String, dynamic>?> trackVolunteerLocation(String volunteerId) {
    return _firestore
        .collection('volunteer_tracking')
        .doc(volunteerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Get all active deliveries for admin monitoring
  Stream<List<Map<String, dynamic>>> trackActiveDeliveries() {
    return _firestore
        .collection('food_donations')
        .where('status', whereIn: ['matched', 'pickedUp', 'inTransit'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Detect delayed or failed deliveries
  Future<List<Map<String, dynamic>>> getDelayedDeliveries() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 2));
      
      final query = await _firestore
          .collection('food_donations')
          .where('status', whereIn: ['matched', 'pickedUp', 'inTransit'])
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      return query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting delayed deliveries: $e');
      return [];
    }
  }

  // Create delivery route optimization data
  Future<Map<String, dynamic>> optimizeDeliveryRoute({
    required List<String> donationIds,
    required String volunteerId,
  }) async {
    try {
      List<Map<String, dynamic>> donations = [];
      
      for (String donationId in donationIds) {
        final doc = await _firestore.collection('food_donations').doc(donationId).get();
        if (doc.exists) {
          donations.add({'id': doc.id, ...doc.data() as Map<String, dynamic>});
        }
      }

      // Simple route optimization (in production, would use Google Maps API)
      return {
        'donations': donations,
        'estimatedTime': donations.length * 30, // 30 minutes per pickup/delivery
        'totalDistance': donations.length * 5.0, // 5km average per stop
        'optimizedOrder': donationIds, // Would be reordered by actual algorithm
      };
    } catch (e) {
      print('Error optimizing delivery route: $e');
      return {};
    }
  }

  // Send real-time updates to stakeholders
  Future<void> _notifyStakeholders(String donationId, DonationStatus status) async {
    try {
      final donationDoc = await _firestore.collection('food_donations').doc(donationId).get();
      if (!donationDoc.exists) return;

      final donation = donationDoc.data() as Map<String, dynamic>;
      
      // Create real-time notification document
      await _firestore.collection('real_time_updates').add({
        'donationId': donationId,
        'status': status.name,
        'donorId': donation['donorId'],
        'ngoId': donation['assignedNGOId'],
        'volunteerId': donation['assignedVolunteerId'],
        'timestamp': Timestamp.now(),
        'message': _getStatusMessage(status),
      });
    } catch (e) {
      print('Error notifying stakeholders: $e');
    }
  }

  String _getStatusMessage(DonationStatus status) {
    switch (status) {
      case DonationStatus.matched:
        return 'Donation has been matched with an NGO';
      case DonationStatus.pickedUp:
        return 'Food has been picked up by volunteer';
      case DonationStatus.inTransit:
        return 'Food is on the way to destination';
      case DonationStatus.delivered:
        return 'Food has been successfully delivered';
      case DonationStatus.cancelled:
        return 'Donation has been cancelled';
      default:
        return 'Donation status updated';
    }
  }
}
