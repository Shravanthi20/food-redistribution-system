import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tracking/location_tracking_model.dart';
import 'notification_handler.dart';

// Check if deliveries are taking too long
class DelayDetectionService {
  final NotificationHandler _notificationHandler;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SLA configurations (in minutes)
  static const int defaultPickupSLA = 60;
  static const int defaultDeliverySLA = 120;

  final Map<String, Timer> _activeMonitors = {};
  final Map<String, DelayAlert> _activeAlerts = {};

  DelayDetectionService({
    required NotificationHandler notificationHandler,
  }) : _notificationHandler = notificationHandler;

  // Start monitoring for delays on a task
  Future<void> startMonitoring({
    required String taskId,
    required String volunteerId,
    required int pickupSLA,
    required int deliverySLA,
  }) async {
    try {
      // Get task document
      final taskDoc = await _firestore
          .collection('delivery_tasks')
          .doc(taskId)
          .get();

      if (!taskDoc.exists) return;

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final status = taskData['status'] as String?;
      final assignedAt = (taskData['assignedAt'] as Timestamp?)?.toDate();

      if (assignedAt == null) return;

      // Check for pickup delay
      final pickupDeadline = assignedAt.add(Duration(minutes: pickupSLA));
      if (DateTime.now().isAfter(pickupDeadline) &&
          status != 'pickedUp' &&
          status != 'delivered') {
        _handlePickupDelay(
          taskId: taskId,
          volunteerId: volunteerId,
          deadline: pickupDeadline,
        );
      }

      // Set up periodic check
      _activeMonitors[taskId]?.cancel();
      _activeMonitors[taskId] = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _checkForDelays(
          taskId: taskId,
          volunteerId: volunteerId,
          pickupSLA: pickupSLA,
          deliverySLA: deliverySLA,
        ),
      );
    } catch (e) {
      debugPrint('Error starting delay monitoring: $e');
    }
  }

  // Check periodically if task is delayed
  Future<void> _checkForDelays({
    required String taskId,
    required String volunteerId,
    required int pickupSLA,
    required int deliverySLA,
  }) async {
    try {
      final taskDoc =
          await _firestore.collection('delivery_tasks').doc(taskId).get();

      if (!taskDoc.exists) return;

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final status = taskData['status'] as String?;
      final assignedAt = (taskData['assignedAt'] as Timestamp?)?.toDate();
      final pickedUpAt = (taskData['pickedUpAt'] as Timestamp?)?.toDate();

      if (assignedAt == null) return;

      // Check pickup delay
      if (status == 'matched' || status == 'assigned') {
        final pickupDeadline = assignedAt.add(Duration(minutes: pickupSLA));
        if (DateTime.now().isAfter(pickupDeadline)) {
          _handlePickupDelay(
            taskId: taskId,
            volunteerId: volunteerId,
            deadline: pickupDeadline,
          );
        }
      }

      // Check delivery delay
      if ((status == 'pickedUp' || status == 'inTransit') && pickedUpAt != null) {
        final deliveryDeadline =
            pickedUpAt.add(Duration(minutes: deliverySLA));
        if (DateTime.now().isAfter(deliveryDeadline)) {
          _handleDeliveryDelay(
            taskId: taskId,
            volunteerId: volunteerId,
            deadline: deliveryDeadline,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking delays: $e');
    }
  }

  // Handle pickup delay
  Future<void> _handlePickupDelay({
    required String taskId,
    required String volunteerId,
    required DateTime deadline,
  }) async {
    try {
      final now = DateTime.now();
      final delayMinutes = now.difference(deadline).inMinutes;
      final severity = _calculateSeverity(delayMinutes);

      final alert = DelayAlert(
        id: '${taskId}_pickup_${now.millisecondsSinceEpoch}',
        taskId: taskId,
        volunteerId: volunteerId,
        type: 'pickup_delay',
        severity: severity,
        reason: 'Pickup not started within SLA',
        detectedAt: now,
        estimatedDelay: Duration(minutes: delayMinutes),
      );

      _activeAlerts[alert.id] = alert;

      // Save to Firestore
      await _firestore
          .collection('delay_alerts')
          .doc(alert.id)
          .set(alert.toMap());

      // Send notification
      await _notificationHandler.sendDelayAlertNotification(
        taskId: taskId,
        volunteerId: volunteerId,
        delayMinutes: delayMinutes,
        severity: severity,
      );
    } catch (e) {
      debugPrint('Error handling pickup delay: $e');
    }
  }

  // Handle delivery delay
  Future<void> _handleDeliveryDelay({
    required String taskId,
    required String volunteerId,
    required DateTime deadline,
  }) async {
    try {
      final now = DateTime.now();
      final delayMinutes = now.difference(deadline).inMinutes;
      final severity = _calculateSeverity(delayMinutes);

      final alert = DelayAlert(
        id: '${taskId}_delivery_${now.millisecondsSinceEpoch}',
        taskId: taskId,
        volunteerId: volunteerId,
        type: 'delivery_delay',
        severity: severity,
        reason: 'Delivery not completed within SLA',
        detectedAt: now,
        estimatedDelay: Duration(minutes: delayMinutes),
      );

      _activeAlerts[alert.id] = alert;

      // Save to Firestore
      await _firestore
          .collection('delay_alerts')
          .doc(alert.id)
          .set(alert.toMap());

      // Send notification
      await _notificationHandler.sendDelayAlertNotification(
        taskId: taskId,
        volunteerId: volunteerId,
        delayMinutes: delayMinutes,
        severity: severity,
      );
    } catch (e) {
      debugPrint('Error handling delivery delay: $e');
    }
  }

  // Stop monitoring a task
  void stopMonitoring(String taskId) {
    _activeMonitors[taskId]?.cancel();
    _activeMonitors.remove(taskId);
  }

  // Resolve an alert
  Future<void> resolveAlert(String alertId, String resolution) async {
    try {
      final alert = _activeAlerts[alertId];
      if (alert == null) return;

      final resolvedAlert = DelayAlert(
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

      await _firestore
          .collection('delay_alerts')
          .doc(alertId)
          .update({'resolvedAt': FieldValue.serverTimestamp(), 'resolutionAction': resolution});

      _activeAlerts[alertId] = resolvedAlert;
    } catch (e) {
      debugPrint('Error resolving alert: $e');
    }
  }

  // Get active alerts
  List<DelayAlert> getActiveAlerts() {
    return _activeAlerts.values
        .where((alert) => alert.resolvedAt == null)
        .toList();
  }

  // Calculate severity based on delay minutes
  String _calculateSeverity(int delayMinutes) {
    if (delayMinutes < 15) return 'low';
    if (delayMinutes < 30) return 'medium';
    if (delayMinutes < 60) return 'high';
    return 'critical';
  }
}
