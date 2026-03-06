import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single checklist item
class HygieneChecklistItem {
  final String id;
  final String question;
  final bool isMandatory;
  bool isChecked;

  HygieneChecklistItem({
    required this.id,
    required this.question,
    this.isMandatory = true,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'isMandatory': isMandatory,
        'isChecked': isChecked,
      };

  factory HygieneChecklistItem.fromMap(Map<String, dynamic> map) =>
      HygieneChecklistItem(
        id: map['id'] ?? '',
        question: map['question'] ?? '',
        isMandatory: map['isMandatory'] ?? true,
        isChecked: map['isChecked'] ?? false,
      );
}

/// Represents the full hygiene compliance record for a donation
class HygieneChecklist {
  final String donationId;
  final String ngoId;
  final List<HygieneChecklistItem> items;
  final bool isComplete;
  final DateTime? completedAt;
  final String? notes;

  HygieneChecklist({
    required this.donationId,
    required this.ngoId,
    required this.items,
    this.isComplete = false,
    this.completedAt,
    this.notes,
  });

  bool get allMandatoryChecked =>
      items.where((i) => i.isMandatory).every((i) => i.isChecked);

  Map<String, dynamic> toFirestore() => {
        'donationId': donationId,
        'ngoId': ngoId,
        'items': items.map((i) => i.toMap()).toList(),
        'isComplete': isComplete,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'notes': notes,
      };

  factory HygieneChecklist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HygieneChecklist(
      donationId: data['donationId'] ?? '',
      ngoId: data['ngoId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => HygieneChecklistItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      isComplete: data['isComplete'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
    );
  }
}

/// Represents a clarification request from NGO to Donor
class ClarificationRequest {
  final String id;
  final String donationId;
  final String ngoId;
  final String donorId;
  final String question;
  final String? reply;
  final DateTime createdAt;
  final DateTime? repliedAt;
  final bool isResolved;

  ClarificationRequest({
    required this.id,
    required this.donationId,
    required this.ngoId,
    required this.donorId,
    required this.question,
    this.reply,
    required this.createdAt,
    this.repliedAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toFirestore() => {
        'donationId': donationId,
        'ngoId': ngoId,
        'donorId': donorId,
        'question': question,
        'reply': reply,
        'createdAt': Timestamp.fromDate(createdAt),
        'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
        'isResolved': isResolved,
      };

  factory ClarificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClarificationRequest(
      id: doc.id,
      donationId: data['donationId'] ?? '',
      ngoId: data['ngoId'] ?? '',
      donorId: data['donorId'] ?? '',
      question: data['question'] ?? '',
      reply: data['reply'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      repliedAt: data['repliedAt'] != null
          ? (data['repliedAt'] as Timestamp).toDate()
          : null,
      isResolved: data['isResolved'] ?? false,
    );
  }
}

/// Represents pickup proof uploaded by volunteer
class PickupProof {
  final String donationId;
  final String volunteerId;
  final String imageUrl;
  final String condition; // good / moderate / unsafe
  final DateTime uploadedAt;
  final String? notes;

  PickupProof({
    required this.donationId,
    required this.volunteerId,
    required this.imageUrl,
    required this.condition,
    required this.uploadedAt,
    this.notes,
  });

  Map<String, dynamic> toFirestore() => {
        'donationId': donationId,
        'volunteerId': volunteerId,
        'imageUrl': imageUrl,
        'condition': condition,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'notes': notes,
      };

  factory PickupProof.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupProof(
      donationId: data['donationId'] ?? '',
      volunteerId: data['volunteerId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      condition: data['condition'] ?? 'unknown',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}

/// Represents a pickup cancellation due to unsafe food
class UnsafePickupCancellation {
  final String donationId;
  final String volunteerId;
  final String reason;
  final String details;
  final DateTime cancelledAt;
  final List<String> notifiedStakeholders;

  UnsafePickupCancellation({
    required this.donationId,
    required this.volunteerId,
    required this.reason,
    required this.details,
    required this.cancelledAt,
    this.notifiedStakeholders = const [],
  });

  Map<String, dynamic> toFirestore() => {
        'donationId': donationId,
        'volunteerId': volunteerId,
        'reason': reason,
        'details': details,
        'cancelledAt': Timestamp.fromDate(cancelledAt),
        'notifiedStakeholders': notifiedStakeholders,
      };
}

/// Default checklist template
class HygieneChecklistTemplate {
  static List<HygieneChecklistItem> get defaultItems => [
        HygieneChecklistItem(
          id: 'packaging',
          question: 'Is the food properly packaged and sealed?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'expiry',
          question: 'Is the food within its expiry date?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'temperature',
          question: 'Is the food stored at an appropriate temperature?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'odor',
          question: 'Does the food have a normal, acceptable odor?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'appearance',
          question:
              'Does the food look fresh and free from mold/discoloration?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'contamination',
          question: 'Is there no visible sign of contamination or pests?',
          isMandatory: true,
        ),
        HygieneChecklistItem(
          id: 'allergen_label',
          question: 'Are allergen labels/information provided?',
          isMandatory: false,
        ),
        HygieneChecklistItem(
          id: 'quantity_match',
          question: 'Does the quantity match what was listed in the donation?',
          isMandatory: false,
        ),
      ];
}
