import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/utils/app_utils.dart';
import 'package:food_redistribution_app/constants/app_constants.dart';

void main() {
  group('Input Validation Tests', () {
    test('should validate email addresses correctly', () {
      // Valid emails
      expect(AppUtils.isValidEmail('test@example.com'), isTrue);
      expect(AppUtils.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(AppUtils.isValidEmail('user+tag@example.org'), isTrue);
      expect(AppUtils.isValidEmail('123@numbers.com'), isTrue);

      // Invalid emails
      expect(AppUtils.isValidEmail(''), isFalse);
      expect(AppUtils.isValidEmail('invalid-email'), isFalse);
      expect(AppUtils.isValidEmail('test@'), isFalse);
      expect(AppUtils.isValidEmail('@domain.com'), isFalse);
      expect(AppUtils.isValidEmail('test..test@domain.com'), isFalse);
      expect(AppUtils.isValidEmail('test@domain'), isFalse);
    });

    test('should validate phone numbers correctly', () {
      // Valid phone numbers
      expect(AppUtils.isValidPhoneNumber('+1234567890'), isTrue);
      expect(AppUtils.isValidPhoneNumber('+91 98765 43210'), isTrue);
      expect(AppUtils.isValidPhoneNumber('+44-20-1234-5678'), isTrue);
      expect(AppUtils.isValidPhoneNumber('(555) 123-4567'), isTrue);

      // Invalid phone numbers
      expect(AppUtils.isValidPhoneNumber(''), isFalse);
      expect(AppUtils.isValidPhoneNumber('123'), isFalse);
      expect(AppUtils.isValidPhoneNumber('abcd1234567890'), isFalse);
      expect(AppUtils.isValidPhoneNumber('++1234567890'), isFalse);
    });

    test('should validate passwords correctly', () {
      // Valid passwords
      expect(AppUtils.isValidPassword('StrongPass123!'), isTrue);
      expect(AppUtils.isValidPassword('MyP@ssw0rd'), isTrue);
      expect(AppUtils.isValidPassword('Complex1#'), isTrue);

      // Invalid passwords
      expect(AppUtils.isValidPassword(''), isFalse);
      expect(AppUtils.isValidPassword('short'), isFalse);
      expect(AppUtils.isValidPassword('onlylowercase'), isFalse);
      expect(AppUtils.isValidPassword('ONLYUPPERCASE'), isFalse);
      expect(AppUtils.isValidPassword('NoNumbers!'), isFalse);
      expect(AppUtils.isValidPassword('NoSpecialChars123'), isFalse);
    });

    test('should validate names correctly', () {
      // Valid names
      expect(AppUtils.isValidName('John Doe'), isTrue);
      expect(AppUtils.isValidName('Mary Jane Smith'), isTrue);
      expect(AppUtils.isValidName('José García'), isTrue);
      expect(AppUtils.isValidName("O'Connor"), isTrue);

      // Invalid names
      expect(AppUtils.isValidName(''), isFalse);
      expect(AppUtils.isValidName('  '), isFalse);
      expect(AppUtils.isValidName('123'), isFalse);
      expect(AppUtils.isValidName('John123'), isFalse);
      expect(AppUtils.isValidName('A'), isFalse); // Too short
    });

    test('should validate organization names correctly', () {
      // Valid organization names
      expect(AppUtils.isValidOrganizationName('Food Bank International'), isTrue);
      expect(AppUtils.isValidOrganizationName('Local Community Center'), isTrue);
      expect(AppUtils.isValidOrganizationName('Hope & Help Foundation'), isTrue);
      expect(AppUtils.isValidOrganizationName('Community Food Network'), isTrue);

      // Invalid organization names
      expect(AppUtils.isValidOrganizationName(''), isFalse);
      expect(AppUtils.isValidOrganizationName('A'), isFalse); // Too short
      expect(AppUtils.isValidOrganizationName('  '), isFalse);
    });
  });

  group('Date and Time Utilities Tests', () {
    test('should format dates correctly', () {
      final testDate = DateTime(2024, 1, 15, 14, 30, 0);
      
      expect(AppUtils.formatDate(testDate), equals('15/01/2024'));
      expect(AppUtils.formatTime(testDate), equals('14:30'));
      expect(AppUtils.formatDateTime(testDate), equals('15/01/2024 14:30'));
      expect(AppUtils.formatDateLong(testDate), equals('15 January 2024'));
    });

    test('should handle relative time formatting', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final yesterday = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      expect(AppUtils.formatRelativeTime(oneHourAgo), equals('1 hour ago'));
      expect(AppUtils.formatRelativeTime(yesterday), equals('1 day ago'));
      expect(AppUtils.formatRelativeTime(oneWeekAgo), equals('7 days ago'));
    });

    test('should calculate time until expiry', () {
      final now = DateTime.now();
      final inOneHour = now.add(const Duration(hours: 1));
      final inTwoDays = now.add(const Duration(days: 2));
      final expired = now.subtract(const Duration(hours: 1));

      expect(AppUtils.timeUntilExpiry(inOneHour), equals('1 hour remaining'));
      expect(AppUtils.timeUntilExpiry(inTwoDays), equals('2 days remaining'));
      expect(AppUtils.timeUntilExpiry(expired), equals('Expired'));
    });

    test('should check if food is expiring soon', () {
      final now = DateTime.now();
      final soonExpiry = now.add(const Duration(hours: 2));
      final laterExpiry = now.add(const Duration(days: 3));
      final expired = now.subtract(const Duration(hours: 1));

      expect(AppUtils.isExpiringSoon(soonExpiry), isTrue);
      expect(AppUtils.isExpiringSoon(laterExpiry), isFalse);
      expect(AppUtils.isExpiringSoon(expired), isTrue); // Already expired
    });
  });

  group('String Utilities Tests', () {
    test('should capitalize text correctly', () {
      expect(AppUtils.capitalize('hello world'), equals('Hello world'));
      expect(AppUtils.capitalize('HELLO WORLD'), equals('Hello world'));
      expect(AppUtils.capitalize(''), equals(''));
      expect(AppUtils.capitalize('a'), equals('A'));
    });

    test('should create initials from names', () {
      expect(AppUtils.getInitials('John Doe'), equals('JD'));
      expect(AppUtils.getInitials('Mary Jane Smith'), equals('MJS'));
      expect(AppUtils.getInitials('SingleName'), equals('S'));
      expect(AppUtils.getInitials(''), equals(''));
      expect(AppUtils.getInitials('a b c d e'), equals('ABCDE'));
    });

    test('should truncate text correctly', () {
      const longText = 'This is a very long text that should be truncated';
      
      expect(AppUtils.truncateText(longText, 20), equals('This is a very long...'));
      expect(AppUtils.truncateText('Short text', 50), equals('Short text'));
      expect(AppUtils.truncateText('', 10), equals(''));
      expect(AppUtils.truncateText('Exact length', 12), equals('Exact length'));
    });

    test('should clean and format text input', () {
      expect(AppUtils.cleanInput('  Hello World  '), equals('Hello World'));
      expect(AppUtils.cleanInput('Multiple   Spaces'), equals('Multiple Spaces'));
      expect(AppUtils.cleanInput('\n\tTabs and newlines\n'), equals('Tabs and newlines'));
    });

    test('should generate random strings', () {
      final random1 = AppUtils.generateRandomId();
      final random2 = AppUtils.generateRandomId();
      
      expect(random1.length, equals(8));
      expect(random2.length, equals(8));
      expect(random1, isNot(equals(random2)));
      
      final customLength = AppUtils.generateRandomId(length: 12);
      expect(customLength.length, equals(12));
    });
  });

  group('Number and Measurement Utilities Tests', () {
    test('should format quantities correctly', () {
      expect(AppUtils.formatQuantity(1, 'kg'), equals('1 kg'));
      expect(AppUtils.formatQuantity(5, 'pieces'), equals('5 pieces'));
      expect(AppUtils.formatQuantity(0.5, 'liters'), equals('0.5 liters'));
    });

    test('should format distances correctly', () {
      expect(AppUtils.formatDistance(0.5), equals('0.5 km'));
      expect(AppUtils.formatDistance(1.0), equals('1.0 km'));
      expect(AppUtils.formatDistance(0.1), equals('100 m'));
      expect(AppUtils.formatDistance(15.7), equals('15.7 km'));
    });

    test('should calculate BMI correctly', () {
      final bmi = AppUtils.calculateBMI(70.0, 1.75); // 70kg, 175cm
      expect(bmi, closeTo(22.86, 0.01));
      
      expect(() => AppUtils.calculateBMI(-70, 175), throwsArgumentError);
      expect(() => AppUtils.calculateBMI(70, 0), throwsArgumentError);
    });

    test('should format file sizes correctly', () {
      expect(AppUtils.formatFileSize(512), equals('512 B'));
      expect(AppUtils.formatFileSize(1024), equals('1.0 KB'));
      expect(AppUtils.formatFileSize(1536), equals('1.5 KB'));
      expect(AppUtils.formatFileSize(1048576), equals('1.0 MB'));
      expect(AppUtils.formatFileSize(1073741824), equals('1.0 GB'));
    });
  });

  group('Color Utilities Tests', () {
    test('should convert colors correctly', () {
      final color = AppUtils.hexToColor('#FF5722');
      expect(color.value, equals(0xFFFF5722));
      
      final colorNoHash = AppUtils.hexToColor('FF5722');
      expect(colorNoHash.value, equals(0xFFFF5722));
      
      expect(() => AppUtils.hexToColor('invalid'), throwsFormatException);
    });

    test('should determine text color on background', () {
      final lightBackground = AppUtils.hexToColor('#FFFFFF');
      final darkBackground = AppUtils.hexToColor('#000000');
      
      expect(AppUtils.getTextColorOnBackground(lightBackground), equals(AppColors.textDark));
      expect(AppUtils.getTextColorOnBackground(darkBackground), equals(AppColors.textLight));
    });

    test('should generate role-based colors', () {
      expect(AppUtils.getRoleColor(UserRole.donor), equals(AppColors.donorPrimary));
      expect(AppUtils.getRoleColor(UserRole.ngo), equals(AppColors.ngoPrimary));
      expect(AppUtils.getRoleColor(UserRole.volunteer), equals(AppColors.volunteerPrimary));
      expect(AppUtils.getRoleColor(UserRole.coordinator), equals(AppColors.coordinatorPrimary));
    });
  });

  group('Navigation Utilities Tests', () {
    test('should generate route names correctly', () {
      expect(AppUtils.generateRouteName('Home'), equals('/home'));
      expect(AppUtils.generateRouteName('User Profile'), equals('/user-profile'));
      expect(AppUtils.generateRouteName('NGO Dashboard'), equals('/ngo-dashboard'));
    });

    test('should parse route parameters', () {
      final params = AppUtils.parseRouteParams('/user/123/profile?tab=settings&edit=true');
      expect(params['tab'], equals('settings'));
      expect(params['edit'], equals('true'));
    });
  });

  group('Device Utilities Tests', () {
    test('should detect platform capabilities', () {
      // These would normally use Flutter's platform detection
      // For unit tests, we test the logic structure
      expect(AppUtils.isMobile(), isA<bool>());
      expect(AppUtils.isTablet(), isA<bool>());
      expect(AppUtils.isDesktop(), isA<bool>());
      expect(AppUtils.isWeb(), isA<bool>());
    });

    test('should calculate responsive values', () {
      expect(AppUtils.getResponsiveValue(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        screenWidth: 400, // Mobile width
      ), equals(16.0));

      expect(AppUtils.getResponsiveValue(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        screenWidth: 800, // Tablet width
      ), equals(20.0));

      expect(AppUtils.getResponsiveValue(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        screenWidth: 1200, // Desktop width
      ), equals(24.0));
    });
  });

  group('Geolocation Utilities Tests', () {
    test('should calculate distance between coordinates', () {
      // Distance from San Francisco to Los Angeles
      final distance = AppUtils.calculateDistance(
        37.7749, -122.4194, // San Francisco
        34.0522, -118.2437, // Los Angeles
      );
      
      expect(distance, greaterThan(500)); // Should be around 559 km
      expect(distance, lessThan(600));
    });

    test('should determine if location is within radius', () {
      const lat1 = 37.7749;
      const lon1 = -122.4194;
      const lat2 = 37.7849; // Very close to lat1
      const lon2 = -122.4094;
      
      expect(AppUtils.isWithinRadius(lat1, lon1, lat2, lon2, 5.0), isTrue);
      expect(AppUtils.isWithinRadius(lat1, lon1, lat2, lon2, 0.1), isFalse);
    });

    test('should format coordinates correctly', () {
      expect(AppUtils.formatCoordinates(37.7749, -122.4194), 
             equals('37.7749, -122.4194'));
      expect(AppUtils.formatCoordinates(0.0, 0.0), 
             equals('0.0000, 0.0000'));
    });
  });
}