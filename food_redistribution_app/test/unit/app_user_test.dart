import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/models/app_user.dart';
import 'package:food_redistribution_app/models/enums.dart';

void main() {
  group('AppUser Model Tests', () {
    late AppUser testUser;
    late Location testLocation;

    setUp(() {
      testLocation = Location(
        latitude: 37.7749,
        longitude: -122.4194,
        address: '123 Test Street, San Francisco, CA 94102',
      );

      testUser = AppUser(
        id: 'test-user-123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.donor,
        address: testLocation,
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: {'notifications': true, 'language': 'en'},
      );
    });

    test('should create AppUser with valid data', () {
      expect(testUser.id, equals('test-user-123'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.displayName, equals('Test User'));
      expect(testUser.role, equals(UserRole.donor));
      expect(testUser.location?.latitude, equals(37.7749));
      expect(testUser.isActive, isTrue);
    });

    test('should validate email format', () {
      expect(testUser.isValidEmail(), isTrue);
      
      final invalidUser = testUser.copyWith(email: 'invalid-email');
      expect(invalidUser.isValidEmail(), isFalse);
    });

    test('should handle role-based permissions for donor', () {
      expect(testUser.canCreateDonation(), isTrue);
      expect(testUser.canManageNGO(), isFalse);
      expect(testUser.canVolunteer(), isFalse);
      expect(testUser.canCoordinate(), isFalse);
    });

    test('should handle role-based permissions for NGO', () {
      final ngoUser = testUser.copyWith(role: UserRole.ngo);
      expect(ngoUser.canCreateDonation(), isFalse);
      expect(ngoUser.canManageNGO(), isTrue);
      expect(ngoUser.canVolunteer(), isFalse);
      expect(ngoUser.canCoordinate(), isFalse);
    });

    test('should handle role-based permissions for volunteer', () {
      final volunteerUser = testUser.copyWith(role: UserRole.volunteer);
      expect(volunteerUser.canCreateDonation(), isFalse);
      expect(volunteerUser.canManageNGO(), isFalse);
      expect(volunteerUser.canVolunteer(), isTrue);
      expect(volunteerUser.canCoordinate(), isFalse);
    });

    test('should handle role-based permissions for admin', () {
      final adminUser = testUser.copyWith(role: UserRole.admin);
      expect(adminUser.canCreateDonation(), isFalse);
      expect(adminUser.canManageNGO(), isFalse);
      expect(adminUser.canVolunteer(), isFalse);
      expect(adminUser.canCoordinate(), isTrue);
    });

    test('should handle user preferences', () {
      expect(testUser.getPreference('notifications'), isTrue);
      expect(testUser.getPreference('language'), equals('en'));
      expect(testUser.getPreference('nonexistent'), isNull);

      final updatedUser = testUser.setPreference('theme', 'dark');
      expect(updatedUser.getPreference('theme'), equals('dark'));
      expect(updatedUser.preferences.length, equals(3));
    });

    test('should convert to and from JSON', () {
      final json = testUser.toJson();
      
      expect(json['id'], equals('test-user-123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['role'], equals('donor'));
      expect(json['address'], isNotNull);

      final fromJson = AppUser.fromJson(json);
      expect(fromJson.id, equals(testUser.id));
      expect(fromJson.email, equals(testUser.email));
      expect(fromJson.role, equals(testUser.role));
      expect(fromJson.location?.latitude, equals(testUser.location?.latitude));
    });

    test('should handle copyWith method', () {
      final updatedUser = testUser.copyWith(
        firstName: 'Updated',
        lastName: 'Name',
        role: UserRole.volunteer,
      );

      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.role, equals(UserRole.volunteer));
      expect(updatedUser.id, equals(testUser.id)); // Unchanged
      expect(updatedUser.email, equals(testUser.email)); // Unchanged
    });

    test('should provide full name and display name', () {
      expect(testUser.fullName, equals('Test User'));
      expect(testUser.displayName, equals('Test User'));
      
      final noNameUser = testUser.copyWith(firstName: '', lastName: '');
      expect(noNameUser.displayName, equals('test@example.com')); // Falls back to email
    });
  });

  group('Location Model Tests', () {
    test('should create Location with valid coordinates', () {
      final location = Location(
        latitude: 40.7128,
        longitude: -74.0060,
        address: 'New York, NY',
      );

      expect(location.latitude, equals(40.7128));
      expect(location.longitude, equals(-74.0060));
      expect(location.address, equals('New York, NY'));
    });

    test('should calculate distance between locations', () {
      final location1 = Location(
        latitude: 40.7128,
        longitude: -74.0060,
        address: 'New York',
      );

      final location2 = Location(
        latitude: 34.0522,
        longitude: -118.2437,
        address: 'Los Angeles',
      );

      final distance = location1.distanceTo(location2);
      expect(distance, greaterThan(3500)); // Approximately 3944 km
      expect(distance, lessThan(4500));
    });

    test('should calculate short distance between nearby locations', () {
      final location1 = Location(
        latitude: 37.7749,
        longitude: -122.4194,
        address: 'San Francisco',
      );

      final location2 = Location(
        latitude: 37.7849,
        longitude: -122.4094,
        address: 'Near San Francisco',
      );

      final distance = location1.distanceTo(location2);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(2.0)); // Should be less than 2 km
    });

    test('should convert to and from JSON', () {
      final location = Location(
        latitude: 51.5074,
        longitude: -0.1278,
        address: 'London, UK',
      );

      final json = location.toJson();
      expect(json['latitude'], equals(51.5074));
      expect(json['longitude'], equals(-0.1278));
      expect(json['address'], equals('London, UK'));

      final fromJson = Location.fromJson(json);
      expect(fromJson.latitude, equals(location.latitude));
      expect(fromJson.longitude, equals(location.longitude));
      expect(fromJson.address, equals(location.address));
    });

    test('should provide full address', () {
      final location = Location(
        latitude: 48.8566,
        longitude: 2.3522,
        address: '123 Main St',
        city: 'Paris',
        state: 'Île-de-France',
        zipCode: '75001',
      );

      expect(location.fullAddress, contains('123 Main St'));
      expect(location.fullAddress, contains('Paris'));
    });
  });
}
