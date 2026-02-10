import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_schema.dart';

class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Report a new issue
  Future<void> reportIssue({
    required String donationId,
    required String reporterId,
    required String reporterRole,
    required String targetRole, // 'NGO', 'Volunteer', 'Donor'
    required String reason,
  }) async {
    await _firestore.collection(Collections.adminTasks).add({
      'donationId': donationId,
      'reporterId': reporterId,
      'reporterRole': reporterRole,
      'targetRole': targetRole,
      'reason': reason,
      'status': 'open', // open, resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get issues for Admin (Stream)
  Stream<QuerySnapshot> getOpenIssues() {
    return _firestore
        .collection(Collections.adminTasks)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get issues for Admin (Future)
  Future<List<Map<String, dynamic>>> getFutureOpenIssues() async {
    final query = await _firestore
        .collection(Collections.adminTasks)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .get();
    
    return query.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  // Resolve an issue
  Future<void> resolveIssue(String issueId, String resolutionNotes) async {
    await _firestore.collection(Collections.adminTasks).doc(issueId).update({
      'status': 'resolved',
      'resolutionNotes': resolutionNotes,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
