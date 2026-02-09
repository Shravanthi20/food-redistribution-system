import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  matched,
  fulfilled,
  cancelled,
  expired
}

enum RequestUrgency {
  low,
  medium,
  high,
  critical
}

enum FoodCategory {
  vegetables,
  fruits,
  grains,
  readyToEat,
  dairy,
  meat,
  bakery,
  beverages,
  other
}

class FoodRequest {
  final String id;
  final String ngoId;
  final String title;
  final String description;
  final List<FoodCategory> requiredFoodTypes;
  final int requiredQuantity;
  final String unit; // kg, servings, packets, etc.
  final RequestUrgency urgency;
  final DateTime neededBy;
  final Map<String, dynamic> deliveryLocation; // GeoPoint data
  final RequestStatus status;
  final List<String> servingPopulation;
  final int expectedBeneficiaries;
  final bool requiresRefrigeration;
  final List<String> dietaryRestrictions; // vegetarian, vegan, halal, etc.
  final String? matchedDonationId;
  final String? assignedVolunteerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const FoodRequest({
    required this.id,
    required this.ngoId,
    required this.title,
    required this.description,
    required this.requiredFoodTypes,
    required this.requiredQuantity,
    required this.unit,
    required this.urgency,
    required this.neededBy,
    required this.deliveryLocation,
    required this.status,
    required this.servingPopulation,
    required this.expectedBeneficiaries,
    required this.requiresRefrigeration,
    required this.dietaryRestrictions,
    this.matchedDonationId,
    this.assignedVolunteerId,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  factory FoodRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FoodRequest(
      id: doc.id,
      ngoId: data['ngoId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requiredFoodTypes: (data['requiredFoodTypes'] as List<dynamic>?)
          ?.map((e) => FoodCategory.values.firstWhere(
                (category) => category.name == e,
                orElse: () => FoodCategory.other,
              ))
          .toList() ?? [],
      requiredQuantity: data['requiredQuantity'] ?? 0,
      unit: data['unit'] ?? 'servings',
      urgency: RequestUrgency.values.firstWhere(
        (e) => e.name == data['urgency'],
        orElse: () => RequestUrgency.medium,
      ),
      neededBy: (data['neededBy'] as Timestamp).toDate(),
      deliveryLocation: data['deliveryLocation'] ?? {},
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      servingPopulation: List<String>.from(data['servingPopulation'] ?? []),
      expectedBeneficiaries: data['expectedBeneficiaries'] ?? 0,
      requiresRefrigeration: data['requiresRefrigeration'] ?? false,
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      matchedDonationId: data['matchedDonationId'],
      assignedVolunteerId: data['assignedVolunteerId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      metadata: data['metadata'] ?? {},
    );
  }

  factory FoodRequest.fromMap(Map<String, dynamic> data) {
    return FoodRequest(
      id: data['id'] ?? '',
      ngoId: data['ngoId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requiredFoodTypes: (data['requiredFoodTypes'] as List<dynamic>?)
          ?.map((e) => FoodCategory.values.firstWhere(
                (category) => category.name == e,
                orElse: () => FoodCategory.other,
              ))
          .toList() ?? [],
      requiredQuantity: data['requiredQuantity'] ?? 0,
      unit: data['unit'] ?? 'servings',
      urgency: RequestUrgency.values.firstWhere(
        (e) => e.name == data['urgency'],
        orElse: () => RequestUrgency.medium,
      ),
      neededBy: data['neededBy'] is Timestamp 
          ? (data['neededBy'] as Timestamp).toDate()
          : DateTime.parse(data['neededBy']),
      deliveryLocation: data['deliveryLocation'] ?? {},
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      servingPopulation: List<String>.from(data['servingPopulation'] ?? []),
      expectedBeneficiaries: data['expectedBeneficiaries'] ?? 0,
      requiresRefrigeration: data['requiresRefrigeration'] ?? false,
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      matchedDonationId: data['matchedDonationId'],
      assignedVolunteerId: data['assignedVolunteerId'],
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : null,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ngoId': ngoId,
      'title': title,
      'description': description,
      'requiredFoodTypes': requiredFoodTypes.map((e) => e.name).toList(),
      'requiredQuantity': requiredQuantity,
      'unit': unit,
      'urgency': urgency.name,
      'neededBy': Timestamp.fromDate(neededBy),
      'deliveryLocation': deliveryLocation,
      'status': status.name,
      'servingPopulation': servingPopulation,
      'expectedBeneficiaries': expectedBeneficiaries,
      'requiresRefrigeration': requiresRefrigeration,
      'dietaryRestrictions': dietaryRestrictions,
      'matchedDonationId': matchedDonationId,
      'assignedVolunteerId': assignedVolunteerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  FoodRequest copyWith({
    String? id,
    String? ngoId,
    String? title,
    String? description,
    List<FoodCategory>? requiredFoodTypes,
    int? requiredQuantity,
    String? unit,
    RequestUrgency? urgency,
    DateTime? neededBy,
    Map<String, dynamic>? deliveryLocation,
    RequestStatus? status,
    List<String>? servingPopulation,
    int? expectedBeneficiaries,
    bool? requiresRefrigeration,
    List<String>? dietaryRestrictions,
    String? matchedDonationId,
    String? assignedVolunteerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FoodRequest(
      id: id ?? this.id,
      ngoId: ngoId ?? this.ngoId,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredFoodTypes: requiredFoodTypes ?? this.requiredFoodTypes,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      unit: unit ?? this.unit,
      urgency: urgency ?? this.urgency,
      neededBy: neededBy ?? this.neededBy,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      status: status ?? this.status,
      servingPopulation: servingPopulation ?? this.servingPopulation,
      expectedBeneficiaries: expectedBeneficiaries ?? this.expectedBeneficiaries,
      requiresRefrigeration: requiresRefrigeration ?? this.requiresRefrigeration,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      matchedDonationId: matchedDonationId ?? this.matchedDonationId,
      assignedVolunteerId: assignedVolunteerId ?? this.assignedVolunteerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}