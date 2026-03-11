import 'package:cloud_firestore/cloud_firestore.dart';

enum FoodType {
  cooked,
  raw,
  packaged,
  dairy,
  fruits,
  vegetables,
  grains,
  meat,
  seafood,
  bakery,
  beverages,
  other
}

enum DonationStatus {
  listed,
  matched,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  expired
}

enum FoodSafetyLevel {
  high,
  medium,
  low
}

class FoodDonation {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final List<FoodType> foodTypes;
  final int quantity; // in servings
  final String unit; // servings, kg, packages, etc.
  final DateTime preparedAt;
  final DateTime expiresAt;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final FoodSafetyLevel safetyLevel;
  final bool requiresRefrigeration;
  final bool isVegetarian;
  final bool isVegan;
  final bool isHalal;
  final String? allergenInfo;
  final String? specialInstructions;
  final List<String> images;
  final Map<String, dynamic> pickupLocation;
  final String pickupAddress;
  final String donorContactPhone;
  final DonationStatus status;
  final String? assignedVolunteerId;
  final String? assignedNGOId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? hygieneCertification;
  final bool isUrgent;
  
  // Additional fields for tracking
  final int estimatedMeals;
  final int estimatedPeopleServed;
  final DateTime? deliveredAt;
  final String? claimedByNGO;
  final String? ngoName;
  final String? volunteerName;

  FoodDonation({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.foodTypes,
    required this.quantity,
    required this.unit,
    required this.preparedAt,
    required this.expiresAt,
    required this.availableFrom,
    required this.availableUntil,
    required this.safetyLevel,
    required this.requiresRefrigeration,
    required this.isVegetarian,
    required this.isVegan,
    required this.isHalal,
    this.allergenInfo,
    this.specialInstructions,
    required this.images,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.donorContactPhone,
    required this.status,
    this.assignedVolunteerId,
    this.assignedNGOId,
    required this.createdAt,
    this.updatedAt,
    this.hygieneCertification,
    this.isUrgent = false,
    this.estimatedMeals = 0,
    this.estimatedPeopleServed = 0,
    this.deliveredAt,
    this.claimedByNGO,
    this.ngoName,
    this.volunteerName,
  });

  factory FoodDonation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FoodDonation(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      foodTypes: (data['foodTypes'] as List<dynamic>?)
              ?.map((t) => FoodType.values.firstWhere(
                    (e) => e.name == t,
                    orElse: () => FoodType.other,
                  ))
              .toList() ??
          [],
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      preparedAt: (data['preparedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      availableFrom: (data['availableFrom'] as Timestamp).toDate(),
      availableUntil: (data['availableUntil'] as Timestamp).toDate(),
      safetyLevel: FoodSafetyLevel.values.firstWhere(
        (e) => e.name == data['safetyLevel'],
        orElse: () => FoodSafetyLevel.medium,
      ),
      requiresRefrigeration: data['requiresRefrigeration'] ?? false,
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isHalal: data['isHalal'] ?? false,
      allergenInfo: data['allergenInfo'],
      specialInstructions: data['specialInstructions'],
      images: List<String>.from(data['images'] ?? []),
      pickupLocation: data['pickupLocation'] ?? {},
      pickupAddress: data['pickupAddress'] ?? '',
      donorContactPhone: data['donorContactPhone'] ?? '',
      status: DonationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DonationStatus.listed,
      ),
      assignedVolunteerId: data['assignedVolunteerId'],
      assignedNGOId: data['assignedNGOId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      hygieneCertification: data['hygieneCertification'],
      isUrgent: data['isUrgent'] ?? false,
      estimatedMeals: data['estimatedMeals'] ?? 0,
      estimatedPeopleServed: data['estimatedPeopleServed'] ?? 0,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      claimedByNGO: data['claimedByNGO'],
      ngoName: data['ngoName'],
      volunteerName: data['volunteerName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'foodTypes': foodTypes.map((t) => t.name).toList(),
      'quantity': quantity,
      'unit': unit,
      'preparedAt': Timestamp.fromDate(preparedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'availableFrom': Timestamp.fromDate(availableFrom),
      'availableUntil': Timestamp.fromDate(availableUntil),
      'safetyLevel': safetyLevel.name,
      'requiresRefrigeration': requiresRefrigeration,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isHalal': isHalal,
      'allergenInfo': allergenInfo,
      'specialInstructions': specialInstructions,
      'images': images,
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'estimatedMeals': estimatedMeals,
      'estimatedPeopleServed': estimatedPeopleServed,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'claimedByNGO': claimedByNGO,
      'ngoName': ngoName,
      'volunteerName': volunteerName,
      'donorContactPhone': donorContactPhone,
      'status': status.name,
      'assignedVolunteerId': assignedVolunteerId,
      'assignedNGOId': assignedNGOId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'hygieneCertification': hygieneCertification,
      'isUrgent': isUrgent,
    };
  }

  FoodDonation copyWith({
    String? title,
    String? description,
    List<FoodType>? foodTypes,
    int? quantity,
    String? unit,
    DateTime? preparedAt,
    DateTime? expiresAt,
    DateTime? availableFrom,
    DateTime? availableUntil,
    FoodSafetyLevel? safetyLevel,
    bool? requiresRefrigeration,
    bool? isVegetarian,
    bool? isVegan,
    bool? isHalal,
    String? allergenInfo,
    String? specialInstructions,
    List<String>? images,
    DonationStatus? status,
    String? assignedVolunteerId,
    String? assignedNGOId,
    DateTime? updatedAt,
    Map<String, dynamic>? hygieneCertification,
    bool? isUrgent,
  }) {
    return FoodDonation(
      id: id,
      donorId: donorId,
      title: title ?? this.title,
      description: description ?? this.description,
      foodTypes: foodTypes ?? this.foodTypes,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      preparedAt: preparedAt ?? this.preparedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      requiresRefrigeration: requiresRefrigeration ?? this.requiresRefrigeration,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isHalal: isHalal ?? this.isHalal,
      allergenInfo: allergenInfo ?? this.allergenInfo,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      images: images ?? this.images,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      donorContactPhone: donorContactPhone,
      status: status ?? this.status,
      assignedVolunteerId: assignedVolunteerId ?? this.assignedVolunteerId,
      assignedNGOId: assignedNGOId ?? this.assignedNGOId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      hygieneCertification: hygieneCertification ?? this.hygieneCertification,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAvailable =>
      DateTime.now().isAfter(availableFrom) &&
      DateTime.now().isBefore(availableUntil) &&
      !isExpired;
  
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  Duration get timeUntilPickupEnd => availableUntil.difference(DateTime.now());
}