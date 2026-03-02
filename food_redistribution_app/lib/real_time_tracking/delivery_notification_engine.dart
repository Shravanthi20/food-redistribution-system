import 'dart:async';

import 'notification_event_router.dart';
import 'status_transition_validator.dart';

class DeliveryNotificationEngine {
  final StreamController<NotificationEvent> _events =
      StreamController.broadcast();
  final NotificationEventRouter _router;

  DeliveryNotificationEngine({NotificationEventRouter? router})
      : _router = router ?? NotificationEventRouter() {
    _events.stream.listen((e) => _router.route(e));
  }

  void _emit(
      String deliveryId, String title, String body, NotificationTarget target) {
    final ev = NotificationEvent(
        deliveryId: deliveryId, title: title, body: body, target: target);
    _events.add(ev);
  }

  /// Called by lifecycle engine on every status change
  void handleStatusChange(
      String deliveryId, DeliveryStatus? from, DeliveryStatus to) {
    // Notify Donor
    if (to == DeliveryStatus.accepted) {
      _emit(deliveryId, 'Donation accepted', 'Your donation has been accepted',
          NotificationTarget.donor);
    }

    if (to == DeliveryStatus.assigned) {
      _emit(deliveryId, 'Volunteer assigned', 'A volunteer has been assigned',
          NotificationTarget.donor);
      _emit(deliveryId, 'Assignment created', 'You have been assigned a pickup',
          NotificationTarget.volunteer);
      _emit(deliveryId, 'Volunteer assigned', 'Volunteer assigned to pickup',
          NotificationTarget.ngo);
    }

    if (to == DeliveryStatus.pickedUp) {
      _emit(deliveryId, 'Pickup started', 'Pickup has started',
          NotificationTarget.donor);
      _emit(deliveryId, 'Pickup started', 'Volunteer has started pickup',
          NotificationTarget.ngo);
      _emit(deliveryId, 'Pickup started', 'Pickup has started',
          NotificationTarget.volunteer);
    }

    if (to == DeliveryStatus.delivered) {
      _emit(deliveryId, 'Delivery completed', 'Delivery has been completed',
          NotificationTarget.donor);
      _emit(deliveryId, 'Delivery completed', 'Delivery completed',
          NotificationTarget.ngo);
      _emit(deliveryId, 'Delivery completed', 'Assignment completed',
          NotificationTarget.volunteer);
    }
  }

  Stream<NotificationEvent> get events => _events.stream;

  void dispose() {
    _events.close();
  }
}
