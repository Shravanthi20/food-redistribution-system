import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firestore_schema.dart';

// Firestore Database Service for centralized Firestore operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Generic CRUD operations for any collection
  Future<void> create(String collection, String docId, Map<String, dynamic> data) async {
    try {
      data['createdAt'] = Timestamp.now();
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      print('Error creating document in $collection: $e');
      rethrow;
    }
  }

  Future<void> update(String collection, String docId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print('Error updating document in $collection: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> get(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      print('Error getting document from $collection: $e');
      rethrow;
    }
  }

  Future<void> delete(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      print('Error deleting document from $collection: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> query(String collection, {Map<String, dynamic>? where, String? orderBy, bool descending = false, int? limit}) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (where != null) {
        where.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query.get();
    } catch (e) {
      print('Error querying collection $collection: $e');
      rethrow;
    }
  }

  // User Operations
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await create(FirestoreCollections.users, userId, userData);
  }

  Future<DocumentSnapshot> getUser(String userId) async {
    return await get(FirestoreCollections.users, userId);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await update(FirestoreCollections.users, userId, updates);
  }

  // Profile Operations
  Future<void> createDonorProfile(String userId, Map<String, dynamic> profileData) async {
    profileData['userId'] = userId;
    await create(FirestoreCollections.donorProfiles, userId, profileData);
  }

  Future<void> createNGOProfile(String userId, Map<String, dynamic> profileData) async {
    profileData['userId'] = userId;
    await create(FirestoreCollections.ngoProfiles, userId, profileData);
  }

  Future<void> createVolunteerProfile(String userId, Map<String, dynamic> profileData) async {
    profileData['userId'] = userId;
    await create(FirestoreCollections.volunteerProfiles, userId, profileData);
  }

  Future<void> createAdminProfile(String userId, Map<String, dynamic> profileData) async {
    profileData['userId'] = userId;
    await create(FirestoreCollections.adminProfiles, userId, profileData);
  }

  // Food Donation Operations
  Future<void> createFoodDonation(String donationId, Map<String, dynamic> donationData) async {
    await create(FirestoreCollections.foodDonations, donationId, donationData);
  }

  Future<QuerySnapshot> getFoodDonationsByStatus(String status) async {
    return await query(FirestoreCollections.foodDonations, where: {'status': status}, orderBy: 'createdAt', descending: true);
  }

  Future<QuerySnapshot> getUserFoodDonations(String userId) async {
    return await query(FirestoreCollections.foodDonations, where: {'donorId': userId}, orderBy: 'createdAt', descending: true);
  }

  // Verification Operations
  Future<void> createVerificationSubmission(String submissionId, Map<String, dynamic> submissionData) async {
    await create(FirestoreCollections.verificationSubmissions, submissionId, submissionData);
  }

  Future<QuerySnapshot> getPendingVerifications() async {
    return await query(FirestoreCollections.verificationSubmissions, where: {'status': 'pending'}, orderBy: 'submittedAt');
  }

  // Admin Task Operations
  Future<void> createAdminTask(Map<String, dynamic> taskData) async {
    final docRef = _firestore.collection(FirestoreCollections.adminTasks).doc();
    taskData['createdAt'] = Timestamp.now();
    await docRef.set(taskData);
  }

  // Audit Log Operations
  Future<void> createAuditLog(Map<String, dynamic> logData) async {
    logData['timestamp'] = Timestamp.now();
    await _firestore.collection(FirestoreCollections.auditLogs).add(logData);
  }

  Future<QuerySnapshot> getAuditLogs({String? userId, String? eventType, int limit = 50}) async {
    Map<String, dynamic>? whereClause;
    if (userId != null) whereClause = {'userId': userId};
    if (eventType != null) whereClause = {...?whereClause, 'eventType': eventType};
    
    return await query(FirestoreCollections.auditLogs, where: whereClause, orderBy: 'timestamp', descending: true, limit: limit);
  }

  // Security Operations
  Future<void> createSecurityLog(String emailHash, Map<String, dynamic> securityData) async {
    await create(FirestoreCollections.securityLogs, emailHash, securityData);
  }

  Future<void> updateSecurityLog(String emailHash, Map<String, dynamic> updates) async {
    await update(FirestoreCollections.securityLogs, emailHash, updates);
  }

  Future<void> createSecurityEvent(Map<String, dynamic> eventData) async {
    eventData['timestamp'] = Timestamp.now();
    await _firestore.collection(FirestoreCollections.securityEvents).add(eventData);
  }

  // Session Operations
  Future<void> createUserSession(String sessionId, Map<String, dynamic> sessionData) async {
    await create(FirestoreCollections.userSessions, sessionId, sessionData);
  }

  Future<QuerySnapshot> getUserActiveSessions(String userId) async {
    return await query(FirestoreCollections.userSessions, 
      where: {'userId': userId, 'isActive': true}, 
      orderBy: 'createdAt', 
      descending: true
    );
  }

  // Notification Operations
  Future<void> sendNotification(String userId, Map<String, dynamic> notificationData) async {
    // Add to main notifications collection
    await _firestore.collection(FirestoreCollections.notifications).add({
      'userId': userId,
      ...notificationData,
      'createdAt': Timestamp.now(),
    });
    
    // Add to user's subcollection for easier querying
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.userNotifications)
        .add({
      ...notificationData,
      'createdAt': Timestamp.now(),
    });
  }

  Future<QuerySnapshot> getUserNotifications(String userId, {int limit = 50}) async {
    return await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.userNotifications)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }

  // Donation Tracking
  Future<void> createDonationTracking(Map<String, dynamic> trackingData) async {
    trackingData['timestamp'] = Timestamp.now();
    await _firestore.collection(FirestoreCollections.donationTracking).add(trackingData);
  }

  // Batch Operations
  WriteBatch getBatch() {
    return _firestore.batch();
  }

  Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }

  // Statistics and Analytics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final totalUsers = await _firestore.collection(FirestoreCollections.users).get();
      
      final donors = await query(FirestoreCollections.users, where: {'role': 'donor'});
      final ngos = await query(FirestoreCollections.users, where: {'role': 'ngo'});
      final volunteers = await query(FirestoreCollections.users, where: {'role': 'volunteer'});
      final verified = await query(FirestoreCollections.users, where: {'status': 'verified'});
      
      return {
        'totalUsers': totalUsers.docs.length,
        'donors': donors.docs.length,
        'ngos': ngos.docs.length,
        'volunteers': volunteers.docs.length,
        'verified': verified.docs.length,
        'generatedAt': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getDonationStatistics() async {
    try {
      final total = await _firestore.collection(FirestoreCollections.foodDonations).get();
      final available = await query(FirestoreCollections.foodDonations, where: {'status': 'available'});
      final completed = await query(FirestoreCollections.foodDonations, where: {'status': 'completed'});
      
      return {
        'total': total.docs.length,
        'available': available.docs.length,
        'completed': completed.docs.length,
        'generatedAt': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting donation statistics: $e');
      return {};
    }
  }

  // Clean up operations
  Future<void> cleanupExpiredSessions() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final expiredSessions = await _firestore
          .collection(FirestoreCollections.userSessions)
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      final batch = _firestore.batch();
      for (var doc in expiredSessions.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredSessions.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${expiredSessions.docs.length} expired sessions from Firestore');
      }
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }

  Future<void> cleanupOldAuditLogs({int retentionDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final oldLogs = await _firestore
          .collection(FirestoreCollections.auditLogs)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500)
          .get();
      
      if (oldLogs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in oldLogs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('Cleaned up ${oldLogs.docs.length} old audit logs from Firestore');
      }
    } catch (e) {
      print('Error cleaning up old audit logs: $e');
    }
  }
}