import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/enums.dart';

class AppUtils {
  
  // Date Formatting Utilities
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }
  
  static String formatTime(DateTime time, {bool is24Hour = false}) {
    return DateFormat(is24Hour ? 'HH:mm' : 'h:mm a').format(time);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - h:mm a').format(dateTime);
  }
  
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Validation Utilities
  static bool isValidEmail(String email) {
    return RegExp(ValidationConstants.emailPattern).hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(ValidationConstants.phonePattern).hasMatch(phone);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= ValidationConstants.minPasswordLength &&
           password.length <= ValidationConstants.maxPasswordLength;
  }
  
  static bool isValidName(String name) {
    return name.length >= ValidationConstants.minNameLength &&
           name.length <= ValidationConstants.maxNameLength &&
           RegExp(ValidationConstants.namePattern).hasMatch(name);
  }
  
  // String Utilities
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format as (XXX) XXX-XXXX for US numbers
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
    
    return phone; // Return original if not a standard format
  }
  
  // Color Utilities
  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return AppColors.donorColor;
      case UserRole.ngo:
        return AppColors.ngoColor;
      case UserRole.volunteer:
        return AppColors.volunteerColor;
      default:
        return AppColors.primary;
    }
  }
  
  static Color getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return AppColors.successColor;
      case DonationStatus.matched:
        return AppColors.warningColor;
      case DonationStatus.pickedUp:
        return AppColors.infoColor;
      case DonationStatus.delivered:
        return AppColors.successColor;
      case DonationStatus.expired:
      case DonationStatus.cancelled:
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }
  
  static Color getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.normal:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      case Priority.urgent:
        return Colors.red.shade800;
      default:
        return AppColors.textSecondary;
    }
  }
  
  // UI Utilities
  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.primary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }
  
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppColors.errorColor);
  }
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppColors.successColor);
  }
  
  static Future<bool?> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppSpacing.md),
            Text(message),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }
  
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // Navigation Utilities
  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  static void navigateAndReplace(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  static void navigateAndClearStack(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }
  
  // Data Formatting Utilities
  static String formatWeight(double weight, {String unit = 'kg'}) {
    if (weight < 1 && unit == 'kg') {
      return '${(weight * 1000).toStringAsFixed(0)}g';
    }
    return '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)}$unit';
  }
  
  static String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }
  
  static String formatQuantity(int quantity, String item) {
    return '$quantity ${quantity == 1 ? item : '${item}s'}';
  }
  
  // Business Logic Utilities
  static bool isFoodExpiringSoon(DateTime expiryDate, {int warningHours = 24}) {
    final now = DateTime.now();
    final warningTime = expiryDate.subtract(Duration(hours: warningHours));
    return now.isAfter(warningTime);
  }
  
  static bool isFoodExpired(DateTime expiryDate) {
    return DateTime.now().isAfter(expiryDate);
  }
  
  static Priority calculateFoodPriority(DateTime expiryDate, double quantity) {
    final hoursUntilExpiry = expiryDate.difference(DateTime.now()).inHours;
    
    if (hoursUntilExpiry <= 2) {
      return Priority.urgent;
    } else if (hoursUntilExpiry <= 8) {
      return Priority.high;
    } else if (hoursUntilExpiry <= 24 || quantity > 50) {
      return Priority.normal;
    } else {
      return Priority.low;
    }
  }
  
  static double calculateImpactScore(double foodWeight, int beneficiaries) {
    // Simple impact calculation: food weight * beneficiaries * sustainability factor
    return foodWeight * beneficiaries * 0.8;
  }
  
  // Location Utilities
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    // Haversine formula for calculating distance between two coordinates
    const double earthRadius = 6371; // km
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        (sin(dLon / 2) * sin(dLon / 2));
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }
  
  // Device Utilities
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  // Logging Utility
  static void logInfo(String message) {
    debugPrint('[INFO] $message');
  }
  
  static void logError(String message, [dynamic error]) {
    debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
  }
  
  static void logWarning(String message) {
    debugPrint('[WARNING] $message');
  }

  static String generateRandomId({int length = 20}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}

// DateTime extension helpers
extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
}
