import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/verification_service.dart';
import '../services/user_service.dart';
import '../services/issue_service.dart';
import '../services/audit_service.dart';
import '../services/security_service.dart';
import '../services/food_donation_service.dart';
import '../models/user.dart';
import '../models/food_donation.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final VerificationService _verificationService = VerificationService();
  final UserService _userService = UserService();
  final IssueService _issueService = IssueService();
  final AuditService _auditService = AuditService();
  final SecurityService _securityService = SecurityService();

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

  // open issues
  List<Map<String, dynamic>> _openIssues = [];
  List<Map<String, dynamic>> get openIssues => _openIssues;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // New states for overhaul
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> get auditLogs => _auditLogs;

  Map<String, dynamic> _securityStats = {};
  Map<String, dynamic> get securityStats => _securityStats;

  List<FoodDonation> _unmatchedDonations = [];
  List<FoodDonation> get unmatchedDonations => _unmatchedDonations;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> get allUsers => _allUsers;

  Map<String, double> _regionalStats = {};
  Map<String, double> get regionalStats => _regionalStats;

  Map<String, dynamic> _deliveryPerformance = {};
  Map<String, dynamic> get deliveryPerformance => _deliveryPerformance;

  List<Map<String, dynamic>> _matchingSessions = [];
  List<Map<String, dynamic>> get matchingSessions => _matchingSessions;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchSystemMetrics(),
        _fetchVerificationStats(),
        _fetchPendingVerifications(),
        _fetchOpenIssues(),
        _fetchAuditLogs(),
        _fetchSecurityStats(),
        _fetchUnmatchedDonations(),
        _fetchRegionalStats(),
        _fetchDeliveryPerformance(),
        _fetchMatchingSessions(),
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
    _systemMetrics = await _analyticsService.getSystemAnalytics() ?? {};
  }

  Future<void> _fetchVerificationStats() async {
    _verificationStats = await _verificationService.getVerificationStats() ?? {};
  }

  Future<void> _fetchPendingVerifications() async {
    _pendingVerifications = await _verificationService.getPendingVerifications() ?? [];
  }

  Future<void> _fetchOpenIssues() async {
    _openIssues = await _issueService.getFutureOpenIssues() ?? [];
  }

  Future<void> _fetchAuditLogs() async {
    _auditLogs = await _auditService.getAuditLogs(limit: 20) ?? [];
  }

  Future<void> _fetchSecurityStats() async {
    _securityStats = await _securityService.getSecurityStats() ?? {};
  }

  Future<void> _fetchUnmatchedDonations() async {
    final foodDonationService = FoodDonationService();
    _unmatchedDonations = await foodDonationService.getDonationsByStatus(DonationStatus.listed);
  }

  Future<void> _fetchRegionalStats() async {
    _regionalStats = await _analyticsService.getRegionalAnalytics() ?? {};
  }

  Future<void> _fetchDeliveryPerformance() async {
    _deliveryPerformance = await _analyticsService.getDeliveryPerformance() ?? {};
  }

  Future<void> _fetchMatchingSessions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('matching_sessions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    
    _matchingSessions = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> searchUsers(String query) async {
    // Basic search implementation
    // In a real app, this might be a server-side search
    // For now, we fetch some users or filter existing ones if allUsers is populated
    // Let's assume we fetch by role or a general search method in UserService
    _isLoading = true;
    notifyListeners();
    try {
      // Dummy logic for now: fetching all donors as a sample for search
      _allUsers = await _userService.getUsersByRole(UserRole.donor);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Action: Force Assign NGO
  Future<bool> forceAssignNGO(String donationId, String adminId, String ngoId, String reason) async {
    try {
      final foodDonationService = FoodDonationService();
      await foodDonationService.forceAssignNGO(
        donationId: donationId,
        adminId: adminId,
        ngoId: ngoId,
        reason: reason,
      );
      await _fetchUnmatchedDonations();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'NGO assignment failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Action: Force Assign Volunteer
  Future<bool> forceAssignVolunteer(String donationId, String adminId, String volunteerId, String reason) async {
    try {
      final foodDonationService = FoodDonationService();
      await foodDonationService.forceAssignVolunteer(
        donationId: donationId,
        adminId: adminId,
        volunteerId: volunteerId,
        reason: reason,
      );
      await _fetchUnmatchedDonations();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Volunteer assignment failed: $e';
      notifyListeners();
      return false;
    }
  }
}
