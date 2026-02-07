import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/food_donation.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import '../models/matching.dart';
import '../models/enums.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

export '../models/matching.dart';
export '../models/enums.dart' show MatchingCriteria;

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
        donationLocation: donation.pickupLocation,
        maxDistance: algorithm.maxDistance,
      );
      
      if (ngos.isEmpty) {
        await _auditService.logEvent(
          eventType: AuditEventType.securityAlert,
          userId: 'system',
          riskLevel: AuditRiskLevel.medium,
          additionalData: {
            'action': 'matching_no_ngos',
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
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'donation_matching_completed',
          'message': 'Found ${topMatches.length} matches for donation $donationId',
          'donationId': donationId,
          'algorithm': algorithm.id,
          'matchCount': topMatches.length,
          'topScore': topMatches.isNotEmpty ? topMatches.first.score : 0,
        },
      );
      
      return topMatches;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'matching_error',
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
      final distance = _locationService.calculateDistance(
        (donation.pickupLocation['latitude'] as num).toDouble(),
        (donation.pickupLocation['longitude'] as num).toDouble(),
        (ngo.location['latitude'] as num).toDouble(),
        (ngo.location['longitude'] as num).toDouble(),
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
      final availabilityScore = await _calculateAvailabilityScore(ngo.id);
      
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
        ngoId: ngo.id,
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
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'score_calculation_error',
          'ngoId': ngo.id,
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
    final donationQuantity = donation.quantity;
    final ngoCapacity = ngo.capacity;
    
    // Optimal if donation is 50-80% of NGO capacity
    final ratio = donationQuantity / ngoCapacity;
    
    if (ratio >= 0.5 && ratio <= 0.8) {
      return 1.0;
    } else if (ratio < 0.5) {
      return ratio / 0.5; // Linear scale up to 50%
    } else {
      return 1.0 - ((ratio - 0.8) / 0.4); // Linear scale down after 80%
    }
  }
  
  /// Calculate urgency score based on expiry time
  double _calculateUrgencyScore(FoodDonation donation) {
    final now = DateTime.now();
    final expiry = donation.expiryDateTime;
    final hoursUntilExpiry = expiry.difference(now).inHours;
    
    if (hoursUntilExpiry <= 2) {
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
    final ngoPreferences = ngo.preferredFoodTypes;
    final donationTypes = donation.foodTypes;
    
    if (ngoPreferences.isEmpty) return 0.5; // Neutral if no preferences
    
    final matchCount = donationTypes
        .where((type) => ngoPreferences.contains(type))
        .length;
    
    return matchCount / donationTypes.length;
  }
  
  /// Calculate availability score based on current workload
  Future<double> _calculateAvailabilityScore(String ngoId) async {
    try {
      // Count active deliveries for this NGO
      final activeDeliveries = await _firestoreService.queryCollection(
        'food_donations',
        where: [
          {'field': 'assignedNGOId', 'operator': '==', 'value': ngoId},
          {'field': 'status', 'operator': 'in', 'value': ['confirmed', 'in_transit']},
        ],
      );
      
      // Score based on current workload (fewer active = higher score)
      final workloadCount = activeDeliveries.length;
      
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
    final doc = await _firestoreService.getDocument('food_donations', donationId);
    if (doc == null) return null;
    return FoodDonation.fromMap(doc.data()! as Map<String, dynamic>);
  }
  
  /// Get available NGOs within range
  Future<List<NGOProfile>> _getAvailableNGOs({
    required Map<String, double> donationLocation,
    required double maxDistance,
  }) async {
    // Get all verified NGOs
    final ngoDocs = await _firestoreService.queryCollection(
      'ngo_profiles',
      where: [
        {'field': 'verificationStatus', 'operator': '==', 'value': 'verified'},
        {'field': 'isActive', 'operator': '==', 'value': true},
      ],
    );
    
    final ngos = <NGOProfile>[];
    
    for (final doc in ngoDocs) {
      final ngo = NGOProfile.fromFirestore(doc);
      
      // Check if NGO is within range
      final distance = _locationService.calculateDistance(
        (donationLocation['latitude'] as num).toDouble(),
        (donationLocation['longitude'] as num).toDouble(),
        (ngo.location['latitude'] as num).toDouble(),
        (ngo.location['longitude'] as num).toDouble(),
      );
      
      if (distance <= maxDistance) {
        ngos.add(ngo);
      }
    }
    
    return ngos;
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
    
    await _firestoreService.addDocument('matching_sessions', matchingSession);
  }
  
  /// Notify matched NGOs about available donation
  Future<void> notifyMatches(List<MatchingResult> matches, FoodDonation donation) async {
    for (final match in matches) {
      await _notificationService.sendToUser(
        userId: match.ngoId,
        title: 'New Food Donation Match',
        body: 'A ${donation.foodTypes.join(", ")} donation (${donation.quantity} servings) is available nearby',
        data: {
          'type': 'donation_match',
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
        'action': 'match_notifications_sent',
        'message': 'Sent ${matches.length} match notifications for donation ${donation.id}',
        'donationId': donation.id,
        'notificationCount': matches.length,
      },
    );
  }
}
