import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../models/food_donation.dart';
import '../models/food_request.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import '../models/matching.dart';
import '../models/enums.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

class FoodDonationMatchingService {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  
  FoodDonationMatchingService({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required NotificationService notificationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService,
       _notificationService = notificationService,
       _auditService = auditService;

  /// Find optimal NGO matches for a food donation
  Future<List<MatchingResult>> findMatches({
    required String donationId,
    MatchingAlgorithm algorithm = MatchingAlgorithm.optimal,
    int maxMatches = 5,
  }) async {
    try {
      // Get donation details
      final donation = await _getDonation(donationId);
      if (donation == null) throw Exception('Donation not found');
      
      // Get available NGOs in range
      final ngos = await _getAvailableNGOs(
        donationLocation: {
          'latitude': donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
          'longitude': donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
        },
        maxDistance: algorithm.maxDistance,
      );
      
      if (ngos.isEmpty) {
        await _auditService.logEvent(
          eventType: AuditEventType.dataAccess,
          userId: 'system',
          riskLevel: AuditRiskLevel.medium,
          additionalData: {
            'event': 'matching_no_ngos',
            'description': 'No NGOs found within range for donation $donationId',
            'donationId': donationId,
            'maxDistance': algorithm.maxDistance,
          },
        );
        return [];
      }
      
      // Calculate matching scores
      final matches = <MatchingResult>[];
      
      for (final ngo in ngos) {
        final score = await _calculateMatchingScore(
          donation: donation,
          ngo: ngo,
          algorithm: algorithm,
        );
        
        if (score != null) {
          matches.add(score);
        }
      }
      
      // Sort by score (highest first) and limit results
      matches.sort((a, b) => b.score.compareTo(a.score));
      final topMatches = matches.take(maxMatches).toList();
      
      // Store matching results for analytics
      await _storeMatchingResults(donationId, algorithm, topMatches);
      
      // Log successful matching
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'event': 'donation_matching_completed',
          'description': 'Found ${topMatches.length} matches for donation $donationId',
          'donationId': donationId,
          'algorithm': algorithm.id,
          'matchCount': topMatches.length,
          'topScore': topMatches.isNotEmpty ? topMatches.first.score : 0,
        },
      );
      
      return topMatches;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'event': 'matching_error',
          'description': 'Error finding matches for donation $donationId: $e',
          'donationId': donationId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
  
  /// Calculate matching score between donation and NGO
  Future<MatchingResult?> _calculateMatchingScore({
    required FoodDonation donation,
    required NGOProfile ngo,
    required MatchingAlgorithm algorithm,
  }) async {
    try {
      // Calculate distance score
      final distance = await _locationService.calculateDistance(
        donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
        ngo.location['latitude']?.toDouble() ?? 0.0,
        ngo.location['longitude']?.toDouble() ?? 0.0,
      );
      
      if (distance > algorithm.maxDistance) return null;
      
      final distanceScore = _calculateDistanceScore(distance, algorithm.maxDistance);
      
      // Calculate capacity score
      final capacityScore = _calculateCapacityScore(donation, ngo);
      
      // Calculate urgency score
      final urgencyScore = _calculateUrgencyScore(donation);
      
      // Calculate food type compatibility score
      final foodTypeScore = _calculateFoodTypeScore(donation, ngo);
      
      // Calculate availability score
      final availabilityScore = await _calculateAvailabilityScore(ngo.userId);
      
      // Calculate weighted total score
      final criteriaScores = {
        MatchingCriteria.distance: distanceScore,
        MatchingCriteria.capacity: capacityScore,
        MatchingCriteria.urgency: urgencyScore,
        MatchingCriteria.foodType: foodTypeScore,
        MatchingCriteria.availability: availabilityScore,
      };
      
      final totalScore = criteriaScores.entries
          .map((entry) => entry.value * algorithm.weights[entry.key]!)
          .reduce((a, b) => a + b);
      
      // Generate reasoning
      final reasoning = _generateReasoning(criteriaScores, algorithm, distance);
      
      return MatchingResult(
        ngoId: ngo.userId,
        donationId: donation.id,
        score: totalScore,
        distance: distance,
        criteriaScores: criteriaScores,
        ngo: ngo,
        reasoning: reasoning,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'event': 'score_calculation_error',
          'description': 'Error calculating score for NGO ${ngo.userId}: $e',
          'ngoId': ngo.userId,
          'donationId': donation.id,
          'error': e.toString(),
        },
      );
      return null;
    }
  }
  
  /// Calculate distance-based score (closer = higher score)
  double _calculateDistanceScore(double distance, double maxDistance) {
    return 1.0 - (distance / maxDistance);
  }
  
  /// Calculate capacity compatibility score
  double _calculateCapacityScore(FoodDonation donation, NGOProfile ngo) {
    final donationQuantity = donation.quantity.toDouble();
    final ngoCapacity = (ngo.capacity ?? 100).toDouble(); // Default capacity
    
    // Prevent division by zero
    if (ngoCapacity <= 0) return 0.5;
    
    // Optimal if donation is 50-80% of NGO capacity
    final ratio = donationQuantity / ngoCapacity;
    
    if (ratio >= 0.5 && ratio <= 0.8) {
      return 1.0;
    } else if (ratio < 0.5) {
      return ratio / 0.5; // Linear scale up to 50%
    } else if (ratio <= 1.2) {
      return 1.0 - ((ratio - 0.8) / 0.4); // Linear scale down after 80%
    } else {
      return 0.2; // Very poor match for oversized donations
    }
  }
  
  /// Calculate urgency score based on expiry time
  double _calculateUrgencyScore(FoodDonation donation) {
    final now = DateTime.now();
    final expiry = donation.expiryDateTime; // Use correct field name
    final hoursUntilExpiry = expiry.difference(now).inHours;
    
    // Handle expired food
    if (hoursUntilExpiry <= 0) {
      return 0.0; // Expired food
    } else if (hoursUntilExpiry <= 2) {
      return 1.0; // Critical urgency
    } else if (hoursUntilExpiry <= 6) {
      return 0.8; // High urgency
    } else if (hoursUntilExpiry <= 12) {
      return 0.6; // Medium urgency
    } else if (hoursUntilExpiry <= 24) {
      return 0.4; // Low urgency
    } else {
      return 0.2; // Very low urgency
    }
  }
  
  /// Calculate food type compatibility score
  double _calculateFoodTypeScore(FoodDonation donation, NGOProfile ngo) {
    // Use servingPopulation as a proxy for food type preferences
    final ngoServingTypes = ngo.servingPopulation;
    final donationFoodTypes = donation.foodTypes;
    
    // If no specific preferences, give neutral score
    if (ngoServingTypes.isEmpty || donationFoodTypes.isEmpty) return 0.7;
    
    // Calculate max compatibility score across all food types
    double maxScore = 0.0;
    for (final foodType in donationFoodTypes) {
      // Basic compatibility matrix
      if (ngoServingTypes.contains('Children') && 
          [FoodType.fruits, FoodType.dairy, FoodType.cooked].contains(foodType)) {
        maxScore = math.max(maxScore, 0.9);
      }
      
      if (ngoServingTypes.contains('Elderly') && 
          [FoodType.cooked, FoodType.dairy, FoodType.fruits].contains(foodType)) {
        maxScore = math.max(maxScore, 0.8);
      }
      
      // Add more general compatibility checks
      if (ngoServingTypes.contains('Homeless') && 
          [FoodType.cooked, FoodType.packaged].contains(foodType)) {
        maxScore = math.max(maxScore, 0.8);
      }
    }
    
    // General compatibility for all populations if no specific match found
    return maxScore > 0.0 ? maxScore : 0.6;
  }
  
  /// Calculate availability score based on current workload
  Future<double> _calculateAvailabilityScore(String ngoId) async {
    try {
      // Count active deliveries for this NGO
      final activeDeliveries = await _firestoreService.query(
        'food_donations',
        where: {
          'assignedNGOId': ngoId,
          'status': 'confirmed', // Note: This simplified query only checks for confirmed status
        },
      );
      
      // Score based on current workload (fewer active = higher score)
      final workloadCount = activeDeliveries.docs.length;
      
      if (workloadCount == 0) return 1.0;
      if (workloadCount <= 2) return 0.8;
      if (workloadCount <= 4) return 0.6;
      if (workloadCount <= 6) return 0.4;
      return 0.2;
    } catch (e) {
      return 0.5; // Default score if unable to calculate
    }
  }
  
  /// Generate human-readable reasoning for the match
  String _generateReasoning(
    Map<MatchingCriteria, double> scores,
    MatchingAlgorithm algorithm,
    double distance,
  ) {
    final reasons = <String>[];
    
    if (scores[MatchingCriteria.distance]! > 0.8) {
      reasons.add('Very close proximity (${distance.toStringAsFixed(1)}km)');
    } else if (scores[MatchingCriteria.distance]! > 0.6) {
      reasons.add('Good distance (${distance.toStringAsFixed(1)}km)');
    }
    
    if (scores[MatchingCriteria.capacity]! > 0.8) {
      reasons.add('Excellent capacity match');
    } else if (scores[MatchingCriteria.capacity]! > 0.6) {
      reasons.add('Good capacity compatibility');
    }
    
    if (scores[MatchingCriteria.urgency]! > 0.8) {
      reasons.add('Critical time sensitivity match');
    } else if (scores[MatchingCriteria.urgency]! > 0.6) {
      reasons.add('Good urgency alignment');
    }
    
    if (scores[MatchingCriteria.foodType]! > 0.8) {
      reasons.add('Perfect food type preference match');
    } else if (scores[MatchingCriteria.foodType]! > 0.6) {
      reasons.add('Good food type compatibility');
    }
    
    if (scores[MatchingCriteria.availability]! > 0.8) {
      reasons.add('High availability (low current workload)');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Meets basic matching criteria');
    }
    
    return reasons.join(', ');
  }
  
  /// Get donation details by ID
  Future<FoodDonation?> _getDonation(String donationId) async {
    final doc = await _firestoreService.get('food_donations', donationId);
    if (doc == null) return null;
    return FoodDonation.fromFirestore(doc);
  }
  
  /// Get available NGOs within range (optimized)
  Future<List<NGOProfile>> _getAvailableNGOs({
    required Map<String, double> donationLocation,
    required double maxDistance,
  }) async {
    try {
      // Get all verified and active NGOs
      final ngoDocs = await _firestoreService.query(
        'ngo_profiles',
        where: {
          'verificationStatus': 'approved',
          'isActive': true,
        },
      );
      
      final ngos = <NGOProfile>[];
      final donationLat = donationLocation['latitude']?.toDouble() ?? 0.0;
      final donationLng = donationLocation['longitude']?.toDouble() ?? 0.0;
      
      // Batch process distance calculations
      for (final doc in ngoDocs.docs) {
        try {
          final ngo = NGOProfile.fromMap(doc.data()! as Map<String, dynamic>);
          
          // Ensure location data exists
          if (ngo.location['latitude'] == null || ngo.location['longitude'] == null) {
            continue;
          }
          
          final ngoLat = ngo.location['latitude']!.toDouble();
          final ngoLng = ngo.location['longitude']!.toDouble();
          
          // Calculate distance
          final distance = await _locationService.calculateDistance(
            donationLat, donationLng, ngoLat, ngoLng,
          );
          
          if (distance <= maxDistance) {
            ngos.add(ngo);
          }
        } catch (e) {
          // Skip invalid NGO profiles
          continue;
        }
      }
      
      return ngos;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'event': 'ngo_query_error',
          'description': 'Error querying available NGOs: $e',
          'error': e.toString(),
        },
      );
      return [];
    }
  }
  
  /// Store matching results for analytics
  Future<void> _storeMatchingResults(
    String donationId,
    MatchingAlgorithm algorithm,
    List<MatchingResult> matches,
  ) async {
    final matchingSession = {
      'donationId': donationId,
      'algorithm': algorithm.id,
      'timestamp': DateTime.now(),
      'matchCount': matches.length,
      'matches': matches.map((m) => m.toMap()).toList(),
    };
    
    final sessionId = 'matching_${DateTime.now().millisecondsSinceEpoch}';
    await _firestoreService.create('matching_sessions', sessionId, matchingSession);
  }
  
  /// Notify matched NGOs about available donation
  Future<void> notifyMatches(List<MatchingResult> matches, FoodDonation donation) async {
    for (final match in matches) {
      await _notificationService.sendNotification(
        userId: match.ngoId,
        title: 'New Food Donation Match',
        message: 'A ${donation.foodTypes.join(", ")} donation (${donation.quantity} servings) is available nearby',
        type: 'donation_match',
        data: {
          'donationId': donation.id,
          'distance': match.distance.toStringAsFixed(1),
          'score': match.score.toStringAsFixed(2),
          'reasoning': match.reasoning,
        },
      );
    }
    
    await _auditService.logEvent(
      eventType: AuditEventType.adminAction,
      userId: 'system',
      riskLevel: AuditRiskLevel.low,
      additionalData: {
        'event': 'match_notifications_sent',
        'description': 'Sent ${matches.length} match notifications for donation ${donation.id}',
        'donationId': donation.id,
        'notificationCount': matches.length,
      },
    );
  }
}

