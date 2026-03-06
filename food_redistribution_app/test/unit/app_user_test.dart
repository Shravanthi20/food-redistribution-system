import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/models/app_user.dart';
import 'package:food_redistribution_app/constants/app_constants.dart';

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
        displayName: 'Test User',
        role: UserRole.donor,
        location: testLocation,
        isActive: true,
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

    test('should handle role-based permissions', () {
      // Test donor role
      expect(testUser.canCreateDonation(), isTrue);
      expect(testUser.canManageNGO(), isFalse);
      expect(testUser.canVolunteer(), isFalse);
      expect(testUser.canCoordinate(), isFalse);

      // Test NGO role
      final ngoUser = testUser.copyWith(role: UserRole.ngo);
      expect(ngoUser.canCreateDonation(), isFalse);
      expect(ngoUser.canManageNGO(), isTrue);
      expect(ngoUser.canVolunteer(), isFalse);
      expect(ngoUser.canCoordinate(), isFalse);

      // Test volunteer role
      final volunteerUser = testUser.copyWith(role: UserRole.volunteer);
      expect(volunteerUser.canCreateDonation(), isFalse);
      expect(volunteerUser.canManageNGO(), isFalse);
      expect(volunteerUser.canVolunteer(), isTrue);
      expect(volunteerUser.canCoordinate(), isFalse);

      // Test coordinator role
      final coordinatorUser = testUser.copyWith(role: UserRole.coordinator);
      expect(coordinatorUser.canCreateDonation(), isTrue);
      expect(coordinatorUser.canManageNGO(), isTrue);
      expect(coordinatorUser.canVolunteer(), isTrue);
      expect(coordinatorUser.canCoordinate(), isTrue);
    });

    test('should calculate distance between users', () {
      final user1Location = Location(
        latitude: 37.7749,
        longitude: -122.4194,
        address: 'San Francisco',
      );
      
      final user2Location = Location(
        latitude: 37.7849,
        longitude: -122.4094,
        address: 'Near San Francisco',
      );

      final user1 = testUser.copyWith(location: user1Location);
      final user2 = testUser.copyWith(
        id: 'user-2',
        location: user2Location,
      );

      final distance = user1.distanceToUser(user2);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(2.0)); // Should be less than 2 km
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
      expect(json['location'], isNotNull);

      final fromJson = AppUser.fromJson(json);
      expect(fromJson.id, equals(testUser.id));
      expect(fromJson.email, equals(testUser.email));
      expect(fromJson.role, equals(testUser.role));
      expect(fromJson.location?.latitude, equals(testUser.location?.latitude));
    });

    test('should handle copyWith method', () {
      final updatedUser = testUser.copyWith(
        displayName: 'Updated Name',
        role: UserRole.volunteer,
      );

      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.role, equals(UserRole.volunteer));
      expect(updatedUser.id, equals(testUser.id)); // Unchanged
      expect(updatedUser.email, equals(testUser.email)); // Unchanged
    });

    test('should validate required fields', () {
      expect(() => AppUser(
        id: '',
        email: 'test@example.com',
        displayName: 'Test',
        role: UserRole.donor,
        isActive: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      ), throwsAssertionError);

      expect(() => AppUser(
        id: 'test-id',
        email: '',
        displayName: 'Test',
        role: UserRole.donor,
        isActive: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      ), throwsAssertionError);
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

    test('should validate coordinate ranges', () {
      expect(() => Location(
        latitude: 91.0, // Invalid latitude
        longitude: -74.0060,
        address: 'Invalid',
      ), throwsAssertionError);

      expect(() => Location(
        latitude: 40.7128,
        longitude: 181.0, // Invalid longitude
        address: 'Invalid',
      ), throwsAssertionError);
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

    test('should provide human-readable string representation', () {
      final location = Location(
        latitude: 48.8566,
        longitude: 2.3522,
        address: 'Paris, France',
      );

      final string = location.toString();
      expect(string, contains('48.8566'));
      expect(string, contains('2.3522'));
      expect(string, contains('Paris, France'));
    });
  });
}