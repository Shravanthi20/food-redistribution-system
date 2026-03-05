import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo and Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Food Redistribution Platform',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Reducing food waste, feeding communities',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.green.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Text(
                  'Choose your role to get started',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRoleCard(
                        context,
                        title: 'Food Donor',
                        description: 'Share surplus food with those in need',
                        icon: Icons.volunteer_activism,
                        color: Colors.blue,
                        onTap: () => _navigateToRole(context, 'donor'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        title: 'NGO Partner',
                        description: 'Connect with donors to help communities',
                        icon: Icons.business_center,
                        color: Colors.orange,
                        onTap: () => _navigateToRole(context, 'ngo'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        title: 'Volunteer',
                        description: 'Help with food collection and delivery',
                        icon: Icons.delivery_dining,
                        color: Colors.green,
                        onTap: () => _navigateToRole(context, 'volunteer'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        title: 'Coordinator',
                        description: 'Manage logistics and optimize routes',
                        icon: Icons.analytics,
                        color: Colors.purple,
                        onTap: () => _navigateToRole(context, 'coordinator'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                    TextButton(
                      onPressed: () => _navigateToLogin(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
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
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRole(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleDashboard(role: role),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
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
                      stat['value'],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role),
                      ),
                    ),
                    Text(
                      stat['label'],
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
      case 'coordinator': return 'Coordinator';
      default: return 'User';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'donor': return Colors.blue;
      case 'ngo': return Colors.orange;
      case 'volunteer': return Colors.green;
      case 'coordinator': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'donor': return Icons.volunteer_activism;
      case 'ngo': return Icons.business_center;
      case 'volunteer': return Icons.delivery_dining;
      case 'coordinator': return Icons.analytics;
      default: return Icons.person;
    }
  }

  String _getRoleWelcomeMessage(String role) {
    switch (role) {
      case 'donor': return 'Ready to share surplus food and make a difference?';
      case 'ngo': return 'Connect with donors and serve your community better.';
      case 'volunteer': return 'Help deliver food to those who need it most.';
      case 'coordinator': return 'Optimize logistics and maximize our impact.';
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
      case 'coordinator':
        return [
          {'value': '156', 'label': 'Routes Optimized'},
          {'value': '23%', 'label': 'Efficiency Gain'},
          {'value': '12', 'label': 'Active Volunteers'},
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
      case 'coordinator':
        return [
          {'label': 'Analytics', 'icon': Icons.analytics, 'action': 'analytics'},
          {'label': 'Route Planning', 'icon': Icons.route, 'action': 'route_planning'},
          {'label': 'Volunteer Management', 'icon': Icons.group, 'action': 'volunteer_management'},
          {'label': 'System Health', 'icon': Icons.health_and_safety, 'action': 'system_health'},
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