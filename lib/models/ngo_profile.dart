import 'package:cloud_firestore/cloud_firestore.dart';

enum NGOType {
  orphanage,
  oldAgeHome,
  school,
  hospital,
  communityCenter,
  foodBank,
  shelter,
  other
}

class NGOProfile {
  final String userId;
  final String organizationName;
  final String registrationNumber;
  final NGOType ngoType;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final Map<String, dynamic> location; // GeoPoint data + geohash
  final int capacity;
  final List<String> servingPopulation;
  final String operatingHours;
  final List<String> preferredFoodTypes;
  final int storageCapacity;
  final bool refrigerationAvailable;
  final String contactPerson;
  final String contactPhone;
  final String? verificationCertificateUrl; // Changed: Replaced placeholder
  final String? taxExemptionCertificate;
  final List<BranchLocation> branches;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NGOProfile({
    required this.userId,
    required this.organizationName,
    required this.registrationNumber,
    required this.ngoType,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.location,
    required this.capacity,
    required this.servingPopulation,
    required this.operatingHours,
    required this.preferredFoodTypes,
    required this.storageCapacity,
    required this.refrigerationAvailable,
    required this.contactPerson,
    required this.contactPhone,
    this.verificationCertificateUrl,
    this.taxExemptionCertificate,
    this.branches = const [],
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory NGOProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NGOProfile(
      userId: doc.id,
      organizationName: data['organizationName'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      ngoType: NGOType.values.firstWhere(
        (e) => e.name == data['ngoType'],
        orElse: () => NGOType.other,
      ),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      location: data['location'] ?? {},
      capacity: data['capacity'] ?? 0,
      servingPopulation: List<String>.from(data['servingPopulation'] ?? []),
      operatingHours: data['operatingHours'] ?? '',
      preferredFoodTypes: List<String>.from(data['preferredFoodTypes'] ?? []),
      storageCapacity: data['storageCapacity'] ?? 0,
      refrigerationAvailable: data['refrigerationAvailable'] ?? false,
      contactPerson: data['contactPerson'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      verificationCertificateUrl: data['verificationCertificateUrl'],
      taxExemptionCertificate: data['taxExemptionCertificate'],
      branches: (data['branches'] as List<dynamic>?)
              ?.map((b) => BranchLocation.fromMap(b))
              .toList() ??
          [],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationName': organizationName,
      'registrationNumber': registrationNumber,
      'ngoType': ngoType.name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'location': location,
      'capacity': capacity,
      'servingPopulation': servingPopulation,
      'operatingHours': operatingHours,
      'preferredFoodTypes': preferredFoodTypes,
      'storageCapacity': storageCapacity,
      'refrigerationAvailable': refrigerationAvailable,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'verificationCertificateUrl': verificationCertificateUrl,
      'taxExemptionCertificate': taxExemptionCertificate,
      'branches': branches.map((b) => b.toMap()).toList(),
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class BranchLocation {
  final String name;
  final String address;
  final String city;
  final String contactPerson;
  final String contactPhone;
  final Map<String, dynamic> location;

  BranchLocation({
    required this.name,
    required this.address,
    required this.city,
    required this.contactPerson,
    required this.contactPhone,
    required this.location,
  });

  factory BranchLocation.fromMap(Map<String, dynamic> data) {
    return BranchLocation(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      location: data['location'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'location': location,
    };
  }
}