import 'package:flutter/material.dart';

// App Constants
class AppConstants {
  static const String appName = 'Food Redistribution Platform';
  static const String appSlogan = 'Reducing food waste, feeding communities';
  static const String appVersion = '1.0.0';
  
  // API Endpoints (when backend is integrated)
  static const String baseUrl = 'https://api.foodredistribution.app';
  static const String donationsEndpoint = '/donations';
  static const String usersEndpoint = '/users';
  static const String volunteersEndpoint = '/volunteers';
  static const String analyticsEndpoint = '/analytics';
}

// Color Schemes for different user roles
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  
  // Role-based Colors
  static const Color donorColor = Color(0xFF2196F3);
  static const Color ngoColor = Color(0xFFFF9800);
  static const Color volunteerColor = Color(0xFF4CAF50);
  
  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surfaceColor,
  );
}

// Spacing Constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border Radius Constants
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 50.0;
}

// Animation Durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

// Food categories are handled by FoodType in food_donation.dart

// App Assets (when actual assets are added)
class AppAssets {
  static const String logoPath = 'assets/images/logo.png';
  static const String donorIcon = 'assets/icons/donor.png';
  static const String ngoIcon = 'assets/icons/ngo.png';
  static const String volunteerIcon = 'assets/icons/volunteer.png';
}

// API Response Keys
class ApiKeys {
  static const String success = 'success';
  static const String message = 'message';
  static const String data = 'data';
  static const String error = 'error';
  static const String token = 'token';
  static const String userId = 'user_id';
}

// SharedPreferences Keys
class PreferenceKeys {
  static const String isLoggedIn = 'is_logged_in';
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String lastSyncTime = 'last_sync_time';
}

// Validation Constants
class ValidationConstants {
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxAddressLength = 200;
  
  // RegExp patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[+]?[\d\s\-\(\)]{10,}$';
  static const String namePattern = r'^[a-zA-Z\s]+$';
}

// Network Constants
class NetworkConstants {
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int maxRetryAttempts = 3;
}

// Notification Types
enum NotificationType {
  donation,
  delivery,
  volunteer,
  system,
  reminder,
  alert,
}