// New classes for enhanced bidirectional matching

/// Result for request-to-donation matching
class RequestDonationMatchingResult {
  final String requestId;
  final String donationId;
  final double score;
  final double distance;
  final Map<MatchingCriteria, double> criteriaScores;
  final FoodDonation donation;
  final String reasoning;
  final DateTime timestamp;
  
  RequestDonationMatchingResult({
    required this.requestId,
    required this.donationId,
    required this.score,
    required this.distance,
    required this.criteriaScores,
    required this.donation,
    required this.reasoning,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'donationId': donationId,
      'score': score,
      'distance': distance,
      'criteriaScores': criteriaScores.map((k, v) => MapEntry(k.toString(), v)),
      'reasoning': reasoning,
      'timestamp': timestamp,
    };
  }
}

/// Enhanced matching service that handles both donations and requests
class EnhancedMatchingService {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  
  EnhancedMatchingService({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required NotificationService notificationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService,
       _notificationService = notificationService,
       _auditService = auditService;

  /// Find optimal donation matches for a food request
  Future<List<RequestDonationMatchingResult>> findDonationsForRequest({
    required String requestId,
    MatchingAlgorithm algorithm = MatchingAlgorithm.optimal,
    int maxMatches = 5,
  }) async {
    try {
      // Get request details
      final request = await _getRequest(requestId);
      if (request == null) throw Exception('Food request not found');
      
      // Get available donations in range
      final donations = await _getAvailableDonations(
        requestLocation: {
          'latitude': request.deliveryLocation['latitude']?.toDouble() ?? 0.0,
          'longitude': request.deliveryLocation['longitude']?.toDouble() ?? 0.0,
        },
        maxDistance: algorithm.maxDistance,
      );
      
      if (donations.isEmpty) {
        await _auditService.logEvent(
          eventType: AuditEventType.dataAccess,
          userId: 'system',
          riskLevel: AuditRiskLevel.medium,
          additionalData: {
            'event': 'matching_no_donations',
            'description': 'No donations found within range for request $requestId',
            'requestId': requestId,
            'maxDistance': algorithm.maxDistance,
          },
        );
        return [];
      }
      
      // Calculate matching scores
      final matches = <RequestDonationMatchingResult>[];
      
      for (final donation in donations) {
        final score = await _calculateRequestDonationScore(
          request: request,
          donation: donation,
          algorithm: algorithm,
        );
        
        if (score != null) {
          matches.add(score);
        }
      }
      
      // Sort by score (highest first) and limit results
      matches.sort((a, b) => b.score.compareTo(a.score));
      final topMatches = matches.take(maxMatches).toList();
      
      // Store matching results for analytics
      await _storeRequestMatchingResults(requestId, algorithm, topMatches);
      
      // Log successful matching
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'event': 'request_matching_completed',
          'description': 'Found ${topMatches.length} donation matches for request $requestId',
          'requestId': requestId,
          'algorithm': algorithm.id,
          'matchCount': topMatches.length,
          'topScore': topMatches.isNotEmpty ? topMatches.first.score : 0,
        },
      );
      
      return topMatches;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'event': 'request_matching_error',
          'description': 'Error finding donation matches for request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Execute automatic matching for both new donations and new requests
  Future<void> executeAutomaticMatching({
    String? donationId,
    String? requestId,
  }) async {
    try {
      if (donationId != null) {
        await _autoMatchDonation(donationId);
      }
      
      if (requestId != null) {
        await _autoMatchRequest(requestId);
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'event': 'auto_matching_error',
          'description': 'Error in automatic matching: $e',
          'donationId': donationId,
          'requestId': requestId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Auto-match a donation with existing requests
  Future<void> _autoMatchDonation(String donationId) async {
    try {
      final donation = await _getDonation(donationId);
      if (donation == null || donation.status != DonationStatus.listed) return;

      // Find compatible requests
      final requests = await _getCompatibleRequests(donation);
      if (requests.isEmpty) return;

      // Find best match
      FoodRequest? bestRequest;
      double bestScore = 0.0;

      for (final request in requests) {
        final score = await _calculateDonationRequestCompatibility(donation, request);
        if (score > bestScore && score >= 0.7) { // 70% threshold
          bestScore = score;
          bestRequest = request;
        }
      }

      if (bestRequest != null) {
        await _executeBidirectionalMatch(donationId, bestRequest.id);
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'event': 'auto_match_donation_error',
          'description': 'Error auto-matching donation $donationId: $e',
          'donationId': donationId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Auto-match a request with existing donations
  Future<void> _autoMatchRequest(String requestId) async {
    try {
      final request = await _getRequest(requestId);
      if (request == null || request.status != RequestStatus.pending) return;

      // Find compatible donations
      final donations = await _getCompatibleDonations(request);
      if (donations.isEmpty) return;

      // Find best match
      FoodDonation? bestDonation;
      double bestScore = 0.0;

      for (final donation in donations) {
        final score = await _calculateDonationRequestCompatibility(donation, request);
        if (score > bestScore && score >= 0.7) { // 70% threshold
          bestScore = score;
          bestDonation = donation;
        }
      }

      if (bestDonation != null) {
        await _executeBidirectionalMatch(bestDonation.id, requestId);
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'event': 'auto_match_request_error',
          'description': 'Error auto-matching request $requestId: $e',
          'requestId': requestId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Execute bidirectional match (donation <-> request)
  Future<void> _executeBidirectionalMatch(String donationId, String requestId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update donation
      batch.update(
        FirebaseFirestore.instance.collection('food_donations').doc(donationId),
        {
          'status': DonationStatus.matched.name,
          'matchedRequestId': requestId,
          'updatedAt': Timestamp.now(),
          'metadata.autoMatched': true,
          'metadata.matchedAt': Timestamp.now(),
        },
      );
      
      // Update request
      batch.update(
        FirebaseFirestore.instance.collection('food_requests').doc(requestId),
        {
          'status': RequestStatus.matched.name,
          'matchedDonationId': donationId,
          'updatedAt': Timestamp.now(),
          'metadata.autoMatched': true,
          'metadata.matchedAt': Timestamp.now(),
        },
      );
      
      await batch.commit();
      
      // Log the match
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'event': 'bidirectional_match_executed',
          'description': 'Bidirectional match executed: donation $donationId <-> request $requestId',
          'donationId': donationId,
          'requestId': requestId,
          'matchType': 'automatic',
        },
      );
      
      // Notify stakeholders
      await _notifyBidirectionalMatch(donationId, requestId);
      
      // Trigger volunteer assignment
      await _triggerVolunteerAssignment(donationId, requestId);
      
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'event': 'bidirectional_match_error',
          'description': 'Error executing bidirectional match: $e',
          'donationId': donationId,
          'requestId': requestId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Calculate compatibility score between donation and request
  Future<double> _calculateDonationRequestCompatibility(
    FoodDonation donation,
    FoodRequest request,
  ) async {
    try {
      double score = 0.0;
      
      // Food type compatibility (35%)
      double foodTypeScore = 0.0;
      final donationFoodTypes = donation.foodTypes;
      
      for (final reqType in request.requiredFoodTypes) {
        for (final donType in donationFoodTypes) {
          if (_areFoodTypesCompatible(reqType, donType)) {
            foodTypeScore = 1.0;
            break;
          }
        }
        if (foodTypeScore > 0) break;
      }
      score += foodTypeScore * 0.35;
      
      // Quantity match (25%) - with better handling
      final requestQuantity = request.requiredQuantity.toDouble();
      final donationQuantity = donation.quantity.toDouble();
      
      if (requestQuantity <= 0) {
        return 0.0; // Invalid request
      }
      
      final quantityRatio = donationQuantity / requestQuantity;
      double quantityScore;
      
      if (quantityRatio >= 0.8 && quantityRatio <= 1.2) {
        quantityScore = 1.0; // Perfect match
      } else if (quantityRatio >= 0.5 && quantityRatio < 0.8) {
        quantityScore = quantityRatio / 0.8; // Proportional score for under-supply
      } else if (quantityRatio > 1.2 && quantityRatio <= 2.0) {
        quantityScore = 0.8; // Good for over-supply
      } else if (quantityRatio > 2.0) {
        quantityScore = 0.5; // Acceptable for large over-supply
      } else {
        quantityScore = quantityRatio; // Poor match for severe under-supply
      }
      
      score += quantityScore * 0.25;
      
      // Distance score (20%)
      try {
        final distance = await _locationService.calculateDistance(
          donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
          donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
          request.deliveryLocation['latitude']?.toDouble() ?? 0.0,
          request.deliveryLocation['longitude']?.toDouble() ?? 0.0,
        );
        
        double distanceScore;
        if (distance <= 5) {
          distanceScore = 1.0;
        } else if (distance <= 15) {
          distanceScore = 0.8;
        } else if (distance <= 30) {
          distanceScore = (40.0 - distance) / 25.0;
        } else {
          distanceScore = 0.1;
        }
        
        score += (distanceScore > 0 ? distanceScore : 0) * 0.2;
      } catch (e) {
        // If distance calculation fails, use medium score
        score += 0.5 * 0.2;
      }
      
      // Time compatibility (15%)
      final now = DateTime.now();
      final timeToExpiry = donation.expiryDateTime.difference(now).inHours;
      final timeToNeeded = request.neededBy.difference(now).inHours;
      
      double timeScore;
      if (timeToExpiry <= 0) {
        timeScore = 0.0; // Expired
      } else if (timeToNeeded > 0 && timeToExpiry > timeToNeeded + 2) {
        timeScore = 1.0; // Perfect timing
      } else if (timeToNeeded > 0 && timeToExpiry > timeToNeeded) {
        timeScore = 0.8; // Good timing
      } else if (timeToExpiry > 6) {
        timeScore = 0.6; // Acceptable
      } else {
        timeScore = 0.3; // Poor timing
      }
      
      score += timeScore * 0.15;
      
      // Dietary compatibility (5%)
      double dietaryScore = 1.0;
      for (final restriction in request.dietaryRestrictions) {
        if (!_isDietaryCompatible(restriction, donation)) {
          dietaryScore = 0.0;
          break;
        }
      }
      score += dietaryScore * 0.05;
      
      // Ensure score is between 0 and 1
      return score.clamp(0.0, 1.0);
    } catch (e) {
      // Return low score for any calculation errors
      return 0.1;
    }
  }

  /// Check if food types are compatible
  bool _areFoodTypesCompatible(FoodCategory requestType, FoodType donationType) {
    // Improved compatibility mapping
    switch (donationType) {
      case FoodType.cooked:
        return requestType == FoodCategory.readyToEat;
      case FoodType.raw:
        return [FoodCategory.vegetables, FoodCategory.fruits, FoodCategory.grains, FoodCategory.meat].contains(requestType);
      case FoodType.packaged:
        return [FoodCategory.grains, FoodCategory.beverages, FoodCategory.bakery, FoodCategory.other].contains(requestType);
      case FoodType.fruits:
        return requestType == FoodCategory.fruits;
      case FoodType.vegetables:
        return requestType == FoodCategory.vegetables;
      case FoodType.dairy:
        return requestType == FoodCategory.dairy;
      case FoodType.meat:
        return requestType == FoodCategory.meat;
      case FoodType.grains:
        return [FoodCategory.grains, FoodCategory.bakery].contains(requestType);
      case FoodType.beverages:
        return requestType == FoodCategory.beverages;
      case FoodType.bakery:
        return [FoodCategory.bakery, FoodCategory.grains].contains(requestType);
      default:
        return requestType == FoodCategory.other;
    }
  }

  /// Check dietary compatibility
  bool _isDietaryCompatible(String restriction, FoodDonation donation) {
    switch (restriction.toLowerCase()) {
      case 'vegetarian':
        return donation.isVegetarian ?? false;
      case 'vegan':
        return donation.isVegan ?? false;
      case 'gluten-free':
        return false; // Not supported in current model
      case 'halal':
        return donation.isHalal ?? false;
      case 'kosher':
        return false; // Not supported in current model
      default:
        return true;
    }
  }

  /// Get compatible requests for a donation
  Future<List<FoodRequest>> _getCompatibleRequests(FoodDonation donation) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('food_requests')
        .where('status', isEqualTo: RequestStatus.pending.name)
        .get();
    
    final requests = <FoodRequest>[];
    for (final doc in snapshot.docs) {
      final request = FoodRequest.fromFirestore(doc);
      
      // Basic compatibility checks
      if (request.neededBy.isAfter(DateTime.now()) &&
          request.neededBy.isAfter(donation.expiresAt.subtract(const Duration(hours: 2)))) {
        requests.add(request);
      }
    }
    
    return requests;
  }

  /// Get compatible donations for a request
  Future<List<FoodDonation>> _getCompatibleDonations(FoodRequest request) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('food_donations')
        .where('status', isEqualTo: DonationStatus.listed.name)
        .get();
    
    final donations = <FoodDonation>[];
    for (final doc in snapshot.docs) {
      final donation = FoodDonation.fromFirestore(doc);
      
      // Basic compatibility checks
      if (donation.expiresAt.isAfter(DateTime.now()) &&
          donation.expiresAt.isAfter(request.neededBy.subtract(const Duration(hours: 2)))) {
        donations.add(donation);
      }
    }
    
    return donations;
  }

  /// Helper methods for the enhanced matching
  Future<FoodRequest?> _getRequest(String requestId) async {
    final doc = await _firestoreService.get('food_requests', requestId);
    if (doc == null) return null;
    return FoodRequest.fromMap(doc.data()! as Map<String, dynamic>);
  }

  Future<FoodDonation?> _getDonation(String donationId) async {
    final doc = await _firestoreService.get('food_donations', donationId);
    if (doc == null) return null;
    return FoodDonation.fromFirestore(doc);
  }

  Future<List<FoodDonation>> _getAvailableDonations({
    required Map<String, double> requestLocation,
    required double maxDistance,
  }) async {
    final donationDocs = await _firestoreService.query(
      'food_donations',
      where: {
        'status': DonationStatus.listed.name,
      },
    );
    
    final donations = <FoodDonation>[];
    
    for (final doc in donationDocs.docs) {
      final donation = FoodDonation.fromFirestore(doc);
      
      // Check if donation is within range
      final distance = await _locationService.calculateDistance(
        requestLocation['latitude']?.toDouble() ?? 0.0,
        requestLocation['longitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
      );
      
      if (distance <= maxDistance) {
        donations.add(donation);
      }
    }
    
    return donations;
  }

  Future<RequestDonationMatchingResult?> _calculateRequestDonationScore({
    required FoodRequest request,
    required FoodDonation donation,
    required MatchingAlgorithm algorithm,
  }) async {
    try {
      // Calculate distance score
      final distance = await _locationService.calculateDistance(
        request.deliveryLocation['latitude']?.toDouble() ?? 0.0,
        request.deliveryLocation['longitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['latitude']?.toDouble() ?? 0.0,
        donation.pickupLocation['longitude']?.toDouble() ?? 0.0,
      );
      
      if (distance > algorithm.maxDistance) return null;
      
      final distanceScore = _calculateDistanceScore(distance, algorithm.maxDistance);
      
      // Calculate quantity score
      final quantityScore = _calculateQuantityScore(donation.quantity, request.requiredQuantity);
      
      // Calculate urgency score
      final urgencyScore = _calculateRequestUrgencyScore(request, donation);
      
      // Calculate food type compatibility score
      final foodTypeScore = _calculateRequestFoodTypeScore(request, donation);
      
      // Calculate availability score (based on expiry vs needed time)
      final availabilityScore = _calculateTimeAvailabilityScore(request, donation);
      
      // Calculate weighted total score
      final criteriaScores = {
        MatchingCriteria.distance: distanceScore,
        MatchingCriteria.capacity: quantityScore,
        MatchingCriteria.urgency: urgencyScore,
        MatchingCriteria.foodType: foodTypeScore,
        MatchingCriteria.availability: availabilityScore,
      };
      
      final totalScore = criteriaScores.entries
          .map((entry) => entry.value * algorithm.weights[entry.key]!)
          .reduce((a, b) => a + b);
      
      // Generate reasoning
      final reasoning = _generateRequestReasoning(criteriaScores, algorithm, distance);
      
      return RequestDonationMatchingResult(
        requestId: request.id,
        donationId: donation.id,
        score: totalScore,
        distance: distance,
        criteriaScores: criteriaScores,
        donation: donation,
        reasoning: reasoning,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'event': 'score_calculation_error',
          'description': 'Error calculating score for request ${request.id} and donation ${donation.id}: $e',
          'requestId': request.id,
          'donationId': donation.id,
          'error': e.toString(),
        },
      );
      return null;
    }
  }

  double _calculateDistanceScore(double distance, double maxDistance) {
    return (maxDistance - distance) / maxDistance;
  }

  double _calculateQuantityScore(int donationQuantity, int requestedQuantity) {
    final ratio = donationQuantity / requestedQuantity;
    return ratio >= 1.0 ? 1.0 : ratio;
  }

  double _calculateRequestUrgencyScore(FoodRequest request, FoodDonation donation) {
    final timeToNeeded = request.neededBy.difference(DateTime.now()).inHours;
    final timeToExpiry = donation.expiresAt.difference(DateTime.now()).inHours;
    
    if (request.urgency == RequestUrgency.critical) return 1.0;
    if (request.urgency == RequestUrgency.high) return 0.8;
    if (timeToNeeded <= 12 && timeToExpiry >= timeToNeeded) return 0.9;
    if (timeToNeeded <= 24 && timeToExpiry >= timeToNeeded) return 0.7;
    return 0.5;
  }

  double _calculateRequestFoodTypeScore(FoodRequest request, FoodDonation donation) {
    for (final reqType in request.requiredFoodTypes) {
      for (final donType in donation.foodTypes) {
        if (_areFoodTypesCompatible(reqType, donType)) {
          return 1.0;
        }
      }
    }
    return 0.0;
  }

  double _calculateTimeAvailabilityScore(FoodRequest request, FoodDonation donation) {
    final timeToNeeded = request.neededBy.difference(DateTime.now()).inHours;
    final timeToExpiry = donation.expiresAt.difference(DateTime.now()).inHours;
    
    if (timeToExpiry < timeToNeeded) return 0.0;
    if (timeToExpiry >= timeToNeeded + 12) return 1.0;
    return 0.7;
  }

  String _generateRequestReasoning(
    Map<MatchingCriteria, double> scores,
    MatchingAlgorithm algorithm,
    double distance,
  ) {
    final reasons = <String>[];
    
    if (scores[MatchingCriteria.distance]! > 0.8) {
      reasons.add('Very close proximity (${distance.toStringAsFixed(1)}km)');
    } else if (scores[MatchingCriteria.distance]! > 0.6) {
      reasons.add('Good distance (${distance.toStringAsFixed(1)}km)');
    }
    
    if (scores[MatchingCriteria.capacity]! > 0.8) {
      reasons.add('Excellent quantity match');
    } else if (scores[MatchingCriteria.capacity]! > 0.6) {
      reasons.add('Good quantity compatibility');
    }
    
    if (scores[MatchingCriteria.urgency]! > 0.8) {
      reasons.add('High urgency match');
    }
    
    if (scores[MatchingCriteria.foodType]! > 0.8) {
      reasons.add('Perfect food type match');
    }
    
    if (scores[MatchingCriteria.availability]! > 0.8) {
      reasons.add('Good time compatibility');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Meets basic matching criteria');
    }
    
    return reasons.join(', ');
  }

  Future<void> _storeRequestMatchingResults(
    String requestId,
    MatchingAlgorithm algorithm,
    List<RequestDonationMatchingResult> matches,
  ) async {
    final matchingSession = {
      'requestId': requestId,
      'algorithm': algorithm.id,
      'timestamp': DateTime.now(),
      'matchCount': matches.length,
      'matches': matches.map((m) => m.toMap()).toList(),
    };
    
    final sessionId = 'request_matching_${DateTime.now().millisecondsSinceEpoch}';
    await _firestoreService.create('request_matching_sessions', sessionId, matchingSession);
  }

  Future<void> _notifyBidirectionalMatch(String donationId, String requestId) async {
    try {
      final donationDoc = await FirebaseFirestore.instance.collection('food_donations').doc(donationId).get();
      final requestDoc = await FirebaseFirestore.instance.collection('food_requests').doc(requestId).get();
      
      if (!donationDoc.exists || !requestDoc.exists) return;
      
      final donation = FoodDonation.fromFirestore(donationDoc);
      final request = FoodRequest.fromFirestore(requestDoc);
      
      // Notify donor
      await _notificationService.sendNotification(
        userId: donation.donorId,
        title: 'Donation Matched!',
        message: 'Your donation has been matched with an NGO request for ${request.expectedBeneficiaries} beneficiaries.',
        type: 'donation_matched',
        data: {
          'donationId': donationId,
          'requestId': requestId,
        },
      );
      
      // Notify NGO
      await _notificationService.sendNotification(
        userId: request.ngoId,
        title: 'Request Matched!',
        message: 'Your food request has been matched with a donation of ${donation.quantity} ${donation.unit}.',
        type: 'request_matched',
        data: {
          'requestId': requestId,
          'donationId': donationId,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'event': 'bidirectional_match_notification_error',
          'description': 'Error sending bidirectional match notifications: $e',
          'donationId': donationId,
          'requestId': requestId,
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _triggerVolunteerAssignment(String donationId, String requestId) async {
    // This will be implemented as part of the volunteer assignment system
    // For now, we'll just log the event
    await _auditService.logEvent(
      eventType: AuditEventType.adminAction,
      userId: 'system',
      riskLevel: AuditRiskLevel.low,
      additionalData: {
        'event': 'volunteer_assignment_triggered',
        'description': 'Volunteer assignment triggered for donation $donationId and request $requestId',
        'donationId': donationId,
        'requestId': requestId,
      },
    );
  }
}
