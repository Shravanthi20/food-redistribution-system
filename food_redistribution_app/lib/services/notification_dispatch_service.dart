import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

enum NotificationChannel {
  inApp,
  push,
  email,
  sms,
  whatsapp,
}

enum NotificationCategory {
  donationMatching,
  volunteerDispatch,
  routeOptimization,
  deliveryTracking,
  systemAlert,
  performanceUpdate,
  resourceAlert,
  scheduleUpdate,
}

class NotificationTemplate {
  final String id;
  final String name;
  final NotificationCategory category;
  final String titleTemplate;
  final String bodyTemplate;
  final Map<String, dynamic> defaultData;
  final List<NotificationChannel> channels;
  final NotificationPriority priority;
  final Duration? delay;
  final Map<String, String> translations;
  
  NotificationTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.defaultData = const {},
    this.channels = const [NotificationChannel.push],
    this.priority = NotificationPriority.normal,
    this.delay,
    this.translations = const {},
  });
  
  String renderTitle(Map<String, dynamic> data, {String language = 'en'}) {
    String template = translations['${language}_title'] ?? titleTemplate;
    return _renderTemplate(template, data);
  }
  
  String renderBody(Map<String, dynamic> data, {String language = 'en'}) {
    String template = translations['${language}_body'] ?? bodyTemplate;
    return _renderTemplate(template, data);
  }
  
  String _renderTemplate(String template, Map<String, dynamic> data) {
    String result = template;
    data.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }
}

class NotificationRule {
  final String id;
  final String name;
  final NotificationCategory category;
  final Map<String, dynamic> conditions;
  final List<String> targetUserTypes;
  final List<NotificationChannel> channels;
  final NotificationPriority priority;
  final Duration? throttleInterval;
  final int? maxPerDay;
  final bool isActive;
  
  NotificationRule({
    required this.id,
    required this.name,
    required this.category,
    required this.conditions,
    required this.targetUserTypes,
    this.channels = const [NotificationChannel.push],
    this.priority = NotificationPriority.normal,
    this.throttleInterval,
    this.maxPerDay,
    this.isActive = true,
  });
}

class ScheduledNotification {
  final String id;
  final String templateId;
  final List<String> recipientIds;
  final Map<String, dynamic> data;
  final DateTime scheduledFor;
  final bool isRecurring;
  final Duration? recurringInterval;
  final NotificationPriority priority;
  final String? groupId;
  
  ScheduledNotification({
    required this.id,
    required this.templateId,
    required this.recipientIds,
    required this.data,
    required this.scheduledFor,
    this.isRecurring = false,
    this.recurringInterval,
    this.priority = NotificationPriority.normal,
    this.groupId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'recipientIds': recipientIds,
      'data': data,
      'scheduledFor': scheduledFor,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval?.inMilliseconds,
      'priority': priority.toString(),
      'groupId': groupId,
      'status': 'pending',
      'createdAt': DateTime.now(),
    };
  }
}

class NotificationBatch {
  final String id;
  final String name;
  final List<ScheduledNotification> notifications;
  final DateTime createdAt;
  final String? description;
  
  NotificationBatch({
    required this.id,
    required this.name,
    required this.notifications,
    required this.createdAt,
    this.description,
  });
}

class NotificationDispatchService {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  
  final Map<String, NotificationTemplate> _templates = {};
  final Map<String, NotificationRule> _rules = {};
  final Map<String, DateTime> _throttleTracker = {};
  final Map<String, List<DateTime>> _dailyCounter = {};
  
