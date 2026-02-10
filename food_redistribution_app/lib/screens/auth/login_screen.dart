import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      if (authProvider.appUser != null) {
        _navigateBasedOnUser(authProvider.appUser!);
      }
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  void _navigateBasedOnUser(dynamic user) {
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
         case OnboardingState.verified:
         case OnboardingState.active:
           _navigateToRoleDashboard(user.role);
           return;
         default:
           break;
       }
    }

    // Default existing logic for others (Donor, Volunteer, Admin)
    switch (user.onboardingState) {
      case OnboardingState.registered:
        // Donors are now active by default, so they won't hit this unless logic matches.
        // Volunteers might still hit this.
         Navigator.pushReplacementNamed(
          context,
          AppRouter.onboarding,
          arguments: {'userRole': user.role},
        );
        break;
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
        // Fallback
        _navigateToRoleDashboard(user.role);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorCoral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, AppRouter.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with glow effect
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                color: AppTheme.accentTeal.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentTeal.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 56,
                              color: AppTheme.accentTeal,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Title with gradient text effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.textPrimary, AppTheme.accentCyanSoft],
                            ).createShader(bounds),
                            child: const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your mission',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Glass Login Card
                          GlassContainer(
                            padding: const EdgeInsets.all(28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GlassTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hintText: 'your@email.com',
                                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Email is required';
                                      if (!v.contains('@')) return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  GlassTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: AppTheme.textMuted,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Password is required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _navigateToForgotPassword,
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(color: AppTheme.accentTeal),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    text: 'Sign In',
                                    onPressed: _signIn,
                                    icon: Icons.login_rounded,
                                    isLoading: authProvider.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRouter.roleSelection),
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: AppTheme.accentTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForgotPasswordForm extends StatefulWidget {
  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _emailResetController = TextEditingController();
  final _resetFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailResetController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .sendPasswordResetEmail(_emailResetController.text.trim());
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset link sent! Check your email.'),
            backgroundColor: AppTheme.successTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive a password reset link.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _resetFormKey,
          child: GlassTextField(
            controller: _emailResetController,
            label: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Send Reset Link',
          isLoading: _isLoading,
          width: double.infinity,
          onPressed: _sendResetLink,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
