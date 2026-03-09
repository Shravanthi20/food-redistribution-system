import 'package:flutter/material.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/gradient_scaffold.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Role',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentTeal, AppTheme.accentCyan],
                ).createShader(bounds),
                child: const Text(
                  'Join Our Mission',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 20, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Secure matching & automated verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Role Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Donor Card
                      _RoleCard(
                        icon: Icons.restaurant_menu,
                        title: 'Donor',
                        subtitle: 'Restaurants, groceries, caterers',
                        description: 'Post surplus food for redistribution',
                        iconColor: AppTheme.warningAmber,
                        onTap: () {
                          Navigator.pushNamed(
                              context, AppRouter.donorRegistration);
                        },
                      ),
                      const SizedBox(height: 16),

                      // NGO Card
                      _RoleCard(
                        icon: Icons.volunteer_activism,
                        title: 'NGO/Organization',
                        subtitle: 'Orphanages, shelters, food banks',
                        description:
                            'Receive and distribute food to those in need',
                        iconColor: AppTheme.accentTeal,
                        onTap: () {
                          Navigator.pushNamed(
                              context, AppRouter.ngoRegistration);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Volunteer Card
                      _RoleCard(
                        icon: Icons.directions_run,
                        title: 'Volunteer',
                        subtitle: 'Individual helpers',
                        description: 'Help pickup and deliver food donations',
                        iconColor: AppTheme.accentCyan,
                        onTap: () {
                          Navigator.pushNamed(
                              context, AppRouter.volunteerRegistration);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Back to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.accentTeal, AppTheme.accentCyan],
                      ).createShader(bounds),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 16,
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
