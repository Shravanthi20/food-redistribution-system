import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_schema.dart';
import '../services/analytics_service.dart';
import '../services/verification_service.dart';
import '../services/user_service.dart';
import '../services/issue_service.dart';
import '../services/audit_service.dart';
import '../services/security_service.dart';
import '../services/food_donation_service.dart';
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

  Map<String, dynamic> _monthlyTrends = {};
  Map<String, dynamic> get monthlyTrends => _monthlyTrends;

  Map<String, dynamic> _demandForecast = {};
  Map<String, dynamic> get demandForecast => _demandForecast;

  List<Map<String, dynamic>> _matchingSessions = [];
  List<Map<String, dynamic>> get matchingSessions => _matchingSessions;
  final List<StreamSubscription<QuerySnapshot>> _subscriptions = [];
  bool _realtimeInitialized = false;
  bool _realtimeRefreshInFlight = false;

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
        _fetchMonthlyTrends(),
        _fetchDemandForecast(),
        _fetchMatchingSessions(),
      ]);
      _startRealtimeUpdates();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeUpdates() {
    if (_realtimeInitialized) return;
    _realtimeInitialized = true;

    _subscriptions.addAll([
      FirebaseFirestore.instance
          .collection('matching_sessions')
          .limit(10)
          .snapshots()
          .listen((_) => _refreshRealtimeData()),
      FirebaseFirestore.instance
          .collection('request_matching_sessions')
          .limit(10)
          .snapshots()
          .listen((_) => _refreshRealtimeData()),
      FirebaseFirestore.instance
          .collection('donation_assignments')
          .limit(10)
          .snapshots()
          .listen((_) => _refreshRealtimeData()),
      FirebaseFirestore.instance
          .collection('donations')
          .snapshots()
          .listen((_) => _refreshRealtimeData()),
      FirebaseFirestore.instance
          .collection('requests')
          .snapshots()
          .listen((_) => _refreshRealtimeData()),
    ]);
  }

  Future<void> _refreshRealtimeData() async {
    if (_realtimeRefreshInFlight) return;
    _realtimeRefreshInFlight = true;

    try {
      await Future.wait([
        _fetchUnmatchedDonations(),
        _fetchMatchingSessions(),
        _fetchMonthlyTrends(),
        _fetchDemandForecast(),
        _fetchDeliveryPerformance(),
        _fetchRegionalStats(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Admin realtime refresh failed: $e');
    } finally {
      _realtimeRefreshInFlight = false;
    }
  }

  Future<void> _fetchSystemMetrics() async {
    _systemMetrics = await _analyticsService.getSystemAnalytics();
  }

  Future<void> _fetchVerificationStats() async {
    _verificationStats = await _verificationService.getVerificationStats();
  }

  Future<void> _fetchPendingVerifications() async {
    _pendingVerifications =
        await _verificationService.getPendingVerifications();
  }

  Future<void> _fetchOpenIssues() async {
    _openIssues = await _issueService.getFutureOpenIssues();
  }

  Future<void> _fetchAuditLogs() async {
    _auditLogs = await _auditService.getAuditLogs(limit: 20);
  }

  Future<void> _fetchSecurityStats() async {
    _securityStats = await _securityService.getSecurityStats();
  }

  Future<void> _fetchUnmatchedDonations() async {
    final foodDonationService = FoodDonationService();
    _unmatchedDonations =
        await foodDonationService.getDonationsByStatus(DonationStatus.listed);
  }

  Future<void> _fetchRegionalStats() async {
    _regionalStats = await _analyticsService.getRegionalAnalytics();
  }

  Future<void> _fetchDeliveryPerformance() async {
    _deliveryPerformance = await _analyticsService.getDeliveryPerformance();
  }

  Future<void> _fetchMonthlyTrends() async {
    _monthlyTrends = await _analyticsService.getMonthlyPlatformTrends();
  }

  Future<void> _fetchDemandForecast() async {
    _demandForecast = await _analyticsService.getDemandForecast();
  }

  Future<void> _fetchMatchingSessions() async {
    final firestore = FirebaseFirestore.instance;
    final donationSnapshot = await firestore
        .collection('matching_sessions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    final requestSnapshot = await firestore
        .collection('request_matching_sessions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    final rawSessions = [
      ...donationSnapshot.docs.map((doc) => {
            'id': doc.id,
            'collection': 'matching_sessions',
            ...doc.data(),
          }),
      ...requestSnapshot.docs.map((doc) => {
            'id': doc.id,
            'collection': 'request_matching_sessions',
            ...doc.data(),
          }),
    ];

    final donationIds = <String>{};
    final requestIds = <String>{};
    final ngoIds = <String>{};

    for (final session in rawSessions) {
      final donationId = session['donationId']?.toString();
      final requestId = session['requestId']?.toString();
      if (donationId != null && donationId.isNotEmpty) {
        donationIds.add(donationId);
      }
      if (requestId != null && requestId.isNotEmpty) {
        requestIds.add(requestId);
      }

      final matches = (session['matches'] as List? ?? []);
      for (final match in matches) {
        if (match is! Map) continue;
        final matchDonationId = match['donationId']?.toString();
        final matchRequestId = match['requestId']?.toString();
        final matchNgoId =
            match['ngoId']?.toString() ?? match['ngoUserId']?.toString();
        if (matchDonationId != null && matchDonationId.isNotEmpty) {
          donationIds.add(matchDonationId);
        }
        if (matchRequestId != null && matchRequestId.isNotEmpty) {
          requestIds.add(matchRequestId);
        }
        if (matchNgoId != null && matchNgoId.isNotEmpty) {
          ngoIds.add(matchNgoId);
        }
      }
    }

    final donationMeta = await _loadDocumentMetadata(
      collection: Collections.donations,
      ids: donationIds,
      titleFields: const ['title', 'description'],
    );
    final requestMeta = await _loadDocumentMetadata(
      collection: Collections.requests,
      ids: requestIds,
      titleFields: const ['title', 'description'],
    );
    final ngoMeta = await _loadDocumentMetadata(
      collection: Collections.users,
      ids: ngoIds,
      titleFields: const ['organizationName', 'fullName', 'firstName', 'email'],
    );

    final normalizedSessions = rawSessions
        .map((session) => _normalizeMatchingSession(
              session,
              donationMeta: donationMeta,
              requestMeta: requestMeta,
              ngoMeta: ngoMeta,
            ))
        .toList();

    normalizedSessions.sort((a, b) {
      final aTime = _asDateTime(a['timestamp']);
      final bTime = _asDateTime(b['timestamp']);
      return bTime.compareTo(aTime);
    });

    _matchingSessions = normalizedSessions.take(20).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadDocumentMetadata({
    required String collection,
    required Set<String> ids,
    required List<String> titleFields,
  }) async {
    final metadata = <String, Map<String, dynamic>>{};

    for (final id in ids) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(id)
            .get();
        if (!doc.exists) continue;

        final data = doc.data() ?? <String, dynamic>{};
        final profile = (data[Fields.profile] as Map<String, dynamic>?) ??
            <String, dynamic>{};
        String title = id;
        for (final field in titleFields) {
          final value = data[field]?.toString().trim();
          if (value != null && value.isNotEmpty) {
            title = value;
            break;
          }
        }
        if (title == id) {
          final profileTitle = (profile['organizationName'] ??
                  profile['fullName'] ??
                  profile['displayName'] ??
                  profile['firstName'])
              ?.toString()
              .trim();
          if (profileTitle != null && profileTitle.isNotEmpty) {
            title = profileTitle;
          }
        }

        metadata[id] = {
          'id': id,
          'title': title,
          'data': data,
        };
      } catch (_) {
        metadata[id] = {
          'id': id,
          'title': id,
          'data': <String, dynamic>{},
        };
      }
    }

    return metadata;
  }

  Map<String, dynamic> _normalizeMatchingSession(
    Map<String, dynamic> session, {
    required Map<String, Map<String, dynamic>> donationMeta,
    required Map<String, Map<String, dynamic>> requestMeta,
    required Map<String, Map<String, dynamic>> ngoMeta,
  }) {
    final collection = session['collection']?.toString() ?? '';
    final isRequestDriven = collection == 'request_matching_sessions';
    final donationId = session['donationId']?.toString();
    final requestId = session['requestId']?.toString();
    final sourceId = isRequestDriven ? requestId : donationId;
    final sourceType = isRequestDriven ? 'ngo_request' : 'donor_donation';
    final sourceHeading = isRequestDriven ? 'NGO Request' : 'Donor Donation';
    final sourceMeta =
        isRequestDriven ? requestMeta[sourceId] : donationMeta[sourceId];
    final counterpartId = isRequestDriven ? donationId : requestId;
    final counterpartMeta = isRequestDriven
        ? donationMeta[counterpartId]
        : requestMeta[counterpartId];
    final rawMatches = (session['matches'] as List? ?? []);

    return {
      ...session,
      'sourceType': sourceType,
      'sourceHeading': sourceHeading,
      'sourceId': sourceId,
      'sourceTitle': sourceMeta?['title']?.toString() ?? sourceId ?? 'Unknown',
      'counterpartId': counterpartId,
      'counterpartTitle':
          counterpartMeta?['title']?.toString() ?? counterpartId ?? 'Unknown',
      'matches': rawMatches
          .map((match) => _normalizeMatchEntry(
                match,
                isRequestDriven: isRequestDriven,
                donationMeta: donationMeta,
                requestMeta: requestMeta,
                ngoMeta: ngoMeta,
              ))
          .toList(),
    };
  }

  Map<String, dynamic> _normalizeMatchEntry(
    dynamic rawMatch, {
    required bool isRequestDriven,
    required Map<String, Map<String, dynamic>> donationMeta,
    required Map<String, Map<String, dynamic>> requestMeta,
    required Map<String, Map<String, dynamic>> ngoMeta,
  }) {
    final match = rawMatch is Map<String, dynamic>
        ? rawMatch
        : Map<String, dynamic>.from(rawMatch as Map? ?? {});

    final donationId = match['donationId']?.toString();
    final requestId = match['requestId']?.toString();
    final ngoId = match['ngoId']?.toString() ?? match['ngoUserId']?.toString();
    final score = (match['score'] as num?)?.toDouble();
    final reasoning = match['reasoning']?.toString();
    final rawCriteria = (match['criteriaScores'] as Map? ?? {});
    final criteriaScores = <String, double>{};

    for (final entry in rawCriteria.entries) {
      final value = entry.value;
      if (value is num) {
        criteriaScores[entry.key.toString()] = value.toDouble();
      }
    }

    return {
      ...match,
      'targetLabel': isRequestDriven ? 'Donation' : 'NGO',
      'targetId': isRequestDriven ? donationId : ngoId,
      'targetTitle': isRequestDriven
          ? (donationMeta[donationId]?['title']?.toString() ??
              donationId ??
              'Unknown')
          : (ngoMeta[ngoId]?['title']?.toString() ?? ngoId ?? 'Unknown'),
      'score': score,
      'reasoning': reasoning,
      'criteriaScores': criteriaScores,
      'matchType': isRequestDriven ? 'request_to_donation' : 'donation_to_ngo',
      'requestTitle': requestMeta[requestId]?['title']?.toString() ??
          requestId ??
          'Unknown',
      'donationTitle': donationMeta[donationId]?['title']?.toString() ??
          donationId ??
          'Unknown',
    };
  }

  DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch all users and filter client-side by name/email
      final allRoles = [
        UserRole.donor,
        UserRole.ngo,
        UserRole.volunteer,
        UserRole.admin
      ];
      List<Map<String, dynamic>> results = [];
      for (final role in allRoles) {
        final users = await _userService.getUsersByRole(role);
        results.addAll(users);
      }
      final lowerQuery = query.toLowerCase();
      _allUsers = results.where((u) {
        final name =
            (u['fullName'] ?? u['firstName'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    } catch (e) {
      _errorMessage = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Action: Review Verification
  Future<bool> reviewVerification(String submissionId, String adminId,
      VerificationStatus decision, String? notes) async {
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
  Future<bool> suspendUser(
      String userId, String adminId, String reason, DateTime endDate) async {
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
  Future<bool> forceAssignNGO(
      String donationId, String adminId, String ngoId, String reason) async {
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
  Future<bool> forceAssignVolunteer(String donationId, String adminId,
      String volunteerId, String reason) async {
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

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
