import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/volunteer_profile.dart';
import '../models/food_donation.dart';
import '../models/dispatch.dart';
import '../models/enums.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

export '../models/dispatch.dart';
export '../models/enums.dart' show DispatchPriority, VolunteerStatus, VehicleType;
class VolunteerDispatchService {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  
  VolunteerDispatchService({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required NotificationService notificationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService,
       _notificationService = notificationService,
       _auditService = auditService;

  /// Find optimal volunteers for a delivery task
  Future<List<DispatchResult>> findAvailableVolunteers({
    required DeliveryTask task,
    DispatchCriteria criteria = const DispatchCriteria(),
    int maxVolunteers = 3,
  }) async {
    try {
      // Get available volunteers in range
      final volunteers = await _getAvailableVolunteers(
        location: task.pickupLocation,
        criteria: criteria,
      );
      
      if (volunteers.isEmpty) {
        await _auditService.logEvent(
          eventType: AuditEventType.securityAlert,
          userId: 'system',
          riskLevel: AuditRiskLevel.high,
          additionalData: {
            'action': 'dispatch_no_volunteers',
            'taskId': task.id,
            'donationId': task.donationId,
            'maxDistance': criteria.maxDistance,
          },
        );
        return [];
      }
      
      // Calculate dispatch scores for each volunteer
      final results = <DispatchResult>[];
      
      for (final volunteer in volunteers) {
        final result = await _calculateDispatchScore(
          volunteer: volunteer,
          task: task,
          criteria: criteria,
        );
        
        if (result != null) {
          results.add(result);
        }
      }
      
      // Sort by score (highest first) and limit results
      results.sort((a, b) => b.score.compareTo(a.score));
      final topResults = results.take(maxVolunteers).toList();
      
      // Store dispatch analysis for optimization
      await _storeDispatchAnalysis(task.id, criteria, topResults);
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'volunteer_dispatch_completed',
          'taskId': task.id,
          'candidateCount': topResults.length,
          'topScore': topResults.isNotEmpty ? topResults.first.score : 0,
        },
      );
      
      return topResults;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'dispatch_error',
          'taskId': task.id, 
          'error': e.toString()
        },
      );
      rethrow;
    }
  }
  
  /// Create delivery task from food donation
  Future<DeliveryTask> createDeliveryTask({
    required String donationId,
    required String pickupAddress,
    required String deliveryAddress,
    required Map<String, double> pickupLocation,
    required Map<String, double> deliveryLocation,
    DateTime? scheduledTime,
    DispatchPriority? priority,
    String? specialInstructions,
    List<String> requiredSkills = const [],
  }) async {
    // Get donation details for task planning
    final donation = await _getDonation(donationId);
    if (donation == null) throw Exception('Donation not found');
    
    // Determine priority based on expiry time
    final calculatedPriority = priority ?? _calculatePriority(donation);
    
    // Estimate weight and volume
    final estimatedWeight = _estimateWeight(donation);
    final estimatedVolume = _estimateVolume(donation);
    
    final task = DeliveryTask(
      id: _generateTaskId(),
      donationId: donationId,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      scheduledTime: scheduledTime ?? DateTime.now().add(Duration(hours: 1)),
      priority: calculatedPriority,
      specialInstructions: specialInstructions,
      requiredSkills: requiredSkills,
      estimatedWeight: estimatedWeight,
      estimatedVolume: estimatedVolume,
    );
    
    // Store task in database
    await _firestoreService.addDocument('delivery_tasks', task.toMap());
    
    await _auditService.logEvent(
      eventType: AuditEventType.dataModification,
      userId: 'system',
      riskLevel: AuditRiskLevel.low,
      additionalData: {
        'action': 'delivery_task_created',
        'taskId': task.id,
        'donationId': donationId,
        'priority': calculatedPriority.toString(),
        'estimatedWeight': estimatedWeight,
      },
    );
    
    return task;
  }
  
  /// Assign task to volunteer
  Future<bool> assignTask({
    required String taskId,
    required String volunteerId,
    Map<String, dynamic>? assignmentMetadata,
  }) async {
    try {
      // Update task with volunteer assignment
      await _firestoreService.updateDocument('delivery_tasks', taskId, {
        'assignedVolunteerId': volunteerId,
        'status': 'assigned',
        'assignedAt': DateTime.now(),
        'assignmentMetadata': assignmentMetadata,
      });
      
      // Update volunteer status
      await _firestoreService.updateDocument('volunteer_profiles', volunteerId, {
        'currentTaskId': taskId,
        'status': 'busy',
        'lastAssignedAt': DateTime.now(),
      });
      
      // Get volunteer and task details for notification
      final volunteer = await _getVolunteer(volunteerId);
      final task = await _getTask(taskId);
      
      if (volunteer != null && task != null) {
        // Send notification to volunteer
        await _notificationService.sendNotification(
          userId: volunteerId,
          title: 'New Delivery Assignment',
          body: 'You have been assigned a delivery task from ${task['pickupAddress']} to ${task['deliveryAddress']}',
          data: {
            'type': 'task_assignment',
            'taskId': taskId,
            'priority': task['priority'],
            'estimatedDuration': task['estimatedDuration']?.toString() ?? '60',
          },
        );
        
        // Send confirmation to donation owner
        await _notificationService.sendToDonor(
          donationId: task['donationId'],
          title: 'Volunteer Assigned',
          body: 'A volunteer has been assigned for your food donation pickup',
          data: {
            'type': 'volunteer_assigned',
            'volunteerId': volunteerId,
            'taskId': taskId,
          },
        );
      }
      
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'task_assignment_completed',
          'taskId': taskId,
          'volunteerId': volunteerId,
          'assignmentMetadata': assignmentMetadata,
        },
      );
      
      return true;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'task_assignment_failed',
          'taskId': taskId,
          'volunteerId': volunteerId,
          'error': e.toString(),
        },
      );
      return false;
    }
  }
  
  /// Calculate dispatch score for volunteer
  Future<DispatchResult?> _calculateDispatchScore({
    required VolunteerProfile volunteer,
    required DeliveryTask task,
    required DispatchCriteria criteria,
  }) async {
    try {
      // Calculate distance to pickup location
      final startLat = volunteer.currentLocation?['latitude'] ?? volunteer.baseLocation['latitude']!;
      final startLon = volunteer.currentLocation?['longitude'] ?? volunteer.baseLocation['longitude']!;
      final endLat = task.pickupLocation['latitude']!;
      final endLon = task.pickupLocation['longitude']!;

      final distance = _locationService.calculateDistance(
        startLat,
        startLon,
        endLat,
        endLon,
      );
      
      if (distance > criteria.maxDistance) return null;
      
      // Calculate various scoring factors
      final distanceScore = _calculateDistanceScore(distance, criteria.maxDistance);
      final ratingScore = _calculateRatingScore(volunteer.rating ?? 0, criteria.minRating);
      final availabilityScore = _calculateAvailabilityScore(volunteer);
      final experienceScore = _calculateExperienceScore(volunteer, criteria.requiresExperience);
      final transportScore = _calculateTransportScore(volunteer, criteria.allowedTransport);
      final priorityScore = _calculatePriorityScore(task.priority, volunteer);
      
      // Calculate weighted total score
      final totalScore = (
        distanceScore * 0.25 +
        ratingScore * 0.20 +
        availabilityScore * 0.20 +
        experienceScore * 0.15 +
        transportScore * 0.10 +
        priorityScore * 0.10
      );
      
      // Estimate duration and arrival time
      final estimatedDuration = _estimateTaskDuration(distance, task, volunteer);
      final estimatedArrival = DateTime.now().add(Duration(minutes: (distance * 2).round()));
      
      // Generate reasoning
      final reasoning = _generateDispatchReasoning({
        'distance': distanceScore,
        'rating': ratingScore,
        'availability': availabilityScore,
        'experience': experienceScore,
        'transport': transportScore,
        'priority': priorityScore,
      }, distance);
      
      return DispatchResult(
        volunteerId: volunteer.id,
        taskId: task.id,
        score: totalScore,
        distance: distance,
        estimatedDuration: estimatedDuration,
        volunteer: volunteer,
        reasoning: reasoning,
        estimatedArrival: estimatedArrival,
        metadata: {
          'distanceScore': distanceScore,
          'ratingScore': ratingScore,
          'availabilityScore': availabilityScore,
          'experienceScore': experienceScore,
          'transportScore': transportScore,
          'priorityScore': priorityScore,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'dispatch_score_error',
          'volunteerId': volunteer.id,
          'taskId': task.id,
          'error': e.toString(),
        },
      );
      return null;
    }
  }
  
  /// Get available volunteers within criteria
  Future<List<VolunteerProfile>> _getAvailableVolunteers({
    required Map<String, double> location,
    required DispatchCriteria criteria,
  }) async {
    // Get all verified and available volunteers
    final volunteerDocs = await _firestoreService.queryCollection(
      'volunteer_profiles',
      where: [
        {'field': 'verificationStatus', 'operator': '==', 'value': 'verified'},
        {'field': 'isActive', 'operator': '==', 'value': true},
        {'field': 'status', 'operator': '==', 'value': 'available'},
      ],
    );
    
    final volunteers = <VolunteerProfile>[];
    
    for (final doc in volunteerDocs) {
      final volunteer = VolunteerProfile.fromMap(doc.data() as Map<String, dynamic>);
      
      // Check basic criteria
      if ((volunteer.rating ?? 0) >= criteria.minRating &&
          criteria.allowedTransport.contains(volunteer.VehicleType)) {
        volunteers.add(volunteer);
      }
    }
    
    return volunteers;
  }
  
  /// Helper scoring functions
  double _calculateDistanceScore(double distance, double maxDistance) {
    return 1.0 - (distance / maxDistance);
  }
  
  double _calculateRatingScore(double rating, int minRating) {
    if (rating >= 4.5) return 1.0;
    if (rating >= 4.0) return 0.8;
    if (rating >= 3.5) return 0.6;
    if (rating >= minRating) return 0.4;
    return 0.0;
  }
  
  double _calculateAvailabilityScore(VolunteerProfile volunteer) {
    // Check if volunteer is currently available
    final now = DateTime.now();
    final isAvailable = volunteer.availability?.any((slot) =>
      slot['dayOfWeek'] == now.weekday &&
      TimeOfDay.fromDateTime(now).hour >= slot['startHour'] &&
      TimeOfDay.fromDateTime(now).hour <= slot['endHour']
    ) ?? true;
    
    return isAvailable ? 1.0 : 0.2;
  }
  
  double _calculateExperienceScore(VolunteerProfile volunteer, bool requiresExperience) {
    final completedTasks = volunteer.completedTasks ?? 0;
    
    if (!requiresExperience) return 0.5; // Neutral if not required
    
    if (completedTasks >= 50) return 1.0;
    if (completedTasks >= 20) return 0.8;
    if (completedTasks >= 5) return 0.6;
    if (completedTasks > 0) return 0.4;
    return 0.2;
  }
  
  double _calculateTransportScore(VolunteerProfile volunteer, List<VehicleType> allowed) {
    if (allowed.contains(volunteer.VehicleType)) {
      // Bonus for better transport methods
      switch (volunteer.VehicleType) {
        case VehicleType.car: return 1.0;
        case VehicleType.bike: return 0.8;
        case VehicleType.scooter: return 0.6;
        case VehicleType.public: return 0.4;
        case VehicleType.walking: return 0.2;
        default: return 0.5;
      }
    }
    return 0.0;
  }
  
  double _calculatePriorityScore(DispatchPriority priority, VolunteerProfile volunteer) {
    // Experienced volunteers get higher priority for urgent tasks
    final completedTasks = volunteer.completedTasks ?? 0;
    
    switch (priority) {
      case DispatchPriority.immediate:
        return completedTasks >= 10 ? 1.0 : 0.3;
      case DispatchPriority.urgent:
        return completedTasks >= 5 ? 1.0 : 0.5;
      case DispatchPriority.scheduled:
      case DispatchPriority.flexible:
        return 0.8;
    }
  }
  
  double _estimateTaskDuration(double distance, DeliveryTask task, VolunteerProfile volunteer) {
    // Base time on transport method and distance
    double baseSpeed; // km/hour
    switch (volunteer.VehicleType) {
      case VehicleType.car: baseSpeed = 30; break;
      case VehicleType.bike: baseSpeed = 15; break;
      case VehicleType.scooter: baseSpeed = 25; break;
      case VehicleType.public: baseSpeed = 12; break;
      case VehicleType.walking: baseSpeed = 5; break;
      default: baseSpeed = 20; break;
    }
    
    final totalDistance = distance * 2; // Round trip
    final travelTime = (totalDistance / baseSpeed) * 60; // minutes
    final loadingTime = 15; // minutes for pickup/delivery
    
    return travelTime + loadingTime;
  }
  
  String _generateDispatchReasoning(Map<String, double> scores, double distance) {
    final reasons = <String>[];
    
    if (scores['distance']! > 0.8) {
      reasons.add('Very close (${distance.toStringAsFixed(1)}km)');
    }
    if (scores['rating']! > 0.8) {
      reasons.add('Excellent rating');
    }
    if (scores['availability']! > 0.8) {
      reasons.add('Currently available');
    }
    if (scores['experience']! > 0.8) {
      reasons.add('Highly experienced');
    }
    if (scores['transport']! > 0.8) {
      reasons.add('Optimal transport method');
    }
    
    return reasons.isEmpty ? 'Meets basic criteria' : reasons.join(', ');
  }
  
  /// Helper functions for data retrieval
  Future<FoodDonation?> _getDonation(String donationId) async {
    final doc = await _firestoreService.getDocument('food_donations', donationId);
    if (doc == null) return null;
    return FoodDonation.fromMap(doc.data()! as Map<String, dynamic>);
  }
  
  Future<VolunteerProfile?> _getVolunteer(String volunteerId) async {
    final doc = await _firestoreService.getDocument('volunteer_profiles', volunteerId);
    if (doc == null) return null;
    return VolunteerProfile.fromMap(doc.data()! as Map<String, dynamic>);
  }
  
  Future<Map<String, dynamic>?> _getTask(String taskId) async {
    final doc = await _firestoreService.getDocument('delivery_tasks', taskId);
    return doc?.data() as Map<String, dynamic>?;
  }
  
  DispatchPriority _calculatePriority(FoodDonation donation) {
    final hoursUntilExpiry = donation.expiryDateTime.difference(DateTime.now()).inHours;
    
    if (hoursUntilExpiry <= 1) return DispatchPriority.immediate;
    if (hoursUntilExpiry <= 4) return DispatchPriority.urgent;
    if (hoursUntilExpiry <= 12) return DispatchPriority.scheduled;
    return DispatchPriority.flexible;
  }
  
  double _estimateWeight(FoodDonation donation) {
    // Estimate based on food types and quantity
    final baseWeight = donation.quantity * 0.5; // 0.5kg per serving average
    return baseWeight;
  }
  
  int _estimateVolume(FoodDonation donation) {
    // Estimate volume in liters
    return (donation.quantity * 0.8).round();
  }
  
  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  Future<void> _storeDispatchAnalysis(String taskId, DispatchCriteria criteria, List<DispatchResult> results) async {
    final analysis = {
      'taskId': taskId,
      'criteria': {
        'maxDistance': criteria.maxDistance,
        'allowedTransport': criteria.allowedTransport.map((t) => t.toString()).toList(),
        'minRating': criteria.minRating,
        'requiresExperience': criteria.requiresExperience,
        'priority': criteria.priority.toString(),
      },
      'results': results.map((r) => r.toMap()).toList(),
      'timestamp': DateTime.now(),
    };
    
    await _firestoreService.addDocument('dispatch_analytics', analysis);
  }
}
