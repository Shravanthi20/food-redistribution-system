import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'location.dart';

export 'enums.dart';
export 'location.dart';

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

  // Profile information
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImageUrl;
  final Location? address;

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
    this.firstName,
    this.lastName,
    this.phone,
    this.profileImageUrl,
    this.address,
    this.lastLoginAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.donor,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.pending,
      ),
      onboardingState: OnboardingState.values.firstWhere(
        (e) => e.name == data['onboardingState'],
        orElse: () => OnboardingState.registered,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      restrictions: data['restrictions'],
      restrictionEndDate: data['restrictionEndDate'] != null
          ? (data['restrictionEndDate'] as Timestamp).toDate()
          : null,
      firstName: data['firstName'] ?? data['first_name'],
      lastName: data['lastName'] ?? data['last_name'],
      phone: data['phone'] ?? data['phone_number'],
      profileImageUrl: data['profileImageUrl'] ?? data['profile_image_url'],
      address: data['address'] != null ? Location.fromJson(data['address']) : null,
      lastLoginAt: data['lastLoginAt'] != null 
          ? (data['lastLoginAt'] is Timestamp 
              ? (data['lastLoginAt'] as Timestamp).toDate() 
              : DateTime.parse(data['lastLoginAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.name,
      'status': status.name,
      'onboardingState': onboardingState.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'restrictions': restrictions,
      'restrictionEndDate': restrictionEndDate != null
          ? Timestamp.fromDate(restrictionEndDate!)
          : null,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'address': address?.toJson(),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
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
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    Location? address,
    DateTime? lastLoginAt,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool get isVerified => status == UserStatus.verified || status == UserStatus.active;
  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;
  bool get isRestricted => 
      status == UserStatus.restricted || 
      (restrictions != null && restrictionEndDate?.isAfter(DateTime.now()) == true);
  
  String get fullName => '${firstName ?? ""} ${lastName ?? ""}'.trim();
}
