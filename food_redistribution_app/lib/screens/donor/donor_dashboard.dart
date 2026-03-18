import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../models/food_donation.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';
import 'create_donation_screen.dart';
import 'donation_list_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({Key? key}) : super(key: key);

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonations();
      _checkVerificationStatus();
    });
  }

  Future<void> _loadDonations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    
    final userId = authProvider.appUser?.uid;
    if (userId != null) {
      await donationProvider.loadMyDonations(userId);
    }
  }

  Future<void> _checkVerificationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final statusChanged = await authProvider.checkAndUpdateVerificationStatus();
    
    if (statusChanged && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primaryNavy),
              SizedBox(width: 12),
              Text('Your account has been verified!'),
            ],
          ),
          backgroundColor: AppTheme.successTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 5),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      appBar: GlassAppBar(
        title: 'Dashboard',
        actions: [
          GlassIconButton(
            icon: Icons.logout_rounded,
            size: 40,
            onPressed: () async {
              final confirmed = await GlassDialog.show<bool>(
                context: context,
                title: 'Sign Out',
                content: Text(
                  'Are you sure you want to sign out?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Sign Out', style: TextStyle(color: AppTheme.errorCoral)),
                  ),
                ],
              );

              if (confirmed == true && mounted) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.appUser;
          if (user == null) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentTeal,
              ),
            );
          }

          final donationProvider = Provider.of<DonationProvider>(context, listen: false);

          return StreamBuilder<List<FoodDonation>>(
            stream: donationProvider.getMyDonationsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.accentTeal),
                );
              }

              final myDonations = snapshot.data ?? [];
              
              final activeCount = myDonations.where((d) => 
                d.status == DonationStatus.listed || 
                d.status == DonationStatus.matched
              ).length;
              
              final deliveredCount = myDonations.where((d) => d.status == DonationStatus.delivered).length;
              
              final inProgressCount = myDonations.where((d) => 
                 d.status == DonationStatus.matched ||
                 d.status == DonationStatus.pickedUp ||
                 d.status == DonationStatus.inTransit
              ).length;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status Banner
                    if (user.onboardingState == OnboardingState.documentSubmitted)
                      _buildVerificationPendingBanner(),
                    if (user.onboardingState == OnboardingState.documentSubmitted)
                      const SizedBox(height: 20),
                    
                    // Welcome Card
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.accentTeal.withOpacity(0.2),
                                      AppTheme.accentCyan.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.accentTeal.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.volunteer_activism_rounded,
                                  size: 28,
                                  color: AppTheme.accentTeal,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome Back!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.successTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.successTeal.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.eco_rounded, color: AppTheme.successTeal, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ready to reduce food waste today?',
                                    style: TextStyle(
                                      color: AppTheme.successTeal,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Statistics Section
                    Text(
                      'Your Impact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Active',
                            value: activeCount.toString(),
                            icon: Icons.list_alt_rounded,
                            accentColor: AppTheme.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassStatCard(
                            title: 'Total',
                            value: myDonations.length.toString(),
                            icon: Icons.all_inclusive_rounded,
                            accentColor: AppTheme.infoCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Delivered',
                            value: deliveredCount.toString(),
                            icon: Icons.check_circle_rounded,
                            accentColor: AppTheme.successTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassStatCard(
                            title: 'In Progress',
                            value: inProgressCount.toString(),
                            icon: Icons.local_shipping_rounded,
                            accentColor: AppTheme.warningAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Quick Actions Section
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildActionCard(
                      'Create New Donation',
                      'Post surplus food for redistribution',
                      Icons.add_circle_rounded,
                      AppTheme.successTeal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateDonationScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'My Donations',
                      'View and manage all your donations',
                      Icons.list_rounded,
                      AppTheme.accentCyan,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DonationListScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'Impact Report',
                      'See your contribution statistics',
                      Icons.analytics_rounded,
                      AppTheme.infoCyan,
                      () => Navigator.pushNamed(context, AppRouter.impactReports),
                    ),
                    const SizedBox(height: 28),

                    // Recent Donations Section
                    if (myDonations.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Donations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DonationListScreen()),
                            ),
                            child: Text(
                              'View All',
                              style: TextStyle(color: AppTheme.accentTeal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      ...myDonations.take(3).map((donation) {
                        return GlassListTile(
                          title: donation.title,
                          subtitle: '${donation.quantity} ${donation.unit} • ${_getStatusDisplayName(donation.status)}',
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getStatusColor(donation.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: _getStatusColor(donation.status),
                              size: 22,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () => Navigator.pushNamed(
                            context, 
                            AppRouter.donationDetail,
                            arguments: donation,
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: GlassFAB(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateDonationScreen()),
          );
          if (result == true) _loadDonations();
        },
        icon: Icons.add_rounded,
        extended: true,
        label: 'New Donation',
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
              size: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return AppTheme.accentCyan;
      case DonationStatus.matched:
        return AppTheme.warningAmber;
      case DonationStatus.pickedUp:
        return AppTheme.infoCyan;
      case DonationStatus.inTransit:
        return AppTheme.accentTealLight;
      case DonationStatus.delivered:
        return AppTheme.successTeal;
      case DonationStatus.cancelled:
        return AppTheme.errorCoral;
      case DonationStatus.expired:
        return AppTheme.textMuted;
    }
  }

  String _getStatusDisplayName(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return 'Listed';
      case DonationStatus.matched:
        return 'Matched';
      case DonationStatus.pickedUp:
        return 'Picked Up';
      case DonationStatus.inTransit:
        return 'In Transit';
      case DonationStatus.delivered:
        return 'Delivered';
      case DonationStatus.cancelled:
        return 'Cancelled';
      case DonationStatus.expired:
        return 'Expired';
    }
  }

  Widget _buildVerificationPendingBanner() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      tintColor: AppTheme.warningAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pending_actions_rounded,
                  color: AppTheme.warningAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verification Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: AppTheme.warningAmber,
                  ),
                ),
              ),
              Icon(
                Icons.hourglass_top_rounded,
                color: AppTheme.warningAmber.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your documents are under review. You\'ll be able to create donations once verified.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlassDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Usually takes 24-48 hours',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
