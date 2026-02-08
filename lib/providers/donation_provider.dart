import 'package:flutter/material.dart';
import '../models/food_donation.dart';
import '../services/food_donation_service.dart';
import '../services/connectivity_service.dart';
import 'dart:async';


class DonationProvider extends ChangeNotifier {
  final FoodDonationService _donationService = FoodDonationService();
  
  List<FoodDonation> _donations = [];
  List<FoodDonation> _myDonations = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  final ConnectivityService _connectivityService = ConnectivityService();

  // Getters
  List<FoodDonation> get donations => _donations;
  List<FoodDonation> get myDonations => _myDonations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FoodDonationService get foodDonationService => _donationService;
  Stream<bool> get connectionStatus => _connectivityService.connectionStatus;

  // Stream access
  Stream<FoodDonation?> getDonationStream(String donationId) => 
      _donationService.getDonationStream(donationId);

  Stream<List<FoodDonation>> getMyDonationsStream(String donorId) =>
      _donationService.getDonorDonationsStream(donorId);

  Stream<List<FoodDonation>> getAvailableDonationsStream() =>
      _donationService.getAvailableDonationsStream();

  Stream<List<FoodDonation>> getVolunteerTasksStream(String volunteerId) =>
      _donationService.getVolunteerTasksStream(volunteerId);

  List<FoodDonation> getDonationsByStatus(DonationStatus status) {
    return _myDonations.where((d) => d.status == status).toList();
  }
  
  // Get active donations count
  int get activeDonationsCount {
    return _myDonations.where((d) => 
      d.status == DonationStatus.listed || 
      d.status == DonationStatus.matched
    ).length;
  }
  
  // Create donation
  Future<String?> createDonation(FoodDonation donation) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final donationId = await _donationService.createFoodDonation(
        donorId: donation.donorId,
        donation: donation,
      );
      
      await loadMyDonations(donation.donorId);
      return donationId;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load my donations
  Future<void> loadMyDonations(String donorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _myDonations = await _donationService.getDonorDonations(donorId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update donation
  Future<bool> updateDonation(String donationId, String donorId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _donationService.updateFoodDonation(
        donationId: donationId,
        donorId: donorId,
        updates: updates,
      );
      
      await loadMyDonations(donorId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Cancel donation
  Future<bool> cancelDonation(String donationId, String donorId, String reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _donationService.cancelFoodDonation(
        donationId: donationId,
        donorId: donorId,
        reason: reason,
      );
      
      await loadMyDonations(donorId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load available donations (for NGO/Volunteer)
  Future<void> loadAvailableDonations({
    Map<String, dynamic>? filters,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _donations = await _donationService.getAvailableDonations(
        filters: filters,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get pending assignments stream
  Stream<List<Map<String, dynamic>>> getPendingAssignmentsStream(String volunteerId) =>
      _donationService.getPendingAssignments(volunteerId);

  // Accept Assignment
  Future<bool> acceptAssignment(String assignmentId, String donationId, String volunteerId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _donationService.acceptAssignment(assignmentId, donationId, volunteerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject Assignment
  Future<bool> rejectAssignment(String assignmentId, String donationId, String volunteerId, String reason) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _donationService.rejectAssignment(assignmentId, donationId, volunteerId, reason);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
