import 'dart:async';

import 'notification_event_router.dart';
import 'status_transition_validator.dart';

class DeliveryNotificationEngine {
  final StreamController<NotificationEvent> _events = StreamController.broadcast();
  final NotificationEventRouter _router;

  DeliveryNotificationEngine({NotificationEventRouter? router}) : _router = router ?? NotificationEventRouter() {
    _events.stream.listen((e) => _router.route(e));
  }

  void _emit(String deliveryId, String title, String body, NotificationTarget target) {
    final ev = NotificationEvent(deliveryId: deliveryId, title: title, body: body, target: target);
    _events.add(ev);
  }

  /// Called by lifecycle engine on every status change
  void handleStatusChange(String deliveryId, DeliveryStatus? from, DeliveryStatus to) {
    // Notify Donor
    if (to == DeliveryStatus.Accepted) {
      _emit(deliveryId, 'Donation accepted', 'Your donation has been accepted', NotificationTarget.Donor);
    }

    if (to == DeliveryStatus.Assigned) {
      _emit(deliveryId, 'Volunteer assigned', 'A volunteer has been assigned', NotificationTarget.Donor);
      _emit(deliveryId, 'Assignment created', 'You have been assigned a pickup', NotificationTarget.Volunteer);
      _emit(deliveryId, 'Volunteer assigned', 'Volunteer assigned to pickup', NotificationTarget.NGO);
    }

    if (to == DeliveryStatus.PickedUp) {
      _emit(deliveryId, 'Pickup started', 'Pickup has started', NotificationTarget.Donor);
      _emit(deliveryId, 'Pickup started', 'Volunteer has started pickup', NotificationTarget.NGO);
      _emit(deliveryId, 'Pickup started', 'Pickup has started', NotificationTarget.Volunteer);
    }

    if (to == DeliveryStatus.Delivered) {
      _emit(deliveryId, 'Delivery completed', 'Delivery has been completed', NotificationTarget.Donor);
      _emit(deliveryId, 'Delivery completed', 'Delivery completed', NotificationTarget.NGO);
      _emit(deliveryId, 'Delivery completed', 'Assignment completed', NotificationTarget.Volunteer);
    }
  }

  Stream<NotificationEvent> get events => _events.stream;

  void dispose() {
    _events.close();
  }
}
