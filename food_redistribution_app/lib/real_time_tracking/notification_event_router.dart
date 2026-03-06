enum NotificationTarget { donor, ngo, volunteer }

class NotificationEvent {
  final String deliveryId;
  final String title;
  final String body;
  final NotificationTarget target;

  NotificationEvent({
    required this.deliveryId,
    required this.title,
    required this.body,
    required this.target,
  });
}

class NotificationEventRouter {
  void route(NotificationEvent event) {
    // This module is independent; integrate with host app's notification services by
    // listening to the router's events. For demo, we simply print.
    // In production, the app can subscribe to events via DeliveryNotificationEngine.
    // Keep this method minimal and replaceable by consumer.
    // ignore: avoid_print
    print(
      '[NotificationRouter] -> ${event.target}: ${event.title} (${event.deliveryId}) - ${event.body}',
    );
  }
}
