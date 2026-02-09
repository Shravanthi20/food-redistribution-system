import 'package:cloud_firestore/cloud_firestore.dart';

enum QueryType {
  donationDispute,
  requestDispute,
  qualityIssue,
  deliveryIssue,
  matchingIssue,
  volunteerIssue,
  other
}

enum QueryStatus {
  open,
  inReview,
  resolved,
  closed
}

enum QueryPriority {
  low,
  medium,
  high,
  urgent
}

class Query {
  final String id;
  final String raiserUserId;
  final String raiserUserType; // donor, ngo, volunteer
  final QueryType type;
  final String subject;
  final String description;
  final QueryStatus status;
  final QueryPriority priority;
  final String? donationId;
  final String? requestId;
  final String? assignmentId;
  final String? assignedAdminId;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final List<QueryUpdate> updates;
  final Map<String, dynamic> metadata;

  const Query({
    required this.id,
    required this.raiserUserId,
    required this.raiserUserType,
    required this.type,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.donationId,
    this.requestId,
    this.assignmentId,
    this.assignedAdminId,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolution,
    this.updates = const [],
    this.metadata = const {},
  });

  factory Query.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Query(
      id: doc.id,
      raiserUserId: data['raiserUserId'] ?? '',
      raiserUserType: data['raiserUserType'] ?? '',
      type: QueryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => QueryType.other,
      ),
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      status: QueryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => QueryStatus.open,
      ),
      priority: QueryPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => QueryPriority.medium,
      ),
      donationId: data['donationId'],
      requestId: data['requestId'],
      assignmentId: data['assignmentId'],
      assignedAdminId: data['assignedAdminId'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      resolution: data['resolution'],
      updates: (data['updates'] as List<dynamic>?)
          ?.map((e) => QueryUpdate.fromMap(e))
          .toList() ?? [],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raiserUserId': raiserUserId,
      'raiserUserType': raiserUserType,
      'type': type.name,
      'subject': subject,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'donationId': donationId,
      'requestId': requestId,
      'assignmentId': assignmentId,
      'assignedAdminId': assignedAdminId,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolution': resolution,
      'updates': updates.map((e) => e.toMap()).toList(),
      'metadata': metadata,
    };
  }

  Query copyWith({
    String? id,
    String? raiserUserId,
    String? raiserUserType,
    QueryType? type,
    String? subject,
    String? description,
    QueryStatus? status,
    QueryPriority? priority,
    String? donationId,
    String? requestId,
    String? assignmentId,
    String? assignedAdminId,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolution,
    List<QueryUpdate>? updates,
    Map<String, dynamic>? metadata,
  }) {
    return Query(
      id: id ?? this.id,
      raiserUserId: raiserUserId ?? this.raiserUserId,
      raiserUserType: raiserUserType ?? this.raiserUserType,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      donationId: donationId ?? this.donationId,
      requestId: requestId ?? this.requestId,
      assignmentId: assignmentId ?? this.assignmentId,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      updates: updates ?? this.updates,
      metadata: metadata ?? this.metadata,
    );
  }
}

class QueryUpdate {
  final String updatedBy;
  final String updateType; // status_change, comment, reassignment, etc.
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> changes;

  const QueryUpdate({
    required this.updatedBy,
    required this.updateType,
    required this.content,
    required this.timestamp,
    this.changes = const {},
  });

  factory QueryUpdate.fromMap(Map<String, dynamic> data) {
    return QueryUpdate(
      updatedBy: data['updatedBy'] ?? '',
      updateType: data['updateType'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      changes: data['changes'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'updatedBy': updatedBy,
      'updateType': updateType,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'changes': changes,
    };
  }
}