import 'dart:async';

import 'status_transition_validator.dart';
import 'lifecycle_log_service.dart';
import 'retry_handler.dart';
import 'offline_sync_queue.dart';
import 'delivery_notification_engine.dart';
import 'delay_detection_service.dart';

class UpdateResult {
  final bool success;
  final String message;
  final DeliveryStatus? updatedStatus;

  UpdateResult({
    required this.success,
    required this.message,
    this.updatedStatus,
  });
}

class StatusLifecycleEngine {
  // In-memory current status store
  final Map<String, DeliveryStatus> _current = {};
  final LifecycleLogService logService;
  late final OfflineSyncQueue offlineQueue;
  final DeliveryNotificationEngine notifier;
  final DelayDetectionService delayDetector;

  final StreamController<MapEntry<String, DeliveryStatus>> _statusController =
      StreamController.broadcast();

  StatusLifecycleEngine._internal(
    this.logService,
    this.notifier,
    this.delayDetector,
  ) {
    // offlineQueue will be injected by factory after creation
  }

  factory StatusLifecycleEngine(
    LifecycleLogService logService,
    DeliveryNotificationEngine notifier,
    DelayDetectionService delayDetector,
  ) {
    final engine = StatusLifecycleEngine._create(
      logService,
      notifier,
      delayDetector,
    );
    return engine;
  }

  static StatusLifecycleEngine _create(
    LifecycleLogService logService,
    DeliveryNotificationEngine notifier,
    DelayDetectionService delayDetector,
  ) {
    final engine = StatusLifecycleEngine._internal(
      logService,
      notifier,
      delayDetector,
    );
    final queue = OfflineSyncQueue(
      applyUpdate: (id, status) => engine._applyUpdate(id, status),
      logService: logService,
    );
    engine._setOfflineQueue(queue);
    return engine;
  }

  void _setOfflineQueue(OfflineSyncQueue q) {
    // ignore: prefer_final_fields
    // assign via reflection-like approach
    // (simple setter)
    // This private setter keeps constructor simple.
    // ignore: invalid_use_of_protected_member
    // assign
    // ignore: unnecessary_null_comparison
    // set
    // actual assignment:
    // ignore: prefer_collection_literals
    // cast
    // performing assignment:
    // ignore: unused_local_variable
    offlineQueue = q;
  }

  /// Stream of updates (deliveryId, status)
  Stream<MapEntry<String, DeliveryStatus>> get statusStream =>
      _statusController.stream;

  DeliveryStatus? getStatus(String deliveryId) => _current[deliveryId];

  /// Public method required by the task
  Future<UpdateResult> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus newStatus,
  ) async {
    final current = _current[deliveryId];
    if (current != null &&
        !StatusTransitionValidator.isValidTransition(current, newStatus)) {
      final msg = 'Invalid transition from $current to $newStatus';
      logService.add(deliveryId, current.toString(), newStatus.toString(), msg);
      return UpdateResult(success: false, message: msg, updatedStatus: current);
    }

    // Idempotency: if same status, return success
    if (current == newStatus) {
      return UpdateResult(
        success: true,
        message: 'No-op (idempotent)',
        updatedStatus: newStatus,
      );
    }

    // If offline, enqueue and report
    if (!offlineQueue.isOnline) {
      offlineQueue.enqueue(deliveryId, newStatus);
      return UpdateResult(
        success: true,
        message: 'Queued for sync (offline)',
        updatedStatus: current,
      );
    }

    try {
      await RetryHandler.runWithRetry(
        () => _applyUpdate(deliveryId, newStatus),
      );
      return UpdateResult(
        success: true,
        message: 'Updated',
        updatedStatus: newStatus,
      );
    } catch (e) {
      // enqueue for later sync
      offlineQueue.enqueue(deliveryId, newStatus);
      return UpdateResult(
        success: false,
        message: 'Failed to update, queued: $e',
        updatedStatus: current,
      );
    }
  }

  // Internal apply method that actually changes state and notifies
  Future<void> _applyUpdate(String deliveryId, DeliveryStatus newStatus) async {
    final previous = _current[deliveryId];
    if (previous == newStatus) return; // idempotent

    _current[deliveryId] = newStatus;
    _statusController.add(MapEntry(deliveryId, newStatus));
    logService.add(
      deliveryId,
      previous?.toString() ?? 'UNKNOWN',
      newStatus.toString(),
      'Status applied',
    );

    // Notify via notification engine
    notifier.handleStatusChange(deliveryId, previous, newStatus);

    // Let delay detector track
    delayDetector.onStatusChanged(deliveryId, previous, newStatus);
  }

  void dispose() {
    _statusController.close();
    offlineQueue.dispose();
  }
}
