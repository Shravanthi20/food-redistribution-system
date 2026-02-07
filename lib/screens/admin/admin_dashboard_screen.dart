import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/food_donation.dart';
import './admin_dashboard_rail.dart';
import '../../services/verification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            AdminDashboardRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_getTitle()),
                elevation: 0,
                backgroundColor: Colors.transparent,
                titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                actions: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return IconButton(
                        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                        onPressed: () => themeProvider.toggleTheme(),
                        tooltip: 'Toggle Theme',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.loadDashboardData(),
                    tooltip: 'Refresh Data',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _handleSignOut(context),
                    tooltip: 'Sign Out',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(provider),
              bottomNavigationBar: !isDesktop
                  ? BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: (index) => setState(() => _selectedIndex = index),
                      type: BottomNavigationBarType.fixed,
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                        BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Verify'),
                        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Gov'),
                        BottomNavigationBarItem(icon: Icon(Icons.swap_calls), label: 'Manual'),
                        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
                        BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Matching'),
                        BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: 'Audit'),
                      ],
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'System Overview';
      case 1: return 'Certificate Verifications';
      case 2: return 'User Governance';
      case 3: return 'Manual Overrides';
      case 4: return 'Analytics & Reporting';
      case 5: return 'Algorithm Matching';
      case 6: return 'Audit & Compliance';
      default: return 'Admin Dashboard';
    }
  }

  Widget _buildBody(AdminDashboardProvider provider) {
    switch (_selectedIndex) {
      case 0: return _buildOverviewTab(provider);
      case 1: return _buildVerificationsTab(provider);
      case 2: return _buildGovernanceTab(provider);
      case 3: return _buildOverridesTab(provider);
      case 4: return _buildAnalyticsTab(provider);
      case 5: return _buildMatchingTab(provider);
      case 6: return _buildAuditTab(provider);
      default: return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildMatchingTab(AdminDashboardProvider provider) {
    final sessions = provider.matchingSessions;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No matching sessions recorded yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final matches = (session['matches'] as List? ?? []);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.orange),
            title: Text('Session: ${session['id'].toString().substring(0, 8)}...'),
            subtitle: Text('Donation: ${session['donationId']} • Algorithm: ${session['algorithm']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Matches:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...matches.map((match) => _buildMatchDetail(match)).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchDetail(dynamic match) {
    final scores = (match['criteriaScores'] as Map? ?? {});
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NGO ID: ${match['ngoId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: ${(match['score'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Reasoning: ${match['reasoning']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          const Text('Criteria Breakdown:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: scores.entries.map<Widget>((e) {
              final label = e.key.split('.').last;
              return Chip(
                label: Text('$label: ${(e.value as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.blue.withOpacity(0.05),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(AdminDashboardProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricCard('Total Users', (provider.systemMetrics['totalUsers'] ?? 0).toString(), Icons.people, Colors.blue),
                _buildMetricCard('Recent Donations', (provider.systemMetrics['totalDonationsThisMonth'] ?? 0).toString(), Icons.fastfood, Colors.green),
                _buildMetricCard('Waste Prevented', '${(provider.systemMetrics['wasteReduced'] ?? 0).toStringAsFixed(1)}kg', Icons.delete_outline, Colors.orange),
                _buildMetricCard('Active Matches', (provider.unmatchedDonations ?? []).length.toString(), Icons.handshake, Colors.purple),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSectionCard(
                title: 'Recent System Activity',
                icon: Icons.history,
                child: Column(
                  children: (provider.auditLogs ?? []).take(6).map((log) => _buildAuditTile(log)).toList(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildSectionCard(
                title: 'System Health',
                icon: Icons.health_and_safety,
                child: Column(
                  children: [
                    _buildHealthItem('Database', 'Operational', Colors.green),
                    _buildHealthItem('Auth Service', 'Operational', Colors.green),
                    _buildHealthItem('Storage', 'Operational', Colors.green),
                    _buildHealthItem('Regional Analytics', (provider.regionalStats ?? {}).isEmpty ? 'Waiting for Data' : 'Operational', 
                      (provider.regionalStats ?? {}).isEmpty ? Colors.orange : Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: VERIFICATIONS ---
  Widget _buildVerificationsTab(AdminDashboardProvider provider) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'NGO Certificates'),
              Tab(text: 'High-Volume Donors'),
            ],
            labelColor: Colors.blue,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVerificationList(provider, UserRole.ngo),
                _buildVerificationList(provider, UserRole.donor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationList(AdminDashboardProvider provider, UserRole role) {
    final list = (provider.pendingVerifications ?? []).where((v) => v['user'] != null && v['user']['role'] == role.name).toList();
    if (list.isEmpty) {
      return const Center(child: Text('No pending verifications for this role'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.description)),
            title: Text(item['user']['email'] ?? 'No Email'),
            subtitle: Text('Submitted: ${_formatDate(item['submission']['submittedAt'])}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _handleReview(context, item['id'], VerificationStatus.approved),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _handleReview(context, item['id'], VerificationStatus.rejected),
                ),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, '/admin/verify-user', arguments: item),
          ),
        );
      },
    );
  }

  // --- TAB 3: GOVERNANCE ---
  Widget _buildGovernanceTab(AdminDashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email or name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (val) => provider.searchUsers(val),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => provider.searchUsers(_searchController.text),
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: (provider.allUsers ?? []).isEmpty 
              ? const Center(child: Text('Search for users to manage roles and restrictions'))
              : ListView.builder(
                  itemCount: provider.allUsers.length,
                  itemBuilder: (context, index) {
                    final user = provider.allUsers[index];
                    return _buildUserGovernanceCard(user);
                  },
                ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: MANUAL OVERRIDES ---
  Widget _buildOverridesTab(AdminDashboardProvider provider) {
    if ((provider.unmatchedDonations ?? []).isEmpty) {
       return const Center(child: Text('All donations are currently matched or non-pending.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: provider.unmatchedDonations.length,
      itemBuilder: (context, index) {
        final donation = provider.unmatchedDonations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(donation.title),
            subtitle: Text('Status: ${donation.status.name} • Available Until: ${_formatDate(donation.availableUntil)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${donation.pickupAddress}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _handleForceAssignNGO(donation.id),
                          icon: const Icon(Icons.business),
                          label: const Text('Force NGO'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _handleForceAssignVolunteer(donation.id),
                          icon: const Icon(Icons.person),
                          label: const Text('Assign Volunteer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 5: ANALYTICS ---
  Widget _buildAnalyticsTab(AdminDashboardProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionCard(
          title: 'Regional Activity Overview',
          icon: Icons.map,
          child: Column(
            children: (provider.regionalStats ?? {}).isEmpty 
              ? [const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Gathering regional data...')))]
              : (provider.regionalStats ?? {}).entries.map((entry) => _buildProgressItem(entry.key, entry.value, _getRegionColor(entry.key))).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Delivery Performance',
          icon: Icons.delivery_dining,
          child: Column(
            children: [
               ListTile(
                title: Text('Success Rate: ${provider.deliveryPerformance['successRate']?.toStringAsFixed(1) ?? '0.0'}%'),
                subtitle: Text('Failure Rate: ${provider.deliveryPerformance['failureRate']?.toStringAsFixed(1) ?? '0.0'}%'),
              ),
              const Divider(),
              Text('Total Completed Transactions: ${provider.deliveryPerformance['totalCompleted'] ?? 0}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 6: AUDIT ---
  Widget _buildAuditTab(AdminDashboardProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Security'), selected: true, onSelected: (val){}),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Hygiene'), selected: false, onSelected: (val){}),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Matching'), selected: false, onSelected: (val){}),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Governance'), selected: false, onSelected: (val){}),
              ],
            ),
          ),
        ),
        Expanded(
          child: (provider.auditLogs ?? []).isEmpty 
            ? const Center(child: Text('No audit logs found matching criteria'))
            : ListView.builder(
                itemCount: provider.auditLogs.length,
                itemBuilder: (context, index) {
                  final log = provider.auditLogs[index];
                  return _buildAuditTile(log, showDetails: true);
                },
              ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Color _getRegionColor(String region) {
    switch (region) {
      case 'Downtown': return Colors.blue;
      case 'Uptown': return Colors.green;
      case 'North Side': return Colors.orange;
      case 'South Side': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Divider(height: 32),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTile(Map<String, dynamic> log, {bool showDetails = false}) {
    return ListTile(
      leading: const Icon(Icons.notification_important_outlined),
      title: Text(log['eventType'] ?? log['action'] ?? 'System Event'),
      subtitle: Text('User: ${log['userId'] ?? 'System'} • IP: ${log['ipAddress'] ?? 'N/A'}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatDate(log['timestamp']), style: const TextStyle(fontSize: 12)),
          if (showDetails)
             Text(log['riskLevel'] ?? 'low', style: TextStyle(
               color: _getRiskColor(log['riskLevel']),
               fontSize: 10,
               fontWeight: FontWeight.bold,
             )),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 12),
          Text(name),
          const Spacer(),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value, color: color, minHeight: 6, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildUserGovernanceCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user['email'] ?? user['emailAddress'] ?? 'No Email'),
        subtitle: Text('Role: ${user['role']} • Status: ${user['status']}'),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
             if (val == 'suspend') _handleSuspendUser(user['id']);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'suspend', child: Text('Suspend (7 Days)')),
            const PopupMenuItem(value: 'restrict', child: Text('Restrict Role')),
            const PopupMenuItem(value: 'history', child: Text('Audit History')),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String? risk) {
    if (risk == 'critical' || risk == 'high') return Colors.red;
    if (risk == 'medium') return Colors.orange;
    return Colors.green;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '--';
    if (timestamp is String) return timestamp;
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split('.')[0];
    }
    if (timestamp is DateTime) {
      return timestamp.toString().split('.')[0];
    }
    return '--';
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Future<void> _handleReview(BuildContext context, String id, VerificationStatus status) async {
    final adminId = context.read<AuthProvider>().appUser?.uid;
    if (adminId == null) {
       _showSnackbar('Session error: Admin not found');
       return;
    }

    final success = await context.read<AdminDashboardProvider>().reviewVerification(
      id,
      adminId,
      status,
      'Approved from System Dashboard',
    );

    if (mounted && success) {
      _showSnackbar('Verification Successful');
    } else if (mounted) {
      _showSnackbar('Review failed: ${context.read<AdminDashboardProvider>().errorMessage}');
    }
  }

  Future<void> _handleSuspendUser(String userId) async {
    final adminId = context.read<AuthProvider>().appUser?.uid;
    if (adminId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Suspension'),
        content: const Text('Are you sure you want to suspend this user for 7 days? This will revoke their access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Suspend')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<AdminDashboardProvider>().suspendUser(
        userId,
        adminId,
        'Flagged for policy violation',
        DateTime.now().add(const Duration(days: 7)),
      );
      if (mounted && success) {
        _showSnackbar('User status updated to SUSPENDED');
      }
    }
  }

  Future<void> _handleForceAssignNGO(String donationId) async {
    final adminId = context.read<AuthProvider>().appUser?.uid;
    if (adminId == null) return;

    // Implementation of NGO selection dialog would go here
    _showSnackbar('Manual matching process initiated');
    
    final success = await context.read<AdminDashboardProvider>().forceAssignNGO(
      donationId,
      adminId,
      'AUTO_SELECTED_PILOT', // In production, this would be from a selection list
      'Manual rescue required',
    );
    
    if (mounted && success) {
      _showSnackbar('Donation force-matched to NGO');
    }
  }

  Future<void> _handleForceAssignVolunteer(String donationId) async {
    final adminId = context.read<AuthProvider>().appUser?.uid;
    if (adminId == null) return;

    final success = await context.read<AdminDashboardProvider>().forceAssignVolunteer(
      donationId,
      adminId,
      'AUTO_VOLUNTEER_1', 
      'Emergency pickup reassignment',
    );
    
    if (mounted && success) {
      _showSnackbar('Volunteer manually assigned to donation');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