  NotificationDispatchService({
    required FirestoreService firestoreService,
    required NotificationService notificationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _notificationService = notificationService,
       _auditService = auditService {
    _initializeTemplates();
    _initializeRules();
  }

  /// Initialize notification templates
  void _initializeTemplates() {
    _templates.addAll({
      'donation_matched': NotificationTemplate(
        id: 'donation_matched',
        name: 'Food Donation Matched',
        category: NotificationCategory.donationMatching,
        titleTemplate: 'New Food Donation Match',
        bodyTemplate: 'A {{foodType}} donation ({{quantity}} servings) is available at {{distance}}km',
        channels: [NotificationChannel.push, NotificationChannel.inApp],
        priority: NotificationPriority.high,
        translations: {
          'es_title': 'Nueva Donación Disponible',
          'es_body': 'Una donación de {{foodType}} ({{quantity}} porciones) está disponible a {{distance}}km',
        },
      ),
      
      'volunteer_assigned': NotificationTemplate(
        id: 'volunteer_assigned',
        name: 'Volunteer Assignment',
        category: NotificationCategory.volunteerDispatch,
        titleTemplate: 'New Delivery Assignment',
        bodyTemplate: 'You have been assigned a {{priority}} priority delivery from {{pickup}} to {{delivery}}',
        channels: [NotificationChannel.push, NotificationChannel.sms],
        priority: NotificationPriority.urgent,
      ),
      
      'route_optimized': NotificationTemplate(
        id: 'route_optimized',
        name: 'Route Optimization Complete',
        category: NotificationCategory.routeOptimization,
        titleTemplate: 'Route Optimized',
        bodyTemplate: 'Your delivery route has been optimized, saving {{timeSaved}} minutes and {{distanceSaved}}km',
        channels: [NotificationChannel.inApp],
        priority: NotificationPriority.normal,
      ),
      
      'delivery_delayed': NotificationTemplate(
        id: 'delivery_delayed',
        name: 'Delivery Delay Alert',
        category: NotificationCategory.deliveryTracking,
        titleTemplate: 'Delivery Delay Alert',
        bodyTemplate: 'Delivery {{taskId}} is running {{delayMinutes}} minutes late. New ETA: {{newEta}}',
        channels: [NotificationChannel.push, NotificationChannel.email],
        priority: NotificationPriority.urgent,
      ),
      
      'system_maintenance': NotificationTemplate(
        id: 'system_maintenance',
        name: 'System Maintenance Notice',
        category: NotificationCategory.systemAlert,
        titleTemplate: 'System Maintenance Scheduled',
        bodyTemplate: 'System will be under maintenance from {{startTime}} to {{endTime}}. Please plan accordingly.',
        channels: [NotificationChannel.push, NotificationChannel.email],
        priority: NotificationPriority.high,
        delay: Duration(hours: 24), // Send 24 hours in advance
      ),
      
      'performance_report': NotificationTemplate(
        id: 'performance_report',
        name: 'Weekly Performance Report',
        category: NotificationCategory.performanceUpdate,
        titleTemplate: 'Your Weekly Impact Report',
        bodyTemplate: 'This week you completed {{deliveries}} deliveries, saved {{foodKg}}kg of food, and helped {{beneficiaries}} people',
        channels: [NotificationChannel.email],
        priority: NotificationPriority.low,
      ),
      
      'resource_low': NotificationTemplate(
        id: 'resource_low',
        name: 'Low Resource Alert',
        category: NotificationCategory.resourceAlert,
        titleTemplate: 'Resource Alert: {{resourceType}}',
        bodyTemplate: '{{resourceType}} is running low ({{currentLevel}}% remaining). Please review and replenish.',
        channels: [NotificationChannel.push, NotificationChannel.email],
        priority: NotificationPriority.high,
      ),
      
      'schedule_reminder': NotificationTemplate(
        id: 'schedule_reminder',
        name: 'Schedule Reminder',
        category: NotificationCategory.scheduleUpdate,
        titleTemplate: 'Upcoming Schedule Reminder',
        bodyTemplate: 'You have a {{taskType}} scheduled for {{scheduledTime}}. Location: {{location}}',
        channels: [NotificationChannel.push],
        priority: NotificationPriority.normal,
        delay: Duration(minutes: 30), // Send 30 minutes before
      ),
    });
  }
  
  /// Initialize notification rules
  void _initializeRules() {
    _rules.addAll({
      'urgent_donations': NotificationRule(
        id: 'urgent_donations',
        name: 'Urgent Food Donations',
        category: NotificationCategory.donationMatching,
        conditions: {'urgency': 'urgent', 'expiryHours': {'<': 2}},
        targetUserTypes: ['ngo', 'volunteer'],
        channels: [NotificationChannel.push, NotificationChannel.sms],
        priority: NotificationPriority.urgent,
        maxPerDay: 10,
      ),
      
      'volunteer_performance': NotificationRule(
        id: 'volunteer_performance',
        name: 'Volunteer Performance Updates',
        category: NotificationCategory.performanceUpdate,
        conditions: {'role': 'volunteer', 'completedTasks': {'>': 5}},
        targetUserTypes: ['volunteer'],
        channels: [NotificationChannel.email],
        priority: NotificationPriority.low,
        throttleInterval: Duration(days: 7),
      ),
      
      'system_alerts': NotificationRule(
        id: 'system_alerts',
        name: 'Critical System Alerts',
        category: NotificationCategory.systemAlert,
        conditions: {'severity': 'critical'},
        targetUserTypes: ['admin'],
        channels: [NotificationChannel.push, NotificationChannel.email, NotificationChannel.sms],
        priority: NotificationPriority.critical,
      ),
      
      'delivery_delays': NotificationRule(
        id: 'delivery_delays',
        name: 'Delivery Delay Notifications',
        category: NotificationCategory.deliveryTracking,
        conditions: {'delayMinutes': {'>': 15}},
        targetUserTypes: ['ngo', 'donor'],
        channels: [NotificationChannel.push],
        priority: NotificationPriority.high,
        throttleInterval: Duration(minutes: 30),
      ),
    });
  }
  
  /// Dispatch notification based on event
  Future<bool> dispatchNotification({
    required String templateId,
    required List<String> recipientIds,
    required Map<String, dynamic> data,
    String? groupId,
    DateTime? scheduledFor,
    String language = 'en',
  }) async {
    try {
      final template = _templates[templateId];
      if (template == null) {
        throw ArgumentError('Template $templateId not found');
      }
      
      // Check if notification should be throttled
      if (await _shouldThrottle(templateId, recipientIds)) {
        await _auditService.logEvent(
          eventType: AuditEventType.securityAlert,
          userId: 'system',
          riskLevel: AuditRiskLevel.low,
          additionalData: {
            'action': 'notification_throttled',
            'templateId': templateId,
            'recipientCount': recipientIds.length,
          },
        );
        return false;
      }
      
      // Schedule for immediate delivery or future delivery
      final notification = ScheduledNotification(
        id: _generateNotificationId(),
        templateId: templateId,
        recipientIds: recipientIds,
        data: data,
        scheduledFor: scheduledFor ?? DateTime.now(),
        priority: template.priority,
        groupId: groupId,
      );
      
      if (scheduledFor == null || scheduledFor.isBefore(DateTime.now())) {
        // Send immediately
        return await _sendNotification(notification, template, language);
      } else {
        // Schedule for later
        return await _scheduleNotification(notification);
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'notification_dispatch_error',
          'templateId': templateId,
          'error': e.toString(),
          'recipientCount': recipientIds.length,
        },
      );
      return false;
    }
  }
  
  /// Send notification immediately
  Future<bool> _sendNotification(
    ScheduledNotification notification,
    NotificationTemplate template,
    String language,
  ) async {
    try {
      final title = template.renderTitle(notification.data, language: language);
      final body = template.renderBody(notification.data, language: language);
      
      int successCount = 0;
      
      for (final recipientId in notification.recipientIds) {
        // Check user preferences for channels
        final userPreferences = await _getUserNotificationPreferences(recipientId);
        final enabledChannels = template.channels
            .where((channel) => userPreferences[channel.toString()] != false)
            .toList();
        
        for (final channel in enabledChannels) {
          final success = await _sendOnChannel(
            recipientId,
            title,
            body,
            notification.data,
            channel,
            template.priority,
          );
          
          if (success) successCount++;
        }
        
        // Update daily counter for throttling
        _updateDailyCounter(template.id, recipientId);
      }
      
      // Store notification record
      await _storeNotificationRecord(notification, template, successCount);
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'notification_sent',
          'templateId': template.id,
          'recipientCount': notification.recipientIds.length,
          'successCount': successCount,
          'channels': template.channels.map((c) => c.name).toList(),
        },
      );
      
      return successCount > 0;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'notification_send_error',
          'notificationId': notification.id,
          'templateId': template.id,
          'error': e.toString(),
        },
      );
      return false;
    }
  }
  
  /// Send notification on specific channel
  Future<bool> _sendOnChannel(
    String recipientId,
    String title,
    String body,
    Map<String, dynamic> data,
    NotificationChannel channel,
    NotificationPriority priority,
  ) async {
    switch (channel) {
      case NotificationChannel.push:
        return await _notificationService.sendNotification(
          userId: recipientId,
          title: title,
          message: body,
          type: 'push',
          data: data,
        );
        
      case NotificationChannel.inApp:
        return await _sendInAppNotification(recipientId, title, body, data);
        
      case NotificationChannel.email:
        return await _sendEmailNotification(recipientId, title, body, data);
        
      case NotificationChannel.sms:
        return await _sendSMSNotification(recipientId, body, priority);
        
      case NotificationChannel.whatsapp:
        return await _sendWhatsAppNotification(recipientId, body, data);
        
      default:
        return false;
    }
  }
  
  /// Schedule notification for future delivery
  Future<bool> _scheduleNotification(ScheduledNotification notification) async {
    try {
      await _firestoreService.create('scheduled_notifications', 'auto_${DateTime.now().millisecondsSinceEpoch}', notification.toMap());
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'notification_scheduled',
          'notificationId': notification.id,
          'templateId': notification.templateId,
          'scheduledFor': notification.scheduledFor.toIso8601String(),
          'recipientCount': notification.recipientIds.length,
        },
      );
      
      return true;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'notification_schedule_error',
          'notificationId': notification.id,
          'error': e.toString(),
        },
      );
      return false;
    }
  }
  
  /// Process scheduled notifications (called by background service)
  Future<void> processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      final docs = await _firestoreService.query(
        'scheduled_notifications',
        where: [
          {'field': 'status', 'operator': '==', 'value': 'pending'},
          {'field': 'scheduledFor', 'operator': '<=', 'value': now},
        ],
        limit: 100, // Process in batches
      );
      
      for (final doc in docs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final notification = ScheduledNotification(
          id: data['id'],
          templateId: data['templateId'],
          recipientIds: List<String>.from(data['recipientIds']),
          data: data['data'],
          scheduledFor: (data['scheduledFor'] as Timestamp).toDate(),
          priority: NotificationPriority.values.firstWhere(
            (p) => p.toString() == data['priority'],
            orElse: () => NotificationPriority.normal,
          ),
        );
        
        final template = _templates[notification.templateId];
        if (template != null) {
          final success = await _sendNotification(notification, template, 'en');
          
          // Update notification status
          await _firestoreService.update('scheduled_notifications', doc.id, {
            'status': success ? 'sent' : 'failed',
            'processedAt': DateTime.now(),
          });
          
          // Handle recurring notifications
          if (data['isRecurring'] == true && success) {
            await _scheduleRecurringNotification(notification, data);
          }
        }
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'scheduled_notification_process_error',
          'error': e.toString(),
        },
      );
    }
  }
  
  /// Create notification batch for bulk operations
  Future<bool> createNotificationBatch({
    required String name,
    required List<ScheduledNotification> notifications,
    String? description,
  }) async {
    try {
      final batch = NotificationBatch(
        id: _generateBatchId(),
        name: name,
        notifications: notifications,
        createdAt: DateTime.now(),
        description: description,
      );
      
      // Store batch metadata
      await _firestoreService.create('notification_batches', 'batch_${DateTime.now().millisecondsSinceEpoch}', {
        'id': batch.id,
        'name': batch.name,
        'description': batch.description,
        'notificationCount': batch.notifications.length,
        'createdAt': batch.createdAt,
        'status': 'pending',
      });
      
      // Schedule individual notifications
      for (final notification in batch.notifications) {
        await _scheduleNotification(notification);
      }
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'notification_batch_created',
          'batchId': batch.id,
          'notificationCount': notifications.length,
        },
      );
      
      return true;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'notification_batch_error',
          'error': e.toString(),
        },
      );
      return false;
    }
  }
  
  /// Helper methods for different notification channels
  Future<bool> _sendInAppNotification(String recipientId, String title, String body, Map<String, dynamic> data) async {
    try {
      await _firestoreService.create('in_app_notifications', 'notif_${DateTime.now().millisecondsSinceEpoch}', {
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': DateTime.now(),
        'isRead': false,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _sendEmailNotification(String recipientId, String title, String body, Map<String, dynamic> data) async {
    // Integration with email service (SendGrid, AWS SES, etc.)
    // This is a placeholder implementation
    await _firestoreService.create('email_queue', 'email_${DateTime.now().millisecondsSinceEpoch}', {
      'recipientId': recipientId,
      'subject': title,
      'body': body,
      'data': data,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
    return true;
  }
  
  Future<bool> _sendSMSNotification(String recipientId, String message, NotificationPriority priority) async {
    // Integration with SMS service (Twilio, AWS SNS, etc.)
    // This is a placeholder implementation
    await _firestoreService.create('sms_queue', 'sms_${DateTime.now().millisecondsSinceEpoch}', {
      'recipientId': recipientId,
      'message': message,
      'priority': priority.toString(),
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
    return true;
  }
  
  Future<bool> _sendWhatsAppNotification(String recipientId, String message, Map<String, dynamic> data) async {
    // Integration with WhatsApp Business API
    // This is a placeholder implementation
    await _firestoreService.create('whatsapp_queue', 'whatsapp_${DateTime.now().millisecondsSinceEpoch}', {
      'recipientId': recipientId,
      'message': message,
      'data': data,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
    return true;
  }
  
  /// Throttling and rate limiting
  Future<bool> _shouldThrottle(String templateId, List<String> recipientIds) async {
    final rule = _rules.values
        .firstWhere((r) => r.id == templateId, orElse: () => _rules.values.first);
    
    // Check throttle interval
    if (rule.throttleInterval != null) {
      final key = '${templateId}_${recipientIds.join('_')}';
      final lastSent = _throttleTracker[key];
      if (lastSent != null && 
          DateTime.now().difference(lastSent) < rule.throttleInterval!) {
        return true;
      }
      _throttleTracker[key] = DateTime.now();
    }
    
    // Check daily limits
    if (rule.maxPerDay != null) {
      for (final recipientId in recipientIds) {
        final key = '${templateId}_$recipientId';
        final today = DateTime.now();
        final dailyCount = _dailyCounter[key]?.where((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day).length ?? 0;
        
        if (dailyCount >= rule.maxPerDay!) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  void _updateDailyCounter(String templateId, String recipientId) {
    final key = '${templateId}_$recipientId';
    _dailyCounter[key] = (_dailyCounter[key] ?? [])..add(DateTime.now());
    
    // Clean old entries (keep only last 24 hours)
    final yesterday = DateTime.now().subtract(Duration(hours: 24));
    _dailyCounter[key] = _dailyCounter[key]!
        .where((date) => date.isAfter(yesterday))
        .toList();
  }
  
  Future<Map<String, dynamic>> _getUserNotificationPreferences(String userId) async {
    final doc = await _firestoreService.get('user_preferences', userId);
    return doc?.data() as Map<String, dynamic>? ?? {
      'push': true,
      'email': true,
      'sms': false,
      'whatsapp': false,
      'inApp': true,
    };
  }
  
  Future<void> _scheduleRecurringNotification(ScheduledNotification notification, Map<String, dynamic> data) async {
    if (data['recurringInterval'] != null) {
      final interval = Duration(milliseconds: data['recurringInterval']);
      final nextSchedule = notification.scheduledFor.add(interval);
      
      final nextNotification = ScheduledNotification(
        id: _generateNotificationId(),
        templateId: notification.templateId,
        recipientIds: notification.recipientIds,
        data: notification.data,
        scheduledFor: nextSchedule,
        isRecurring: true,
        recurringInterval: interval,
        priority: notification.priority,
      );
      
      await _scheduleNotification(nextNotification);
    }
  }
  
  Future<bool> _storeNotificationRecord(
    ScheduledNotification notification,
    NotificationTemplate template,
    int successCount,
  ) async {
    try {
      await _firestoreService.create('notification_records', 'record_${DateTime.now().millisecondsSinceEpoch}', {
        'notificationId': notification.id,
        'templateId': template.id,
        'templateName': template.name,
        'category': template.category.name,
        'recipientCount': notification.recipientIds.length,
        'successCount': successCount,
        'channels': template.channels.map((c) => c.name).toList(),
        'priority': template.priority.name,
        'sentAt': DateTime.now(),
        'data': notification.data,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  
  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Get notification analytics
  Future<Map<String, dynamic>> getNotificationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 7));
    final end = endDate ?? DateTime.now();
    
    final records = await _firestoreService.query(
      'notification_records',
      where: [
        {'field': 'sentAt', 'operator': '>=', 'value': start},
        {'field': 'sentAt', 'operator': '<=', 'value': end},
      ],
    );
    
    final analytics = {
      'totalSent': 0,
      'successRate': 0.0,
      'categoryBreakdown': <String, int>{},
      'channelBreakdown': <String, int>{},
      'priorityBreakdown': <String, int>{},
      'dailyTrends': <String, int>{},
    };
    
    for (final doc in records) {
      final data = doc.data() as Map<String, dynamic>;
      analytics['totalSent'] = (analytics['totalSent'] as int) + 1;
      
      // Category breakdown
      final category = data['category'] as String;
      analytics['categoryBreakdown'][category] = 
          (analytics['categoryBreakdown'][category] as int? ?? 0) + 1;
      
      // Daily trends
      final date = (data['sentAt'] as Timestamp).toDate();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      analytics['dailyTrends'][dateKey] = 
          (analytics['dailyTrends'][dateKey] as int? ?? 0) + 1;
    }
    
    return analytics;
  }
}
