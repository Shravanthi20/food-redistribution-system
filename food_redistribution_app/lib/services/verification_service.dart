import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'notification_service.dart';
import 'firestore_service.dart';
import '../config/firestore_schema.dart';

enum DocumentType {
  businessLicense,
  foodSafetyCertificate,
  ngoRegistration,
  taxExemption,
  identityDocument,
  other
}

enum VerificationStatus {
  pending,
  underReview,
  approved,
  rejected,
  clarificationNeeded
}

class VerificationService {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit verification information (text-based)
  Future<String> submitVerificationInfo({
    required String userId,
    required UserRole userRole,
    required Map<String, String> documentInfo, // {type: description/number}
  }) async {
    try {
      final submissionId = _firestore.collection('verification_submissions').doc().id;
      
      // Create text-based verification submission
      List<Map<String, dynamic>> submittedDocs = [];
      
      documentInfo.forEach((type, info) {
        submittedDocs.add({
          'type': type,
          'information': info,
          'submittedAt': Timestamp.now(),
        });
      });
      
      return await _createSubmission(
        submissionId: submissionId,
        userId: userId,
        userRole: userRole,
        submittedDocs: submittedDocs,
      );
    } catch (e) {
      print('Error submitting verification info: $e');
      rethrow;
    }
  }

  // Submit file-based verification
  Future<String> submitFileVerification({
    required String userId,
    required UserRole userRole,
    required String documentUrl,
    required String documentType,
  }) async {
    try {
      final submissionId = _firestore.collection('verification_submissions').doc().id;
      
      List<Map<String, dynamic>> submittedDocs = [{
        'type': documentType,
        'information': documentUrl,
        'submittedAt': Timestamp.now(),
      }];
      
      return await _createSubmission(
        submissionId: submissionId,
        userId: userId,
        userRole: userRole,
        submittedDocs: submittedDocs,
      );
    } catch (e) {
      print('Error submitting file verification: $e');
      rethrow;
    }
  }

