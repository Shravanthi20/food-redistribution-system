import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_localizations_ext.dart';
import '../utils/app_theme.dart';
import '../utils/app_router.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glass_widgets.dart';
import 'auth/donor_registration_screen.dart';
import 'auth/ngo_registration_screen.dart';
import 'auth/volunteer_registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              // Language picker - top right
              Align(
                alignment: Alignment.topRight,
                child: _LanguagePickerButton(),
              ),
              const SizedBox(height: 8),
              // Glowing Logo
              Container(
                padding: const EdgeInsets.all(24),
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
                    color: AppTheme.accentTeal.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withValues(alpha: 0.3),
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
                child: Text(
                  context.l10n.foodRedistribution,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.reducingWaste,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                context.l10n.selectRole,
                style: const TextStyle(
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
                      title: context.l10n.roleDonor,
                      description: context.l10n.donorRoleDescription,
                      icon: Icons.volunteer_activism_rounded,
                      color: AppTheme.accentCyan,
                      onTap: () => _navigateToRole(context, 'donor'),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      title: context.l10n.ngoPartner,
                      description: context.l10n.ngoRoleDescription,
                      icon: Icons.business_center_rounded,
                      color: AppTheme.warningAmber,
                      onTap: () => _navigateToRole(context, 'ngo'),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      title: context.l10n.roleVolunteer,
                      description: context.l10n.volunteerRoleDescription,
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
                    context.l10n.alreadyHaveAccount,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => _navigateToLogin(context),
                    child: Text(
                      context.l10n.signIn,
                      style: const TextStyle(
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
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
              color: color.withValues(alpha: 0.1),
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
            content: Text(context.l10n.registrationComingSoon),
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

/// Compact language picker button for use on the welcome & login screens.
class _LanguagePickerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentCode = localeProvider.locale.languageCode.toUpperCase();

    return GestureDetector(
      onTap: () => _showLanguagePicker(context, localeProvider),
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

  void _showLanguagePicker(
      BuildContext context, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
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
            Text(
              context.l10n.chooseLanguageLabel,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...LocaleProvider.supportedLocaleOptions.map((opt) {
              final isSelected =
                  localeProvider.locale.languageCode == opt.locale.languageCode;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppTheme.accentTeal : AppTheme.textMuted,
                ),
                title: Text(
                  opt.displayName,
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.accentTeal : AppTheme.textPrimary,
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
  }
}

class RoleDashboard extends StatefulWidget {
  final String role;
  final String? userId;

  const RoleDashboard({super.key, required this.role, this.userId});

  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    try {
      final userId = widget.userId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (widget.role == 'donor') {
        final donations = await _firestore
            .collection('donations')
            .where('donorId', isEqualTo: userId)
            .get();
        final total = donations.docs.length;
        final completed = donations.docs
            .where((d) => d.data()['status'] == 'delivered')
            .length;
        int totalQuantity = 0;
        int totalPeopleServed = 0;
        for (final doc in donations.docs) {
          totalQuantity += (doc.data()['quantity'] as num?)?.toInt() ?? 0;
          totalPeopleServed +=
              (doc.data()['estimatedPeopleServed'] as num?)?.toInt() ?? 0;
        }
        _stats = {
          'Donations': '$total',
          'Delivered': '$completed',
          'Qty Donated': '$totalQuantity',
          'People Served': '$totalPeopleServed',
        };
        _recentActivity = donations.docs
            .take(5)
            .map((d) => {
                  'title': d.data()['title'] ?? 'Donation',
                  'status': d.data()['status'] ?? 'listed',
                  'time': d.data()['createdAt'],
                })
            .toList();
      } else if (widget.role == 'ngo') {
        final requests = await _firestore
            .collection('requests')
            .where('ngoId', isEqualTo: userId)
            .get();
        final donations = await _firestore
            .collection('donations')
            .where('assignedNGOId', isEqualTo: userId)
            .get();
        final fulfilled = requests.docs
            .where((d) => d.data()['status'] == 'fulfilled')
            .length;
        int totalBeneficiaries = 0;
        for (final doc in requests.docs) {
          totalBeneficiaries +=
              (doc.data()['expectedBeneficiaries'] as num?)?.toInt() ?? 0;
        }
        _stats = {
          'Received': '${donations.docs.length}',
          'Requests': '${requests.docs.length}',
          'Fulfilled': '$fulfilled',
          'Beneficiaries': '$totalBeneficiaries',
        };
        _recentActivity = donations.docs
            .take(5)
            .map((d) => {
                  'title': d.data()['title'] ?? 'Donation',
                  'status': d.data()['status'] ?? 'pending',
                  'time': d.data()['createdAt'],
                })
            .toList();
      } else if (widget.role == 'volunteer') {
        final tasks = await _firestore
            .collection('donations')
            .where('assignedVolunteerId', isEqualTo: userId)
            .get();
        final completed =
            tasks.docs.where((d) => d.data()['status'] == 'delivered').length;
        // Fetch profile for rating
        final profile =
            await _firestore.collection('volunteer_profiles').doc(userId).get();
        final rating = profile.data()?['rating']?.toString() ?? '-';
        _stats = {
          'Deliveries': '${tasks.docs.length}',
          'Completed': '$completed',
          'Rating': '$rating★',
        };
        _recentActivity = tasks.docs
            .take(5)
            .map((d) => {
                  'title': d.data()['title'] ?? 'Task',
                  'status': d.data()['status'] ?? 'pending',
                  'time': d.data()['createdAt'],
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Fallback to empty stats
      _stats = {'Data': '—', 'Loading': '—', 'Error': '—'};
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoleTitle(widget.role)} Dashboard'),
        backgroundColor: _getRoleColor(widget.role),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getRoleColor(widget.role),
              _getRoleColor(widget.role).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
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
                color: _getRoleColor(widget.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getRoleIcon(widget.role),
                size: 40,
                color: _getRoleColor(widget.role),
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
                          color: _getRoleColor(widget.role),
                        ),
                  ),
                  Text(
                    _getRoleWelcomeMessage(widget.role),
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
    if (_stats.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: _stats.entries.map((entry) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      entry.value,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getRoleColor(widget.role),
                              ),
                    ),
                    Text(
                      entry.key,
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
          children: _getRoleActions(widget.role).map((action) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                        color: _getRoleColor(widget.role),
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
    return Column(
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
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _recentActivity.isEmpty
                ? Center(
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Activity will appear here once you start using the platform',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _recentActivity.map((activity) {
                      final status = activity['status'] ?? '';
                      final statusColor = status == 'delivered'
                          ? Colors.green
                          : status == 'cancelled'
                              ? Colors.red
                              : status == 'inTransit'
                                  ? Colors.orange
                                  : Colors.blue;
                      return ListTile(
                        dense: true,
                        leading:
                            Icon(Icons.circle, size: 10, color: statusColor),
                        title: Text(
                          activity['title'] ?? 'Activity',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'donor':
        return 'Food Donor';
      case 'ngo':
        return 'NGO Partner';
      case 'volunteer':
        return 'Volunteer';
      default:
        return 'User';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'donor':
        return Colors.blue;
      case 'ngo':
        return Colors.orange;
      case 'volunteer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'donor':
        return Icons.volunteer_activism;
      case 'ngo':
        return Icons.business_center;
      case 'volunteer':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  String _getRoleWelcomeMessage(String role) {
    switch (role) {
      case 'donor':
        return 'Ready to share surplus food and make a difference?';
      case 'ngo':
        return 'Connect with donors and serve your community better.';
      case 'volunteer':
        return 'Help deliver food to those who need it most.';
      default:
        return 'Welcome to the platform!';
    }
  }

  List<Map<String, dynamic>> _getRoleActions(String role) {
    switch (role) {
      case 'donor':
        return [
          {
            'label': 'Post Donation',
            'icon': Icons.add_circle,
            'action': 'post_donation'
          },
          {
            'label': 'View History',
            'icon': Icons.history,
            'action': 'view_history'
          },
          {
            'label': 'Track Status',
            'icon': Icons.track_changes,
            'action': 'track_status'
          },
          {
            'label': 'Impact Report',
            'icon': Icons.assessment,
            'action': 'impact_report'
          },
        ];
      case 'ngo':
        return [
          {
            'label': 'Browse Donations',
            'icon': Icons.search,
            'action': 'browse_donations'
          },
          {
            'label': 'Request Food',
            'icon': Icons.request_page,
            'action': 'request_food'
          },
          {
            'label': 'Manage Inventory',
            'icon': Icons.inventory,
            'action': 'manage_inventory'
          },
          {
            'label': 'Beneficiary List',
            'icon': Icons.people,
            'action': 'beneficiary_list'
          },
        ];
      case 'volunteer':
        return [
          {
            'label': 'Available Tasks',
            'icon': Icons.assignment,
            'action': 'available_tasks'
          },
          {
            'label': 'Start Delivery',
            'icon': Icons.local_shipping,
            'action': 'start_delivery'
          },
          {
            'label': 'Update Status',
            'icon': Icons.update,
            'action': 'update_status'
          },
          {
            'label': 'My Schedule',
            'icon': Icons.schedule,
            'action': 'my_schedule'
          },
        ];
      default:
        return [];
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      // Donor actions
      case 'post_donation':
        Navigator.pushNamed(context, AppRouter.createDonation);
        break;
      case 'view_history':
        Navigator.pushNamed(context, AppRouter.donationList);
        break;
      case 'track_status':
        Navigator.pushNamed(context, AppRouter.donationList);
        break;
      case 'impact_report':
        Navigator.pushNamed(context, AppRouter.impactReports);
        break;
      // NGO actions
      case 'browse_donations':
        Navigator.pushNamed(context, AppRouter.ngoDashboard);
        break;
      case 'request_food':
        Navigator.pushNamed(context, AppRouter.ngoCreateRequest);
        break;
      case 'manage_inventory':
        Navigator.pushNamed(context, AppRouter.ngoDashboard);
        break;
      case 'beneficiary_list':
        Navigator.pushNamed(context, AppRouter.ngoDashboard);
        break;
      // Volunteer actions
      case 'available_tasks':
        Navigator.pushNamed(context, AppRouter.volunteerDashboard);
        break;
      case 'start_delivery':
        Navigator.pushNamed(context, AppRouter.volunteerDashboard);
        break;
      case 'update_status':
        Navigator.pushNamed(context, AppRouter.volunteerDashboard);
        break;
      case 'my_schedule':
        Navigator.pushNamed(context, AppRouter.volunteerProfile);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action.replaceAll('_', ' ')),
            backgroundColor: _getRoleColor(widget.role),
          ),
        );
    }
  }
}
