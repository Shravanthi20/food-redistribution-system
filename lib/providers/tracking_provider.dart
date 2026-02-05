import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracking/location_tracking_model.dart';
import '../services/tracking/offline_tracking_service.dart';
import '../services/tracking/notification_handler.dart';
import '../services/tracking/delay_detection_service.dart';
import '../services/tracking/analytics_aggregation_service.dart';

// Keep track of all deliveries happening right now
class TrackingProvider extends ChangeNotifier {
  late final DelayDetectionService _delayDetectionService;
  final AnalyticsAggregationService _analyticsService = AnalyticsAggregationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrackingProvider() {
    _delayDetectionService = DelayDetectionService(
      notificationHandler: NotificationHandler(),
    );
  }

  // Tracking state
  late TrackingState _trackingState = TrackingState(
    isTracking: false,
    isOnline: true,
    currentStatus: 'idle',
    pendingUpdates: 0,
  );

  // Location history
  final List<LocationUpdate> _locationHistory = [];

  // Delay alerts
  final List<DelayAlert> _delayAlerts = [];

  // Getters
  TrackingState get trackingState => _trackingState;
  List<LocationUpdate> get locationHistory => _locationHistory;
  List<DelayAlert> get delayAlerts => _delayAlerts;

  bool get isTracking => _trackingState.isTracking;
  bool get isOnline => _trackingState.isOnline;
  LocationUpdate? get currentLocation => _trackingState.currentLocation;
  String? get currentStatus => _trackingState.currentStatus;
  int get pendingUpdates => _trackingState.pendingUpdates;
  DateTime? get lastSync => _trackingState.lastSync;
  int get activeTasksCount => _delayAlerts.length;

  // Begin recording volunteer's location for a delivery
  Future<bool> startTracking({
    required String volunteerId,
    required String taskId,
    int updateIntervalSeconds = 30,
  }) async {
    try {
      _trackingState = _trackingState.copyWith(
        isTracking: true,
        currentTaskId: taskId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Stop recording volunteer's location
  Future<void> stopTracking(String volunteerId) async {
    try {
      _trackingState = _trackingState.copyWith(
        isTracking: false,
        currentTaskId: null,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
    }
  }

  // Update what stage the donation is at
  Future<bool> updateDonationStatus({
    required String donationId,
    required String newStatus,
    required String userId,
    Map<String, dynamic>? locationData,
    String? notes,
  }) async {
    try {
      await _firestore
          .collection('donations')
          .doc(donationId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': userId,
            if (notes != null) 'notes': notes,
          });

      _trackingState = _trackingState.copyWith(
        currentStatus: newStatus,
        lastSync: DateTime.now(),
      );
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating donation status: $e');
      return false;
    }
  }

  // Record where volunteer is right now
  Future<bool> updateVolunteerLocation({
    required String volunteerId,
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final newLocation = LocationUpdate(
        id: '${volunteerId}_${DateTime.now().millisecondsSinceEpoch}',
        volunteerId: volunteerId,
        taskId: taskId,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        status: _trackingState.currentStatus ?? 'enRoute',
      );

      // Save to Firestore
      await _firestore
          .collection('location_updates')
          .doc(newLocation.id)
          .set(newLocation.toMap());

      _locationHistory.add(newLocation);

      _trackingState = _trackingState.copyWith(
        currentLocation: newLocation,
        lastSync: DateTime.now(),
      );
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating volunteer location: $e');
      return false;
    }
  }

  // See all updates for a donation
  Future<List<LocationUpdate>> getDonationTrackingHistory(
      String donationId) async {
    try {
      final snapshot = await _firestore
          .collection('location_updates')
          .where('taskId', isEqualTo: donationId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => LocationUpdate.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting tracking history: $e');
      return [];
    }
  }

  // Tell app if phone has internet
  void setOnlineStatus(bool isOnline) {
    _trackingState = _trackingState.copyWith(isOnline: isOnline);
    notifyListeners();
  }

  // See how much data waiting to be sent
  void updatePendingUpdates(int count) {
    _trackingState = _trackingState.copyWith(pendingUpdates: count);
    notifyListeners();
  }

  // Mark that a delivery is running late
  void addDelayAlert(DelayAlert alert) {
    _delayAlerts.add(alert);
    notifyListeners();
  }

  // Mark delay as resolved
  void resolveDelayAlert(String alertId, {String? resolution}) {
    final index = _delayAlerts.indexWhere((alert) => alert.id == alertId);
    if (index >= 0) {
      final alert = _delayAlerts[index];
      _delayAlerts[index] = DelayAlert(
        id: alert.id,
        taskId: alert.taskId,
        volunteerId: alert.volunteerId,
        type: alert.type,
        severity: alert.severity,
        reason: alert.reason,
        detectedAt: alert.detectedAt,
        resolvedAt: DateTime.now(),
        resolutionAction: resolution,
        estimatedDelay: alert.estimatedDelay,
      );
      notifyListeners();
    }
  }

  // Delete all stored location points
  void clearLocationHistory() {
    _locationHistory.clear();
    notifyListeners();
  }
}
