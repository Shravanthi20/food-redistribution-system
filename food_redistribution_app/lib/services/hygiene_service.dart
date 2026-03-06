import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/hygiene_checklist.dart';

/// HygieneService handles all Firestore operations related to:
/// - Hygiene checklist submission by NGOs
/// - Donation acceptance/rejection by NGOs
/// - Clarification requests (NGO ↔ Donor)
/// - Locking donation records after acceptance
/// - Volunteer pickup proof image upload
/// - Unsafe pickup cancellation with stakeholder notification
class HygieneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─────────────────────────────────────────────────────────────
  // 1. HYGIENE CHECKLIST
  // ─────────────────────────────────────────────────────────────

  /// Save/update the hygiene checklist for a donation (before accept/reject).
  Future<void> submitHygieneChecklist(HygieneChecklist checklist) async {
    await _firestore
        .collection('donations')
        .doc(checklist.donationId)
        .collection('hygieneChecklist')
        .doc('record')
        .set(checklist.toFirestore(), SetOptions(merge: true));

    // Also mirror key fields to the parent donation for easy querying
    await _firestore.collection('donations').doc(checklist.donationId).update({
      'hygieneChecklistComplete': checklist.allMandatoryChecked,
      'hygieneChecklistAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch existing checklist record for a donation
  Future<HygieneChecklist?> getHygieneChecklist(String donationId) async {
    final doc = await _firestore
        .collection('donations')
        .doc(donationId)
        .collection('hygieneChecklist')
        .doc('record')
        .get();
    if (!doc.exists) return null;
    return HygieneChecklist.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // 2. ACCEPT DONATION (with lock)
  // ─────────────────────────────────────────────────────────────

  /// Accept a donation. Locks the record immediately after acceptance.
  Future<void> acceptDonation({
    required String donationId,
    required String ngoId,
    required HygieneChecklist checklist,
  }) async {
    // Submit the final checklist
    await submitHygieneChecklist(
      HygieneChecklist(
        donationId: donationId,
        ngoId: ngoId,
        items: checklist.items,
        isComplete: true,
        completedAt: DateTime.now(),
        notes: checklist.notes,
      ),
    );

    // Accept + lock the donation
    await _firestore.collection('donations').doc(donationId).update({
      'status': 'accepted',
      'isLocked': true,
      'acceptedByNGO': ngoId,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 3. REJECT DONATION
  // ─────────────────────────────────────────────────────────────

  /// Reject a donation with a mandatory reason.
  Future<void> rejectDonation({
    required String donationId,
    required String ngoId,
    required String reason,
    String? additionalInfo,
  }) async {
    await _firestore.collection('donations').doc(donationId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectionAdditionalInfo': additionalInfo,
      'rejectedByNGO': ngoId,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log rejection event
    await _firestore.collection('audit_logs').add({
      'event': 'donation_rejected',
      'donationId': donationId,
      'ngoId': ngoId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 4. CLARIFICATION REQUESTS
  // ─────────────────────────────────────────────────────────────

  /// NGO sends a clarification request to the donor.
  Future<void> sendClarificationRequest({
    required String donationId,
    required String ngoId,
    required String donorId,
    required String question,
  }) async {
    // Store under donation subcollection
    await _firestore
        .collection('donations')
        .doc(donationId)
        .collection('clarifications')
        .add({
      'donationId': donationId,
      'ngoId': ngoId,
      'donorId': donorId,
      'question': question,
      'reply': null,
      'isResolved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update donation status to pending_clarification
    await _firestore.collection('donations').doc(donationId).update({
      'status': 'pending_clarification',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all clarification requests for a donation
  Stream<List<ClarificationRequest>> getClarifications(String donationId) {
    return _firestore
        .collection('donations')
        .doc(donationId)
        .collection('clarifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClarificationRequest.fromFirestore(d))
            .toList());
  }

  /// Donor replies to a clarification request
  Future<void> replyClarification({
    required String donationId,
    required String clarificationId,
    required String reply,
  }) async {
    await _firestore
        .collection('donations')
        .doc(donationId)
        .collection('clarifications')
        .doc(clarificationId)
        .update({
      'reply': reply,
      'repliedAt': FieldValue.serverTimestamp(),
      'isResolved': true,
    });

    // Restore status to listed so NGO can review again
    await _firestore.collection('donations').doc(donationId).update({
      'status': 'listed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 5. PICKUP PROOF IMAGE UPLOAD
  // ─────────────────────────────────────────────────────────────

  /// Upload pickup proof image to Firebase Storage, save URL to Firestore.
  Future<String> uploadPickupProofImage({
    required String donationId,
    required String volunteerId,
    required File imageFile,
    required String foodCondition, // good / moderate / unsafe
    String? notes,
  }) async {
    // Upload to Storage
    final ref = _storage.ref(
        'pickup_proofs/$donationId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    // Save proof record
    await _firestore
        .collection('donations')
        .doc(donationId)
        .collection('pickupProofs')
        .add({
      'donationId': donationId,
      'volunteerId': volunteerId,
      'imageUrl': imageUrl,
      'condition': foodCondition,
      'notes': notes,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    // Update donation with proof URL
    await _firestore.collection('donations').doc(donationId).update({
      'pickupProofImageUrl': imageUrl,
      'pickupProofUploaded': true,
      'pickupCondition': foodCondition,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return imageUrl;
  }

  // ─────────────────────────────────────────────────────────────
  // 6. UNSAFE PICKUP CANCELLATION
  // ─────────────────────────────────────────────────────────────

  /// Volunteer cancels pickup because food is unsafe.
  /// Logs mandatory reason and triggers stakeholder notification.
  Future<void> cancelPickupUnsafe({
    required String donationId,
    required String volunteerId,
    required String reason,
    required String details,
    required String ngoId,
    required String donorId,
    String? adminId,
  }) async {
    final cancellationData = {
      'donationId': donationId,
      'volunteerId': volunteerId,
      'reason': reason,
      'details': details,
      'cancelledAt': FieldValue.serverTimestamp(),
      'notifiedStakeholders': [ngoId, donorId, if (adminId != null) adminId],
    };

    // Log cancellation to subcollection
    await _firestore
        .collection('donations')
        .doc(donationId)
        .collection('unsafeCancellations')
        .add(cancellationData);

    // Update donation status
    await _firestore.collection('donations').doc(donationId).update({
      'status': 'pickup_cancelled_unsafe',
      'cancellationReason': reason,
      'cancellationDetails': details,
      'cancelledByVolunteer': volunteerId,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Audit log
    await _firestore.collection('audit_logs').add({
      'event': 'unsafe_pickup_cancelled',
      'donationId': donationId,
      'volunteerId': volunteerId,
      'reason': reason,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'severity': 'high',
    });

    // Notification records for each stakeholder (picked up by notification service)
    final message =
        'Pickup cancelled: food deemed unsafe. Reason: $reason. Details: $details';
    for (final uid in [ngoId, donorId, if (adminId != null) adminId]) {
      await _firestore.collection('notifications').add({
        'recipientId': uid,
        'donationId': donationId,
        'type': 'unsafe_pickup_cancelled',
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Check whether a donation record is locked
  Future<bool> isDonationLocked(String donationId) async {
    final doc = await _firestore.collection('donations').doc(donationId).get();
    return (doc.data()?['isLocked'] as bool?) ?? false;
  }

  /// Get audit logs for a specific donation
  Stream<List<Map<String, dynamic>>> getDonationAuditLogs(String donationId) {
    return _firestore
        .collection('audit_logs')
        .where('donationId', isEqualTo: donationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
