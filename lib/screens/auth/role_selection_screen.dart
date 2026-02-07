import 'package:flutter/material.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join the mission',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Select your role to start making a direct impact in your local community.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.brightness == Brightness.dark 
                    ? Colors.white60 
                    : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              
              _ImpactCard(
                icon: Icons.restaurant_rounded,
                title: 'Food Donor',
                description: 'Restaurants, shops, and caterers sharing surplus high-quality food.',
                color: AppTheme.primaryEmerald,
                onTap: () => Navigator.pushNamed(context, AppRouter.donorRegistration),
              ),
              const SizedBox(height: 20),
              _ImpactCard(
                icon: Icons.business_rounded,
                title: 'NGO / Shelter',
                description: 'Registered organizations managing food distribution to those in need.',
                color: AppTheme.primaryAccent,
                onTap: () => Navigator.pushNamed(context, AppRouter.ngoRegistration),
              ),
              const SizedBox(height: 20),
              _ImpactCard(
                icon: Icons.electric_bolt_rounded,
                title: 'Volunteer',
                description: 'Community heroes facilitating the quick transfer from donors to NGOs.',
                color: AppTheme.warningGold,
                onTap: () => Navigator.pushNamed(context, AppRouter.volunteerRegistration),
              ),
              
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Text(
                      'By joining, you agree to our Terms of Service',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRouter.login);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('Already have an account? Sign In'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ImpactCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.05) 
            : AppTheme.slate200,
          width: 1,
        ),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: color.withOpacity(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}