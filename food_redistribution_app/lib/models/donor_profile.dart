import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class DonorProfile {
  final String userId;
  final DonorType donorType;
  final String businessName;
  final String businessRegistrationNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final Map<String, dynamic> location; // GeoPoint data
  final List<String> foodTypes;
  final String operatingHours;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final String? businessLicense;
  final String? foodSafetyCertificate;
  final DateTime? certificateExpiryDate;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DonorProfile({
    required this.userId,
    required this.donorType,
    required this.businessName,
    required this.businessRegistrationNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.location,
    required this.foodTypes,
    required this.operatingHours,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    this.businessLicense,
    this.foodSafetyCertificate,
    this.certificateExpiryDate,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory DonorProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DonorProfile(
      userId: doc.id,
      donorType: DonorType.values.firstWhere(
        (e) => e.name == data['donorType'],
        orElse: () => DonorType.other,
      ),
      businessName: data['businessName'] ?? '',
      businessRegistrationNumber: data['businessRegistrationNumber'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      location: data['location'] ?? {},
      foodTypes: List<String>.from(data['foodTypes'] ?? []),
      operatingHours: data['operatingHours'] ?? '',
      pickupAvailable: data['pickupAvailable'] ?? false,
      deliveryAvailable: data['deliveryAvailable'] ?? false,
      businessLicense: data['businessLicense'],
      foodSafetyCertificate: data['foodSafetyCertificate'],
      certificateExpiryDate: data['certificateExpiryDate'] != null
          ? (data['certificateExpiryDate'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorType': donorType.name,
      'businessName': businessName,
      'businessRegistrationNumber': businessRegistrationNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'location': location,
      'foodTypes': foodTypes,
      'operatingHours': operatingHours,
      'pickupAvailable': pickupAvailable,
      'deliveryAvailable': deliveryAvailable,
      'businessLicense': businessLicense,
      'foodSafetyCertificate': foodSafetyCertificate,
      'certificateExpiryDate': certificateExpiryDate != null
          ? Timestamp.fromDate(certificateExpiryDate!)
          : null,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
