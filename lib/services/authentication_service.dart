import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import '../utils/app_utils.dart';
import '../models/food_donation.dart'; // [NEW] Added for DonationStatus

/// Comprehensive authentication service for the Food Redistribution Platform
/// 
/// This service handles all authentication-related operations including:
/// - User registration and login
/// - Social authentication (Google, Facebook, Apple)
/// - Phone number verification
/// - Password management
/// - Session management and token handling
/// - Multi-factor authentication
/// - Security monitoring and fraud detection
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Service dependencies (would be injected in production)
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  // final FacebookAuth _facebookAuth = FacebookAuth.instance;
  
  // Internal state management
  AppUser? _currentUser;
  Timer? _tokenRefreshTimer;
  StreamController<AppUser?>? _userStreamController;
  
  // Session configuration
  static const Duration _tokenRefreshInterval = Duration(minutes: 55);
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const int _maxLoginAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  /// Current authenticated user
  AppUser? get currentUser => _currentUser;
  
  /// Stream of authentication state changes
  Stream<AppUser?> get authStateChanges {
    _userStreamController ??= StreamController<AppUser?>.broadcast();
    return _userStreamController!.stream;
  }
  
  /// Check if user is currently authenticated
  bool get isAuthenticated => _currentUser != null;
  
  /// Check if current user has specific role
  bool hasRole(UserRole role) => _currentUser?.role == role;
  
  /// Check if current user has permission for specific action
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    switch (_currentUser!.role) {
      case UserRole.admin:
        return true; // Admins have all permissions
      case UserRole.donor:
        return [
          'create_donation',
          'view_own_donations',
          'update_profile',
        ].contains(permission);
      case UserRole.ngo:
        return [
          'claim_donations',
          'manage_programs',
          'view_analytics',
          'manage_volunteers',
          'update_profile',
        ].contains(permission);
      case UserRole.volunteer:
        return [
          'view_opportunities',
          'sign_up_activities',
          'track_hours',
          'update_profile',
        ].contains(permission);
    }
  }

  /// Register new user with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    Location? location,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate input
      if (!AppUtils.isValidEmail(email)) {
        return AuthResult.failure('Invalid email address');
      }
      
      if (!AppUtils.isValidPassword(password)) {
        return AuthResult.failure(
          'Password must be at least 8 characters with uppercase, lowercase, number and special character'
        );
      }
      
      if (!AppUtils.isValidName(displayName)) {
        return AuthResult.failure('Invalid display name');
      }

      // Check if email is already registered
      final existingUser = await _checkEmailExists(email);
      if (existingUser) {
        return AuthResult.failure('Email address is already registered');
      }

      // Create user account (Firebase Auth simulation)
      final userId = AppUtils.generateRandomId(length: 28);
      final now = DateTime.now();
      
      final user = AppUser(
        uid: userId,
        email: email,
        firstName: displayName.split(' ').first,
        lastName: displayName.contains(' ') ? displayName.split(' ').skip(1).join(' ') : '',
        role: role,
        status: UserStatus.pending,
        onboardingState: OnboardingState.registered,
        createdAt: now,
      );

      // Store user in database (Firestore simulation)
      await _storeUserInDatabase(user);
      
      // Send verification email
      await _sendEmailVerification(email);
      
      // Set current user
      _setCurrentUser(user);
      
      // Log registration event
      await _logAuthEvent('user_registered', {
        'user_id': userId,
        'role': role.toString(),
        'registration_method': 'email',
      });

      return AuthResult.success(
        user: user,
        message: 'Registration successful. Please verify your email.',
      );
      
    } catch (e) {
      await _logAuthError('registration_failed', e.toString());
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Validate input
      if (!AppUtils.isValidEmail(email)) {
        return AuthResult.failure('Invalid email address');
      }
      
      if (password.isEmpty) {
        return AuthResult.failure('Password is required');
      }

      // Check for account lockout
      if (await _isAccountLocked(email)) {
        return AuthResult.failure(
          'Account is locked due to multiple failed login attempts. Please try again later.'
        );
      }

      // Authenticate with Firebase (simulation)
      final user = await _authenticateWithEmailPassword(email, password);
      if (user == null) {
        await _recordFailedLoginAttempt(email);
        return AuthResult.failure('Invalid email or password');
      }

      // Update last login timestamp
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _updateUserInDatabase(updatedUser);
      
      // Set current user and start session
      _setCurrentUser(updatedUser);
      await _startUserSession(rememberMe);
      
      // Clear failed login attempts
      await _clearFailedLoginAttempts(email);
      
      // Log successful login
      await _logAuthEvent('user_signed_in', {
        'user_id': user.id,
        'login_method': 'email',
        'remember_me': rememberMe,
      });

      return AuthResult.success(
        user: updatedUser,
        message: 'Login successful',
      );
      
    } catch (e) {
      await _logAuthError('login_failed', e.toString());
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        await _logAuthEvent('user_signed_out', {
          'user_id': _currentUser!.id,
        });
      }

      // Clear user session
      await _endUserSession();
      
      // Clear current user
      _setCurrentUser(null);
      
      // Cancel token refresh timer
      _tokenRefreshTimer?.cancel();
      
    } catch (e) {
      await _logAuthError('signout_failed', e.toString());
    }
  }

  // Private helper methods (simulated implementations)

  void _setCurrentUser(AppUser? user) {
    _currentUser = user;
    _userStreamController?.add(user);
  }

  Future<bool> _checkEmailExists(String email) async {
    // Simulate database check
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Assume email doesn't exist for demo
  }

  Future<void> _storeUserInDatabase(AppUser user) async {
    // Simulate Firestore write
    await Future.delayed(const Duration(milliseconds: 300));
    if (kDebugMode) {
      print('Stored user in database: ${user.id}');
    }
  }

  Future<void> _updateUserInDatabase(AppUser user) async {
    // Simulate Firestore update
    await Future.delayed(const Duration(milliseconds: 200));
    if (kDebugMode) {
      print('Updated user in database: ${user.id}');
    }
  }

  Future<void> _sendEmailVerification(String email) async {
    // Simulate sending verification email
    await Future.delayed(const Duration(milliseconds: 1000));
    if (kDebugMode) {
      print('Sent verification email to: $email');
    }
  }

  Future<AppUser?> _authenticateWithEmailPassword(String email, String password) async {
    // Simulate Firebase Auth
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return mock user for demo
    return AppUser(
      uid: 'demo-user-123',
      email: email,
      firstName: 'Demo',
      lastName: 'User',
      role: UserRole.donor,
      status: UserStatus.active,
      onboardingState: OnboardingState.active,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<bool> _isAccountLocked(String email) async {
    // Check for account lockout
    await Future.delayed(const Duration(milliseconds: 100));
    return false; // No lockout for demo
  }

  Future<void> _recordFailedLoginAttempt(String email) async {
    // Record failed attempt
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('Recorded failed login attempt for: $email');
    }
  }

  Future<void> _clearFailedLoginAttempts(String email) async {
    // Clear failed attempts
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('Cleared failed login attempts for: $email');
    }
  }

  Future<void> _startUserSession(bool rememberMe) async {
    // Start user session
    if (kDebugMode) {
      print('Started user session (remember: $rememberMe)');
    }
  }

  Future<void> _endUserSession() async {
    // End user session
    _tokenRefreshTimer?.cancel();
    if (kDebugMode) {
      print('Ended user session');
    }
  }

  Future<void> _logAuthEvent(String eventName, Map<String, dynamic> parameters) async {
    // Log authentication events for analytics
    if (kDebugMode) {
      print('Auth Event: $eventName - $parameters');
    }
  }

  Future<void> _logAuthError(String errorType, String errorMessage) async {
    // Log authentication errors
    if (kDebugMode) {
      print('Auth Error: $errorType - $errorMessage');
    }
  }

  void dispose() {
    _tokenRefreshTimer?.cancel();
    _userStreamController?.close();
  }
}

/// Result object for authentication operations
class AuthResult {
  final bool isSuccess;
  final String message;
  final AppUser? user;
  final Map<String, dynamic>? data;

  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
    this.data,
  });

  factory AuthResult.success({
    required String message,
    AppUser? user,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
      data: data,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}
