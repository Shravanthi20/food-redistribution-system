import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glass_widgets.dart';
import 'auth/donor_registration_screen.dart';
import 'auth/ngo_registration_screen.dart';
import 'auth/volunteer_registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Glowing Logo
              Container(
                padding: const EdgeInsets.all(24),
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
                  size: 52,
                  color: AppTheme.accentTeal,
                ),
              ),
              const SizedBox(height: 32),
              // Title with gradient
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
              const SizedBox(height: 8),
              Text(
                'Reducing waste, feeding communities',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                'Choose your role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoleCard(
                      context,
                      title: 'Food Donor',
                      description: 'Share surplus food with those in need',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppTheme.accentCyan,
                      onTap: () => _navigateToRole(context, 'donor'),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      title: 'NGO Partner',
                      description: 'Connect with donors to help communities',
                      icon: Icons.business_center_rounded,
                      color: AppTheme.warningAmber,
                      onTap: () => _navigateToRole(context, 'ngo'),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      title: 'Volunteer',
                      description: 'Help with food collection and delivery',
                      icon: Icons.delivery_dining_rounded,
                      color: AppTheme.successTeal,
                      onTap: () => _navigateToRole(context, 'volunteer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => _navigateToLogin(context),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.accentTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      tintColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRole(BuildContext context, String role) {
    Widget destination;
    
    switch (role) {
      case 'donor':
        destination = const DonorRegistrationScreen();
        break;
      case 'ngo':
        destination = const NGORegistrationScreen();
        break;
      case 'volunteer':
        destination = const VolunteerRegistrationScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration for this role is coming soon!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }
}

class RoleDashboard extends StatelessWidget {
  final String role;

  const RoleDashboard({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoleTitle(role)} Dashboard'),
        backgroundColor: _getRoleColor(role),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getRoleColor(role),
              _getRoleColor(role).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 20),
                _buildStatsRow(context),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildRecentActivity(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getRoleIcon(role),
                size: 40,
                color: _getRoleColor(role),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(role),
                    ),
                  ),
                  Text(
                    _getRoleWelcomeMessage(role),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = _getRoleStats(role);
    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      stat['value']!,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role),
                      ),
                    ),
                    Text(
                      stat['label']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _getRoleActions(role).map((action) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _handleAction(context, action['action']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action['icon'],
                        size: 32,
                        color: _getRoleColor(role),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Activity will appear here once you start using the platform',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'donor': return 'Food Donor';
      case 'ngo': return 'NGO Partner';
      case 'volunteer': return 'Volunteer';
      default: return 'User';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'donor': return Colors.blue;
      case 'ngo': return Colors.orange;
      case 'volunteer': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'donor': return Icons.volunteer_activism;
      case 'ngo': return Icons.business_center;
      case 'volunteer': return Icons.delivery_dining;
      default: return Icons.person;
    }
  }

  String _getRoleWelcomeMessage(String role) {
    switch (role) {
      case 'donor': return 'Ready to share surplus food and make a difference?';
      case 'ngo': return 'Connect with donors and serve your community better.';
      case 'volunteer': return 'Help deliver food to those who need it most.';
      default: return 'Welcome to the platform!';
    }
  }

  List<Map<String, String>> _getRoleStats(String role) {
    switch (role) {
      case 'donor':
        return [
          {'value': '12', 'label': 'Donations Made'},
          {'value': '45kg', 'label': 'Food Shared'},
          {'value': '89', 'label': 'People Fed'},
        ];
      case 'ngo':
        return [
          {'value': '234', 'label': 'Received Donations'},
          {'value': '1.2t', 'label': 'Food Distributed'},
          {'value': '567', 'label': 'Beneficiaries'},
        ];
      case 'volunteer':
        return [
          {'value': '18', 'label': 'Deliveries'},
          {'value': '24hrs', 'label': 'Time Volunteered'},
          {'value': '4.8★', 'label': 'Rating'},
        ];
      default:
        return [
          {'value': '0', 'label': 'Getting'},
          {'value': '0', 'label': 'Started'},
          {'value': '0', 'label': 'Soon'},
        ];
    }
  }

  List<Map<String, dynamic>> _getRoleActions(String role) {
    switch (role) {
      case 'donor':
        return [
          {'label': 'Post Donation', 'icon': Icons.add_circle, 'action': 'post_donation'},
          {'label': 'View History', 'icon': Icons.history, 'action': 'view_history'},
          {'label': 'Track Status', 'icon': Icons.track_changes, 'action': 'track_status'},
          {'label': 'Impact Report', 'icon': Icons.assessment, 'action': 'impact_report'},
        ];
      case 'ngo':
        return [
          {'label': 'Browse Donations', 'icon': Icons.search, 'action': 'browse_donations'},
          {'label': 'Request Food', 'icon': Icons.request_page, 'action': 'request_food'},
          {'label': 'Manage Inventory', 'icon': Icons.inventory, 'action': 'manage_inventory'},
          {'label': 'Beneficiary List', 'icon': Icons.people, 'action': 'beneficiary_list'},
        ];
      case 'volunteer':
        return [
          {'label': 'Available Tasks', 'icon': Icons.assignment, 'action': 'available_tasks'},
          {'label': 'Start Delivery', 'icon': Icons.local_shipping, 'action': 'start_delivery'},
          {'label': 'Update Status', 'icon': Icons.update, 'action': 'update_status'},
          {'label': 'My Schedule', 'icon': Icons.schedule, 'action': 'my_schedule'},
        ];
      default:
        return [];
    }
  }

  void _handleAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${action.replaceAll('_', ' ')} feature coming soon!'),
        backgroundColor: _getRoleColor(role),
      ),
    );
  }
}
