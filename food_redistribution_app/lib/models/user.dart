import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'location.dart';
import '../config/firebase_schema.dart';

export 'enums.dart';
export 'location.dart';

/// Unified User model with embedded profile data
/// Uses new Firebase schema v2.0 - stored in /users collection
class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final UserStatus status;
  final OnboardingState onboardingState;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? restrictions;
  final DateTime? restrictionEndDate;
  final DateTime? lastLoginAt;

  String get id => uid;

  // Embedded profile information
  final UserProfile profile;

  // Convenience getters for backward compatibility
  String? get firstName => profile.firstName;
  String? get lastName => profile.lastName;
  String? get phone => profile.phone;
  String? get profileImageUrl => profile.profileImageUrl;
  Location? get address => profile.location;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
    required this.onboardingState,
    required this.createdAt,
    this.updatedAt,
    this.restrictions,
    this.restrictionEndDate,
    this.lastLoginAt,
    UserProfile? profile,
  }) : profile = profile ?? UserProfile();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data, id: doc.id);
  }

  factory AppUser.fromMap(Map<String, dynamic> data, {String? id}) {
    // Handle embedded profile or legacy flat structure
    final profileData = data[Fields.profile] as Map<String, dynamic>? ?? {};
    
    // Merge legacy flat fields into profile if not in profile object
    final mergedProfile = {
      ...profileData,
      if (data['firstName'] != null && profileData['firstName'] == null)
        'firstName': data['firstName'],
      if (data['lastName'] != null && profileData['lastName'] == null)
        'lastName': data['lastName'],
      if (data['phone'] != null && profileData['phone'] == null)
        'phone': data['phone'],
      if (data['profileImageUrl'] != null && profileData['profileImageUrl'] == null)
        'profileImageUrl': data['profileImageUrl'],
      if (data['address'] != null && profileData['location'] == null)
        'location': data['address'],
    };
    
    return AppUser(
      uid: id ?? data['uid'] ?? '',
      email: data[Fields.email] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data[Fields.role],
        orElse: () => UserRole.donor,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data[Fields.status],
        orElse: () => UserStatus.pending,
      ),
      onboardingState: OnboardingState.values.firstWhere(
        (e) => e.name == data[Fields.onboardingState],
        orElse: () => OnboardingState.registered,
      ),
      createdAt: _parseTimestamp(data[Fields.createdAt]) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data[Fields.updatedAt]),
      restrictions: data['restrictions'],
      restrictionEndDate: _parseTimestamp(data['restrictionEndDate']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      profile: UserProfile.fromMap(mergedProfile),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      Fields.email: email,
      Fields.role: role.name,
      Fields.status: status.name,
      Fields.onboardingState: onboardingState.name,
      Fields.createdAt: Timestamp.fromDate(createdAt),
      Fields.updatedAt: updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'restrictions': restrictions,
      'restrictionEndDate': restrictionEndDate != null
          ? Timestamp.fromDate(restrictionEndDate!)
          : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      Fields.profile: profile.toMap(),
    };
  }

  AppUser copyWith({
    String? email,
    UserRole? role,
    UserStatus? status,
    OnboardingState? onboardingState,
    DateTime? updatedAt,
    Map<String, dynamic>? restrictions,
    DateTime? restrictionEndDate,
    DateTime? lastLoginAt,
    UserProfile? profile,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      onboardingState: onboardingState ?? this.onboardingState,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      restrictions: restrictions ?? this.restrictions,
      restrictionEndDate: restrictionEndDate ?? this.restrictionEndDate,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
    );
  }

  bool get isVerified => status == UserStatus.verified || status == UserStatus.active;
  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;
  bool get isRestricted => 
      status == UserStatus.restricted || 
      (restrictions != null && restrictionEndDate?.isAfter(DateTime.now()) == true);
  
  String get fullName => profile.fullName;
  
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Embedded user profile with role-specific fields
class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final Location? location;
  
  // Donor-specific fields
  final String? businessName;
  final String? businessType;
  final String? organizationType;
  
  // Volunteer-specific fields
  final bool? hasVehicle;
  final VehicleType? vehicleType;
  final int? maxRadius;
  final List<String>? availabilityHours;
  final List<String>? workingDays;
  final List<String>? preferredTasks;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? drivingLicense;
  final bool? isAvailable;
  final double? rating;
  final int? completedTasks;
  
  // NGO-specific fields (links to organization)
  final String? organizationId;
  
  UserProfile({
    this.firstName,
    this.lastName,
    this.phone,
    this.profileImageUrl,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.location,
    this.businessName,
    this.businessType,
    this.organizationType,
    this.hasVehicle,
    this.vehicleType,
    this.maxRadius,
    this.availabilityHours,
    this.workingDays,
    this.preferredTasks,
    this.emergencyContact,
    this.emergencyPhone,
    this.drivingLicense,
    this.isAvailable,
    this.rating,
    this.completedTasks,
    this.organizationId,
  });
  
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      location: data['location'] != null ? Location.fromJson(data['location']) : null,
      businessName: data['businessName'],
      businessType: data['businessType'],
      organizationType: data['organizationType'],
      hasVehicle: data['hasVehicle'],
      vehicleType: data['vehicleType'] != null
          ? VehicleType.values.firstWhere(
              (e) => e.name == data['vehicleType'],
              orElse: () => VehicleType.none,
            )
          : null,
      maxRadius: data['maxRadius'],
      availabilityHours: data['availabilityHours'] != null 
          ? List<String>.from(data['availabilityHours'])
          : null,
      workingDays: data['workingDays'] != null
          ? List<String>.from(data['workingDays'])
          : null,
      preferredTasks: data['preferredTasks'] != null
          ? List<String>.from(data['preferredTasks'])
          : null,
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      drivingLicense: data['drivingLicense'],
      isAvailable: data['isAvailable'],
      rating: (data['rating'] as num?)?.toDouble(),
      completedTasks: data['completedTasks'],
      organizationId: data['organizationId'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (location != null) 'location': location!.toJson(),
      if (businessName != null) 'businessName': businessName,
      if (businessType != null) 'businessType': businessType,
      if (organizationType != null) 'organizationType': organizationType,
      if (hasVehicle != null) 'hasVehicle': hasVehicle,
      if (vehicleType != null) 'vehicleType': vehicleType!.name,
      if (maxRadius != null) 'maxRadius': maxRadius,
      if (availabilityHours != null) 'availabilityHours': availabilityHours,
      if (workingDays != null) 'workingDays': workingDays,
      if (preferredTasks != null) 'preferredTasks': preferredTasks,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
      if (drivingLicense != null) 'drivingLicense': drivingLicense,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (rating != null) 'rating': rating,
      if (completedTasks != null) 'completedTasks': completedTasks,
      if (organizationId != null) 'organizationId': organizationId,
    };
  }
  
  String get fullName => '${firstName ?? ""} ${lastName ?? ""}'.trim();
  
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    Location? location,
    String? businessName,
    String? businessType,
    String? organizationType,
    bool? hasVehicle,
    VehicleType? vehicleType,
    int? maxRadius,
    List<String>? availabilityHours,
    List<String>? workingDays,
    List<String>? preferredTasks,
    String? emergencyContact,
    String? emergencyPhone,
    String? drivingLicense,
    bool? isAvailable,
    double? rating,
    int? completedTasks,
    String? organizationId,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      location: location ?? this.location,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      organizationType: organizationType ?? this.organizationType,
      hasVehicle: hasVehicle ?? this.hasVehicle,
      vehicleType: vehicleType ?? this.vehicleType,
      maxRadius: maxRadius ?? this.maxRadius,
      availabilityHours: availabilityHours ?? this.availabilityHours,
      workingDays: workingDays ?? this.workingDays,
      preferredTasks: preferredTasks ?? this.preferredTasks,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      completedTasks: completedTasks ?? this.completedTasks,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
