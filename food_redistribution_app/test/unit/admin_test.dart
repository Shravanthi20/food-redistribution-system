import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/models/food_donation.dart';
import 'package:food_redistribution_app/models/user.dart';
import 'package:food_redistribution_app/providers/admin_dashboard_provider.dart';
import 'package:food_redistribution_app/services/verification_service.dart';

void main() {
  group('Admin AppUser behavior', () {
    late Map<String, dynamic> baseAdminData;

    setUp(() {
      baseAdminData = {
        'email': 'admin@example.com',
        'role': UserRole.admin.name,
        'status': UserStatus.verified.name,
        'onboardingState': OnboardingState.verified.name,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'profile': {
          'firstName': 'System',
          'lastName': 'Admin',
        },
      };
    });

    test('fromMap maps admin fields and computed getters correctly', () {
      final admin = AppUser.fromMap(baseAdminData, id: 'admin-1');

      expect(admin.uid, 'admin-1');
      expect(admin.role, UserRole.admin);
      expect(admin.isVerified, isTrue);
      expect(admin.isRestricted, isFalse);
      expect(admin.fullName, 'System Admin');
    });

    test('isRestricted returns true when restrictions are active', () {
      final admin = AppUser.fromMap(
        {
          ...baseAdminData,
          'status': UserStatus.active.name,
          'restrictionEndDate':
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'restrictions': {'all': true},
          'profile': {
            'firstName': 'Ops',
            'lastName': 'Admin',
          },
        },
        id: 'admin-2',
      );

      expect(admin.role, UserRole.admin);
      expect(admin.isActive, isTrue);
      expect(admin.isRestricted, isTrue);
    });

    test('isRestricted returns false when restriction end date is in the past',
        () {
      final admin = AppUser.fromMap(
        {
          ...baseAdminData,
          'status': UserStatus.active.name,
          'restrictionEndDate':
              DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'restrictions': {'all': true},
        },
        id: 'admin-archived',
      );

      expect(admin.isRestricted, isFalse);
    });

    test('copyWith preserves admin identity while updating mutable fields', () {
      final admin = AppUser.fromMap(
        {
          ...baseAdminData,
          'status': UserStatus.pending.name,
          'onboardingState': OnboardingState.registered.name,
          'profile': {
            'firstName': 'Review',
            'lastName': 'Admin',
          },
        },
        id: 'admin-3',
      );

      final updated = admin.copyWith(
        status: UserStatus.active,
        onboardingState: OnboardingState.verified,
      );

      expect(updated.uid, admin.uid);
      expect(updated.role, UserRole.admin);
      expect(updated.status, UserStatus.active);
      expect(updated.onboardingState, OnboardingState.verified);
      expect(updated.fullName, 'Review Admin');
    });
  });

  group('AdminDashboardProvider admin actions', () {
    late AdminDashboardProvider provider;
    late Map<UserRole, List<Map<String, dynamic>>> usersByRole;
    late List<Map<String, dynamic>> pendingVerifications;
    late Map<String, dynamic> verificationStats;
    late List<FoodDonation> unmatchedDonations;

    final requestedRoles = <UserRole>[];
    final reviewCalls = <Map<String, dynamic>>[];
    final restrictionCalls = <Map<String, dynamic>>[];
    final ngoAssignmentCalls = <Map<String, dynamic>>[];
    final volunteerAssignmentCalls = <Map<String, dynamic>>[];

    setUp(() {
      requestedRoles.clear();
      reviewCalls.clear();
      restrictionCalls.clear();
      ngoAssignmentCalls.clear();
      volunteerAssignmentCalls.clear();

      usersByRole = {};
      pendingVerifications = [];
      verificationStats = {};
      unmatchedDonations = [];

      provider = AdminDashboardProvider(
        enableRealtime: false,
        getUsersByRole: (role) async {
          requestedRoles.add(role);
          return usersByRole[role] ?? const [];
        },
        reviewVerification: ({
          required submissionId,
          required adminId,
          required decision,
          String? notes,
        }) async {
          reviewCalls.add({
            'submissionId': submissionId,
            'adminId': adminId,
            'decision': decision,
            'notes': notes,
          });
        },
        restrictUser: ({
          required userId,
          required adminId,
          required restrictions,
          required endDate,
          String? reason,
        }) async {
          restrictionCalls.add({
            'userId': userId,
            'adminId': adminId,
            'restrictions': restrictions,
            'endDate': endDate,
            'reason': reason,
          });
        },
        forceAssignNgo: ({
          required donationId,
          required adminId,
          required ngoId,
          String? reason,
        }) async {
          ngoAssignmentCalls.add({
            'donationId': donationId,
            'adminId': adminId,
            'ngoId': ngoId,
            'reason': reason,
          });
        },
        forceAssignVolunteer: ({
          required donationId,
          required adminId,
          required volunteerId,
          String? reason,
        }) async {
          volunteerAssignmentCalls.add({
            'donationId': donationId,
            'adminId': adminId,
            'volunteerId': volunteerId,
            'reason': reason,
          });
        },
        getPendingVerifications: () async => pendingVerifications,
        getVerificationStats: () async => verificationStats,
        getDonationsByStatus: (status) async => unmatchedDonations,
      );
    });

    test('searchUsers queries all governance roles and filters by name', () async {
      usersByRole = {
        UserRole.donor: [
          {'id': 'donor-1', 'fullName': 'Alice Donor', 'email': 'alice@test.dev'}
        ],
        UserRole.ngo: [
          {'id': 'ngo-1', 'fullName': 'Care NGO', 'email': 'contact@care.test'}
        ],
        UserRole.volunteer: [
          {'id': 'vol-1', 'firstName': 'Bob', 'email': 'bob@volunteer.test'}
        ],
        UserRole.admin: [
          {'id': 'admin-1', 'fullName': 'Ops Admin', 'email': 'ops@admin.test'}
        ],
      };

      await provider.searchUsers('alice');

      expect(requestedRoles, [
        UserRole.donor,
        UserRole.ngo,
        UserRole.volunteer,
        UserRole.admin,
      ]);
      expect(provider.isLoading, isFalse);
      expect(provider.allUsers, hasLength(1));
      expect(provider.allUsers.single['id'], 'donor-1');
      expect(provider.errorMessage, isNull);
    });

    test('searchUsers returns early for blank queries', () async {
      await provider.searchUsers('   ');

      expect(requestedRoles, isEmpty);
      expect(provider.allUsers, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('reviewVerification refreshes admin verification state on success',
        () async {
      pendingVerifications = [
        {
          'id': 'submission-2',
          'user': {'role': UserRole.ngo.name, 'email': 'ngo@test.dev'},
          'submission': {'submittedAt': DateTime(2026, 1, 1).toIso8601String()},
        }
      ];
      verificationStats = {
        'pendingCount': 1,
        'approvedCount': 3,
      };

      final result = await provider.reviewVerification(
        'submission-1',
        'admin-1',
        VerificationStatus.approved,
        'Looks valid',
      );

      expect(result, isTrue);
      expect(reviewCalls.single['submissionId'], 'submission-1');
      expect(reviewCalls.single['adminId'], 'admin-1');
      expect(reviewCalls.single['decision'], VerificationStatus.approved);
      expect(reviewCalls.single['notes'], 'Looks valid');
      expect(provider.pendingVerifications, hasLength(1));
      expect(provider.verificationStats['approvedCount'], 3);
      expect(provider.errorMessage, isNull);
    });

    test('reviewVerification stores an error and returns false on failure',
        () async {
      provider = AdminDashboardProvider(
        enableRealtime: false,
        reviewVerification: ({
          required submissionId,
          required adminId,
          required decision,
          String? notes,
        }) async {
          throw StateError('review failed');
        },
        getPendingVerifications: () async => pendingVerifications,
        getVerificationStats: () async => verificationStats,
        getDonationsByStatus: (status) async => unmatchedDonations,
      );

      final result = await provider.reviewVerification(
        'submission-1',
        'admin-1',
        VerificationStatus.rejected,
        'Missing documents',
      );

      expect(result, isFalse);
      expect(provider.errorMessage, contains('Review failed'));
    });

    test('suspendUser sends a full restriction payload', () async {
      final endDate = DateTime(2026, 4, 1);

      final result = await provider.suspendUser(
        'user-42',
        'admin-1',
        'Policy violation',
        endDate,
      );

      expect(result, isTrue);
      expect(restrictionCalls.single['userId'], 'user-42');
      expect(restrictionCalls.single['adminId'], 'admin-1');
      expect(restrictionCalls.single['restrictions'], {'all': true});
      expect(restrictionCalls.single['reason'], 'Policy violation');
      expect(restrictionCalls.single['endDate'], endDate);
    });

    test('forceAssignNGO delegates override and refreshes unmatched donations',
        () async {
      final donation = _buildDonation(id: 'donation-remaining');
      unmatchedDonations = [donation];

      final result = await provider.forceAssignNGO(
        'donation-1',
        'admin-1',
        'ngo-22',
        'Manual rescue required',
      );

      expect(result, isTrue);
      expect(ngoAssignmentCalls.single['donationId'], 'donation-1');
      expect(ngoAssignmentCalls.single['adminId'], 'admin-1');
      expect(ngoAssignmentCalls.single['ngoId'], 'ngo-22');
      expect(ngoAssignmentCalls.single['reason'], 'Manual rescue required');
      expect(provider.unmatchedDonations, [donation]);
    });

    test('forceAssignVolunteer delegates override and refreshes unmatched donations',
        () async {
      final donation = _buildDonation(id: 'donation-queued');
      unmatchedDonations = [donation];

      final result = await provider.forceAssignVolunteer(
        'donation-1',
        'admin-1',
        'volunteer-8',
        'Emergency pickup reassignment',
      );

      expect(result, isTrue);
      expect(volunteerAssignmentCalls.single['donationId'], 'donation-1');
      expect(volunteerAssignmentCalls.single['adminId'], 'admin-1');
      expect(volunteerAssignmentCalls.single['volunteerId'], 'volunteer-8');
      expect(
        volunteerAssignmentCalls.single['reason'],
        'Emergency pickup reassignment',
      );
      expect(provider.unmatchedDonations, [donation]);
    });

    test('forceAssignVolunteer stores an error and returns false on failure',
        () async {
      provider = AdminDashboardProvider(
        enableRealtime: false,
        forceAssignVolunteer: ({
          required donationId,
          required adminId,
          required volunteerId,
          String? reason,
        }) async {
          throw StateError('assignment failed');
        },
        getPendingVerifications: () async => pendingVerifications,
        getVerificationStats: () async => verificationStats,
        getDonationsByStatus: (status) async => unmatchedDonations,
      );

      final result = await provider.forceAssignVolunteer(
        'donation-1',
        'admin-1',
        'volunteer-8',
        'Emergency pickup reassignment',
      );

      expect(result, isFalse);
      expect(provider.errorMessage, contains('Volunteer assignment failed'));
    });
  });
}

FoodDonation _buildDonation({required String id}) {
  final now = DateTime(2026, 1, 1, 12);
  return FoodDonation(
    id: id,
    donorId: 'donor-1',
    title: 'Cooked Meals',
    description: 'Fresh lunch packs',
    foodTypes: const [FoodType.cooked],
    quantity: 25,
    unit: 'meals',
    preparedAt: now.subtract(const Duration(hours: 1)),
    expiresAt: now.add(const Duration(hours: 4)),
    availableFrom: now,
    availableUntil: now.add(const Duration(hours: 2)),
    safetyLevel: FoodSafetyLevel.high,
    requiresRefrigeration: false,
    isVegetarian: true,
    isVegan: false,
    isHalal: false,
    images: const [],
    pickupLocation: const {'latitude': 12.0, 'longitude': 77.0},
    pickupAddress: 'Test pickup address',
    donorContactPhone: '9999999999',
    status: DonationStatus.listed,
    createdAt: now,
  );
}
