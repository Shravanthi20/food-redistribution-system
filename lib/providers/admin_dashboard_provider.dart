import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../services/verification_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final VerificationService _verificationService = VerificationService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // dashboard metrics
  Map<String, dynamic> _systemMetrics = {};
  Map<String, dynamic> get systemMetrics => _systemMetrics;

  // verification stats
  Map<String, dynamic> _verificationStats = {};
  Map<String, dynamic> get verificationStats => _verificationStats;

  // pending items
  List<Map<String, dynamic>> _pendingVerifications = [];
  List<Map<String, dynamic>> get pendingVerifications => _pendingVerifications;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchSystemMetrics(),
        _fetchVerificationStats(),
        _fetchPendingVerifications(),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSystemMetrics() async {
    _systemMetrics = await _analyticsService.getSystemAnalytics();
  }

  Future<void> _fetchVerificationStats() async {
    _verificationStats = await _verificationService.getVerificationStats();
  }

  Future<void> _fetchPendingVerifications() async {
    _pendingVerifications = await _verificationService.getPendingVerifications();
  }

  // Action: Review Verification
  Future<bool> reviewVerification(String submissionId, String adminId, VerificationStatus decision, String? notes) async {
    try {
      await _verificationService.reviewSubmission(
        submissionId: submissionId,
        adminId: adminId,
        decision: decision,
        notes: notes,
      );
      
      // Refresh list
      await _fetchPendingVerifications();
      await _fetchVerificationStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Review failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Action: Suspend User
  Future<bool> suspendUser(String userId, String adminId, String reason, DateTime endDate) async {
    try {
      await _userService.restrictUser(
        userId: userId,
        adminId: adminId,
        restrictions: {'all': true}, // Full suspension
        endDate: endDate,
        reason: reason,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Suspension failed: $e';
      notifyListeners();
      return false;
    }
  }
}
