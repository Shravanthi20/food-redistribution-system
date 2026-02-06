import 'package:cloud_firestore/cloud_firestore.dart';

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
    await _firestore.collection('issues').add({
      'donationId': donationId,
      'reporterId': reporterId,
      'reporterRole': reporterRole,
      'targetRole': targetRole,
      'reason': reason,
      'status': 'open', // open, resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get issues for Admin
  Stream<QuerySnapshot> getOpenIssues() {
    return _firestore
        .collection('issues')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Resolve an issue
  Future<void> resolveIssue(String issueId, String resolutionNotes) async {
    await _firestore.collection('issues').doc(issueId).update({
      'status': 'resolved',
      'resolutionNotes': resolutionNotes,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
