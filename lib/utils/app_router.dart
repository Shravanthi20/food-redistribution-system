import 'package:flutter/material.dart';
import '../models/food_donation.dart';
// Auth screens
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/donor_registration_screen.dart';
import '../screens/auth/ngo_registration_screen.dart';
import '../screens/auth/volunteer_registration_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/forgot_password_screen.dart'; // [NEW] Import
import '../screens/donor/donor_dashboard.dart';
import '../screens/donor/create_donation_screen.dart';
import '../screens/donor/donation_list_screen.dart';
import '../screens/donor/donation_detail_screen.dart';
import '../screens/donor/impact_reports_screen.dart';

// NGO extra screens
import '../screens/ngo/clarify_request_screen.dart';
import '../screens/ngo/reject_donation_screen.dart';
import '../screens/ngo/inspect_delivery_screen.dart';
import '../screens/ngo/ngo_dashboard.dart';
import '../screens/ngo/update_demand_screen.dart';

// Dashboards

import '../screens/volunteer/volunteer_dashboard.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_issues_screen.dart';
import '../screens/admin/verify_user_screen.dart';
import '../screens/ngo/document_submission_screen.dart';
import '../screens/ngo/verification_pending_screen.dart';
import '../screens/ngo/verification_rejected_screen.dart';

import '../models/food_donation.dart';
// Donor flow
import '../screens/volunteer/accept_task_screen.dart';
import '../screens/volunteer/reject_task_screen.dart';
import '../screens/volunteer/task_execution_screen.dart';
import '../screens/coordination/issue_reporting_screen.dart';
import '../screens/volunteer/volunteer_profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String roleSelection = '/role-selection';
  static const String donorRegistration = '/donor-registration';
  static const String ngoRegistration = '/ngo-registration';
  static const String volunteerRegistration = '/volunteer-registration';
  static const String emailVerification = '/email-verification';
  static const String onboarding = '/onboarding';

  static const String forgotPassword = '/forgot-password'; // [NEW] Route

  static const String donorDashboard = '/donor-dashboard';
  static const String ngoDashboard = '/ngo-dashboard';
  static const String volunteerDashboard = '/volunteer-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminIssues = '/admin-issues';

  static const String createDonation = '/create-donation';
  static const String donationList = '/donation-list';
  static const String donationDetail = '/donation-detail';
  static const String impactReports = '/impact-reports';

  // ✅ NGO workflow routes
  static const String inspectDelivery = '/inspect-delivery';
  static const String clarifyRequest = '/clarify-request';
  static const String rejectDonation = '/reject-donation';
  static const String updateDemand = '/update-demand';

  static const String acceptTask = '/accept-task';
  static const String rejectTask = '/reject-task';
  static const String taskExecution = '/task-execution';

  // NGO Onboarding
  static const String documentSubmission = '/document-submission';
  static const String verificationPending = '/verification-pending';
  static const String verificationRejected = '/verification-rejected';
  
  static const String issueReporting = '/issue-reporting'; // [NEW]
  static const String verifyUser = '/admin/verify-user';
  static const String volunteerProfile = '/volunteer-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // [NEW] Forgot Password Route
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case donorRegistration:
        return MaterialPageRoute(
            builder: (_) => const DonorRegistrationScreen());

      case ngoRegistration:
        return MaterialPageRoute(builder: (_) => const NGORegistrationScreen());

      case volunteerRegistration:
        return MaterialPageRoute(
            builder: (_) => const VolunteerRegistrationScreen());

      case emailVerification:
        return MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen());

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
      
      case documentSubmission:
        return MaterialPageRoute(
          builder: (_) => const DocumentSubmissionScreen(),
        );

      case verificationPending:
        return MaterialPageRoute(
          builder: (_) => const VerificationPendingScreen(),
        );
      
       case verificationRejected:
        return MaterialPageRoute(
          builder: (_) => const VerificationRejectedScreen(),
        );
      case inspectDelivery:
        final donation = settings.arguments as FoodDonation;
        return MaterialPageRoute(
          builder: (_) => InspectDeliveryScreen(donation: donation),
        );

      case clarifyRequest:
        return MaterialPageRoute(
          builder: (_) => const ClarifyRequestScreen(),
        );

      case rejectDonation:
        return MaterialPageRoute(
          builder: (_) => const RejectDonationScreen(),
        );

      case updateDemand:
        return MaterialPageRoute(
          builder: (_) => const UpdateDemandScreen(),
        );

      case volunteerDashboard:
        return MaterialPageRoute(builder: (_) => const VolunteerDashboard());

      case volunteerProfile:
        return MaterialPageRoute(builder: (_) => const VolunteerProfileScreen());

      case acceptTask:
        return MaterialPageRoute(builder: (_) => const AcceptTaskScreen());

      case rejectTask:
        return MaterialPageRoute(builder: (_) => const RejectTaskScreen());

      case taskExecution:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('donationId')) {
           return MaterialPageRoute(
              builder: (_) => TaskExecutionScreen(donationId: args['donationId']!),
           );
        }
        return _errorRoute();

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case adminIssues:
         return MaterialPageRoute(builder: (_) => const AdminIssuesScreen());

      case verifyUser:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VerifyUserScreen(verificationData: args),
        );

      case createDonation:
        return MaterialPageRoute(builder: (_) => const CreateDonationScreen());
      case donationList:
        return MaterialPageRoute(builder: (_) => const DonationListScreen());

      case donationDetail:
        final donation = settings.arguments as FoodDonation;
        return MaterialPageRoute(
          builder: (_) => DonationDetailScreen(initialDonation: donation),
        );

      case impactReports:
        return MaterialPageRoute(builder: (_) => const ImpactReportsScreen());

      case issueReporting:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => IssueReportingScreen(donationId: args['donationId']));
      
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}
