import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firestore_schema.dart';
import '../config/firebase_schema.dart';

/// Firestore Database Service for centralized Firestore operations
/// Updated for Firebase Schema v2.0
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Generic CRUD operations for any collection
  Future<void> create(String collection, String docId, Map<String, dynamic> data) async {
    try {
      data[Fields.createdAt] = Timestamp.now();
      data[Fields.updatedAt] = Timestamp.now();
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      print('Error creating document in $collection: $e');
      rethrow;
    }
  }

  Future<void> update(String collection, String docId, Map<String, dynamic> data) async {
    try {
      data[Fields.updatedAt] = Timestamp.now();
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

  Future<QuerySnapshot> query(String collection, {Map<String, dynamic>? where, String? orderBy, bool isDescending = false, int? limit}) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (where != null) {
        where.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: isDescending);
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

  // ============================================================
  // USER OPERATIONS (new schema - embedded profiles)
  // ============================================================
  
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await create(Collections.users, userId, userData);
  }

  Future<DocumentSnapshot> getUser(String userId) async {
    return await get(Collections.users, userId);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await update(Collections.users, userId, updates);
  }
  
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileUpdates) async {
    // Update the embedded profile object
    final updates = <String, dynamic>{};
    profileUpdates.forEach((key, value) {
      updates['${Fields.profile}.$key'] = value;
    });
    await update(Collections.users, userId, updates);
  }

  // ============================================================
  // ORGANIZATION OPERATIONS (replaces ngo_profiles)
  // ============================================================
  
  Future<void> createOrganization(String orgId, Map<String, dynamic> orgData) async {
    await create(Collections.organizations, orgId, orgData);
  }
  
  Future<DocumentSnapshot> getOrganization(String orgId) async {
    return await get(Collections.organizations, orgId);
  }
  
  Future<void> updateOrganization(String orgId, Map<String, dynamic> updates) async {
    await update(Collections.organizations, orgId, updates);
  }
  
  Future<QuerySnapshot> getVerifiedOrganizations() async {
    return await query(Collections.organizations, where: {Fields.isVerified: true});
  }

  // ============================================================
  // DONATION OPERATIONS (replaces food_donations)
  // ============================================================
  
  Future<void> createDonation(String donationId, Map<String, dynamic> donationData) async {
    await create(Collections.donations, donationId, donationData);
  }

  Future<QuerySnapshot> getDonationsByStatus(String status) async {
    return await query(Collections.donations, 
      where: {Fields.status: status}, 
      orderBy: Fields.createdAt, 
      isDescending: true
    );
  }

  Future<QuerySnapshot> getUserDonations(String userId) async {
    return await query(Collections.donations, 
      where: {Fields.donorId: userId}, 
      orderBy: Fields.createdAt, 
      isDescending: true
    );
  }
  
  Future<void> addDonationHistory(String donationId, Map<String, dynamic> historyData) async {
    historyData['timestamp'] = Timestamp.now();
    await _firestore
        .collection(Collections.donations)
        .doc(donationId)
        .collection(Subcollections.history)
        .add(historyData);
  }

  // ============================================================
  // DELIVERY OPERATIONS (new collection)
  // ============================================================
  
  Future<void> createDelivery(String deliveryId, Map<String, dynamic> deliveryData) async {
    await create(Collections.deliveries, deliveryId, deliveryData);
  }
  
  Future<QuerySnapshot> getVolunteerDeliveries(String volunteerId) async {
    return await query(Collections.deliveries, 
      where: {Fields.volunteerId: volunteerId}, 
      orderBy: Fields.createdAt, 
      isDescending: true
    );
  }
  
  Future<void> addDeliveryCheckpoint(String deliveryId, Map<String, dynamic> checkpointData) async {
    checkpointData['timestamp'] = Timestamp.now();
    await _firestore
        .collection(Collections.deliveries)
        .doc(deliveryId)
        .collection(Subcollections.checkpoints)
        .add(checkpointData);
  }

  // ============================================================
  // REQUEST OPERATIONS (NGO food requests)
  // ============================================================
  
  Future<void> createRequest(String requestId, Map<String, dynamic> requestData) async {
    await create(Collections.requests, requestId, requestData);
  }
  
  Future<QuerySnapshot> getNGORequests(String ngoId) async {
    return await query(Collections.requests, 
      where: {Fields.ngoId: ngoId}, 
      orderBy: Fields.createdAt, 
      isDescending: true
    );
  }

  // ============================================================
  // ASSIGNMENT OPERATIONS
  // ============================================================
  
  Future<void> createAssignment(String assignmentId, Map<String, dynamic> assignmentData) async {
    await create(Collections.assignments, assignmentId, assignmentData);
  }
  
  Future<QuerySnapshot> getAssigneeAssignments(String assigneeId, {String? status}) async {
    final where = <String, dynamic>{Fields.assigneeId: assigneeId};
    if (status != null) where[Fields.status] = status;
    return await query(Collections.assignments, where: where, orderBy: Fields.createdAt, isDescending: true);
  }

  // ============================================================
  // VERIFICATION OPERATIONS
  // ============================================================
  
  Future<void> createVerification(String verificationId, Map<String, dynamic> verificationData) async {
    await create(Collections.verifications, verificationId, verificationData);
  }

  Future<QuerySnapshot> getPendingVerifications() async {
    return await query(Collections.verifications, 
      where: {Fields.status: 'pending'}, 
      orderBy: Fields.createdAt
    );
  }

  // ============================================================
  // ADMIN TASK OPERATIONS
  // ============================================================
  
  Future<void> createAdminTask(Map<String, dynamic> taskData) async {
    final docRef = _firestore.collection(Collections.adminTasks).doc();
    taskData[Fields.createdAt] = Timestamp.now();
    await docRef.set(taskData);
  }

  // ============================================================
  // AUDIT OPERATIONS
  // ============================================================
  
  Future<void> createAuditLog(Map<String, dynamic> logData) async {
    logData['timestamp'] = Timestamp.now();
    await _firestore.collection(Collections.audit).add(logData);
  }

  Future<QuerySnapshot> getAuditLogs({String? userId, String? eventType, int limit = 50}) async {
    Map<String, dynamic>? whereClause;
    if (userId != null) whereClause = {'userId': userId};
    if (eventType != null) whereClause = {...?whereClause, 'eventType': eventType};
    
    return await query(Collections.audit, 
      where: whereClause, 
      orderBy: 'timestamp', 
      isDescending: true, 
      limit: limit
    );
  }

  // ============================================================
  // SECURITY OPERATIONS
  // ============================================================
  
  Future<void> createSecurityEvent(Map<String, dynamic> eventData) async {
    eventData['timestamp'] = Timestamp.now();
    await _firestore.collection(Collections.security).add(eventData);
  }

  // ============================================================
  // TRACKING OPERATIONS
  // ============================================================
  
  Future<void> updateVolunteerLocation(String volunteerId, Map<String, dynamic> locationData) async {
    locationData['timestamp'] = Timestamp.now();
    await _firestore
        .collection(Collections.tracking)
        .doc(volunteerId)
        .collection(Subcollections.locations)
        .add(locationData);
  }
  
  Stream<QuerySnapshot> getVolunteerLocationStream(String volunteerId) {
    return _firestore
        .collection(Collections.tracking)
        .doc(volunteerId)
        .collection(Subcollections.locations)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  // ============================================================
  // NOTIFICATION OPERATIONS (subcollection pattern)
  // ============================================================
  
  Future<void> sendNotification(String userId, Map<String, dynamic> notificationData) async {
    await _firestore
        .collection(Collections.notifications)
        .doc(userId)
        .collection(Subcollections.items)
        .add({
      ...notificationData,
      'read': false,
      Fields.createdAt: Timestamp.now(),
    });
  }
  
  Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return _firestore
        .collection(Collections.notifications)
        .doc(userId)
        .collection(Subcollections.items)
        .orderBy(Fields.createdAt, descending: true)
        .limit(50)
        .snapshots();
  }
  
  Future<void> markNotificationRead(String userId, String notificationId) async {
    await _firestore
        .collection(Collections.notifications)
        .doc(userId)
        .collection(Subcollections.items)
        .doc(notificationId)
        .update({'read': true, 'readAt': Timestamp.now()});
  }

  // ============================================================
  // LEGACY COMPATIBILITY METHODS (deprecated)
  // ============================================================
  
  @Deprecated('Use createDonation instead')
  Future<void> createFoodDonation(String donationId, Map<String, dynamic> donationData) async {
    await createDonation(donationId, donationData);
  }

  @Deprecated('Use getDonationsByStatus instead')
  Future<QuerySnapshot> getFoodDonationsByStatus(String status) async {
    return await getDonationsByStatus(status);
  }

  @Deprecated('Use getUserDonations instead')
  Future<QuerySnapshot> getUserFoodDonations(String userId) async {
    return await getUserDonations(userId);
  }

  @Deprecated('Use createVerification instead')
  Future<void> createVerificationSubmission(String submissionId, Map<String, dynamic> submissionData) async {
    await createVerification(submissionId, submissionData);
  }

  @Deprecated('Profile data is now embedded in users collection')
  Future<void> createDonorProfile(String userId, Map<String, dynamic> profileData) async {
    await updateUserProfile(userId, profileData);
  }

  @Deprecated('Use createOrganization instead')
  Future<void> createNGOProfile(String userId, Map<String, dynamic> profileData) async {
    profileData[Fields.ownerId] = userId;
    await createOrganization(userId, profileData);
  }

  @Deprecated('Profile data is now embedded in users collection')
  Future<void> createVolunteerProfile(String userId, Map<String, dynamic> profileData) async {
    await updateUserProfile(userId, profileData);
  }

  @Deprecated('Profile data is now embedded in users collection')
  Future<void> createAdminProfile(String userId, Map<String, dynamic> profileData) async {
    await updateUserProfile(userId, profileData);
  }

  @Deprecated('Use createSecurityEvent instead')
  Future<void> createSecurityLog(String emailHash, Map<String, dynamic> securityData) async {
    securityData['emailHash'] = emailHash;
    await createSecurityEvent(securityData);
  }

  @Deprecated('Use createSecurityEvent instead')
  Future<void> updateSecurityLog(String emailHash, Map<String, dynamic> updates) async {
    updates['emailHash'] = emailHash;
    await createSecurityEvent(updates);
  }

  @Deprecated('Session data should be managed via Firebase Auth')
  Future<void> createUserSession(String sessionId, Map<String, dynamic> sessionData) async {
    await create('sessions', sessionId, sessionData);
  }

  @Deprecated('Session data should be managed via Firebase Auth')
  Future<QuerySnapshot> getUserActiveSessions(String userId) async {
    return await query('sessions', 
      where: {'userId': userId, 'isActive': true}, 
      orderBy: Fields.createdAt, 
      isDescending: true
    );
  }

  Future<QuerySnapshot> getUserNotifications(String userId, {int limit = 50}) async {
    return await _firestore
        .collection(Collections.notifications)
        .doc(userId)
        .collection(Subcollections.items)
        .orderBy(Fields.createdAt, descending: true)
        .limit(limit)
        .get();
  }

  // Donation Tracking
  Future<void> createDonationTracking(Map<String, dynamic> trackingData) async {
    trackingData['timestamp'] = Timestamp.now();
    await _firestore.collection(Collections.tracking).add(trackingData);
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
      final totalUsers = await _firestore.collection(Collections.users).get();
      
      final donors = await query(Collections.users, where: {'role': 'donor'});
      final ngos = await query(Collections.users, where: {'role': 'ngo'});
      final volunteers = await query(Collections.users, where: {'role': 'volunteer'});
      final verified = await query(Collections.users, where: {'status': 'verified'});
      
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
      final total = await _firestore.collection(Collections.donations).get();
      final available = await query(Collections.donations, where: {'status': 'available'});
      final completed = await query(Collections.donations, where: {'status': 'completed'});
      
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
          .collection(Collections.security)
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
          .collection(Collections.audit)
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