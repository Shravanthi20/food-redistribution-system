import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_schema.dart';
import 'enums.dart';
import 'location.dart';

/// Organization model for NGOs
/// Stored in /organizations collection
class Organization {
  final String id;
  final String ownerId;
  final String name;
  final String registrationNumber;
  final NGOType type;
  final String description;
  final Location location;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final int capacity;
  final List<String> servingPopulation;
  final String operatingHours;
  final List<String> preferredFoodTypes;
  final int storageCapacity;
  final bool refrigerationAvailable;
  final String contactPerson;
  final String contactPhone;
  final String? contactEmail;
  final String? website;
  final String? verificationUrl;
  final String? taxExemptionCertificate;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Analytics fields
  final int totalMealsReceived;
  final int totalDeliveries;
  final double? rating;

  Organization({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.registrationNumber,
    this.type = NGOType.other,
    this.description = '',
    required this.location,
    required this.address,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.capacity = 0,
    this.servingPopulation = const [],
    this.operatingHours = '',
    this.preferredFoodTypes = const [],
    this.storageCapacity = 0,
    this.refrigerationAvailable = false,
    this.contactPerson = '',
    this.contactPhone = '',
    this.contactEmail,
    this.website,
    this.verificationUrl,
    this.taxExemptionCertificate,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.totalMealsReceived = 0,
    this.totalDeliveries = 0,
    this.rating,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    return Organization.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  factory Organization.fromMap(Map<String, dynamic> data, {String? id}) {
    return Organization(
      id: id ?? data['id'] ?? '',
      ownerId: data[Fields.ownerId] ?? '',
      name: data[Fields.organizationName] ?? data['name'] ?? '',
      registrationNumber: data[Fields.registrationNumber] ?? '',
      type: NGOType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NGOType.other,
      ),
      description: data[Fields.description] ?? '',
      location: data[Fields.location] != null 
          ? Location.fromJson(data[Fields.location])
          : Location(latitude: 0, longitude: 0, address: ''),
      address: data[Fields.address] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      capacity: data[Fields.capacity] ?? 0,
      servingPopulation: List<String>.from(data['servingPopulation'] ?? []),
      operatingHours: data['operatingHours'] ?? '',
      preferredFoodTypes: List<String>.from(data['preferredFoodTypes'] ?? []),
      storageCapacity: data['storageCapacity'] ?? 0,
      refrigerationAvailable: data['refrigerationAvailable'] ?? false,
      contactPerson: data['contactPerson'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'],
      website: data['website'],
      verificationUrl: data['verificationUrl'],
      taxExemptionCertificate: data['taxExemptionCertificate'],
      isVerified: data[Fields.isVerified] ?? false,
      createdAt: _parseTimestamp(data[Fields.createdAt]) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data[Fields.updatedAt]),
      totalMealsReceived: data['totalMealsReceived'] ?? 0,
      totalDeliveries: data['totalDeliveries'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      Fields.ownerId: ownerId,
      Fields.organizationName: name,
      Fields.registrationNumber: registrationNumber,
      'type': type.name,
      Fields.description: description,
      Fields.location: location.toJson(),
      Fields.address: address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      Fields.capacity: capacity,
      'servingPopulation': servingPopulation,
      'operatingHours': operatingHours,
      'preferredFoodTypes': preferredFoodTypes,
      'storageCapacity': storageCapacity,
      'refrigerationAvailable': refrigerationAvailable,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'website': website,
      'verificationUrl': verificationUrl,
      'taxExemptionCertificate': taxExemptionCertificate,
      Fields.isVerified: isVerified,
      Fields.createdAt: Timestamp.fromDate(createdAt),
      Fields.updatedAt: updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'totalMealsReceived': totalMealsReceived,
      'totalDeliveries': totalDeliveries,
      'rating': rating,
    };
  }

  Organization copyWith({
    String? ownerId,
    String? name,
    String? registrationNumber,
    NGOType? type,
    String? description,
    Location? location,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    int? capacity,
    List<String>? servingPopulation,
    String? operatingHours,
    List<String>? preferredFoodTypes,
    int? storageCapacity,
    bool? refrigerationAvailable,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    String? website,
    String? verificationUrl,
    String? taxExemptionCertificate,
    bool? isVerified,
    DateTime? updatedAt,
    int? totalMealsReceived,
    int? totalDeliveries,
    double? rating,
  }) {
    return Organization(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      capacity: capacity ?? this.capacity,
      servingPopulation: servingPopulation ?? this.servingPopulation,
      operatingHours: operatingHours ?? this.operatingHours,
      preferredFoodTypes: preferredFoodTypes ?? this.preferredFoodTypes,
      storageCapacity: storageCapacity ?? this.storageCapacity,
      refrigerationAvailable: refrigerationAvailable ?? this.refrigerationAvailable,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      website: website ?? this.website,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      taxExemptionCertificate: taxExemptionCertificate ?? this.taxExemptionCertificate,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      totalMealsReceived: totalMealsReceived ?? this.totalMealsReceived,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      rating: rating ?? this.rating,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Organization branch location
class Branch {
  final String id;
  final String name;
  final String address;
  final String city;
  final Location location;
  final String contactPerson;
  final String contactPhone;
  final int capacity;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.location,
    this.contactPerson = '',
    this.contactPhone = '',
    this.capacity = 0,
    this.isActive = true,
  });

  factory Branch.fromMap(Map<String, dynamic> data, {String? id}) {
    return Branch(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      location: data['location'] != null
          ? Location.fromJson(data['location'])
          : Location(latitude: 0, longitude: 0, address: ''),
      contactPerson: data['contactPerson'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      capacity: data['capacity'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'location': location.toJson(),
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'capacity': capacity,
      'isActive': isActive,
    };
  }
}
