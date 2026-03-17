import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

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
  final String? drivingLicense;
  final DateTime? licenseExpiryDate;
  final List<String> availabilityHours;
  final List<String> workingDays;
  final int maxRadius; // in kilometers
  final List<String> preferredTasks;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? profileImageUrl;
  final bool isAvailable;
  final bool isVerified;
  final VehicleType vehicleType;
  final double? rating;
  final int? completedTasks;
  final List<Map<String, dynamic>>? availability;
  final Map<String, double>? currentLocation;
  final Map<String, double> baseLocation;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VolunteerProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.address = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.location = const {},
    required this.hasVehicle,
    required this.vehicleType,
    this.drivingLicense,
    this.licenseExpiryDate,
    this.availabilityHours = const [],
    this.workingDays = const [],
    this.maxRadius = 10,
    this.preferredTasks = const [],
    this.emergencyContact,
    this.emergencyPhone,
    this.profileImageUrl,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating,
    this.completedTasks,
    this.availability,
    this.currentLocation,
    this.baseLocation = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory VolunteerProfile.fromFirestore(DocumentSnapshot doc) {
    return VolunteerProfile.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  factory VolunteerProfile.fromMap(Map<String, dynamic> data, {String? id}) {
    return VolunteerProfile(
      userId: id ?? data['userId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      location: data['location'] ?? {},
      hasVehicle: data['hasVehicle'] ?? false,
      drivingLicense: data['drivingLicense'],
      licenseExpiryDate: data['licenseExpiryDate'] != null
          ? (data['licenseExpiryDate'] is Timestamp 
              ? (data['licenseExpiryDate'] as Timestamp).toDate() 
              : DateTime.parse(data['licenseExpiryDate'].toString()))
          : null,
      availabilityHours: List<String>.from(data['availabilityHours'] ?? []),
      workingDays: List<String>.from(data['workingDays'] ?? []),
      maxRadius: data['maxRadius'] ?? 10,
      preferredTasks: List<String>.from(data['preferredTasks'] ?? []),
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      profileImageUrl: data['profileImageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == (data['vehicleType'] ?? 'none'),
        orElse: () => VehicleType.none,
      ),
      rating: (data['rating'] as num?)?.toDouble(),
      completedTasks: data['completedTasks'] as int?,
      availability: (data['availability'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      currentLocation: (data['currentLocation'] as Map<dynamic, dynamic>?)
          ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      baseLocation: (data['location'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
          const {},
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
      'firstName': firstName,
      'isAvailable': isAvailable,
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
  String get id => userId;
}
