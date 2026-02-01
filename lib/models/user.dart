import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { donor, ngo, volunteer, admin }

enum UserStatus { pending, verified, active, suspended, restricted }

enum OnboardingState {
  registered,
  documentSubmitted,
  verified,
  profileComplete,
  active
}

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

  // Profile information
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImageUrl;

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
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
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
    );
  }

  bool get isVerified => status == UserStatus.verified || status == UserStatus.active;
  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;
  bool get isRestricted => 
      status == UserStatus.restricted || 
      (restrictions != null && restrictionEndDate?.isAfter(DateTime.now()) == true);
}