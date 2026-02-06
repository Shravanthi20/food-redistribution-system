import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/food_donation.dart';
import '../models/ngo_profile.dart';
import '../models/user.dart';
import 'user_service.dart';

class FoodDonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final Uuid _uuid = const Uuid();

  // US8: Post Surplus Food (Donor)
  Future<String> createFoodDonation({
    required String donorId,
    required FoodDonation donation,
  }) async {
    try {
      // Validate donor permissions (check if user is a donor)
      final hasRole = await _userService.hasAnyRole(donorId, [UserRole.donor, UserRole.admin]);
      
      if (!hasRole) {
        throw Exception('Only donors can create donations');
      }

      // Validate safety time window
      if (!_isValidSafetyWindow(donation)) {
        throw Exception('Invalid safety time window');
      }

      // Generate donation ID
      final donationId = _uuid.v4();
      
      // Create donation with generated ID
      final donationWithId = FoodDonation(
        id: donationId,
        donorId: donation.donorId,
        title: donation.title,
        description: donation.description,
        foodTypes: donation.foodTypes,
        quantity: donation.quantity,
        unit: donation.unit,
        preparedAt: donation.preparedAt,
        expiresAt: donation.expiresAt,
        availableFrom: donation.availableFrom,
        availableUntil: donation.availableUntil,
        safetyLevel: donation.safetyLevel,
        requiresRefrigeration: donation.requiresRefrigeration,
        isVegetarian: donation.isVegetarian,
        isVegan: donation.isVegan,
        isHalal: donation.isHalal,
        allergenInfo: donation.allergenInfo,
        specialInstructions: donation.specialInstructions,
        images: donation.images,
        pickupLocation: donation.pickupLocation,
        pickupAddress: donation.pickupAddress,
        donorContactPhone: donation.donorContactPhone,
        status: DonationStatus.listed,
        createdAt: DateTime.now(),
        isUrgent: donation.isUrgent,
      );

      // Store in Firestore
      await _firestore
          .collection('food_donations')
          .doc(donationId)
          .set(donationWithId.toFirestore());

      // Log action
      await _logDonationAction('donation_created', donationId, donorId);

      return donationId;
    } catch (e) {
      print('Error creating food donation: $e');
      rethrow;
    }
  }

  // US9: Update or Cancel Donation (Donor)
  Future<void> updateFoodDonation({
    required String donationId,
    required String donorId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final donationDoc = await _firestore
          .collection('food_donations')
          .doc(donationId)
          .get();

      if (!donationDoc.exists) {
        throw Exception('Donation not found');
      }

      final donation = FoodDonation.fromFirestore(donationDoc);

      // Check ownership
      if (donation.donorId != donorId) {
        throw Exception('Unauthorized: Can only edit own donations');
      }

      // Check if donation can be edited
      if (donation.status != DonationStatus.listed) {
        throw Exception('Cannot edit donation after pickup has started');
      }

      // Validate safety window if time fields are being updated
      if (updates.containsKey('expiresAt') || 
          updates.containsKey('availableFrom') || 
          updates.containsKey('availableUntil')) {
        
        final updatedDonation = donation.copyWith(
          expiresAt: updates['expiresAt'] != null 
              ? (updates['expiresAt'] as Timestamp).toDate() 
              : donation.expiresAt,
          availableFrom: updates['availableFrom'] != null 
              ? (updates['availableFrom'] as Timestamp).toDate() 
              : donation.availableFrom,
          availableUntil: updates['availableUntil'] != null 
              ? (updates['availableUntil'] as Timestamp).toDate() 
              : donation.availableUntil,
        );

        if (!_isValidSafetyWindow(updatedDonation)) {
          throw Exception('Invalid safety time window');
        }
      }

      // Update donation
      await _firestore
          .collection('food_donations')
          .doc(donationId)
          .update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });

      // Log action
      await _logDonationAction('donation_updated', donationId, donorId);

      // Notify stakeholders if assigned
      if (donation.assignedVolunteerId != null || donation.assignedNGOId != null) {
        await _notifyStakeholders(donationId, 'donation_updated');
      }
    } catch (e) {
      print('Error updating food donation: $e');
      rethrow;
    }
  }

  // Cancel donation
  Future<void> cancelFoodDonation({
    required String donationId,
    required String donorId,
    String? reason,
  }) async {
    try {
      final donationDoc = await _firestore
          .collection('food_donations')
          .doc(donationId)
          .get();

      if (!donationDoc.exists) {
        throw Exception('Donation not found');
      }

      final donation = FoodDonation.fromFirestore(donationDoc);

      // Check ownership
      if (donation.donorId != donorId) {
        throw Exception('Unauthorized: Can only cancel own donations');
      }

      // Check if donation can be cancelled
      if (donation.status == DonationStatus.pickedUp || 
          donation.status == DonationStatus.delivered) {
        throw Exception('Cannot cancel donation after pickup');
      }

      // Update status to cancelled
      await _firestore
          .collection('food_donations')
          .doc(donationId)
          .update({
        'status': DonationStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
        'cancellationReason': reason,
      });

      // Log action
      await _logDonationAction('donation_cancelled', donationId, donorId, 
          additionalData: {'reason': reason});

      // Notify stakeholders
      await _notifyStakeholders(donationId, 'donation_cancelled');
    } catch (e) {
      print('Error cancelling food donation: $e');
      rethrow;
    }
  }

  // US11: NGO Food Request and Requirements
  Future<void> createFoodRequest({
    required String ngoId,
    required Map<String, dynamic> requirements,
  }) async {
    try {
      final hasRole = await _userService.hasAnyRole(ngoId, [UserRole.ngo, UserRole.admin]);
      
      if (!hasRole) {
        throw Exception('Only NGOs can create food requests');
      }

      await _firestore.collection('food_requests').add({
        'ngoId': ngoId,
        'foodTypes': requirements['foodTypes'] ?? [],
        'quantityRange': requirements['quantityRange'] ?? {},
        'timingConstraints': requirements['timingConstraints'] ?? {},
        'preferredPickupTime': requirements['preferredPickupTime'],
        'specialRequirements': requirements['specialRequirements'],
        'isUrgent': requirements['isUrgent'] ?? false,
        'status': 'active',
        'createdAt': Timestamp.now(),
      });

      // Log action
      await _logDonationAction('food_request_created', null, ngoId);
    } catch (e) {
      print('Error creating food request: $e');
      rethrow;
    }
  }

  // Admin: Force assign NGO
  Future<void> forceAssignNGO({
    required String donationId,
    required String adminId,
    required String ngoId,
    String? reason,
  }) async {
    try {
      // Check admin role
      final isAdmin = await _userService.hasAnyRole(adminId, [UserRole.admin]);
      if (!isAdmin) throw Exception('Unauthorized: Only admins can force assignment');

      await _firestore.collection('food_donations').doc(donationId).update({
        'assignedNGOId': ngoId,
        'status': DonationStatus.matched.name,
        'matchingStatus': 'forced_admin',
        'updatedAt': Timestamp.now(),
      });

      await _logDonationAction('admin_force_assign_ngo', donationId, adminId, additionalData: {
        'assignedNGOId': ngoId,
        'reason': reason,
      });

      // Notify stakeholders
      await _notifyStakeholders(donationId, 'admin_forced_match');
    } catch (e) {
      print('Error forcing NGO assignment: $e');
      rethrow;
    }
  }

  // Admin: Force assign Volunteer
  Future<void> forceAssignVolunteer({
    required String donationId,
    required String adminId,
    required String volunteerId,
    String? reason,
  }) async {
    try {
      // Check admin role
      final isAdmin = await _userService.hasAnyRole(adminId, [UserRole.admin]);
      if (!isAdmin) throw Exception('Unauthorized: Only admins can force assignment');
      
      await _firestore.collection('food_donations').doc(donationId).update({
        'assignedVolunteerId': volunteerId,
        'updatedAt': Timestamp.now(),
      });

       await _logDonationAction('admin_force_assign_volunteer', donationId, adminId, additionalData: {
        'assignedVolunteerId': volunteerId,
        'reason': reason,
      });

      // Notify stakeholders
      await _notifyStakeholders(donationId, 'admin_forced_volunteer');
    } catch (e) {
      print('Error forcing volunteer assignment: $e');
      rethrow;
    }
  }

  // US12: NGO Review and Accept Donations
  Future<void> reviewDonation({
    required String donationId,
    required String ngoId,
    required bool accept,
    String? reason,
    Map<String, dynamic>? hygieneChecklist,
  }) async {
    try {
      final hasPermission = await _userService.hasAnyRole(ngoId, [UserRole.ngo, UserRole.admin]);
      
      if (!hasPermission) {
        throw Exception('Only NGOs can review donations');
      }

      final donationDoc = await _firestore
          .collection('food_donations')
          .doc(donationId)
          .get();

      if (!donationDoc.exists) {
        throw Exception('Donation not found');
      }

      final donation = FoodDonation.fromFirestore(donationDoc);

      if (donation.status != DonationStatus.listed) {
        throw Exception('Donation is no longer available for review');
      }

      // Validate hygiene requirements
      if (accept && !_validateHygieneSafety(donation, hygieneChecklist)) {
        throw Exception('Hygiene safety requirements not met');
      }

      if (accept) {
        // Accept donation
        await _firestore
            .collection('food_donations')
            .doc(donationId)
            .update({
          'status': DonationStatus.matched.name,
          'assignedNGOId': ngoId,
          'hygieneCertification': hygieneChecklist,
          'updatedAt': Timestamp.now(),
        });

        // Create donation acceptance record
        await _firestore.collection('donation_acceptances').add({
          'donationId': donationId,
          'ngoId': ngoId,
          'hygieneChecklist': hygieneChecklist,
          'acceptedAt': Timestamp.now(),
        });

        // Log action
        await _logDonationAction('donation_accepted', donationId, ngoId);

        // Notify donor
        await _notifyStakeholders(donationId, 'donation_accepted');
        
        // Trigger volunteer assignment
        await _triggerVolunteerAssignment(donationId);
      } else {
        // Record rejection for tracking
        await _firestore.collection('donation_rejections').add({
          'donationId': donationId,
          'ngoId': ngoId,
          'reason': reason,
          'rejectedAt': Timestamp.now(),
        });

        // Log action
        await _logDonationAction('donation_rejected', donationId, ngoId,
            additionalData: {'reason': reason});
      }
    } catch (e) {
      print('Error reviewing donation: $e');
      rethrow;
    }
  }

  // Request clarification from donor
  Future<void> requestClarification({
    required String donationId,
    required String ngoId,
    required String clarificationRequest,
  }) async {
    try {
      await _firestore.collection('clarification_requests').add({
        'donationId': donationId,
        'ngoId': ngoId,
        'request': clarificationRequest,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      // Notify donor
      await _notifyStakeholders(donationId, 'clarification_requested');

      // Log action
      await _logDonationAction('clarification_requested', donationId, ngoId);
    } catch (e) {
      print('Error requesting clarification: $e');
      rethrow;
    }
  }

  // Donor responds to clarification
  Future<void> respondToClarification({
    required String clarificationId,
    required String donorId,
    required String response,
    Map<String, dynamic>? updatedInfo,
  }) async {
    try {
      // Update clarification request
      await _firestore
          .collection('clarification_requests')
          .doc(clarificationId)
          .update({
        'response': response,
        'status': 'responded',
        'respondedAt': Timestamp.now(),
      });

      // Update donation if additional info provided
      if (updatedInfo != null) {
        final clarificationDoc = await _firestore
            .collection('clarification_requests')
            .doc(clarificationId)
            .get();
        
        if (clarificationDoc.exists) {
          final data = clarificationDoc.data() as Map<String, dynamic>;
          final donationId = data['donationId'];
          
          await _firestore
              .collection('food_donations')
              .doc(donationId)
              .update({
            ...updatedInfo,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      // Log action
      await _logDonationAction('clarification_responded', null, donorId);
    } catch (e) {
      print('Error responding to clarification: $e');
      rethrow;
    }
  }

  // Get donations by status
  Future<List<FoodDonation>> getDonationsByStatus(DonationStatus status) async {
    try {
      final query = await _firestore
          .collection('food_donations')
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FoodDonation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting donations by status: $e');
      return [];
    }
  }

  // Get donations for NGO (based on preferences and location)
  Future<List<FoodDonation>> getAvailableDonationsForNGO(String ngoId) async {
    try {
      // Get NGO profile to understand preferences
      final ngoProfile = await _userService.getUserProfile(ngoId) as NGOProfile?;
      if (ngoProfile == null) return [];

      Query query = _firestore
          .collection('food_donations')
          .where('status', isEqualTo: DonationStatus.listed.name);

      // Filter by preferred food types if specified
      if (ngoProfile.preferredFoodTypes.isNotEmpty) {
        query = query.where('foodTypes', arrayContainsAny: ngoProfile.preferredFoodTypes);
      }

      final result = await query.orderBy('createdAt', descending: true).get();
      
      return result.docs
          .map((doc) => FoodDonation.fromFirestore(doc))
          .where((donation) => donation.isAvailable)
          .toList();
    } catch (e) {
      print('Error getting available donations for NGO: $e');
      return [];
    }
  }

  // Get donor's donations
  Future<List<FoodDonation>> getDonorDonations(String donorId) async {
    try {
      final query = await _firestore
          .collection('food_donations')
          .where('donorId', isEqualTo: donorId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FoodDonation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting donor donations: $e');
      return [];
    }
  }

  // Get available donations with optional filters
  Future<List<FoodDonation>> getAvailableDonations({
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore
          .collection('food_donations')
          .where('status', isEqualTo: DonationStatus.listed.name);

      // Apply filters if provided
      if (filters != null) {
        if (filters['foodTypes'] != null && (filters['foodTypes'] as List).isNotEmpty) {
          query = query.where('foodTypes', arrayContainsAny: filters['foodTypes']);
        }
        
        if (filters['isUrgent'] != null) {
          query = query.where('isUrgent', isEqualTo: filters['isUrgent']);
        }
      }

      final result = await query.orderBy('createdAt', descending: true).limit(50).get();
      
      return result.docs
          .map((doc) => FoodDonation.fromFirestore(doc))
          .where((donation) => donation.isAvailable)
          .toList();
    } catch (e) {
      print('Error getting available donations: $e');
      return [];
    }
  }

  // Private helper methods
  bool _isValidSafetyWindow(FoodDonation donation) {
    final now = DateTime.now();
    
    // Check if pickup window is valid
    if (donation.availableFrom.isAfter(donation.availableUntil)) {
      return false;
    }
    
    // Check if pickup ends before food expires
    if (donation.availableUntil.isAfter(donation.expiresAt)) {
      return false;
    }
    
    // Check if pickup starts in the future or now
    if (donation.availableFrom.isBefore(now.subtract(const Duration(hours: 1)))) {
      return false;
    }
    
    return true;
  }

  bool _validateHygieneSafety(
    FoodDonation donation,
    Map<String, dynamic>? hygieneChecklist,
  ) {
    if (hygieneChecklist == null) return false;
    
    // Basic hygiene validation
    final requiredFields = [
      'foodSafetyCompliant',
      'temperatureControlled',
      'properlyStored',
      'freshness',
    ];
    
    for (String field in requiredFields) {
      if (!hygieneChecklist.containsKey(field) || 
          hygieneChecklist[field] != true) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _triggerVolunteerAssignment(String donationId) async {
    // In a real implementation, this would trigger the volunteer assignment service
    // For now, we'll just log it
    await _logDonationAction('volunteer_assignment_triggered', donationId, null);
  }

  Future<void> _notifyStakeholders(String donationId, String eventType) async {
    // In a real implementation, this would send notifications
    // For now, we'll create notification records
    final donationDoc = await _firestore
        .collection('food_donations')
        .doc(donationId)
        .get();

    if (donationDoc.exists) {
      final donation = FoodDonation.fromFirestore(donationDoc);
      
      await _firestore.collection('notifications').add({
        'donationId': donationId,
        'eventType': eventType,
        'donorId': donation.donorId,
        'ngoId': donation.assignedNGOId,
        'volunteerId': donation.assignedVolunteerId,
        'createdAt': Timestamp.now(),
        'read': false,
      });
    }
  }

  Future<void> _logDonationAction(
    String action,
    String? donationId,
    String? userId, {
    Map<String, dynamic>? additionalData,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'donationId': donationId,
      'userId': userId,
      'timestamp': Timestamp.now(),
      ...?additionalData,
    });
  }
  // Real-time Streams
  Stream<FoodDonation?> getDonationStream(String donationId) {
    return _firestore
        .collection('food_donations')
        .doc(donationId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return FoodDonation.fromFirestore(doc);
        });
  }

  Stream<List<FoodDonation>> getDonationStreamByStatus(String donorId, DonationStatus status) {
     return _firestore
        .collection('food_donations')
        .where('donorId', isEqualTo: donorId)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FoodDonation.fromFirestore(doc))
              .toList();
        });
  }
}
