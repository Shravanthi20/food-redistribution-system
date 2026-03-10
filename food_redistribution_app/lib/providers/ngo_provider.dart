import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/food_request.dart';
import '../models/food_donation.dart';
import '../models/query.dart' as query_model;
import '../services/food_request_service.dart';
import '../services/food_donation_service.dart';
import '../services/query_service.dart';
import '../services/matching_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';
import '../config/firebase_schema.dart';

class NGOProvider extends ChangeNotifier {
  final FoodRequestService _requestService = FoodRequestService();
  final FoodDonationService _donationService = FoodDonationService();
  final QueryService _queryService = QueryService();
  final EnhancedMatchingService _matchingService = EnhancedMatchingService(
    firestoreService: FirestoreService(),
    locationService: LocationService(),
    notificationService: NotificationService(),
    auditService: AuditService(),
  );

  bool _isLoading = false;
  String? _errorMessage;

  // Food requests data
  List<FoodRequest> _myRequests = [];
  List<FoodDonation> _availableDonations = [];
  List<RequestDonationMatchingResult> _potentialMatches = [];

  // Dashboard statistics
  Map<String, dynamic> _dashboardStats = {};

  // Queries/disputes
  List<query_model.Query> _myQueries = [];
  final List<StreamSubscription<QuerySnapshot>> _requestSubscriptions = [];
  final List<StreamSubscription<QuerySnapshot>> _querySubscriptions = [];
  StreamSubscription<QuerySnapshot>? _donationsSubscription;
  String? _currentUserId;
  String? _currentOrganizationId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FoodRequest> get myRequests => _myRequests;
  List<FoodDonation> get availableDonations => _availableDonations;
  List<RequestDonationMatchingResult> get potentialMatches => _potentialMatches;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<query_model.Query> get myQueries => _myQueries;

  // Filtered getters
  List<FoodRequest> get pendingRequests =>
      _myRequests.where((r) => r.status == RequestStatus.pending).toList();

  List<FoodRequest> get matchedRequests =>
      _myRequests.where((r) => r.status == RequestStatus.matched).toList();

  List<FoodRequest> get fulfilledRequests =>
      _myRequests.where((r) => r.status == RequestStatus.fulfilled).toList();

  List<FoodRequest> get criticalRequests =>
      _myRequests.where((r) => r.urgency == RequestUrgency.critical).toList();

  Future<List<String>> _resolveNgoIdentifiers(String uid) async {
    final identifiers = <String>{uid};
    final authService = AuthService();
    final appUser = await authService.getCurrentAppUser();

    if (appUser == null) {
      throw Exception('User profile not found.');
    }

    final organizationId = appUser.profile.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      identifiers.add(organizationId);
    }

