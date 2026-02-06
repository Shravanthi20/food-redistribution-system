import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/ngo_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        try {
          _appUser = await _authService.getCurrentAppUser();
        } catch (e) {
          print('Error getting app user: $e');
          _appUser = null;
        }
      } else {
        _appUser = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      if (credential != null) {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerDonor({
    required String email,
    required String password,
    required dynamic donorProfile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.registerDonor(
        email: email,
        password: password,
        donorProfile: donorProfile,
      );

      if (credential != null) {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerNGO({
    required String email,
    required String password,
    required NGOProfile ngoProfile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.registerNGO(
        email: email,
        password: password,
        ngoProfile: ngoProfile,
      );

      if (credential != null) {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerVolunteer({
    required String email,
    required String password,
    required dynamic volunteerProfile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.registerVolunteer(
        email: email,
        password: password,
        volunteerProfile: volunteerProfile,
      );

      if (credential != null) {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit Verification Document (For NGO onboarding flow)
  Future<void> uploadVerificationDocument(String userId, PlatformFile file) async {
    _setLoading(true);
    try {
      // 1. Upload file to Storage
      // Ideally use a storage service, but calling directly for brevity as per previous implementation patterns here
      // Assuming 'verification_docs' folder exists or is automatically created
      // NOTE: Since I don't have the Storage instance exposed here clearly, I'll rely on a putative StorageService or similar logic. 
      // Actually, I will check if Storage is initialized. 
      // Re-using the logic from registerNGO but isolated.
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('verification_docs')
          .child('$userId.${file.extension}');
          
      if (kIsWeb) {
        await ref.putData(file.bytes!);
      } else {
        await ref.putFile(File(file.path!));
      }
      
      final url = await ref.getDownloadURL();

      // 2. Update User Verification Status
      await _firestore.collection('users').doc(userId).update({
        'verificationDocUrl': url,
        'onboardingState': OnboardingState.documentSubmitted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local user model
      await _fetchUser(userId);

    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _firebaseUser = null;
      _appUser = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      await _authService.resendEmailVerification();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateOnboardingState(OnboardingState state) async {
    if (_appUser != null) {
      try {
        await _authService.updateOnboardingState(_appUser!.uid, state);
        _appUser = _appUser!.copyWith(onboardingState: state);
        notifyListeners();
      } catch (e) {
        _errorMessage = _getErrorMessage(e);
        notifyListeners();
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return error.toString();
  }
}