import 'package:flutter/material.dart';
import '../models/food_request.dart';
import '../models/food_donation.dart';
import '../models/ngo_profile.dart';
import '../models/query.dart' as query_model;
import '../services/food_request_service.dart';
import '../services/food_donation_service.dart';
import '../services/query_service.dart';
import '../services/matching_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

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

  // Load all NGO data
  Future<void> loadNGOData(String ngoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadMyRequests(ngoId),
        _loadAvailableDonations(),
        _loadDashboardStats(ngoId),
        _loadMyQueries(ngoId),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load NGO data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load NGO's food requests
  Future<void> _loadMyRequests(String ngoId) async {
    try {
      _myRequests = await _requestService.getNGORequests(ngoId);
    } catch (e) {
      throw Exception('Failed to load food requests: $e');
    }
  }

  // Load available donations (for manual matching)
  Future<void> _loadAvailableDonations() async {
    try {
      _availableDonations = await _donationService.getAvailableDonations();
    } catch (e) {
      throw Exception('Failed to load available donations: $e');
    }
  }

  // Load dashboard statistics
  Future<void> _loadDashboardStats(String ngoId) async {
    try {
      _dashboardStats = {
        'totalRequests': _myRequests.length,
        'pendingRequests': pendingRequests.length,
        'matchedRequests': matchedRequests.length,
        'fulfilledRequests': fulfilledRequests.length,
        'criticalRequests': criticalRequests.length,
        'totalBeneficiaries': _myRequests.fold<int>(0, (sum, r) => sum + r.expectedBeneficiaries),
      };
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  // Load NGO's queries
  Future<void> _loadMyQueries(String ngoId) async {
    try {
      _myQueries = await _queryService.getUserQueries(ngoId);
    } catch (e) {
      throw Exception('Failed to load queries: $e');
    }
  }

  // Create new food request
  Future<String?> createFoodRequest({
    required String ngoId,
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

      final request = FoodRequest(
        id: '',
        ngoId: ngoId,
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
      );

      final requestId = await _requestService.createFoodRequest(
        ngoId: ngoId,
        request: request,
      );

      // Reload requests
      await _loadMyRequests(ngoId);
      await _loadDashboardStats(ngoId);
      
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
      await _loadMyRequests(ngoId);
      await _loadDashboardStats(ngoId);
      
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
      await _loadMyRequests(ngoId);
      await _loadDashboardStats(ngoId);
      
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
      await _loadMyRequests(ngoId);
      await _loadDashboardStats(ngoId);
      
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
      await _loadMyQueries(ngoId);
      
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
    return _myRequests.where((r) => 
      r.status == RequestStatus.pending &&
      r.neededBy.difference(now).inHours <= 24
    ).toList();
  }

  // Add update to query
  Future<void> addQueryUpdate(String queryId, String message) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get the current query to access its raiser user ID
      final query = _myQueries.firstWhere((q) => q.id == queryId);
      
      await _queryService.addQueryUpdate(
        queryId, 
        query.raiserUserId, // updatedBy
        'message', // updateType
        message, // content
      );
      
      // Reload queries to get the updated data
      await _loadMyQueries(query.raiserUserId);
    } catch (e) {
      _errorMessage = 'Failed to add query update: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}