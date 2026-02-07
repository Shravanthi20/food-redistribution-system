import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/donor_profile.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import '../utils/result_utils.dart';
import 'base_service.dart';
import 'notification_service.dart';

class UserService extends BaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Simple local cache for permissions to avoid excessive Firestore reads
  static final Map<String, _PermissionCacheEntry> _permissionCache = {};
  static const _cacheDuration = Duration(minutes: 5);

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

  // US7: Role-Based Access Control (Cached & Effective)
  Future<bool> hasPermission({
    required String userId,
    required String permission,
  }) async {
    // 1. Check Cache
    final cached = _permissionCache[userId];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) {
      return _evaluatePermissions(cached.role, cached.status, cached.restrictions, permission);
    }

    // 2. Fetch from Firestore if not cached or expired
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
      final restrictions = userData['restrictions'] as Map<String, dynamic>?;

      // Update Cache
      _permissionCache[userId] = _PermissionCacheEntry(
        role: role,
        status: status,
        restrictions: restrictions,
        expiry: DateTime.now().add(_cacheDuration),
      );

      return _evaluatePermissions(role, status, restrictions, permission);
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  bool _evaluatePermissions(UserRole role, UserStatus status, Map<String, dynamic>? restrictions, String permission) {
    // Admin bypass
    if (role == UserRole.admin) return true;

    // Check if user is restricted
    if (status == UserStatus.restricted && restrictions != null) {
      if (restrictions.containsKey(permission)) return false;
    }

    // Check base role permissions
    return _getRolePermissions(role).contains(permission);
  }

  // NGO/Donor Verification (Effective Transactional Logic)
  Future<Result<void>> verifyUser({
    required String userId,
    required bool approved,
    required String adminId,
    String? reason,
  }) async {
    return safeExecute(() async {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) throw Exception('User not found');
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'];

        // 1. Update User Document
        transaction.update(userRef, {
          'status': approved ? UserStatus.verified.name : UserStatus.pending.name,
          'onboardingState': approved ? OnboardingState.verified.name : OnboardingState.registered.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Update Profile Document
        final profileCollection = _getProfileCollectionForRole(role);
        if (profileCollection != null) {
          final profileRef = _firestore.collection(profileCollection).doc(userId);
          transaction.update(profileRef, {
            'isVerified': approved,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Update Review Queue
        final reviewQuery = await _firestore
            .collection('review_queue')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

        for (var doc in reviewQuery.docs) {
          transaction.update(doc.reference, {
            'status': approved ? 'approved' : 'rejected',
            'reviewedBy': adminId,
            'reviewedAt': FieldValue.serverTimestamp(),
            'reason': reason,
          });
        }
        
        // Clear permission cache for this user since status changed
        _permissionCache.remove(userId);
      });
    }, auditAction: 'user_verification', auditUserId: adminId, auditData: {'targetUserId': userId, 'approved': approved});
  }

  String? _getProfileCollectionForRole(String? role) {
    if (role == UserRole.donor.name) return 'donor_profiles';
    if (role == UserRole.ngo.name) return 'ngo_profiles';
    if (role == UserRole.volunteer.name) return 'volunteer_profiles';
    return null;
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

  // Get user statistics for admin dashboard
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // We can use multiple queries to get the counts
      // Note: In a production app with many users, we should use aggregation queries or maintain counters.
      final allUsers = await _firestore.collection('users').get();
      final docs = allUsers.docs;

      int donors = 0;
      int ngos = 0;
      int volunteers = 0;
      int verified = 0;
      int suspended = 0;
      int newUsers = 0;

      for (var doc in docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final status = data['status'] as String?;
        final createdAt = data['createdAt'];

        if (role == 'donor') donors++;
        else if (role == 'ngo') ngos++;
        else if (role == 'volunteer') volunteers++;

        if (status == UserStatus.verified.name) verified++;
        if (status == UserStatus.suspended.name) suspended++;

        if (createdAt != null) {
           DateTime createdDate;
           if (createdAt is Timestamp) {
             createdDate = createdAt.toDate();
           } else if (createdAt is String) {
             createdDate = DateTime.parse(createdAt);
           } else {
             createdDate = DateTime.now(); // Fallback
           }
           
           if (createdDate.isAfter(startOfMonth)) {
             newUsers++;
           }
        }
      }

      return {
        'totalUsers': docs.length,
        'donors': donors,
        'ngos': ngos,
        'volunteers': volunteers,
        'verified': verified,
        'suspended': suspended,
        'newUsersThisMonth': newUsers,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'totalUsers': 0,
        'donors': 0,
        'ngos': 0,
        'volunteers': 0,
        'verified': 0,
        'suspended': 0,
        'newUsersThisMonth': 0,
      };
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

/// Internal helper for permission caching
class _PermissionCacheEntry {
  final UserRole role;
  final UserStatus status;
  final Map<String, dynamic>? restrictions;
  final DateTime expiry;

  _PermissionCacheEntry({
    required this.role,
    required this.status,
    this.restrictions,
    required this.expiry,
  });
}