  Future<String> _createSubmission({
    required String submissionId,
    required String userId,
    required UserRole userRole,
    required List<Map<String, dynamic>> submittedDocs,
  }) async {
    // Create verification submission
    await _firestore.collection('verification_submissions').doc(submissionId).set({
      'userId': userId,
      'userRole': userRole.name,
      'documentInfo': submittedDocs,
      'status': VerificationStatus.pending.name,
      'submittedAt': Timestamp.now(),
      'reviewedBy': null,
      'reviewedAt': null,
      'notes': null,
    });
    
    // Update user onboarding state
    await _firestore.collection('users').doc(userId).update({
      'onboardingState': OnboardingState.documentSubmitted.name,
      'updatedAt': Timestamp.now(),
    });
    
    // Add to admin review queue
    await _firestore.collection('admin_tasks').add({
      'type': 'document_verification',
      'submissionId': submissionId,
      'userId': userId,
      'userRole': userRole.name,
      'priority': _getPriority(userRole),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
    
    // Notify admins
    await _notifyAdminsOfSubmission(submissionId, userRole);
    
    // Log verification event
    await _logVerificationEvent('documents_submitted', userId, {
      'submissionId': submissionId,
      'documentCount': submittedDocs.length,
    });
    
    return submissionId;
  }

  // Admin: Review submitted documents
  Future<void> reviewSubmission({
    required String submissionId,
    required String adminId,
    required VerificationStatus decision,
    String? notes,
    List<String>? requestedClarifications,
  }) async {
    try {
      final batch = _firestore.batch();
      String userId;
      bool isLegacy = submissionId.startsWith('legacy_');

      if (isLegacy) {
        userId = submissionId.replaceFirst('legacy_', '');
      } else {
        // Update submission records
        final submissionRef = _firestore.collection('verification_submissions').doc(submissionId);
        
        // Get submission data to update user
        final submissionDoc = await submissionRef.get();
        if (!submissionDoc.exists) {
          throw Exception('Submission not found');
        }

        final submissionData = submissionDoc.data() as Map<String, dynamic>;
        userId = submissionData['userId'];

        batch.update(submissionRef, {
          'status': decision.name,
          'reviewedBy': adminId,
          'reviewedAt': Timestamp.now(),
          'notes': notes,
          'requestedClarifications': requestedClarifications,
        });

        // Update admin task
        final taskQuery = await _firestore
            .collection('admin_tasks')
            .where('submissionId', isEqualTo: submissionId)
            .where('status', isEqualTo: 'pending')
            .get();
        
        for (var doc in taskQuery.docs) {
          batch.update(doc.reference, {
            'status': 'completed',
            'completedBy': adminId,
            'completedAt': Timestamp.now(),
          });
        }
      }
      
      // Update user status based on decision
      final userRef = _firestore.collection('users').doc(userId);
      switch (decision) {
        case VerificationStatus.approved:
          batch.update(userRef, {
            'status': UserStatus.verified.name,
            'onboardingState': OnboardingState.verified.name,
            'verifiedAt': Timestamp.now(),
            'verifiedBy': adminId,
            'updatedAt': Timestamp.now(),
          });
          break;
        case VerificationStatus.rejected:
          batch.update(userRef, {
            'status': UserStatus.pending.name,
            'onboardingState': OnboardingState.registered.name,
            'rejectedAt': Timestamp.now(),
            'rejectedBy': adminId,
            'updatedAt': Timestamp.now(),
          });
          break;
        case VerificationStatus.clarificationNeeded:
          batch.update(userRef, {
            'onboardingState': OnboardingState.documentSubmitted.name,
            'clarificationRequested': true,
            'updatedAt': Timestamp.now(),
          });
          break;
        default:
          break;
      }
      
      await batch.commit();
      
      // Send notification to user
      await _notifyUserOfDecision(userId, decision, notes);
      
      // Log verification event
      await _logVerificationEvent('documents_reviewed', userId, {
        'submissionId': submissionId,
        'adminId': adminId,
        'decision': decision.name,
        'isLegacy': isLegacy,
      });
    } catch (e) {
      print('Error reviewing submission: $e');
      rethrow;
    }
  }

  // Get pending verifications for admin
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      print('Fetching pending verifications...');
      
      // Attempt to get from submissions collection
      // TEMPORARY: Removed .orderBy('submittedAt') to avoid indexing requirements until verified
      final query = await _firestore
          .collection('verification_submissions')
          .where('status', isEqualTo: VerificationStatus.pending.name)
          .get();
      
      List<Map<String, dynamic>> submissions = [];
      Set<String> processedUserIds = {}; // Track to avoid duplicates if falling back
      
      for (var doc in query.docs) {
        final data = doc.data();
        final userId = data['userId'];
        processedUserIds.add(userId);
        
        // Get user details
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.exists ? userDoc.data() : {};
        
        submissions.add({
          'id': doc.id,
          'submission': data,
          'user': userData,
        });
      }
      
      print('Found ${submissions.length} formal submissions.');

      // FALLBACK: Look for users with onboardingState == 'documentSubmitted' but no submission record
      // This handles NGOs created before the sync was implemented.
      final fallbackQuery = await _firestore
          .collection('users')
          .where('onboardingState', isEqualTo: OnboardingState.documentSubmitted.name)
          .get();
      
      int fallbackCount = 0;
      for (var userDoc in fallbackQuery.docs) {
        if (!processedUserIds.contains(userDoc.id)) {
          final userData = userDoc.data();
          
          // Synthetic submission for the UI
          final syntheticSubmission = {
            'userId': userDoc.id,
            'userRole': userData['role'] ?? 'ngo',
            'documentInfo': [
              if (userData['verificationDocUrl'] != null)
                {
                  'type': 'Uploaded Document',
                  'information': userData['verificationDocUrl'],
                }
            ],
            'status': VerificationStatus.pending.name,
            'submittedAt': userData['updatedAt'] ?? Timestamp.now(),
            'notes': 'Auto-recovered from legacy status',
          };
          
          submissions.add({
            'id': 'legacy_${userDoc.id}',
            'submission': syntheticSubmission,
            'user': userData,
          });
          fallbackCount++;
        }
      }

      if (fallbackCount > 0) {
        print('Recovered $fallbackCount legacy verifications from users collection.');
      }
      
      return submissions;
    } catch (e) {
      print('ERROR in getPendingVerifications: $e');
      if (e.toString().contains('index')) {
        print('CRITICAL: Firestore Composite Index may be missing. Check the link in the error above.');
      }
      return [];
    }
  }

