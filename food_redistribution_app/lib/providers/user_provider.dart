import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  dynamic _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  dynamic get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _userProfile = await _userService.getUserProfile(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _userService.updateUserProfile(
        userId: userId,
        profileData: profileData,
      );

      // Reload profile data
      await loadUserProfile(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasPermission({
    required String userId,
    required String permission,
  }) async {
    try {
      return await _userService.hasPermission(
        userId: userId,
        permission: permission,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
