import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/donor_profile.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import '../utils/result_utils.dart';
import 'base_service.dart';

class AuthService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current app user data
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      print('Error getting current app user: $e');
      return null;
    }
  }

  // US4: Secure Authentication (Effective & Audited)
  Future<Result<UserCredential>> signIn({
    required String email,
    required String password,
  }) async {
    return safeExecute(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    }, auditAction: 'login', auditData: {'email': email});
  }

  // Registration Helper (Internal Transactional Creation)
  Future<Result<UserCredential>> _registerUser({
    required String email,
    required String password,
    required UserRole role,
    required Map<String, dynamic> profileData,
    required String profileCollection,
  }) async {
    return safeExecute(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userId = credential.user!.uid;
        
        // Use a batch for atomic creation
        final batch = _firestore.batch();
        
        final userDocRef = _firestore.collection('users').doc(userId);
        batch.set(userDocRef, {
          'uid': userId,
          'email': email,
          'role': role.name,
          'status': UserStatus.pending.name,
          'onboardingState': OnboardingState.registered.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final profileDocRef = _firestore.collection(profileCollection).doc(userId);
        batch.set(profileDocRef, {
          ...profileData,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        await credential.user!.sendEmailVerification();
        
        return credential;
      }
      throw Exception('Failed to create user credential');
    }, auditAction: '${role.name}_registration', auditData: {'email': email});
  }

  // US1: Secure Donor Registration
  Future<Result<UserCredential>> registerDonor({
    required String email,
    required String password,
    required DonorProfile donorProfile,
  }) {
    return _registerUser(
      email: email,
      password: password,
      role: UserRole.donor,
      profileData: donorProfile.toFirestore(),
      profileCollection: 'donor_profiles',
    );
  }

  // US2: NGO Organization Registration
  Future<Result<UserCredential>> registerNGO({
    required String email,
    required String password,
    required NGOProfile ngoProfile,
  }) {
    return _registerUser(
      email: email,
      password: password,
      role: UserRole.ngo,
      profileData: ngoProfile.toFirestore(),
      profileCollection: 'ngo_profiles',
    ).then((result) async {
       if (result.isSuccess) {
         await _addToReviewQueue('ngo', result.data!.user!.uid);
       }
       return result;
    });
  }

  // US3: Volunteer Account Creation
  Future<Result<UserCredential>> registerVolunteer({
    required String email,
    required String password,
    required VolunteerProfile volunteerProfile,
  }) {
    return _registerUser(
      email: email,
      password: password,
      role: UserRole.volunteer,
      profileData: volunteerProfile.toFirestore(),
      profileCollection: 'volunteer_profiles',
    );
  }

  // US5: Secure Account Recovery
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log recovery action
      await _logAction('password_reset_request', null, additionalData: {
        'email': email,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final userId = currentUser?.uid;
      await _auth.signOut();
      await _secureStorage.deleteAll();
      
      // Log logout action
      if (userId != null) {
        await _logAction('logout', userId);
      }
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Update onboarding state
  Future<void> updateOnboardingState(String userId, OnboardingState state) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'onboardingState': state.name,
        'updatedAt': Timestamp.now(),
      });
      
      await _logAction('onboarding_state_update', userId, additionalData: {
        'newState': state.name,
      });
    } catch (e) {
      print('Error updating onboarding state: $e');
      rethrow;
    }
  }

  // Check if user email is verified
  Future<bool> isEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      print('Error resending email verification: $e');
      rethrow;
    }
  }

  // Private helper methods
  Future<void> _addToReviewQueue(String type, String userId) async {
    await _firestore.collection('review_queue').add({
      'type': type,
      'userId': userId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> _logAction(String action, String? userId, {Map<String, dynamic>? additionalData}) async {
    final logData = {
      'action': action,
      'userId': userId,
      'timestamp': Timestamp.now(),
      'ip': null, // Would need to get IP from request
      ...?additionalData,
    };

    await _firestore.collection('audit_logs').add(logData);
  }
}