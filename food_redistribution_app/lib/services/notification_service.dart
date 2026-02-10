import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/firebase_schema.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission for iOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(Collections.notifications).add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Alias methods for compatibility with DispatchService
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotification(userId: userId, title: title, message: body, type: 'dispatch_update', data: data);
  }

  Future<void> sendToDonor({
    required String donationId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Note: In a real app, we'd look up the donorId from the donationId
    // For now, we'll assume the donorId is passed as donationId OR we'd need to fetch it
    await sendNotification(userId: donationId, title: title, message: body, type: 'donation_update', data: data);
  }

  // Send notification to multiple stakeholders (Donor, NGO, potentially Admin)
  Future<void> sendToStakeholders({
    required String taskId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Fetch task to get donor and NGO IDs
      final taskDoc = await _firestore.collection(Collections.deliveries).doc(taskId).get();
      if (!taskDoc.exists) return;

      final taskData = taskDoc.data()!;
      final donorId = taskData['donorId'] as String?;
      final ngoId = taskData['ngoId'] as String?;
      final volunteerId = taskData['volunteerId'] as String?;

      if (donorId != null) {
        await sendToUser(userId: donorId, title: title, body: body, data: data);
      }
      if (ngoId != null) {
        await sendToUser(userId: ngoId, title: title, body: body, data: data);
      }
      // Usually doesn't notify the volunteer about their own actions but could be useful
      if (volunteerId != null && (data?['notifyVolunteer'] == true)) {
        await sendToUser(userId: volunteerId, title: title, body: body, data: data);
      }
    } catch (e) {
      print('Error sending notifications to stakeholders: $e');
    }
  }

  // Send push notification
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Implementation would use Firebase Cloud Functions
    // This is a placeholder for the client-side structure
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection(Collections.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Save FCM Token to User Profile
  Future<void> saveTokenToUser(String userId) async {
    try {
      String?token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }
      
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await _firestore
        .collection(Collections.users)
        .doc(userId)
        .collection(Subcollections.tokens)
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'flutter',
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(Collections.notifications)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
