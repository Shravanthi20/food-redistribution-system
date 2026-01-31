import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/donor_profile.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import 'audit_service.dart';
import 'notification_service.dart';
import 'firestore_service.dart';
import '../config/firestore_schema.dart';

class UserService {
  final FirestoreService _firestoreService = FirestoreService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();

  // RBAC Middleware - Check if user has required role
  Future<bool> hasRole(String userId, UserRole requiredRole) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userRoleStr = userData['role'] as String?;
      
      if (userRoleStr == null) return false;
      
      final userRole = UserRole.values.firstWhere(
        (role) => role.name == userRoleStr,
        orElse: () => UserRole.donor,
      );
      
      // Admin can access everything
      if (userRole == UserRole.admin) return true;
      
      // Check specific role
      return userRole == requiredRole;
    } catch (e) {
      print('Error checking user role: $e');
      return false;
    }
  }

  // RBAC Middleware - Check if user has any of the required roles
  Future<bool> hasAnyRole(String userId, List<UserRole> requiredRoles) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userRoleStr = userData['role'] as String?;
      
      if (userRoleStr == null) return false;
      
      final userRole = UserRole.values.firstWhere(
        (role) => role.name == userRoleStr,
        orElse: () => UserRole.donor,
      );
      
      // Admin can access everything
      if (userRole == UserRole.admin) return true;
      
      // Check if user has any of the required roles
      return requiredRoles.contains(userRole);
    } catch (e) {
      print('Error checking user roles: $e');
      return false;
    }
  }

  // Check if user is currently suspended
  Future<bool> isUserSuspended(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final status = userData['status'] as String?;
      
      if (status != UserStatus.suspended.name) return false;
      
      // Check if suspension has expired
      final suspendedUntil = userData['suspendedUntil'] as Timestamp?;
      if (suspendedUntil != null) {
        final suspensionEnd = suspendedUntil.toDate();
        if (DateTime.now().isAfter(suspensionEnd)) {
          // Auto-reactivate expired suspension
          await _firestore.collection('users').doc(userId).update({
            'status': UserStatus.verified.name,
            'suspendedAt': FieldValue.delete(),
            'suspendedBy': FieldValue.delete(),
            'suspendedUntil': FieldValue.delete(),
            'suspensionReason': FieldValue.delete(),
            'updatedAt': Timestamp.now(),
          });
          
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Error checking user suspension: $e');
      return false;
    }
  }

  // US6: Admin - Verify NGO and Donor Certificates
  Future<void> verifyUser({
    required String userId,
    required bool approved,
    required String adminId,
    String? reason,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update user status
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'status': approved ? UserStatus.verified.name : UserStatus.pending.name,
        'onboardingState': approved 
            ? OnboardingState.verified.name 
            : OnboardingState.registered.name,
        'updatedAt': Timestamp.now(),
      });

      // Update profile verification status
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'];
        
        if (role == UserRole.donor.name) {
          final profileRef = _firestore.collection('donor_profiles').doc(userId);
          batch.update(profileRef, {
            'isVerified': approved,
            'updatedAt': Timestamp.now(),
          });
        } else if (role == UserRole.ngo.name) {
          final profileRef = _firestore.collection('ngo_profiles').doc(userId);
          batch.update(profileRef, {
            'isVerified': approved,
            'updatedAt': Timestamp.now(),
          });
        } else if (role == UserRole.volunteer.name) {
          final profileRef = _firestore.collection('volunteer_profiles').doc(userId);
          batch.update(profileRef, {
            'isVerified': approved,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      // Update review queue
      final reviewQuery = await _firestore
          .collection('review_queue')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in reviewQuery.docs) {
        batch.update(doc.reference, {
          'status': approved ? 'approved' : 'rejected',
          'reviewedBy': adminId,
          'reviewedAt': Timestamp.now(),
          'reason': reason,
        });
      }

      // Log verification action
      final logRef = _firestore.collection('audit_logs').doc();
      batch.set(logRef, {
        'action': 'user_verification',
        'adminId': adminId,
        'userId': userId,
        'approved': approved,
        'reason': reason,
        'timestamp': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      print('Error verifying user: $e');
      rethrow;
    }
  }

  // US9: Temporary Role Restriction
  Future<void> restrictUser({
    required String userId,
    required String adminId,
    required Map<String, dynamic> restrictions,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': UserStatus.restricted.name,
        'restrictions': restrictions,
        'restrictionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': Timestamp.now(),
      });

      // Log restriction action
      await _firestore.collection('audit_logs').add({
        'action': 'user_restriction',
        'adminId': adminId,
        'userId': userId,
        'restrictions': restrictions,
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'timestamp': Timestamp.now(),
      });

      // Schedule automatic restoration (in real implementation, use Cloud Functions)
      await _scheduleRestrictionEnd(userId, endDate);
    } catch (e) {
      print('Error restricting user: $e');
      rethrow;
    }
  }

  // Remove restriction
  Future<void> removeRestriction({
    required String userId,
    required String adminId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': UserStatus.active.name,
        'restrictions': FieldValue.delete(),
        'restrictionEndDate': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });

      // Log restriction removal
      await _firestore.collection('audit_logs').add({
        'action': 'restriction_removed',
        'adminId': adminId,
        'userId': userId,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error removing restriction: $e');
      rethrow;
    }
  }

  // US7: Role-Based Access Control
  Future<bool> hasPermission({
    required String userId,
    required String permission,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = UserRole.values.firstWhere(
        (e) => e.name == userData['role'],
        orElse: () => UserRole.donor,
      );
      final status = UserStatus.values.firstWhere(
        (e) => e.name == userData['status'],
        orElse: () => UserStatus.pending,
      );

      // Check if user is restricted
      if (status == UserStatus.restricted) {
        final restrictions = userData['restrictions'] as Map<String, dynamic>?;
        final restrictionEndDate = userData['restrictionEndDate'] as Timestamp?;
        
        if (restrictions != null && restrictionEndDate != null) {
          if (DateTime.now().isBefore(restrictionEndDate.toDate())) {
            return !restrictions.containsKey(permission);
          }
        }
      }

      // Check role-based permissions
      return _getRolePermissions(role).contains(permission);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  // Get user profile based on role
  Future<dynamic> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'];

      switch (role) {
        case 'donor':
          final profileDoc = await _firestore
              .collection('donor_profiles')
              .doc(userId)
              .get();
          return profileDoc.exists ? DonorProfile.fromFirestore(profileDoc) : null;
        
        case 'ngo':
          final profileDoc = await _firestore
              .collection('ngo_profiles')
              .doc(userId)
              .get();
          return profileDoc.exists ? NGOProfile.fromFirestore(profileDoc) : null;
        
        case 'volunteer':
          final profileDoc = await _firestore
              .collection('volunteer_profiles')
              .doc(userId)
              .get();
          return profileDoc.exists ? VolunteerProfile.fromFirestore(profileDoc) : null;
        
        default:
          return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'];

      String collection;
      switch (role) {
        case 'donor':
          collection = 'donor_profiles';
          break;
        case 'ngo':
          collection = 'ngo_profiles';
          break;
        case 'volunteer':
          collection = 'volunteer_profiles';
          break;
        default:
          throw Exception('Invalid user role');
      }

      await _firestore.collection(collection).doc(userId).update({
        ...profileData,
        'updatedAt': Timestamp.now(),
      });

      // Update onboarding state if profile is complete
      if (_isProfileComplete(profileData, role)) {
        await _firestore.collection('users').doc(userId).update({
          'onboardingState': OnboardingState.profileComplete.name,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Get pending users for admin review
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final query = await _firestore
          .collection('review_queue')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt')
          .get();

      List<Map<String, dynamic>> pendingUsers = [];
      
      for (var doc in query.docs) {
        final data = doc.data();
        final userId = data['userId'];
        
        // Get user details
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final profile = await getUserProfile(userId);
          
          pendingUsers.add({
            'reviewId': doc.id,
            'user': userData,
            'profile': profile,
            'submittedAt': data['createdAt'],
          });
        }
      }

      return pendingUsers;
    } catch (e) {
      print('Error getting pending users: $e');
      return [];
    }
  }

  // Private helper methods
  List<String> _getRolePermissions(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return [
          'create_donation',
          'edit_own_donation',
          'view_own_donations',
          'view_own_profile',
          'update_own_profile',
        ];
      case UserRole.ngo:
        return [
          'view_donations',
          'request_donations',
          'manage_food_requests',
          'view_own_profile',
          'update_own_profile',
        ];
      case UserRole.volunteer:
        return [
          'view_assignments',
          'accept_assignments',
          'update_delivery_status',
          'view_own_profile',
          'update_own_profile',
        ];
      case UserRole.admin:
        return [
          'verify_users',
          'manage_users',
          'view_all_data',
          'system_administration',
          'access_audit_logs',
        ];
      default:
        return [];
    }
  }

  bool _isProfileComplete(Map<String, dynamic> profileData, String role) {
    // Basic validation - in real implementation, would be more comprehensive
    switch (role) {
      case 'donor':
        return profileData.containsKey('businessName') &&
               profileData.containsKey('address') &&
               profileData.containsKey('foodTypes');
      case 'ngo':
        return profileData.containsKey('organizationName') &&
               profileData.containsKey('registrationNumber') &&
               profileData.containsKey('address');
      case 'volunteer':
        return profileData.containsKey('firstName') &&
               profileData.containsKey('lastName') &&
               profileData.containsKey('phone');
      default:
        return false;
    }
  }

  Future<void> _scheduleRestrictionEnd(String userId, DateTime endDate) async {
    // In a real implementation, this would use Cloud Functions or a job scheduler
    // For now, we'll just add a document that can be processed by a background job
    await _firestore.collection('scheduled_tasks').add({
      'type': 'remove_restriction',
      'userId': userId,
      'executeAt': Timestamp.fromDate(endDate),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }
}