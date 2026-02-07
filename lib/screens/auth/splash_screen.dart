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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon with smooth shadow and premium look
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 70,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            
            // App Title - Premium Typography
            Text(
              'ShareFood',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reducing waste, feeding hope',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 80),
            
            // Minimalist loading
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}