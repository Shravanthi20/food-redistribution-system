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
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';

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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryNavy,
            AppTheme.primaryNavyLight,
            AppTheme.primaryNavyMedium,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(_getTitle()),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentTeal,
                    fontSize: 22,
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                          tooltip: 'Toggle Theme',
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.8)),
                      onPressed: () => provider.loadDashboardData(),
                      tooltip: 'Refresh Data',
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.8)),
                      onPressed: () => _handleSignOut(context),
                      tooltip: 'Sign Out',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentTeal))
                    : _buildBody(provider),
                bottomNavigationBar: !isDesktop
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withOpacity(0.95),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.accentTeal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: BottomNavigationBar(
                          currentIndex: _selectedIndex,
                          onTap: (index) => setState(() => _selectedIndex = index),
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.transparent,
                          selectedItemColor: AppTheme.accentTeal,
                          unselectedItemColor: Colors.white.withOpacity(0.5),
                          selectedLabelStyle: const TextStyle(fontSize: 10),
                          unselectedLabelStyle: const TextStyle(fontSize: 10),
                          items: const [
                            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                            BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Verify'),
                            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Gov'),
                            BottomNavigationBarItem(icon: Icon(Icons.swap_calls), label: 'Manual'),
                            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
                            BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Matching'),
                            BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: 'Audit'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
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
                _buildMetricCard('Active Matches', provider.unmatchedDonations.length.toString(), Icons.handshake, Colors.purple),
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
                  children: provider.auditLogs.take(6).map((log) => _buildAuditTile(log)).toList(),
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
                    _buildHealthItem('Regional Analytics', provider.regionalStats.isEmpty ? 'Waiting for Data' : 'Operational',
                      provider.regionalStats.isEmpty ? Colors.orange : Colors.green),
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              tabs: const [
                Tab(text: 'NGO Certificates'),
                Tab(text: 'High-Volume Donors'),
              ],
              labelColor: AppTheme.accentTeal,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              indicatorColor: AppTheme.accentTeal,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
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
    final list = provider.pendingVerifications.where((v) => v['user'] != null && v['user']['role'] == role.name).toList();
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No pending verifications for this role',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: AppTheme.accentTeal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['user']['email'] ?? 'No Email',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatDate(item['submission']['submittedAt'])}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppTheme.successTeal, size: 28),
                onPressed: () => _handleReview(context, item['id'], VerificationStatus.approved),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: AppTheme.errorCoral, size: 28),
                onPressed: () => _handleReview(context, item['id'], VerificationStatus.rejected),
              ),
            ],
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
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by email or name...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.accentTeal),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    onSubmitted: (val) => provider.searchUsers(val),
                  ),
                ),
                const SizedBox(width: 16),
                GradientButton(
                  onPressed: () => provider.searchUsers(_searchController.text),
                  text: 'Search',
                  icon: Icons.search,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.allUsers.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Search for users to manage roles and restrictions',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                )
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
    if (provider.unmatchedDonations.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.check_circle_outline, size: 64, color: Colors.white.withOpacity(0.3)),
             const SizedBox(height: 16),
             Text(
               'All donations are currently matched or non-pending.',
               style: TextStyle(color: Colors.white.withOpacity(0.6)),
             ),
           ],
         ),
       );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: provider.unmatchedDonations.length,
      itemBuilder: (context, index) {
        final donation = provider.unmatchedDonations[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          borderRadius: 12,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: AppTheme.warningAmber),
              ),
              title: Text(donation.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Status: ${donation.status.name} • Available Until: ${_formatDate(donation.availableUntil)}',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              iconColor: Colors.white.withOpacity(0.6),
              collapsedIconColor: Colors.white.withOpacity(0.6),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup: ${donation.pickupAddress}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
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
            children: provider.regionalStats.isEmpty 
              ? [const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Gathering regional data...')))]
              : provider.regionalStats.entries.map((entry) => _buildProgressItem(entry.key, entry.value, _getRegionColor(entry.key))).toList(),
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
          child: provider.auditLogs.isEmpty 
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
    return GlassContainer(
      width: 250,
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.accentTeal),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ],
          ),
          Divider(height: 32, color: Colors.white.withOpacity(0.2)),
          child,
        ],
      ),
    );
  }

  Widget _buildAuditTile(Map<String, dynamic> log, {bool showDetails = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.notification_important_outlined, color: Colors.white.withOpacity(0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['eventType'] ?? log['action'] ?? 'System Event',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  'User: ${log['userId'] ?? 'System'} • IP: ${log['ipAddress'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatDate(log['timestamp']), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              if (showDetails)
                 Text(log['riskLevel'] ?? 'low', style: TextStyle(
                   color: _getRiskColor(log['riskLevel']),
                   fontSize: 10,
                   fontWeight: FontWeight.bold,
                 )),
            ],
          ),
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
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
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
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: AppTheme.accentCyan),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['email'] ?? user['emailAddress'] ?? 'No Email',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${user['role']} • Status: ${user['status']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.6)),
            color: AppTheme.primaryNavyLight,
            onSelected: (val) {
               if (val == 'suspend') _handleSuspendUser(user['id']);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'suspend',
                child: Text('Suspend (7 Days)', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ),
              PopupMenuItem(
                value: 'restrict',
                child: Text('Restrict Role', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ),
              PopupMenuItem(
                value: 'history',
                child: Text('Audit History', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ),
            ],
          ),
        ],
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
