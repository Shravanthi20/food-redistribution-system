import 'dart:async';

import 'lifecycle_log_service.dart';
import 'status_transition_validator.dart' show DeliveryStatus;

class _QueuedUpdate {
  final String deliveryId;
  final DeliveryStatus status;

  _QueuedUpdate(this.deliveryId, this.status);
}

/// OfflineSyncQueue is intentionally independent and accepts a callback to apply updates.
class OfflineSyncQueue {
  final List<_QueuedUpdate> _queue = [];
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get hasPending => _queue.isNotEmpty;

  final LifecycleLogService logService;
  final Future<void> Function(String deliveryId, DeliveryStatus status)
  _applyCallback;

  Timer? _syncTimer;

  OfflineSyncQueue({
    required Future<void> Function(String, DeliveryStatus) applyUpdate,
    required this.logService,
  }) : _applyCallback = applyUpdate {
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isOnline && _queue.isNotEmpty) sync();
    });
  }

  void setOnline(bool online) {
    _isOnline = online;
    logService.add(
      'SYSTEM',
      'NETWORK',
      online ? 'online' : 'offline',
      'Network ${online ? 'restored' : 'lost'}',
    );
    if (online) sync();
  }

  void enqueue(String deliveryId, DeliveryStatus status) {
    // Avoid duplicate same-status entries (idempotency)
    if (_queue.any((q) => q.deliveryId == deliveryId && q.status == status)) {
      return;
    }
    _queue.add(_QueuedUpdate(deliveryId, status));
    logService.add(deliveryId, 'QUEUE', status.toString(), 'Enqueued update');
  }

  Future<void> sync() async {
    if (!_isOnline) return;
    while (_queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      try {
        await _applyCallback(item.deliveryId, item.status);
        logService.add(
          item.deliveryId,
          'QUEUE',
          item.status.toString(),
          'Synced',
        );
      } catch (e) {
        logService.add(
          item.deliveryId,
          'QUEUE',
          item.status.toString(),
          'Sync failed: $e',
        );
        // Re-enqueue and break to avoid tight loop
        _queue.insert(0, item);
        break;
      }
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
