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
import '../config/firebase_schema.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Whitelisted admin emails - these users are automatically set as admin
  static const List<String> _adminEmails = [
    'sisirreddy11@gmail.com',
    'sisireddy112@gmail.com',
  ];
  
  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current app user data
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection(Collections.users).doc(user.uid).get();
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
        // Create AppUser document with embedded profile
        // Donors are now active immediately, no verification required
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.donor,
          status: UserStatus.active, // Set to active immediately
          onboardingState: OnboardingState.active, // Skip onboarding
          createdAt: DateTime.now(),
          profile: UserProfile(
            firstName: donorProfile.businessName,
            lastName: '',
            address: donorProfile.address,
            city: donorProfile.city,
            state: donorProfile.state,
            zipCode: donorProfile.zipCode,
            organizationType: donorProfile.donorType.name,
            businessName: donorProfile.businessName,
          ),
        );

        // Store user data in Firestore (with embedded profile)
        await _firestore
            .collection(Collections.users)
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

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
        // Generate organization ID
        final orgId = _firestore.collection(Collections.organizations).doc().id;
        
        // Create AppUser document with pending status
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.ngo,
          status: UserStatus.pending,
          onboardingState: OnboardingState.registered,
          createdAt: DateTime.now(),
          profile: UserProfile(
            firstName: ngoProfile.organizationName,
            lastName: '',
            phone: ngoProfile.contactPhone,
            address: ngoProfile.address,
            city: ngoProfile.city,
            state: ngoProfile.state,
            zipCode: ngoProfile.zipCode,
            organizationId: orgId,
          ),
        );

        // Store user data in Firestore
        await _firestore
            .collection(Collections.users)
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

        // Store NGO organization in new collection
        await _firestore
            .collection(Collections.organizations)
            .doc(orgId)
            .set({
          Fields.ownerId: credential.user!.uid,
          'name': ngoProfile.organizationName,
          'registrationNumber': ngoProfile.registrationNumber,
          'type': ngoProfile.ngoType.name,
          'description': ngoProfile.description,
          'address': ngoProfile.address,
          'city': ngoProfile.city,
          'state': ngoProfile.state,
          'zipCode': ngoProfile.zipCode,
          'phone': ngoProfile.contactPhone,
          'location': ngoProfile.location,
          'capacity': ngoProfile.capacity,
          'servingPopulation': ngoProfile.servingPopulation,
          'preferredFoodTypes': ngoProfile.preferredFoodTypes,
          Fields.isVerified: false,
          Fields.status: 'pending',
          Fields.createdAt: Timestamp.now(),
          Fields.updatedAt: Timestamp.now(),
        });

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Add to admin review queue (verification collection)
        await _firestore.collection(Collections.verifications).add({
          'type': 'ngo',
          Fields.userId: credential.user!.uid,
          'organizationId': orgId,
          Fields.status: 'pending',
          Fields.createdAt: Timestamp.now(),
        });

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
        // Create AppUser document with embedded profile
        // Volunteers are now active immediately, no verification required
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          role: UserRole.volunteer,
          status: UserStatus.active, // Set to active immediately
          onboardingState: OnboardingState.verified, // Set to verified immediately
          createdAt: DateTime.now(),
          profile: UserProfile(
            firstName: volunteerProfile.firstName,
            lastName: volunteerProfile.lastName,
            phone: volunteerProfile.phone,
            address: volunteerProfile.address,
            city: volunteerProfile.city,
            state: volunteerProfile.state,
            zipCode: volunteerProfile.zipCode,
            hasVehicle: volunteerProfile.hasVehicle,
            vehicleType: volunteerProfile.vehicleType,
            maxRadius: volunteerProfile.maxRadius,
            availabilityHours: volunteerProfile.availabilityHours,
            workingDays: volunteerProfile.workingDays,
            preferredTasks: volunteerProfile.preferredTasks,
          ),
        );

        // Store user data in Firestore (with embedded profile)
        await _firestore
            .collection(Collections.users)
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

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
        
        // Auto-set admin role for whitelisted emails
        if (_adminEmails.contains(email.toLowerCase())) {
          await _ensureAdminRole(credential.user!.uid, email);
        }
      }

      return credential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }
  
  // Ensure admin role for whitelisted users
  Future<void> _ensureAdminRole(String uid, String email) async {
    try {
      final docRef = _firestore.collection(Collections.users).doc(uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] != 'admin') {
          await docRef.update({
            'role': 'admin',
            'status': 'active',
            'onboardingState': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Auto-set admin role for $email');
        }
      } else {
        // Create admin user document
        await docRef.set({
          'email': email,
          'role': 'admin',
          'status': 'active',
          'onboardingState': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Created admin user document for $email');
      }
    } catch (e) {
      print('Error ensuring admin role: $e');
      // Don't rethrow - this is a best-effort operation
    }
  }

  // US5: Secure Account Recovery
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log recovery action (best effort)
      try {
        await _logAction('password_reset_request', null, additionalData: {
          'email': email,
          'timestamp': Timestamp.now(),
        });
      } catch (logError) {
        print('Failed to log password reset request: $logError');
        // Retrieve silently so user flow isn't interrupted
      }
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
      await _firestore.collection(Collections.users).doc(userId).update({
        'onboardingState': state.name,
        Fields.updatedAt: Timestamp.now(),
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
  @Deprecated('Use verifications collection directly')
  Future<void> _addToReviewQueue(String type, String userId) async {
    await _firestore.collection(Collections.verifications).add({
      'type': type,
      Fields.userId: userId,
      Fields.status: 'pending',
      Fields.createdAt: Timestamp.now(),
    });
  }

  Future<void> _logAction(String action, String? userId, {Map<String, dynamic>? additionalData}) async {
    final logData = {
      'action': action,
      Fields.userId: userId,
      'timestamp': Timestamp.now(),
      'ip': null, // Would need to get IP from request
      ...?additionalData,
    };

    await _firestore.collection(Collections.audit).add(logData);
  }

  // ============================================================
  // PHONE OTP AUTHENTICATION (for Volunteers)
  // ============================================================
  
  String? _verificationId;
  int? _resendToken;

  /// Initiate phone number verification
  /// Returns a Future that completes when verification code is sent
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String errorMessage) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    int? forceResendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendToken ?? _resendToken,
        
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices (Android)
          onAutoVerified(credential);
        },
        
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else {
            errorMessage = e.message ?? 'Phone verification failed';
          }
          onError(errorMessage);
        },
        
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId, resendToken);
          
          // Log OTP sent
          _logAction('otp_sent', null, additionalData: {
            'phoneNumber': phoneNumber,
          });
        },
        
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print('Error verifying phone number: $e');
      onError('Failed to send verification code');
    }
  }

  /// Verify OTP code and sign in
  Future<UserCredential?> verifyOTPAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _logAction('phone_login', userCredential.user!.uid);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error verifying OTP: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign in with phone credential (for auto-verification)
  Future<UserCredential?> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _logAction('phone_auto_login', userCredential.user!.uid);
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with phone credential: $e');
      rethrow;
    }
  }

  /// Register volunteer with phone number (after OTP verification)
  Future<UserCredential?> registerVolunteerWithPhone({
    required String phoneNumber,
    required String verificationId,
    required String otp,
    required VolunteerProfile volunteerProfile,
  }) async {
    try {
      // Verify OTP and get credentials
      final credential = await verifyOTPAndSignIn(
        verificationId: verificationId,
        otp: otp,
      );

      if (credential?.user != null) {
        final user = credential!.user!;
        
        // Create AppUser document with embedded profile
        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          role: UserRole.volunteer,
          status: UserStatus.active,
          onboardingState: OnboardingState.verified,
          createdAt: DateTime.now(),
          profile: UserProfile(
            firstName: volunteerProfile.firstName,
            lastName: volunteerProfile.lastName,
            phone: phoneNumber,
            address: volunteerProfile.address,
            city: volunteerProfile.city,
            state: volunteerProfile.state,
            zipCode: volunteerProfile.zipCode,
            hasVehicle: volunteerProfile.hasVehicle,
            vehicleType: volunteerProfile.vehicleType,
            maxRadius: volunteerProfile.maxRadius,
            availabilityHours: volunteerProfile.availabilityHours,
            workingDays: volunteerProfile.workingDays,
            preferredTasks: volunteerProfile.preferredTasks,
          ),
        );

        // Store user data in Firestore (with embedded profile)
        await _firestore
            .collection(Collections.users)
            .doc(user.uid)
            .set(appUser.toFirestore());

        // Log registration action
        await _logAction('volunteer_phone_registration', user.uid);

        return credential;
      }
    } catch (e) {
      print('Error registering volunteer with phone: $e');
      rethrow;
    }
    return null;
  }

  /// Check if user exists for phone number
  Future<bool> checkPhoneUserExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(Collections.users)
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone user: $e');
      return false;
    }
  }

  /// Get stored verification ID
  String? get storedVerificationId => _verificationId;

  /// Get stored resend token
  int? get storedResendToken => _resendToken;
}
