import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final Map<String, dynamic> location;
  final bool hasVehicle;
  final String? vehicleType;
  final String? drivingLicense;
  final DateTime? licenseExpiryDate;
  final List<String> availabilityHours;
  final List<String> workingDays;
  final int maxRadius; // in kilometers
  final List<String> preferredTasks;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? profileImageUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VolunteerProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.location,
    required this.hasVehicle,
    this.vehicleType,
    this.drivingLicense,
    this.licenseExpiryDate,
    required this.availabilityHours,
    required this.workingDays,
    required this.maxRadius,
    required this.preferredTasks,
    this.emergencyContact,
    this.emergencyPhone,
    this.profileImageUrl,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory VolunteerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VolunteerProfile(
      userId: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      location: data['location'] ?? {},
      hasVehicle: data['hasVehicle'] ?? false,
      vehicleType: data['vehicleType'],
      drivingLicense: data['drivingLicense'],
      licenseExpiryDate: data['licenseExpiryDate'] != null
          ? (data['licenseExpiryDate'] as Timestamp).toDate()
          : null,
      availabilityHours: List<String>.from(data['availabilityHours'] ?? []),
      workingDays: List<String>.from(data['workingDays'] ?? []),
      maxRadius: data['maxRadius'] ?? 10,
      preferredTasks: List<String>.from(data['preferredTasks'] ?? []),
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      profileImageUrl: data['profileImageUrl'],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'location': location,
      'hasVehicle': hasVehicle,
      'vehicleType': vehicleType,
      'drivingLicense': drivingLicense,
      'licenseExpiryDate': licenseExpiryDate != null
          ? Timestamp.fromDate(licenseExpiryDate!)
          : null,
      'availabilityHours': availabilityHours,
      'workingDays': workingDays,
      'maxRadius': maxRadius,
      'preferredTasks': preferredTasks,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get fullName => '$firstName $lastName';
}