import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/utils/app_utils.dart';
import 'package:food_redistribution_app/models/enums.dart';

void main() {
  group('Input Validation Tests', () {
    test('should validate email addresses correctly', () {
      // Valid emails
      expect(AppUtils.isValidEmail('test@example.com'), isTrue);
      expect(AppUtils.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(AppUtils.isValidEmail('user+tag@example.org'), isTrue);

      // Invalid emails
      expect(AppUtils.isValidEmail(''), isFalse);
      expect(AppUtils.isValidEmail('invalid-email'), isFalse);
      expect(AppUtils.isValidEmail('test@'), isFalse);
      expect(AppUtils.isValidEmail('@domain.com'), isFalse);
    });

    test('should validate phone numbers correctly', () {
      // Valid phone numbers
      expect(AppUtils.isValidPhone('+1234567890'), isTrue);
      expect(AppUtils.isValidPhone('1234567890'), isTrue);

      // Invalid phone numbers
      expect(AppUtils.isValidPhone(''), isFalse);
      expect(AppUtils.isValidPhone('123'), isFalse);
    });

    test('should validate passwords correctly', () {
      // Valid passwords (8+ characters)
      expect(AppUtils.isValidPassword('StrongPass123!'), isTrue);
      expect(AppUtils.isValidPassword('MyPassword'), isTrue);

      // Invalid passwords
      expect(AppUtils.isValidPassword(''), isFalse);
      expect(AppUtils.isValidPassword('short'), isFalse);
    });

    test('should validate names correctly', () {
      // Valid names
      expect(AppUtils.isValidName('John Doe'), isTrue);
      expect(AppUtils.isValidName('Mary Jane Smith'), isTrue);

      // Invalid names
      expect(AppUtils.isValidName(''), isFalse);
      expect(AppUtils.isValidName('A'), isFalse); // Too short
    });
  });

  group('Date and Time Utilities Tests', () {
    test('should format dates correctly', () {
      final testDate = DateTime(2024, 1, 15, 14, 30, 0);
      
      expect(AppUtils.formatDate(testDate), isA<String>());
      expect(AppUtils.formatTime(testDate), isA<String>());
      expect(AppUtils.formatDateTime(testDate), isA<String>());
    });

    test('should handle relative time formatting', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final yesterday = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      expect(AppUtils.getTimeAgo(oneHourAgo), contains('hour'));
      expect(AppUtils.getTimeAgo(yesterday), contains('day'));
      expect(AppUtils.getTimeAgo(oneWeekAgo), contains('days'));
    });

    test('should detect food expiry status', () {
      final now = DateTime.now();
      final soonExpiry = now.add(const Duration(hours: 12));
      final laterExpiry = now.add(const Duration(days: 3));
      final expired = now.subtract(const Duration(hours: 1));

      expect(AppUtils.isFoodExpiringSoon(soonExpiry), isTrue);
      expect(AppUtils.isFoodExpiringSoon(laterExpiry), isFalse);
      expect(AppUtils.isFoodExpired(expired), isTrue);
    });
  });

  group('String Utilities Tests', () {
    test('should capitalize strings', () {
      expect(AppUtils.capitalize('hello'), equals('Hello'));
      expect(AppUtils.capitalize('WORLD'), equals('World'));
      expect(AppUtils.capitalize(''), equals(''));
    });

    test('should truncate text correctly', () {
      expect(AppUtils.truncateText('Hello World', 5), equals('Hello...'));
      expect(AppUtils.truncateText('Hi', 10), equals('Hi'));
    });

    test('should format phone numbers', () {
      expect(AppUtils.formatPhoneNumber('1234567890'), contains('('));
    });
  });

  group('Quantity and Weight Utilities Tests', () {
    test('should format quantities correctly', () {
      expect(AppUtils.formatQuantity(1, 'apple'), equals('1 apple'));
      expect(AppUtils.formatQuantity(5, 'meal'), equals('5 meals'));
      expect(AppUtils.formatQuantity(0, 'item'), equals('0 items'));
    });

    test('should format weight correctly', () {
      expect(AppUtils.formatWeight(5.0), equals('5kg'));
      expect(AppUtils.formatWeight(0.5), contains('g')); // Should convert to grams
    });

    test('should format distance correctly', () {
      expect(AppUtils.formatDistance(5.5), equals('5.5km'));
      expect(AppUtils.formatDistance(0.5), contains('m')); // Should be in meters
    });
  });

  group('Priority and Role Color Tests', () {
    test('should get role colors', () {
      expect(AppUtils.getRoleColor(UserRole.donor), isA<Object>());
      expect(AppUtils.getRoleColor(UserRole.ngo), isA<Object>());
      expect(AppUtils.getRoleColor(UserRole.volunteer), isA<Object>());
    });

    test('should get status colors', () {
      expect(AppUtils.getStatusColor(DonationStatus.listed), isA<Object>());
      expect(AppUtils.getStatusColor(DonationStatus.delivered), isA<Object>());
      expect(AppUtils.getStatusColor(DonationStatus.cancelled), isA<Object>());
    });

    test('should get priority colors', () {
      expect(AppUtils.getPriorityColor(Priority.low), isA<Object>());
      expect(AppUtils.getPriorityColor(Priority.high), isA<Object>());
      expect(AppUtils.getPriorityColor(Priority.urgent), isA<Object>());
    });
  });

  group('Business Logic Tests', () {
    test('should calculate food priority based on expiry', () {
      final now = DateTime.now();
      final almostExpired = now.add(const Duration(hours: 1));
      final soonExpiring = now.add(const Duration(hours: 6));
      final normalExpiry = now.add(const Duration(hours: 20));

      expect(AppUtils.calculateFoodPriority(almostExpired, 10), equals(Priority.urgent));
      expect(AppUtils.calculateFoodPriority(soonExpiring, 10), equals(Priority.high));
      expect(AppUtils.calculateFoodPriority(normalExpiry, 10), equals(Priority.normal));
    });

    test('should calculate impact score', () {
      final score = AppUtils.calculateImpactScore(10.0, 50);
      expect(score, greaterThan(0));
    });
  });

  group('Location Utilities Tests', () {
    test('should calculate distance between coordinates', () {
      // New York to Los Angeles
      final double lat1 = 40.7128;
      final double lon1 = -74.0060;
      final double lat2 = 34.0522;
      final double lon2 = -118.2437;

      final distance = AppUtils.calculateDistance(lat1, lon1, lat2, lon2);
      expect(distance, greaterThan(3500)); // Approximately 3944 km
      expect(distance, lessThan(4500));
    });

    test('should calculate short distances', () {
      // Two points close together in San Francisco
      final distance = AppUtils.calculateDistance(37.7749, -122.4194, 37.7849, -122.4094);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(2.0)); // Should be less than 2 km
    });
  });

  group('Random ID Generation Tests', () {
    test('should generate random IDs of specified length', () {
      final id1 = AppUtils.generateRandomId(length: 10);
      final id2 = AppUtils.generateRandomId(length: 10);
      
      expect(id1.length, equals(10));
      expect(id2.length, equals(10));
      expect(id1, isNot(equals(id2))); // Should be unique
    });

    test('should use default length of 20', () {
      final id = AppUtils.generateRandomId();
      expect(id.length, equals(20));
    });
  });

  group('DateTime Extension Tests', () {
    test('should correctly identify today', () {
      final now = DateTime.now();
      expect(now.isToday, isTrue);
      
      final yesterday = now.subtract(const Duration(days: 1));
      expect(yesterday.isToday, isFalse);
    });

    test('should correctly identify yesterday', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(yesterday.isYesterday, isTrue);
      expect(now.isYesterday, isFalse);
    });

    test('should correctly identify tomorrow', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      expect(tomorrow.isTomorrow, isTrue);
      expect(now.isTomorrow, isFalse);
    });
  });
}
