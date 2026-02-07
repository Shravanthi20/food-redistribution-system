import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

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
  final String description;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NGOProfile({
    required this.userId,
    required this.organizationName,
    required this.registrationNumber,
    this.ngoType = NGOType.other,
    required this.address,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.location = const {},
    this.capacity = 0,
    this.servingPopulation = const [],
    this.operatingHours = '',
    this.preferredFoodTypes = const [],
    this.storageCapacity = 0,
    this.refrigerationAvailable = false,
    this.contactPerson = '',
    this.contactPhone = '',
    this.verificationCertificateUrl,
    this.taxExemptionCertificate,
    this.description = '',
    this.branches = const [],
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory NGOProfile.fromFirestore(DocumentSnapshot doc) {
    return NGOProfile.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  factory NGOProfile.fromMap(Map<String, dynamic> data, {String? id}) {
    return NGOProfile(
      userId: id ?? data['userId'] ?? '',
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
      description: data['description'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(data['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationName': organizationName,
      'description': description,
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

  String get id => userId;
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
