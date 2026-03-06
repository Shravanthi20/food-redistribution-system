import 'dart:async';

import 'status_transition_validator.dart';

class DelayAlert {
  final String deliveryId;
  final String message;
  final DateTime timestamp;

  DelayAlert({required this.deliveryId, required this.message})
    : timestamp = DateTime.now();
}

class DelayDetectionService {
  final Duration pickupThreshold;
  final Duration deliveryThreshold;

  final Map<String, DateTime> _assignedAt = {};
  final Map<String, DateTime> _pickedAt = {};

  final StreamController<DelayAlert> _alerts = StreamController.broadcast();

  DelayDetectionService({
    Duration? pickupThreshold,
    Duration? deliveryThreshold,
  }) : pickupThreshold = pickupThreshold ?? const Duration(minutes: 20),
       deliveryThreshold = deliveryThreshold ?? const Duration(hours: 1);

  Stream<DelayAlert> get alerts => _alerts.stream;

  void onStatusChanged(
    String deliveryId,
    DeliveryStatus? from,
    DeliveryStatus to,
  ) {
    if (to == DeliveryStatus.assigned) {
      _assignedAt[deliveryId] = DateTime.now();
      // schedule check
      Future.delayed(pickupThreshold, () => _checkPickupDelay(deliveryId));
    }

    if (to == DeliveryStatus.pickedUp) {
      _pickedAt[deliveryId] = DateTime.now();
      // schedule delivery check
      Future.delayed(deliveryThreshold, () => _checkDeliveryDelay(deliveryId));
    }

    if (to == DeliveryStatus.delivered) {
      _assignedAt.remove(deliveryId);
      _pickedAt.remove(deliveryId);
    }
  }

  void _checkPickupDelay(String deliveryId) {
    final assigned = _assignedAt[deliveryId];
    if (assigned == null) return;
    final elapsed = DateTime.now().difference(assigned);
    if (elapsed >= pickupThreshold) {
      _alerts.add(
        DelayAlert(
          deliveryId: deliveryId,
          message: 'Pickup delayed by ${elapsed.inMinutes} minutes',
        ),
      );
    }
  }

  void _checkDeliveryDelay(String deliveryId) {
    final picked = _pickedAt[deliveryId];
    if (picked == null) return;
    final elapsed = DateTime.now().difference(picked);
    if (elapsed >= deliveryThreshold) {
      _alerts.add(
        DelayAlert(
          deliveryId: deliveryId,
          message: 'Delivery delayed by ${elapsed.inMinutes} minutes',
        ),
      );
    }
  }

  void dispose() {
    _alerts.close();
  }
}
