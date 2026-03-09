import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_localizations_ext.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
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
    if (_formKey.currentState?.validate() != true) return;

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
      } else {
        // appUser is null after successful sign-in — show feedback
        _showErrorSnackBar(context.l10n.loginProfileLoadError);
      }
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  void _navigateBasedOnUser(AppUser user) {
    // Admin users bypass all verification/onboarding - go directly to dashboard
    if (user.role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      return;
    }

    if (user.role == UserRole.ngo) {
      switch (user.onboardingState) {
        case OnboardingState.registered:
          Navigator.pushReplacementNamed(context, AppRouter.documentSubmission);
          return;
        case OnboardingState.documentSubmitted:
          Navigator.pushReplacementNamed(
              context, AppRouter.verificationPending);
          return;
        case OnboardingState.profileComplete:
        case OnboardingState.verified:
        case OnboardingState.active:
          _navigateToRoleDashboard(user.role);
          return;
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
                          // Language picker
                          _buildLanguagePicker(context),
                          const SizedBox(height: 24),
                          // Logo with glow effect
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.accentTeal.withValues(alpha: 0.2),
                                  AppTheme.accentCyan.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color:
                                    AppTheme.accentTeal.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentTeal
                                      .withValues(alpha: 0.3),
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
                              colors: [
                                AppTheme.textPrimary,
                                AppTheme.accentCyanSoft
                              ],
                            ).createShader(bounds),
                            child: Text(
                              context.l10n.loginTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.signInToContinue,
                            style: const TextStyle(
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
                                    label: context.l10n.email,
                                    hintText: context.l10n.emailPlaceholder,
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        color: AppTheme.textSecondary),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return context.l10n.emailRequired;
                                      }
                                      if (!v.contains('@')) {
                                        return context.l10n.invalidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  GlassTextField(
                                    controller: _passwordController,
                                    label: context.l10n.password,
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: AppTheme.textSecondary),
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppTheme.textMuted,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) => v!.isEmpty
                                        ? context.l10n.passwordRequired
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _navigateToForgotPassword,
                                      child: Text(
                                        context.l10n.forgotPassword,
                                        style: const TextStyle(
                                            color: AppTheme.accentTeal),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    text: context.l10n.signIn,
                                    onPressed: _signIn,
                                    icon: Icons.login_rounded,
                                    isLoading: authProvider.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, AppRouter.roleSelection),
                                  child: Text(
                                    context.l10n.createAccount,
                                    style: const TextStyle(
                                      color: AppTheme.accentTeal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildLanguagePicker(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentCode = localeProvider.locale.languageCode.toUpperCase();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border:
                  Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Language / भाषा चुनें / மொழி தேர்வு',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...LocaleProvider.supportedLocaleOptions.map((opt) {
                  final isSelected = localeProvider.locale.languageCode ==
                      opt.locale.languageCode;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color:
                          isSelected ? AppTheme.accentTeal : AppTheme.textMuted,
                    ),
                    title: Text(
                      opt.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accentTeal
                            : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      localeProvider.setLocale(opt.locale);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected
                        ? AppTheme.accentTeal.withValues(alpha: 0.1)
                        : null,
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentTeal.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                color: AppTheme.accentTeal, size: 18),
            const SizedBox(width: 6),
            Text(
              currentCode,
              style: const TextStyle(
                color: AppTheme.accentTeal,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.accentTeal, size: 18),
          ],
        ),
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
            content: Text(context.l10n.resetLinkSent),
            backgroundColor: AppTheme.successTeal,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          context.l10n.resetPassword,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.resetPasswordInstructions,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _resetFormKey,
          child: GlassTextField(
            controller: _emailResetController,
            label: context.l10n.emailAddress,
            prefixIcon:
                const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return context.l10n.emailRequired;
              if (!v.contains('@')) return context.l10n.invalidEmail;
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: context.l10n.sendResetLink,
          isLoading: _isLoading,
          width: double.infinity,
          onPressed: _sendResetLink,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
