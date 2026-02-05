import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'firestore_service.dart';
import '../config/firestore_schema.dart';

enum AuditEventType {
  userLogin,
  userLogout,
  userRegistration,
  passwordChange,
  roleChange,
  accountLocked,
  accountUnlocked,
  verificationSubmitted,
  verificationApproved,
  verificationRejected,
  userSuspended,
  userReactivated,
  dataAccess,
  dataModification,
  dataExport,
  adminAction,
  securityAlert
}

enum AuditRiskLevel {
  low,
  medium,
  high,
  critical
}

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  // Log audit event
  Future<void> logEvent({
    required AuditEventType eventType,
    required String userId,
    AuditRiskLevel riskLevel = AuditRiskLevel.low,
    String? targetUserId,
    String? resourceId,
    String? resourceType,
    Map<String, dynamic>? additionalData,
    String? ipAddress,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final currentUser = _auth.currentUser;
      
      final auditLog = {
        'eventType': eventType.name,
        'riskLevel': riskLevel.name,
        'userId': userId,
        'currentUserId': currentUser?.uid,
        'targetUserId': targetUserId,
        'resourceId': resourceId,
        'resourceType': resourceType,
        'timestamp': Timestamp.now(),
        'ipAddress': ipAddress,
        'userAgent': deviceInfo['userAgent'],
        'deviceInfo': deviceInfo,
        'additionalData': additionalData ?? {},
      };
      
      await _firestore.collection('audit_logs').add(auditLog);
      
      // If high or critical risk, create alert
      if (riskLevel == AuditRiskLevel.high || riskLevel == AuditRiskLevel.critical) {
        await _createSecurityAlert(auditLog);
      }
    } catch (e) {
      print('Error logging audit event: $e');
      // Don't throw - audit logging should not break app functionality
    }
  }

  // Log user authentication events
  Future<void> logAuthEvent({
    required String eventType,
    required String userId,
    String? email,
    bool success = true,
    String? failureReason,
    String? ipAddress,
  }) async {
    final riskLevel = success ? AuditRiskLevel.low : AuditRiskLevel.medium;
    
    await logEvent(
      eventType: eventType == 'login' ? AuditEventType.userLogin : AuditEventType.userLogout,
      userId: userId,
      riskLevel: riskLevel,
      additionalData: {
        'email': email,
        'success': success,
        'failureReason': failureReason,
      },
      ipAddress: ipAddress,
    );
  }

  // Log role changes
  Future<void> logRoleChange({
    required String adminUserId,
    required String targetUserId,
    required String oldRole,
    required String newRole,
    String? reason,
  }) async {
    await logEvent(
      eventType: AuditEventType.roleChange,
      userId: adminUserId,
      riskLevel: AuditRiskLevel.high,
      targetUserId: targetUserId,
      additionalData: {
        'oldRole': oldRole,
        'newRole': newRole,
        'reason': reason,
      },
    );
  }

  // Log verification events
  Future<void> logVerificationEvent({
    required String eventType,
    required String userId,
    String? adminUserId,
    String? submissionId,
    String? decision,
    Map<String, dynamic>? additionalData,
  }) async {
    AuditEventType auditEventType;
    switch (eventType) {
      case 'submitted':
        auditEventType = AuditEventType.verificationSubmitted;
        break;
      case 'approved':
        auditEventType = AuditEventType.verificationApproved;
        break;
      case 'rejected':
        auditEventType = AuditEventType.verificationRejected;
        break;
      default:
        auditEventType = AuditEventType.adminAction;
    }
    
    await logEvent(
      eventType: auditEventType,
      userId: adminUserId ?? userId,
      riskLevel: AuditRiskLevel.medium,
      targetUserId: userId != adminUserId ? userId : null,
      resourceId: submissionId,
      resourceType: 'verification_submission',
      additionalData: {
        'decision': decision,
        ...?additionalData,
      },
    );
  }

  // Log data access events
  Future<void> logDataAccess({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String action,
    Map<String, dynamic>? sensitiveFields,
  }) async {
    await logEvent(
      eventType: AuditEventType.dataAccess,
      userId: userId,
      riskLevel: sensitiveFields?.isNotEmpty == true ? AuditRiskLevel.medium : AuditRiskLevel.low,
      resourceId: resourceId,
      resourceType: resourceType,
      additionalData: {
        'action': action,
        'sensitiveFields': sensitiveFields?.keys.toList(),
      },
    );
  }

  // Log admin actions
  Future<void> logAdminAction({
    required String adminUserId,
    required String action,
    String? targetUserId,
    String? resourceId,
    String? resourceType,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent(
      eventType: AuditEventType.adminAction,
      userId: adminUserId,
      riskLevel: AuditRiskLevel.high,
      targetUserId: targetUserId,
      resourceId: resourceId,
      resourceType: resourceType,
      additionalData: {
        'action': action,
        ...?additionalData,
      },
    );
  }

  // Get audit logs with filters
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    AuditEventType? eventType,
    AuditRiskLevel? minRiskLevel,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('audit_logs');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.name);
      }
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final querySnapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> logs = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      // Filter by risk level if specified (Firestore doesn't support enum ordering)
      if (minRiskLevel != null) {
        final riskLevels = AuditRiskLevel.values;
        final minIndex = riskLevels.indexOf(minRiskLevel);
        
        logs = logs.where((log) {
          final logRiskLevel = AuditRiskLevel.values
              .firstWhere((level) => level.name == log['riskLevel'], orElse: () => AuditRiskLevel.low);
          return riskLevels.indexOf(logRiskLevel) >= minIndex;
        }).toList();
      }
      
      return logs;
    } catch (e) {
      print('Error getting audit logs: $e');
      return [];
    }
  }

  // Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final query = await _firestore
          .collection('audit_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      
      final logs = query.docs.map((doc) => doc.data()).toList();
      
      // Calculate statistics
      final eventTypeCounts = <String, int>{};
      final riskLevelCounts = <String, int>{};
      final dailyCounts = <String, int>{};
      
      for (final log in logs) {
        final eventType = log['eventType'] as String;
        final riskLevel = log['riskLevel'] as String;
        final timestamp = (log['timestamp'] as Timestamp).toDate();
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        
        eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;
        riskLevelCounts[riskLevel] = (riskLevelCounts[riskLevel] ?? 0) + 1;
        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }
      
      return {
        'totalEvents': logs.length,
        'eventTypeCounts': eventTypeCounts,
        'riskLevelCounts': riskLevelCounts,
        'dailyCounts': dailyCounts,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting audit statistics: $e');
      return {};
    }
  }

  // Create security alert for high-risk events
  Future<void> _createSecurityAlert(Map<String, dynamic> auditLog) async {
    try {
      await _firestore.collection('security_alerts').add({
        'auditLogId': auditLog['id'],
        'eventType': auditLog['eventType'],
        'riskLevel': auditLog['riskLevel'],
        'userId': auditLog['userId'],
        'timestamp': auditLog['timestamp'],
        'status': 'open',
        'reviewedBy': null,
        'reviewedAt': null,
        'notes': null,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error creating security alert: $e');
    }
  }

  // Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'brand': androidInfo.brand,
          'userAgent': 'Android/${androidInfo.version.release} ${androidInfo.brand}/${androidInfo.model}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
          'userAgent': 'iOS/${iosInfo.systemVersion} ${iosInfo.model}',
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'version': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          'userAgent': 'Windows/${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'userAgent': Platform.operatingSystem,
        };
      }
    } catch (e) {
      return {
        'platform': 'Unknown',
        'userAgent': 'Unknown',
      };
    }
  }

  // Clean up old audit logs (data retention)
  Future<void> cleanupOldLogs({int retentionDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      final oldLogsQuery = await _firestore
          .collection('audit_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // Process in batches
          .get();
      
      if (oldLogsQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldLogsQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        print('Cleaned up ${oldLogsQuery.docs.length} old audit logs');
      }
    } catch (e) {
      print('Error cleaning up old audit logs: $e');
    }
  }
}