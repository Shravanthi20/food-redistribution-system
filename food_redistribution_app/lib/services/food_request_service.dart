import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_request.dart';
import '../models/food_donation.dart';
import '../models/ngo_profile.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';
import '../services/location_service.dart';
import '../config/firebase_schema.dart';
import 'matching_service.dart';
import 'firestore_service.dart';

class FoodRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final AuditService _auditService = AuditService();
  final LocationService _locationService = LocationService();
  late final EnhancedMatchingService _matchingService = EnhancedMatchingService(
    firestoreService: FirestoreService(),
    locationService: _locationService,
    notificationService: _notificationService,
    auditService: _auditService,
  );

  /// Create a new food request
  Future<String> createFoodRequest({
    required String ngoId,
    String? organizationId,
    required FoodRequest request,
  }) async {
    try {
      final resolvedOrganizationId = organizationId ??
          ((request.metadata['organizationId'] as String?)?.trim().isNotEmpty ==
                  true
              ? (request.metadata['organizationId'] as String).trim()
              : null);

      // Validate NGO organization exists and is verified when available
      final ngoDoc = resolvedOrganizationId == null
          ? null
          : await _firestore
              .collection(Collections.organizations)
              .doc(resolvedOrganizationId)
              .get();
      if (resolvedOrganizationId != null &&
          (ngoDoc == null || !ngoDoc.exists)) {
        throw Exception('NGO profile not found');
      }

      if (ngoDoc != null) {
        final ngo = NGOProfile.fromFirestore(ngoDoc);
        if (!ngo.isVerified) {
          throw Exception('NGO must be verified to create food requests');
        }
      }

      final requestToSave = request.copyWith(
        metadata: {
          ...request.metadata,
          if (resolvedOrganizationId != null)
            'organizationId': resolvedOrganizationId,
          'createdByUserId': ngoId,
        },
      );

      if (resolvedOrganizationId == null && requestToSave.ngoId != ngoId) {
        throw Exception('Unauthorized NGO request owner');
      }

      // Create request document
      final docRef = await _firestore
          .collection(Collections.requests)
          .add(requestToSave.toMap());

      // Log action
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: ngoId,
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'food_request_created',
          'description':
              'NGO $ngoId created food request for ${request.requiredQuantity} ${request.unit} of ${request.requiredFoodTypes.join(", ")}',
          'requestId': docRef.id,
          'ngoId': ngoId,
          if (resolvedOrganizationId != null)
            'organizationId': resolvedOrganizationId,
          'urgency': request.urgency.name,
          'expectedBeneficiaries': request.expectedBeneficiaries,
        },
      );

      // Trigger matching algorithm
      await _triggerMatching(docRef.id);

      return docRef.id;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: ngoId,
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'food_request_creation_failed',
          'description': 'Failed to create food request for NGO $ngoId: $e',
          'ngoId': ngoId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Get food requests for an NGO
  Future<List<FoodRequest>> getNGORequests(String ngoId,
      {RequestStatus? status}) async {
    try {
      return getNGORequestsForIds([ngoId], status: status);
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: ngoId,
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'get_ngo_requests_failed',
          'description': 'Failed to get requests for NGO $ngoId: $e',
          'ngoId': ngoId,
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Get food requests for any of the provided NGO identifiers.
  /// This supports both user IDs and organization IDs and avoids composite-index-only queries.
  Future<List<FoodRequest>> getNGORequestsForIds(
    List<String> ngoIds, {
    RequestStatus? status,
  }) async {
    final sanitizedIds =
        ngoIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (sanitizedIds.isEmpty) return [];

    try {
      final requests = <FoodRequest>[];

      for (final ngoId in sanitizedIds) {
        Query query = _firestore
            .collection(Collections.requests)
            .where('ngoId', isEqualTo: ngoId);

        if (status != null) {
          query = query.where('status', isEqualTo: status.name);
        }

        final snapshot = await query.get();
        requests.addAll(
          snapshot.docs.map((doc) => FoodRequest.fromFirestore(doc)),
        );
      }

      final deduped = <String, FoodRequest>{};
      for (final request in requests) {
        deduped[request.id] = request;
      }

      final sorted = deduped.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: sanitizedIds.first,
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'get_ngo_requests_for_ids_failed',
          'description':
              'Failed to get requests for NGO identifiers $sanitizedIds: $e',
          'ngoIds': sanitizedIds,
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Get all active food requests (for admin)
  Future<List<FoodRequest>> getAllActiveRequests() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.requests)
          .where('status', whereIn: [
            RequestStatus.pending.name,
            RequestStatus.matched.name,
          ])
          .orderBy('urgency', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FoodRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'get_all_requests_failed',
          'description': 'Failed to get all active requests: $e',
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Update food request
  Future<void> updateFoodRequest(
      String requestId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(Collections.requests)
          .doc(requestId)
          .update(updates);

      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'food_request_updated',
          'description': 'Food request $requestId updated',
          'requestId': requestId,
          'updates': updates.keys.toList(),
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'food_request_update_failed',
          'description': 'Failed to update food request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Cancel food request
  Future<void> cancelFoodRequest(
      String requestId, String ngoId, String reason) async {
    try {
      await _firestore.collection(Collections.requests).doc(requestId).update({
        'status': RequestStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
        'metadata.cancellationReason': reason,
        'metadata.cancelledBy': ngoId,
        'metadata.cancelledAt': Timestamp.now(),
      });

      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: ngoId,
        riskLevel: AuditRiskLevel.low,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'food_request_cancelled',
          'description':
              'Food request $requestId cancelled by NGO $ngoId: $reason',
          'requestId': requestId,
          'ngoId': ngoId,
          'reason': reason,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'food_request_cancellation_failed',
          'description': 'Failed to cancel food request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Match request with donation
  Future<void> matchRequestWithDonation(
      String requestId, String donationId) async {
    try {
      final batch = _firestore.batch();

      // Update request
      batch.update(_firestore.collection(Collections.requests).doc(requestId), {
        'status': RequestStatus.matched.name,
        'matchedDonationId': donationId,
        'updatedAt': Timestamp.now(),
      });

      // Update donation
      batch.update(
          _firestore.collection(Collections.donations).doc(donationId), {
        'status': DonationStatus.matched.name,
        'matchedRequestId': requestId,
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();

      // Log the match
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'request_donation_matched',
          'description':
              'Food request $requestId matched with donation $donationId',
          'requestId': requestId,
          'donationId': donationId,
        },
      );

      // Notify stakeholders
      await _notifyMatch(requestId, donationId);
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'match_request_donation_failed',
          'description':
              'Failed to match request $requestId with donation $donationId: $e',
          'requestId': requestId,
          'donationId': donationId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Find potential donations for a request
  Future<List<FoodDonation>> findPotentialDonations(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection(Collections.requests)
          .doc(requestId)
          .get();
      if (!requestDoc.exists) return [];

      final request = FoodRequest.fromFirestore(requestDoc);

      // Get available donations within reasonable distance
      final donations = <FoodDonation>[];
      final donationsSnapshot = await _firestore
          .collection(Collections.donations)
          .where('status', isEqualTo: DonationStatus.listed.name)
          .get();

      for (final doc in donationsSnapshot.docs) {
        final donation = FoodDonation.fromFirestore(doc);

        // Check if donation matches request criteria
        if (await _isCompatible(request, donation)) {
          donations.add(donation);
        }
      }

      // Sort by compatibility score
      donations.sort((a, b) => _calculateCompatibilityScore(request, b)
          .compareTo(_calculateCompatibilityScore(request, a)));

      return donations.take(10).toList(); // Return top 10 matches
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'find_potential_donations_failed',
          'description':
              'Failed to find potential donations for request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Check if donation is compatible with request
  Future<bool> _isCompatible(FoodRequest request, FoodDonation donation) async {
    try {
      // Check food type compatibility
      final hasMatchingFoodType = request.requiredFoodTypes.any((reqType) =>
          donation.foodTypes
              .any((donType) => _areFoodTypesCompatible(reqType, donType)));

      if (!hasMatchingFoodType) return false;

      // Check expiry vs. needed by date
      if (donation.expiresAt
          .isBefore(request.neededBy.subtract(const Duration(hours: 2)))) {
        return false;
      }

      // Check quantity (donation should be at least 30% of requested quantity)
      if (donation.quantity < (request.requiredQuantity * 0.3)) return false;

      // Check distance (should be within 50km)
      final distance = _locationService.calculateDistance(
        donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
        request.deliveryLocation['latitude']?.toDouble() ?? 0.0,
        request.deliveryLocation['longitude']?.toDouble() ?? 0.0,
      );

      return distance <= 50.0;
    } catch (e) {
      return false;
    }
  }

  /// Calculate compatibility score between request and donation
  double _calculateCompatibilityScore(
      FoodRequest request, FoodDonation donation) {
    double score = 0.0;

    // Food type match score (40%)
    double foodTypeScore = 0.0;
    for (final reqType in request.requiredFoodTypes) {
      for (final donType in donation.foodTypes) {
        if (_areFoodTypesCompatible(reqType, donType)) {
          foodTypeScore = 1.0;
          break;
        }
      }
      if (foodTypeScore > 0) break;
    }
    score += foodTypeScore * 0.4;

    // Quantity match score (30%)
    final quantityRatio = donation.quantity / request.requiredQuantity;
    final quantityScore = quantityRatio >= 1.0 ? 1.0 : quantityRatio;
    score += quantityScore * 0.3;

    // Urgency vs. expiry score (20%)
    final timeToExpiry = donation.expiresAt.difference(DateTime.now()).inHours;
    final timeToNeeded = request.neededBy.difference(DateTime.now()).inHours;
    final urgencyScore =
        timeToNeeded > 0 && timeToExpiry > timeToNeeded ? 1.0 : 0.5;
    score += urgencyScore * 0.2;

    // Dietary compatibility (10%)
    double dietaryScore = 1.0; // Default to compatible
    for (final restriction in request.dietaryRestrictions) {
      if (!_isDietaryCompatible(restriction, donation)) {
        dietaryScore = 0.0;
        break;
      }
    }
    score += dietaryScore * 0.1;

    return score;
  }

  /// Check if food types are compatible
  bool _areFoodTypesCompatible(
      FoodCategory requestType, FoodType donationType) {
    // Map donation food types to request categories
    switch (donationType) {
      case FoodType.cooked:
        return requestType == FoodCategory.readyToEat;
      case FoodType.raw:
        return [
          FoodCategory.vegetables,
          FoodCategory.fruits,
          FoodCategory.grains,
          FoodCategory.meat
        ].contains(requestType);
      case FoodType.packaged:
        return [
          FoodCategory.grains,
          FoodCategory.beverages,
          FoodCategory.bakery
        ].contains(requestType);
      case FoodType.fruits:
        return [
          FoodCategory.vegetables,
          FoodCategory.fruits,
          FoodCategory.dairy
        ].contains(requestType);
      default:
        return true; // Default to compatible for other types
    }
  }

  /// Check dietary compatibility
  bool _isDietaryCompatible(String restriction, FoodDonation donation) {
    switch (restriction.toLowerCase()) {
      case 'vegetarian':
        return donation.isVegetarian;
      case 'vegan':
        return donation.isVegan;
      case 'gluten-free':
        return false; // Not supported in current model
      case 'halal':
        return donation.isHalal;
      case 'kosher':
        return false; // Not supported in current model
      default:
        return true; // Default to compatible for unknown restrictions
    }
  }

  /// Trigger automatic matching for a new request
  Future<void> _triggerMatching(String requestId) async {
    try {
      await _matchingService.executeAutomaticMatching(requestId: requestId);
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        resourceId: requestId,
        resourceType: 'food_request',
        additionalData: {
          'action': 'auto_match_failed',
          'description': 'Auto-matching failed for request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Notify stakeholders about a match
  Future<void> _notifyMatch(String requestId, String donationId) async {
    try {
      // Get request and donation details
      final requestDoc = await _firestore
          .collection(Collections.requests)
          .doc(requestId)
          .get();
      final donationDoc = await _firestore
          .collection(Collections.donations)
          .doc(donationId)
          .get();

      if (!requestDoc.exists || !donationDoc.exists) return;

      final request = FoodRequest.fromFirestore(requestDoc);
      final donation = FoodDonation.fromFirestore(donationDoc);

      // Notify NGO
      await _notificationService.sendNotification(
        userId: request.ngoId,
        title: 'Food Request Matched!',
        message:
            'Your request for ${request.requiredQuantity} ${request.unit} has been matched with a donation.',
        type: 'request_matched',
        data: {
          'requestId': requestId,
          'donationId': donationId,
        },
      );

      // Notify Donor
      await _notificationService.sendNotification(
        userId: donation.donorId,
        title: 'Donation Matched!',
        message:
            'Your donation has been matched with an NGO for ${request.expectedBeneficiaries} beneficiaries.',
        type: 'donation_matched',
        data: {
          'donationId': donationId,
          'requestId': requestId,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        resourceId: requestId,
        resourceType: 'notification',
        additionalData: {
          'action': 'match_notification_failed',
          'description': 'Failed to send match notifications: $e',
          'requestId': requestId,
          'donationId': donationId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Get request statistics for admin dashboard
  Future<Map<String, dynamic>> getRequestStatistics() async {
    try {
      final snapshot = await _firestore.collection(Collections.requests).get();
      final requests =
          snapshot.docs.map((doc) => FoodRequest.fromFirestore(doc)).toList();

      return {
        'totalRequests': requests.length,
        'pendingRequests':
            requests.where((r) => r.status == RequestStatus.pending).length,
        'matchedRequests':
            requests.where((r) => r.status == RequestStatus.matched).length,
        'fulfilledRequests':
            requests.where((r) => r.status == RequestStatus.fulfilled).length,
        'cancelledRequests':
            requests.where((r) => r.status == RequestStatus.cancelled).length,
        'criticalRequests':
            requests.where((r) => r.urgency == RequestUrgency.critical).length,
        'totalBeneficiaries':
            requests.fold<int>(0, (acc, r) => acc + r.expectedBeneficiaries),
      };
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'get_request_statistics_failed',
          'description': 'Failed to get request statistics: $e',
          'error': e.toString(),
        },
      );
      return {};
    }
  }
}
