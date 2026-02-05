import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';
import '../../models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Listen to auth state changes
    authProvider.addListener(() {
      if (!authProvider.isLoading && mounted) {
        _navigateToAppropriateScreen(authProvider);
      }
    });

    // If already loaded, navigate immediately
    if (!authProvider.isLoading) {
      _navigateToAppropriateScreen(authProvider);
    }
  }

  void _navigateToAppropriateScreen(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
// Bypass email verification for testing
      // if (!authProvider.isEmailVerified) {
      //   Navigator.pushReplacementNamed(context, AppRouter.emailVerification);
      // } else
      if (authProvider.appUser != null) {
        _navigateBasedOnUserState(authProvider.appUser!);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  void _navigateBasedOnUserState(AppUser user) {
    // Navigate based on onboarding state
    switch (user.onboardingState) {
      case OnboardingState.registered:
      case OnboardingState.documentSubmitted:
        Navigator.pushReplacementNamed(
          context,
          AppRouter.onboarding,
          arguments: {'userRole': user.role},
        );
        break;
      case OnboardingState.verified:
      case OnboardingState.profileComplete:
      case OnboardingState.active:
        _navigateToRoleDashboard(user.role);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  void _navigateToRoleDashboard(UserRole role) {
    switch (role) {
      case UserRole.donor:
        Navigator.pushReplacementNamed(context, AppRouter.donorDashboard);
        break;
      case UserRole.ngo:
        Navigator.pushReplacementNamed(context, AppRouter.ngoDashboard);
        break;
      case UserRole.volunteer:
        Navigator.pushReplacementNamed(context, AppRouter.volunteerDashboard);
        break;
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 30),

            // App Title
            Text(
              'Food Redistribution',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reducing waste, feeding hope',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 50),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
