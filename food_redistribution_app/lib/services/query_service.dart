import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/query.dart' as query_model;
import '../services/notification_service.dart';
import '../services/audit_service.dart';
import '../config/firebase_schema.dart';

class QueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final AuditService _auditService = AuditService();

  /// Create a new query/dispute
  Future<String> createQuery({
    required String raiserUserId,
    required String raiserUserType,
    required query_model.QueryType type,
    required String subject,
    required String description,
    query_model.QueryPriority priority = query_model.QueryPriority.medium,
    String? donationId,
    String? requestId,
    String? assignmentId,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      final query = query_model.Query(
        id: '',
        raiserUserId: raiserUserId,
        raiserUserType: raiserUserType,
        type: type,
        subject: subject,
        description: description,
        status: query_model.QueryStatus.open,
        priority: priority,
        donationId: donationId,
        requestId: requestId,
        assignmentId: assignmentId,
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(Collections.adminTasks).add(query.toMap());

      // Log action
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: raiserUserId,
        riskLevel: priority == query_model.QueryPriority.urgent 
            ? AuditRiskLevel.high 
            : priority == query_model.QueryPriority.high
                ? AuditRiskLevel.medium
                : AuditRiskLevel.low,
        resourceId: docRef.id,
        resourceType: 'query',
        additionalData: {
          'action': 'query_created',
          'description': '$raiserUserType $raiserUserId created ${type.name} query: $subject',
          'queryId': docRef.id,
          'raiserUserId': raiserUserId,
          'type': type.name,
          'priority': priority.name,
          'donationId': donationId,
          'requestId': requestId,
        },
      );

      // Notify admin team
      await _notifyAdminTeam(docRef.id, query);

      return docRef.id;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: raiserUserId,
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'query_creation_failed',
          'description': 'Failed to create query for $raiserUserType $raiserUserId: $e',
          'raiserUserId': raiserUserId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Get queries for admin dashboard
  Future<List<query_model.Query>> getQueriesForAdmin({
    query_model.QueryStatus? status,
    query_model.QueryPriority? priority,
    String? assignedAdminId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(Collections.adminTasks)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }
      
      if (assignedAdminId != null) {
        query = query.where('assignedAdminId', isEqualTo: assignedAdminId);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => query_model.Query.fromFirestore(doc)).toList();
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'get_queries_failed',
          'description': 'Failed to get queries for admin: $e',
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Get queries raised by a user
  Future<List<query_model.Query>> getUserQueries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(Collections.adminTasks)
          .where('raiserUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => query_model.Query.fromFirestore(doc)).toList();
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: userId,
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'get_user_queries_failed',
          'description': 'Failed to get queries for user $userId: $e',
          'userId': userId,
          'error': e.toString(),
        },
      );
      return [];
    }
  }

  /// Assign query to admin
  Future<void> assignQueryToAdmin(String queryId, String adminId) async {
    try {
      await _firestore.collection(Collections.adminTasks).doc(queryId).update({
        'assignedAdminId': adminId,
        'status': query_model.QueryStatus.inReview.name,
        'updatedAt': Timestamp.now(),
        'updates': FieldValue.arrayUnion([
          {
            'updatedBy': adminId,
            'updateType': 'assignment',
            'content': 'Query assigned for review',
            'timestamp': Timestamp.now(),
            'changes': {'assignedAdminId': adminId, 'status': query_model.QueryStatus.inReview.name},
          }
        ]),
      });

      // Log action
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: adminId,
        riskLevel: AuditRiskLevel.low,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_assigned',
          'description': 'Query $queryId assigned to admin $adminId',
          'queryId': queryId,
          'adminId': adminId,
        },
      );

      // Notify admin
      await _notificationService.sendNotification(
        userId: adminId,
        title: 'Query Assigned',
        message: 'A new query has been assigned to you for review.',
        type: 'query_assigned',
        data: {
          'queryId': queryId,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: adminId,
        riskLevel: AuditRiskLevel.high,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_assignment_failed',
          'description': 'Failed to assign query $queryId to admin $adminId: $e',
          'queryId': queryId,
          'adminId': adminId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Add update to query
  Future<void> addQueryUpdate(
    String queryId,
    String updatedBy,
    String updateType,
    String content, {
    Map<String, dynamic> changes = const {},
  }) async {
    try {
      final update = {
        'updatedBy': updatedBy,
        'updateType': updateType,
        'content': content,
        'timestamp': Timestamp.now(),
        'changes': changes,
      };

      await _firestore.collection(Collections.adminTasks).doc(queryId).update({
        'updatedAt': Timestamp.now(),
        'updates': FieldValue.arrayUnion([update]),
        ...changes, // Apply any status or field changes
      });

      // Log action
      await _auditService.logEvent(
        eventType: AuditEventType.dataModification,
        userId: updatedBy,
        riskLevel: AuditRiskLevel.low,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_updated',
          'description': 'Query $queryId updated by $updatedBy: $updateType',
          'queryId': queryId,
          'updatedBy': updatedBy,
          'updateType': updateType,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_update_failed',
          'description': 'Failed to update query $queryId: $e',
          'queryId': queryId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Resolve query
  Future<void> resolveQuery(
    String queryId,
    String adminId,
    String resolution,
  ) async {
    try {
      await _firestore.collection(Collections.adminTasks).doc(queryId).update({
        'status': query_model.QueryStatus.resolved.name,
        'resolution': resolution,
        'resolvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'updates': FieldValue.arrayUnion([
          {
            'updatedBy': adminId,
            'updateType': 'resolution',
            'content': resolution,
            'timestamp': Timestamp.now(),
            'changes': {
              'status': query_model.QueryStatus.resolved.name,
              'resolvedAt': Timestamp.now(),
            },
          }
        ]),
      });

      // Get query details to notify raiser
      final queryDoc = await _firestore.collection(Collections.adminTasks).doc(queryId).get();
      if (queryDoc.exists) {
        final query = query_model.Query.fromFirestore(queryDoc);
        
        // Notify the person who raised the query
        await _notificationService.sendNotification(
          userId: query.raiserUserId,
          title: 'Query Resolved',
          message: 'Your query "${query.subject}" has been resolved.',
          type: 'query_resolved',
          data: {
            'queryId': queryId,
          },
        );
      }

      // Log action
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: adminId,
        riskLevel: AuditRiskLevel.low,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_resolved',
          'description': 'Query $queryId resolved by admin $adminId',
          'queryId': queryId,
          'adminId': adminId,
        },
      );
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: adminId,
        riskLevel: AuditRiskLevel.high,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'query_resolution_failed',
          'description': 'Failed to resolve query $queryId: $e',
          'queryId': queryId,
          'adminId': adminId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Reassign donation/request due to query
  Future<void> reassignDueToQuery(
    String queryId,
    String adminId,
    String? newDonationId,
    String? newRequestId,
    String? newVolunteerId,
    String reassignmentReason,
  ) async {
    try {
      // Get query details
      final queryDoc = await _firestore.collection(Collections.adminTasks).doc(queryId).get();
      if (!queryDoc.exists) throw Exception('Query not found');
      
      final query = query_model.Query.fromFirestore(queryDoc);
      
      final batch = _firestore.batch();
      
      // If reassigning donation
      if (query.donationId != null && newDonationId != null) {
        // Update old donation
        batch.update(_firestore.collection(Collections.donations).doc(query.donationId!), {
          'status': 'available',
          'matchedRequestId': null,
          'assignedVolunteerId': null,
          'updatedAt': Timestamp.now(),
          'metadata.reassignedFrom': queryId,
        });
        
        // Update new donation
        batch.update(_firestore.collection(Collections.donations).doc(newDonationId), {
          'status': 'matched',
          'matchedRequestId': query.requestId,
          'updatedAt': Timestamp.now(),
          'metadata.reassignedTo': queryId,
        });
      }
      
      // If reassigning request
      if (query.requestId != null && newRequestId != null) {
        // Update old request
        batch.update(_firestore.collection(Collections.requests).doc(query.requestId!), {
          'status': 'pending',
          'matchedDonationId': null,
          'assignedVolunteerId': null,
          'updatedAt': Timestamp.now(),
          'metadata.reassignedFrom': queryId,
        });
        
        // Update new request
        batch.update(_firestore.collection(Collections.requests).doc(newRequestId), {
          'status': 'matched',
          'matchedDonationId': query.donationId,
          'updatedAt': Timestamp.now(),
          'metadata.reassignedTo': queryId,
        });
      }
      
      // Update query with reassignment info
      batch.update(_firestore.collection(Collections.adminTasks).doc(queryId), {
        'status': query_model.QueryStatus.resolved.name,
        'resolution': 'Reassignment completed: $reassignmentReason',
        'resolvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'metadata.reassignmentDetails': {
          'adminId': adminId,
          'reason': reassignmentReason,
          'newDonationId': newDonationId,
          'newRequestId': newRequestId,
          'newVolunteerId': newVolunteerId,
          'reassignedAt': Timestamp.now(),
        },
        'updates': FieldValue.arrayUnion([
          {
            'updatedBy': adminId,
            'updateType': 'reassignment',
            'content': 'Reassignment completed: $reassignmentReason',
            'timestamp': Timestamp.now(),
            'changes': {
              'status': query_model.QueryStatus.resolved.name,
              'resolvedAt': Timestamp.now(),
            },
          }
        ]),
      });
      
      await batch.commit();
      
      // Log the reassignment
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: adminId,
        riskLevel: AuditRiskLevel.medium,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'admin_reassignment',
          'description': 'Admin $adminId reassigned due to query $queryId: $reassignmentReason',
          'queryId': queryId,
          'adminId': adminId,
          'reassignmentReason': reassignmentReason,
          'newDonationId': newDonationId,
          'newRequestId': newRequestId,
          'newVolunteerId': newVolunteerId,
        },
      );
      
      // Notify affected parties
      await _notifyReassignment(query, adminId, reassignmentReason);
      
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: adminId,
        riskLevel: AuditRiskLevel.high,
        resourceId: queryId,
        resourceType: 'query',
        additionalData: {
          'action': 'reassignment_failed',
          'description': 'Failed to reassign due to query $queryId: $e',
          'queryId': queryId,
          'adminId': adminId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Notify admin team about new query
  Future<void> _notifyAdminTeam(String queryId, query_model.Query query) async {
    try {
      // Get all admin users
      final adminSnapshot = await _firestore
          .collection(Collections.users)
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Send notification to all admins
      for (final adminDoc in adminSnapshot.docs) {
        await _notificationService.sendNotification(
          userId: adminDoc.id,
          title: 'New ${query.type.name.toUpperCase()} Query',
          message: 'Priority: ${query.priority.name.toUpperCase()} - ${query.subject}',
          type: 'new_query',
          data: {
            'queryId': queryId,
            'priority': query.priority.name,
            'queryType': query.type.name,
          },
        );
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        resourceId: queryId,
        resourceType: 'notification',
        additionalData: {
          'action': 'admin_notification_failed',
          'description': 'Failed to notify admin team about query $queryId: $e',
          'queryId': queryId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Notify about reassignment
  Future<void> _notifyReassignment(
    query_model.Query query,
    String adminId,
    String reason,
  ) async {
    try {
      // Notify the person who raised the query
      await _notificationService.sendNotification(
        userId: query.raiserUserId,
        title: 'Query Resolved - Reassignment Complete',
        message: 'Your query has been resolved through reassignment.',
        type: 'query_reassignment',
        data: {
          'queryId': query.id,
        },
      );
      
      // If there was a donation involved, notify the donor
      if (query.donationId != null) {
        final donationDoc = await _firestore.collection(Collections.donations).doc(query.donationId!).get();
        if (donationDoc.exists) {
          final donorId = donationDoc.data()!['donorId'];
          await _notificationService.sendNotification(
            userId: donorId,
            title: 'Donation Reassignment',
            message: 'Your donation has been reassigned due to an administrative review.',
            type: 'donation_reassignment',
            data: {
              'donationId': query.donationId!,
              'queryId': query.id,
            },
          );
        }
      }
      
      // If there was a request involved, notify the NGO
      if (query.requestId != null) {
        final requestDoc = await _firestore.collection(Collections.requests).doc(query.requestId!).get();
        if (requestDoc.exists) {
          final ngoId = requestDoc.data()!['ngoId'];
          await _notificationService.sendNotification(
            userId: ngoId,
            title: 'Request Reassignment',
            message: 'Your food request has been reassigned due to an administrative review.',
            type: 'request_reassignment',
            data: {
              'requestId': query.requestId!,
              'queryId': query.id,
            },
          );
        }
      }
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        resourceId: query.id,
        resourceType: 'notification',
        additionalData: {
          'action': 'reassignment_notification_failed',
          'description': 'Failed to send reassignment notifications: $e',
          'queryId': query.id,
          'error': e.toString(),
        },
      );
    }
  }

  /// Get query statistics for admin dashboard
  Future<Map<String, dynamic>> getQueryStatistics() async {
    try {
      final snapshot = await _firestore.collection(Collections.adminTasks).get();
      final queries = snapshot.docs.map((doc) => query_model.Query.fromFirestore(doc)).toList();
      
      return {
        'totalQueries': queries.length,
        'openQueries': queries.where((q) => q.status == query_model.QueryStatus.open).length,
        'inReviewQueries': queries.where((q) => q.status == query_model.QueryStatus.inReview).length,
        'resolvedQueries': queries.where((q) => q.status == query_model.QueryStatus.resolved).length,
        'urgentQueries': queries.where((q) => q.priority == query_model.QueryPriority.urgent).length,
        'highPriorityQueries': queries.where((q) => q.priority == query_model.QueryPriority.high).length,
        'averageResolutionTime': _calculateAverageResolutionTime(queries),
        'queriesByType': _getQueriesByType(queries),
      };
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.dataAccess,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'get_query_statistics_failed',
          'description': 'Failed to get query statistics: $e',
          'error': e.toString(),
        },
      );
      return {};
    }
  }

  double _calculateAverageResolutionTime(List<query_model.Query> queries) {
    final resolvedQueries = queries.where((q) => q.resolvedAt != null).toList();
    if (resolvedQueries.isEmpty) return 0.0;
    
    final totalHours = resolvedQueries.fold<double>(0.0, (sum, query) {
      return sum + query.resolvedAt!.difference(query.createdAt).inHours;
    });
    
    return totalHours / resolvedQueries.length;
  }

  Map<String, int> _getQueriesByType(List<query_model.Query> queries) {
    final Map<String, int> typeCount = {};
    for (final type in query_model.QueryType.values) {
      typeCount[type.name] = queries.where((q) => q.type == type).length;
    }
    return typeCount;
  }
}
