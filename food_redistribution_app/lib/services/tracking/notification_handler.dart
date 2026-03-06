import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Send push notifications to volunteers and NGOs
class NotificationHandler {
  late final FirebaseMessaging _firebaseMessaging;

  NotificationHandler({FirebaseMessaging? firebaseMessaging}) {
    _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;
  }

  // Set up push notifications when app starts
  Future<void> initializeNotifications() async {
    try {
      // Request permissions (iOS)
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Show notification while user has app open
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');

    // Show notification in-app
    final notification = message.notification;
    if (notification != null) {
      _showInAppNotification(
        title: notification.title,
        body: notification.body,
        data: message.data,
      );
    }
  }

  // Handle notification when app is closed
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    // Background message handling
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    // Navigate to appropriate screen based on data
    final data = message.data;
    final notificationType = data['type'] ?? 'general';

    switch (notificationType) {
      case 'assignment':
        debugPrint('Navigate to assignment details');
        // Navigator.pushNamed(context, '/assignment', arguments: data);
        break;
      case 'pickup':
        debugPrint('Navigate to pickup screen');
        // Navigator.pushNamed(context, '/pickup', arguments: data);
        break;
      case 'delivery':
        debugPrint('Navigate to delivery screen');
        // Navigator.pushNamed(context, '/delivery', arguments: data);
        break;
      case 'delay':
        debugPrint('Navigate to delay notification');
        // Navigator.pushNamed(context, '/delay', arguments: data);
        break;
    }
  }

  /// Show in-app notification
  void _showInAppNotification({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) {
    // This will be called from UI context, so implement using local notifications
    debugPrint('Show in-app notification: $title - $body');
  }

  /// Send assignment notification to volunteer
  Future<bool> sendAssignmentNotification({
    required String volunteerId,
    required String taskId,
    required String donationTitle,
    required String pickupLocation,
  }) async {
    try {
      // This would typically be sent from your backend
      // For now, we'll prepare the payload structure
      final payload = {
        'type': 'assignment',
        'volunteerId': volunteerId,
        'taskId': taskId,
        'donationTitle': donationTitle,
        'pickupLocation': pickupLocation,
        'title': 'New Assignment',
        'body': 'You have been assigned to pick up: $donationTitle',
      };

      debugPrint('Assignment notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending assignment notification: $e');
      return false;
    }
  }

  /// Send pickup start notification to donor and NGO
  Future<bool> sendPickupStartNotification({
    required String volunteerId,
    required String volunteerName,
    required String donationId,
    required String recipientIds, // comma-separated user IDs
  }) async {
    try {
      final payload = {
        'type': 'pickup',
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'donationId': donationId,
        'title': 'Pickup Started',
        'body': '$volunteerName is on the way to pick up your donation',
      };

      debugPrint('Pickup start notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending pickup notification: $e');
      return false;
    }
  }

  /// Send delivery arrival notification to recipient NGO
  Future<bool> sendDeliveryArrivalNotification({
    required String volunteerId,
    required String volunteerName,
    required String donationId,
    required String ngoId,
    required String estimatedArrivalMinutes,
  }) async {
    try {
      final payload = {
        'type': 'delivery',
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'donationId': donationId,
        'ngoId': ngoId,
        'estimatedArrival': estimatedArrivalMinutes,
        'title': 'Delivery Arriving Soon',
        'body':
            'Volunteer $volunteerName will arrive in approximately $estimatedArrivalMinutes minutes',
      };

      debugPrint('Delivery arrival notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending delivery notification: $e');
      return false;
    }
  }

  /// Send delay alert notification
  Future<bool> sendDelayAlertNotification({
    required String taskId,
    required String volunteerId,
    required int delayMinutes,
    required String severity,
  }) async {
    try {
      final payload = {
        'type': 'delay',
        'taskId': taskId,
        'volunteerId': volunteerId,
        'delayMinutes': delayMinutes,
        'severity': severity,
        'title': 'Delivery Delayed',
        'body':
            'Delivery delayed by $delayMinutes minutes (Severity: $severity)',
      };

      debugPrint('Delay alert notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending delay alert: $e');
      return false;
    }
  }

  /// Send reassignment notification
  Future<bool> sendReassignmentNotification({
    required String taskId,
    required String newVolunteerId,
    required String newVolunteerName,
    required String reason,
    required List<String> recipientIds,
  }) async {
    try {
      final payload = {
        'type': 'reassignment',
        'taskId': taskId,
        'newVolunteerId': newVolunteerId,
        'newVolunteerName': newVolunteerName,
        'reason': reason,
        'title': 'Volunteer Reassigned',
        'body': 'Delivery reassigned to $newVolunteerName. Reason: $reason',
      };

      debugPrint('Reassignment notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending reassignment notification: $e');
      return false;
    }
  }

  /// Send completion notification
  Future<bool> sendCompletionNotification({
    required String donationId,
    required String volunteerId,
    required String ngoName,
    required List<String> recipientIds,
  }) async {
    try {
      final payload = {
        'type': 'completion',
        'donationId': donationId,
        'volunteerId': volunteerId,
        'ngoName': ngoName,
        'title': 'Delivery Completed',
        'body': 'Your donation has been successfully delivered to $ngoName',
      };

      debugPrint('Completion notification payload: $payload');
      return true;
    } catch (e) {
      debugPrint('Error sending completion notification: $e');
      return false;
    }
  }

  /// Subscribe to topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Get FCM token for user
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
