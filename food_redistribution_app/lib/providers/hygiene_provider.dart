import 'package:flutter/material.dart';
import '../models/hygiene_checklist.dart';
import '../services/hygiene_service.dart';

class HygieneProvider extends ChangeNotifier {
  final HygieneService _service = HygieneService();

  HygieneChecklist? _currentChecklist;
  bool _isLoading = false;
  String? _error;

  HygieneChecklist? get currentChecklist => _currentChecklist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Checklist ────────────────────────────────────────────────

  void initChecklist(String donationId, String ngoId) {
    _currentChecklist = HygieneChecklist(
      donationId: donationId,
      ngoId: ngoId,
      items: HygieneChecklistTemplate.defaultItems,
    );
    notifyListeners();
  }

  void toggleItem(int index, bool value) {
    if (_currentChecklist == null) return;
    _currentChecklist!.items[index].isChecked = value;
    notifyListeners();
  }

  bool get allMandatoryChecked =>
      _currentChecklist?.allMandatoryChecked ?? false;

  Future<void> loadExistingChecklist(String donationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final existing = await _service.getHygieneChecklist(donationId);
      if (existing != null) {
        _currentChecklist = existing;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Accept ───────────────────────────────────────────────────

  Future<bool> acceptDonation(String donationId, String ngoId,
      {String? notes}) async {
    if (_currentChecklist == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final checklist = HygieneChecklist(
        donationId: donationId,
        ngoId: ngoId,
        items: _currentChecklist!.items,
        isComplete: true,
        completedAt: DateTime.now(),
        notes: notes,
      );
      await _service.acceptDonation(
        donationId: donationId,
        ngoId: ngoId,
        checklist: checklist,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Reject ───────────────────────────────────────────────────

  Future<bool> rejectDonation({
    required String donationId,
    required String ngoId,
    required String reason,
    String? additionalInfo,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.rejectDonation(
        donationId: donationId,
        ngoId: ngoId,
        reason: reason,
        additionalInfo: additionalInfo,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Clarification ────────────────────────────────────────────

  Future<bool> sendClarification({
    required String donationId,
    required String ngoId,
    required String donorId,
    required String question,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.sendClarificationRequest(
        donationId: donationId,
        ngoId: ngoId,
        donorId: donorId,
        question: question,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Stream<List<ClarificationRequest>> clarificationsStream(String donationId) =>
      _service.getClarifications(donationId);

  // ─── Unsafe Cancel ────────────────────────────────────────────

  Future<bool> cancelPickupUnsafe({
    required String donationId,
    required String volunteerId,
    required String reason,
    required String details,
    required String ngoId,
    required String donorId,
    String? adminId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.cancelPickupUnsafe(
        donationId: donationId,
        volunteerId: volunteerId,
        reason: reason,
        details: details,
        ngoId: ngoId,
        donorId: donorId,
        adminId: adminId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
