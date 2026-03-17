import '../constants/app_constants.dart';
import 'enums.dart';

class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final bool isActive;
  final Location? address;
  final Map<String, dynamic> preferences;
  final List<String> certifications;
  final double? rating;
  final int completedTasks;
  final DateTime? lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.isActive = true,
    this.address,
    this.preferences = const {},
    this.certifications = const [],
    this.rating,
    this.completedTasks = 0,
    this.lastLoginAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      address: json['address'] != null 
        ? Location.fromJson(json['address']) 
        : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      certifications: List<String>.from(json['certifications'] ?? []),
      rating: json['rating']?.toDouble(),
      completedTasks: json['completed_tasks'] ?? 0,
      lastLoginAt: json['last_login_at'] != null 
        ? DateTime.parse(json['last_login_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.toString().split('.').last,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified': isVerified,
      'is_active': isActive,
      'address': address?.toJson(),
      'preferences': preferences,
      'certifications': certifications,
      'rating': rating,
      'completed_tasks': completedTasks,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.trim().isNotEmpty ? fullName : email;

  String get roleDisplayName {
    switch (role) {
      case UserRole.donor:
        return 'Food Donor';
      case UserRole.ngo:
        return 'NGO Partner';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
    Location? address,
    Map<String, dynamic>? preferences,
    List<String>? certifications,
    double? rating,
    int? completedTasks,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      preferences: preferences ?? this.preferences,
      certifications: certifications ?? this.certifications,
      rating: rating ?? this.rating,
      completedTasks: completedTasks ?? this.completedTasks,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? landmark;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.landmark,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'landmark': landmark,
    };
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }
}