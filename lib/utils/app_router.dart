import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/donor_registration_screen.dart';
import '../screens/auth/ngo_registration_screen.dart';
import '../screens/auth/volunteer_registration_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/donor/donor_dashboard.dart';
import '../screens/donor/create_donation_screen.dart';
import '../screens/ngo/ngo_dashboard.dart';
import '../screens/volunteer/volunteer_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String roleSelection = '/role-selection';
  static const String donorRegistration = '/donor-registration';
  static const String ngoRegistration = '/ngo-registration';
  static const String volunteerRegistration = '/volunteer-registration';
  static const String emailVerification = '/email-verification';
  static const String onboarding = '/onboarding';
  static const String donorDashboard = '/donor-dashboard';
  static const String ngoDashboard = '/ngo-dashboard';
  static const String volunteerDashboard = '/volunteer-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String createDonation = '/create-donation';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      
      case donorRegistration:
        return MaterialPageRoute(builder: (_) => const DonorRegistrationScreen());
      
      case ngoRegistration:
        return MaterialPageRoute(builder: (_) => const NGORegistrationScreen());
      
      case volunteerRegistration:
        return MaterialPageRoute(builder: (_) => const VolunteerRegistrationScreen());
      
      case emailVerification:
        return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());
      
      case onboarding:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            userRole: args?['userRole'],
          ),
        );
      
      case donorDashboard:
        return MaterialPageRoute(builder: (_) => const DonorDashboard());
      
      case ngoDashboard:
        return MaterialPageRoute(builder: (_) => const NGODashboard());
      
      case volunteerDashboard:
        return MaterialPageRoute(builder: (_) => const VolunteerDashboard());
      
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      
      case createDonation:
        return MaterialPageRoute(builder: (_) => const CreateDonationScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}