    return identifiers.toList();
  }

  // Load all NGO data
  Future<void> loadNGOData(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ngoIds = await _resolveNgoIdentifiers(uid);
      await _matchingService.maybeRunInitialBackfill(ngoIds);

      _currentUserId = uid;
      final organizationId = ngoIds.firstWhere(
        (id) => id != uid,
        orElse: () => '',
      );
      _currentOrganizationId = organizationId.isEmpty ? null : organizationId;

      // Load requests and donations first (in parallel)
      await Future.wait([
        _loadMyRequests(ngoIds),
        _loadAvailableDonations(
          userId: uid,
          organizationId: organizationId.isEmpty ? null : organizationId,
        ),
        _loadMyQueries(ngoIds),
      ]);

      // Then calculate dashboard stats (depends on _myRequests being loaded)
      await _loadDashboardStats();
      _startRealtimeListeners(ngoIds);
    } catch (e) {
      _errorMessage = 'Failed to load NGO data: $e';
      debugPrint('NGO Provider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeListeners(List<String> ngoIds) {
    for (final subscription in _requestSubscriptions) {
      subscription.cancel();
    }
    _requestSubscriptions.clear();

    for (final subscription in _querySubscriptions) {
      subscription.cancel();
    }
    _querySubscriptions.clear();

    _donationsSubscription?.cancel();

    for (final ngoId in ngoIds) {
      _requestSubscriptions.add(
        FirebaseFirestore.instance
            .collection(Collections.requests)
            .where('ngoId', isEqualTo: ngoId)
            .snapshots()
            .listen((_) async {
          await _loadMyRequests(ngoIds);
          await _loadDashboardStats();
          notifyListeners();
        }),
      );

      _querySubscriptions.add(
        FirebaseFirestore.instance
            .collection(Collections.adminTasks)
            .where('raiserUserId', isEqualTo: ngoId)
            .snapshots()
            .listen((_) async {
          await _loadMyQueries(ngoIds);
          notifyListeners();
        }),
      );
    }

    _donationsSubscription = FirebaseFirestore.instance
        .collection(Collections.donations)
        .where('status', whereIn: [
          DonationStatus.listed.name,
          DonationStatus.matched.name,
        ])
        .snapshots()
        .listen((_) async {
          if (_currentUserId == null) return;
          await _loadAvailableDonations(
            userId: _currentUserId!,
            organizationId: _currentOrganizationId,
          );
          notifyListeners();
        });
  }

  // Load NGO's food requests
  Future<void> _loadMyRequests(List<String> ngoIds) async {
    try {
      _myRequests = await _requestService.getNGORequestsForIds(ngoIds);
    } catch (e) {
      throw Exception('Failed to load food requests: $e');
    }
  }

  // Load available donations (for manual matching) and matched donations
  Future<void> _loadAvailableDonations({
    required String userId,
    String? organizationId,
  }) async {
    try {
      final available = await _donationService.getAvailableDonations();
      final matched = await _donationService.getAvailableDonationsForNGO(
        userId: userId,
        organizationId: organizationId,
      );

      // Combine them so that the UI can find matched donations using getDonationById
      _availableDonations = [...available, ...matched];
    } catch (e) {
      throw Exception('Failed to load available and matched donations: $e');
    }
  }

  // Load dashboard statistics
  Future<void> _loadDashboardStats() async {
    try {
      _dashboardStats = {
        'totalRequests': _myRequests.length,
        'pendingRequests': pendingRequests.length,
        'matchedRequests': matchedRequests.length,
        'fulfilledRequests': fulfilledRequests.length,
        'criticalRequests': criticalRequests.length,
        'totalBeneficiaries': _myRequests.fold<int>(
            0, (total, r) => total + r.expectedBeneficiaries),
      };
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  // Load NGO's queries
  Future<void> _loadMyQueries(List<String> ngoIds) async {
    try {
      _myQueries = await _queryService.getUserQueriesForIds(ngoIds);
    } catch (e) {
      throw Exception('Failed to load queries: $e');
    }
  }

  // Create new food request
  Future<String?> createFoodRequest({
    required String uid,
    required String title,
    required String description,
    required List<FoodCategory> requiredFoodTypes,
    required int requiredQuantity,
    required String unit,
    required RequestUrgency urgency,
    required DateTime neededBy,
    required Map<String, dynamic> deliveryLocation,
    required List<String> servingPopulation,
    required int expectedBeneficiaries,
    required bool requiresRefrigeration,
    required List<String> dietaryRestrictions,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final ngoIds = await _resolveNgoIdentifiers(uid);
      final organizationId =
          ngoIds.firstWhere((id) => id != uid, orElse: () => '');

      final request = FoodRequest(
        id: '',
        ngoId: uid,
        title: title,
        description: description,
        requiredFoodTypes: requiredFoodTypes,
        requiredQuantity: requiredQuantity,
        unit: unit,
        urgency: urgency,
        neededBy: neededBy,
        deliveryLocation: deliveryLocation,
        status: RequestStatus.pending,
        servingPopulation: servingPopulation,
        expectedBeneficiaries: expectedBeneficiaries,
        requiresRefrigeration: requiresRefrigeration,
        dietaryRestrictions: dietaryRestrictions,
        createdAt: DateTime.now(),
        metadata: {
          if (organizationId.isNotEmpty) 'organizationId': organizationId,
        },
      );

      final requestId = await _requestService.createFoodRequest(
        ngoId: uid,
        organizationId: organizationId.isEmpty ? null : organizationId,
        request: request,
      );

      // Reload requests
      await _loadMyRequests(ngoIds);
      await _loadDashboardStats();

      return requestId;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update food request
  Future<bool> updateFoodRequest(
    String requestId,
    Map<String, dynamic> updates,
    String ngoId,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _requestService.updateFoodRequest(requestId, updates);

      // Reload requests
      await _loadMyRequests([ngoId]);
      await _loadDashboardStats();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel food request
  Future<bool> cancelFoodRequest(
    String requestId,
    String ngoId,
    String reason,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _requestService.cancelFoodRequest(requestId, ngoId, reason);

      // Reload requests
      await _loadMyRequests([ngoId]);
      await _loadDashboardStats();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Find potential matches for a request
  Future<void> findPotentialMatches(String requestId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _potentialMatches = await _matchingService.findDonationsForRequest(
        requestId: requestId,
        maxMatches: 10,
      );
    } catch (e) {
      _errorMessage = 'Failed to find potential matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept a donation match
  Future<bool> acceptDonationMatch(
    String requestId,
    String donationId,
    String ngoId,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _requestService.matchRequestWithDonation(requestId, donationId);

      // Reload requests
      await _loadMyRequests([ngoId]);
      await _loadDashboardStats();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a query/dispute
  Future<String?> createQuery({
    required String ngoId,
    required query_model.QueryType type,
    required String subject,
    required String description,
    query_model.QueryPriority priority = query_model.QueryPriority.medium,
    String? donationId,
    String? requestId,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final queryId = await _queryService.createQuery(
        raiserUserId: ngoId,
        raiserUserType: 'ngo',
        type: type,
        subject: subject,
        description: description,
        priority: priority,
        donationId: donationId,
        requestId: requestId,
        attachmentUrls: attachmentUrls,
      );

      // Reload queries
      await _loadMyQueries([ngoId]);

      return queryId;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get request by ID
  FoodRequest? getRequestById(String requestId) {
    try {
      return _myRequests.firstWhere((r) => r.id == requestId);
    } catch (e) {
      return null;
    }
  }

  // Get donation by ID
  FoodDonation? getDonationById(String donationId) {
    try {
      return _availableDonations.firstWhere((d) => d.id == donationId);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refreshData(String ngoId) async {
    await loadNGOData(ngoId);
  }

  Future<bool> rerunAutomaticMatching(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final ngoIds = await _resolveNgoIdentifiers(uid);
      await _matchingService.backfillMatchesForNGO(ngoIds);
      await loadNGOData(uid);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to rerun automatic matching: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get requests by status
  List<FoodRequest> getRequestsByStatus(RequestStatus status) {
    return _myRequests.where((r) => r.status == status).toList();
  }

  // Get urgent requests (needed within 24 hours)
  List<FoodRequest> get urgentRequests {
    final now = DateTime.now();
    return _myRequests
        .where((r) =>
            r.status == RequestStatus.pending &&
            r.neededBy.difference(now).inHours <= 24)
        .toList();
  }

  // Add update to query
  Future<void> addQueryUpdate(String queryId, String message) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get the current query to access its raiser user ID
      final queryIndex = _myQueries.indexWhere((q) => q.id == queryId);
      if (queryIndex == -1) {
        _errorMessage = 'Query not found in local data.';
        return;
      }
      final query = _myQueries[queryIndex];

      await _queryService.addQueryUpdate(
        queryId,
        query.raiserUserId, // updatedBy
        'message', // updateType
        message, // content
      );

      // Reload queries to get the updated data
      await _loadMyQueries([query.raiserUserId]);
    } catch (e) {
      _errorMessage = 'Failed to add query update: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final subscription in _requestSubscriptions) {
      subscription.cancel();
    }
    for (final subscription in _querySubscriptions) {
      subscription.cancel();
    }
    _donationsSubscription?.cancel();
    super.dispose();
  }
}
