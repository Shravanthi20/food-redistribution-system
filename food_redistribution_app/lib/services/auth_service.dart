import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/donor_profile.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';

class AuthService {
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

  // US1: Secure Donor Registration
  Future<UserCredential?> registerDonor({
    required String email,
    required String password,
    required DonorProfile donorProfile,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create AppUser document
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.donor,
          status: UserStatus.pending,
          onboardingState: OnboardingState.registered,
          createdAt: DateTime.now(),
        );

        // Store user data in Firestore
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

        // Store donor profile
        await _firestore
            .collection('donor_profiles')
            .doc(credential.user!.uid)
            .set(donorProfile.toFirestore());

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Log registration action
        await _logAction('donor_registration', credential.user!.uid);

        return credential;
      }
    } catch (e) {
      print('Error registering donor: $e');
      rethrow;
    }
    return null;
  }

  // US2: NGO Organization Registration
  Future<UserCredential?> registerNGO({
    required String email,
    required String password,
    required NGOProfile ngoProfile,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create AppUser document with pending status
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.ngo,
          status: UserStatus.pending,
          onboardingState: OnboardingState.registered,
          createdAt: DateTime.now(),
        );

        // Store user data in Firestore
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

        // Store NGO profile
        await _firestore
            .collection('ngo_profiles')
            .doc(credential.user!.uid)
            .set(ngoProfile.toFirestore());

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Add to admin review queue
        await _addToReviewQueue('ngo', credential.user!.uid);

        // Log registration action
        await _logAction('ngo_registration', credential.user!.uid);

        return credential;
      }
    } catch (e) {
      print('Error registering NGO: $e');
      rethrow;
    }
    return null;
  }

  // Upload Verification Certificate
  Future<String?> uploadVerificationCertificate(String userId, PlatformFile file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('verification_certificates')
          .child('$userId.${file.extension}');

      if (kIsWeb) {
        await ref.putData(file.bytes!);
      } else {
        await ref.putFile(File(file.path!));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading certificate: $e');
      return null; // Don't block registration if upload fails, but prefer to handle it
    }
  }

  // US3: Volunteer Account Creation
  Future<UserCredential?> registerVolunteer({
    required String email,
    required String password,
    required VolunteerProfile volunteerProfile,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create AppUser document
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.volunteer,
          status: UserStatus.pending,
          onboardingState: OnboardingState.registered,
          createdAt: DateTime.now(),
        );

        // Store user data in Firestore
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

        // Store volunteer profile
        await _firestore
            .collection('volunteer_profiles')
            .doc(credential.user!.uid)
            .set(volunteerProfile.toFirestore());

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Log registration action
        await _logAction('volunteer_registration', credential.user!.uid);

        return credential;
      }
    } catch (e) {
      print('Error registering volunteer: $e');
      rethrow;
    }
    return null;
  }

  // US4: Secure Authentication
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log login action
      if (credential.user != null) {
        await _logAction('login', credential.user!.uid);
      }

      return credential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
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