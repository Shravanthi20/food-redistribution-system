import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
        // Donors are now active immediately, no verification required
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.donor,
          status: UserStatus.active, // Set to active immediately
          onboardingState: OnboardingState.active, // Skip onboarding
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
      print('Using Storage Bucket: ${FirebaseStorage.instance.bucket}'); 
      final ref = FirebaseStorage.instance
          .ref()
          .child('verification_certificates')
          .child('$userId.${file.extension}');

      Uint8List? dataToUpload;
      File? fileToUpload;

      // Check if image and compress
      final isImage = ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());

      print('Starting upload for ${file.name} (isImage: $isImage)');

      if (isImage) {
        try {
          print('Attempting compression...');
          // Attempt compression
          if (kIsWeb) {
             if (file.bytes != null) {
               dataToUpload = await FlutterImageCompress.compressWithList(
                 file.bytes!,
                 minHeight: 1024,
                 minWidth: 1024,
                 quality: 70,
               );
             }
          } else if (file.path != null) {
            // Native
             final result = await FlutterImageCompress.compressWithFile(
               file.path!,
               minHeight: 1024,
               minWidth: 1024,
               quality: 70,
             );
             if (result != null) {
                dataToUpload = result; // Use bytes for upload
             }
          }
           print('Compression done.');
        } catch (e) {
          print('Compression failed or not supported, falling back to original file: $e');
          // Fallback handled below (dataToUpload remains null)
        }
      }

      print('Uploading to ${ref.fullPath}...');
      if (dataToUpload != null) {
        await ref.putData(dataToUpload);
      } else if (kIsWeb) {
        await ref.putData(file.bytes!);
      } else {
        print('Uploading file from path: ${file.path}');
        await ref.putFile(File(file.path!));
      }
      print('Upload complete. Getting download URL...');

      final url = await ref.getDownloadURL();
      print('Got URL: $url');
      return url;
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
        // Volunteers are now active immediately, no verification required
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.volunteer,
          status: UserStatus.active, // Set to active immediately
          onboardingState: OnboardingState.verified, // Set to verified immediately
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
      
      // Log logout action BEFORE signing out (so we still have permissions)
      if (userId != null) {
        await _logAction('logout', userId);
      }

      await _auth.signOut();
      await _secureStorage.deleteAll();
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
