import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'firestore_service.dart';
import '../config/firestore_schema.dart';

class SecurityService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Brute-force protection settings
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 8);

  // Check if user account is locked
  Future<bool> isAccountLocked(String email) async {
    try {
      final doc = await _firestore
          .collection('security_logs')
          .doc(_hashEmail(email))
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final attempts = data['failedAttempts'] ?? 0;
      final lastAttempt = (data['lastAttempt'] as Timestamp?)?.toDate();
      
      if (attempts >= maxLoginAttempts && lastAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
        return timeSinceLastAttempt < lockoutDuration;
      }
      
      return false;
    } catch (e) {
      print('Error checking account lock: $e');
      return false;
    }
  }

  // Record failed login attempt
  Future<void> recordFailedLogin(String email, String? ipAddress) async {
    try {
      final emailHash = _hashEmail(email);
      final securityRef = _firestore.collection('security_logs').doc(emailHash);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(securityRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentAttempts = data['failedAttempts'] ?? 0;
          
          transaction.update(securityRef, {
            'failedAttempts': currentAttempts + 1,
            'lastAttempt': Timestamp.now(),
            'ipAddress': ipAddress,
            'updatedAt': Timestamp.now(),
          });
        } else {
          transaction.set(securityRef, {
            'emailHash': emailHash,
            'failedAttempts': 1,
            'lastAttempt': Timestamp.now(),
            'ipAddress': ipAddress,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        }
      });
      
      // Log security event
      await _logSecurityEvent('failed_login', {
        'emailHash': emailHash,
        'ipAddress': ipAddress,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error recording failed login: $e');
    }
  }

  // Record successful login
  Future<void> recordSuccessfulLogin(String userId, String? ipAddress) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Clear failed attempts
        final emailHash = _hashEmail(user.email!);
        await _firestore.collection('security_logs').doc(emailHash).delete();
        
        // Create session record
        await _createUserSession(userId, ipAddress);
        
        // Log security event
        await _logSecurityEvent('successful_login', {
          'userId': userId,
          'ipAddress': ipAddress,
          'timestamp': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error recording successful login: $e');
    }
  }

  // Create and store user session
  Future<void> _createUserSession(String userId, String? ipAddress) async {
    try {
      final sessionId = _generateSessionId();
      final sessionData = {
        'userId': userId,
        'sessionId': sessionId,
        'ipAddress': ipAddress,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(sessionTimeout)),
        'isActive': true,
      };
      
      // Store in Firestore
      await _firestore.collection('user_sessions').doc(sessionId).set(sessionData);
      
      // Store session ID securely on device
      await _secureStorage.write(key: 'session_id', value: sessionId);
      await _secureStorage.write(key: 'session_expires', value: DateTime.now().add(sessionTimeout).toIso8601String());
    } catch (e) {
      print('Error creating user session: $e');
    }
  }

  // Validate current session
  Future<bool> isValidSession() async {
    try {
      final sessionId = await _secureStorage.read(key: 'session_id');
      final expiresStr = await _secureStorage.read(key: 'session_expires');
      
      if (sessionId == null || expiresStr == null) return false;
      
      final expires = DateTime.parse(expiresStr);
      if (DateTime.now().isAfter(expires)) {
        await invalidateSession();
        return false;
      }
      
      // Check if session exists in Firestore
      final doc = await _firestore.collection('user_sessions').doc(sessionId).get();
      if (!doc.exists) {
        await invalidateSession();
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return data['isActive'] == true;
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }

  // Invalidate current session
  Future<void> invalidateSession() async {
    try {
      final sessionId = await _secureStorage.read(key: 'session_id');
      
      if (sessionId != null) {
        // Mark session as inactive in Firestore
        await _firestore.collection('user_sessions').doc(sessionId).update({
          'isActive': false,
          'invalidatedAt': Timestamp.now(),
        });
      }
      
      // Clear local session data
      await _secureStorage.delete(key: 'session_id');
      await _secureStorage.delete(key: 'session_expires');
    } catch (e) {
      print('Error invalidating session: $e');
    }
  }

  // Clean up expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      
      final expiredSessions = await _firestore
          .collection('user_sessions')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      final batch = _firestore.batch();
      for (var doc in expiredSessions.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }

  // Get active sessions for user
  Future<List<Map<String, dynamic>>> getUserActiveSessions(String userId) async {
    try {
      final query = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting user active sessions: $e');
      return [];
    }
  }

  // Terminate specific session
  Future<void> terminateSession(String sessionId) async {
    try {
      await _firestore.collection('user_sessions').doc(sessionId).update({
        'isActive': false,
        'terminatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error terminating session: $e');
    }
  }

  // Log security events
  Future<void> _logSecurityEvent(String event, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('security_events').add({
        'event': event,
        'timestamp': Timestamp.now(),
        ...data,
      });
    } catch (e) {
      print('Error logging security event: $e');
    }
  }

  // Generate secure session ID
  String _generateSessionId() {
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch + i);
    return sha256.convert(bytes).toString();
  }

  // Hash email for privacy
  String _hashEmail(String email) {
    return sha256.convert(utf8.encode(email.toLowerCase())).toString();
  }

  // Admin: Force unlock account
  Future<void> unlockAccount(String email, String adminId) async {
    try {
      final emailHash = _hashEmail(email);
      await _firestore.collection('security_logs').doc(emailHash).delete();
      
      await _logSecurityEvent('account_unlocked', {
        'emailHash': emailHash,
        'adminId': adminId,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error unlocking account: $e');
      rethrow;
    }
  }

  // Get security statistics for admin
  Future<Map<String, dynamic>> getSecurityStats() async {
    try {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      
      final failedLogins = await _firestore
          .collection('security_events')
          .where('event', isEqualTo: 'failed_login')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(dayAgo))
          .get();
      
      final successfulLogins = await _firestore
          .collection('security_events')
          .where('event', isEqualTo: 'successful_login')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(dayAgo))
          .get();
      
      final lockedAccounts = await _firestore
          .collection('security_logs')
          .where('failedAttempts', isGreaterThanOrEqualTo: maxLoginAttempts)
          .get();
      
      return {
        'failedLoginsLast24h': failedLogins.docs.length,
        'successfulLoginsLast24h': successfulLogins.docs.length,
        'currentlyLockedAccounts': lockedAccounts.docs.length,
        'generatedAt': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting security stats: $e');
      return {};
    }
  }
}