  // Get verification history for user
  Future<List<Map<String, dynamic>>> getUserVerificationHistory(String userId) async {
    try {
      final query = await _firestore
          .collection('verification_submissions')
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting verification history: $e');
      return [];
    }
  }

  // Admin: Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final pending = await _firestore
          .collection('verification_submissions')
          .where('status', isEqualTo: VerificationStatus.pending.name)
          .get();
      
      final approved = await _firestore
          .collection('verification_submissions')
          .where('status', isEqualTo: VerificationStatus.approved.name)
          .get();
      
      final rejected = await _firestore
          .collection('verification_submissions')
          .where('status', isEqualTo: VerificationStatus.rejected.name)
          .get();
      
      final thisMonth = DateTime.now().subtract(const Duration(days: 30));
      final recentSubmissions = await _firestore
          .collection('verification_submissions')
          .where('submittedAt', isGreaterThan: Timestamp.fromDate(thisMonth))
          .get();
      
      return {
        'pendingCount': pending.docs.length,
        'approvedCount': approved.docs.length,
        'rejectedCount': rejected.docs.length,
        'submissionsThisMonth': recentSubmissions.docs.length,
        'approvalRate': (approved.docs.length + rejected.docs.length) > 0 
            ? (approved.docs.length / (approved.docs.length + rejected.docs.length)) * 100 
            : 0,
        'generatedAt': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting verification stats: $e');
      return {};
    }
  }

  // Helper methods
  int _getPriority(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return 3; // High priority for food donors
      case UserRole.ngo:
        return 2; // Medium priority
      case UserRole.volunteer:
        return 1; // Lower priority
      case UserRole.admin:
        return 4; // Highest priority
    }
  }

  Future<void> _notifyAdminsOfSubmission(String submissionId, UserRole userRole) async {
    try {
      // Get all admin users
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.admin.name)
          .get();
      
      for (var doc in adminQuery.docs) {
        await _notificationService.sendNotification(
          userId: doc.id,
          title: 'New Verification Submission',
          message: 'A ${userRole.name} has submitted documents for verification',
          type: 'verification_request',
          data: {'submissionId': submissionId},
        );
      }
    } catch (e) {
      print('Error notifying admins: $e');
    }
  }

  Future<void> _notifyUserOfDecision(String userId, VerificationStatus decision, String? notes) async {
    String title, message;
    
    switch (decision) {
      case VerificationStatus.approved:
        title = 'Account Verified!';
        message = 'Your documents have been approved. You can now access all features.';
        break;
      case VerificationStatus.rejected:
        title = 'Verification Rejected';
        message = 'Your documents were rejected. Please review the feedback and resubmit.';
        break;
      case VerificationStatus.clarificationNeeded:
        title = 'Clarification Needed';
        message = 'Please provide additional information for your verification.';
        break;
      default:
        title = 'Verification Update';
        message = 'Your verification status has been updated.';
    }
    
    await _notificationService.sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'verification_update',
      data: {
        'decision': decision.name,
        'notes': notes,
      },
    );
  }

  Future<void> _logVerificationEvent(String event, String userId, Map<String, dynamic> data) async {
    await _firestore.collection('verification_logs').add({
      'event': event,
      'userId': userId,
      'timestamp': Timestamp.now(),
      ...data,
    });
  }
}
