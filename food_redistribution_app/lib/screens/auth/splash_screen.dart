import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../widgets/gradient_scaffold.dart';

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
    // Admin users bypass all verification/onboarding - go directly to dashboard
    if (user.role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      return;
    }
    
    if (user.role == UserRole.ngo) {
       switch(user.onboardingState) {
         case OnboardingState.registered:
           Navigator.pushReplacementNamed(context, AppRouter.documentSubmission);
           return;
         case OnboardingState.documentSubmitted:
           Navigator.pushReplacementNamed(context, AppRouter.verificationPending);
           return;
         // If we had a rejected state in enum, handle it. Assuming it might be handled via status or re-purposed state.
         // For now, if active/verified:
         case OnboardingState.verified:
         case OnboardingState.active:
           _navigateToRoleDashboard(user.role);
           return;
         default:
           // If profile not complete etc
           break;
       }
    }

    // Default existing logic for others
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
    return GradientScaffold(
      showAnimatedBackground: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated App Icon with glow
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.accentTeal.withOpacity(0.2),
                          AppTheme.accentCyan.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.accentTeal.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withOpacity(0.3 * value),
                          blurRadius: 40 * value,
                          spreadRadius: 10 * value,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 60,
                      color: AppTheme.accentTeal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Animated App Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.textPrimary, AppTheme.accentCyanSoft],
              ).createShader(bounds),
              child: const Text(
                'Food Redistribution',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reducing waste, feeding hope',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 60),

            // Elegant loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
                backgroundColor: AppTheme.surfaceGlassDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
