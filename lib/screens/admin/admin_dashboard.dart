import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart'; // [NEW]
import '../../services/verification_service.dart'; // For VerificationStatus enum
import '../../services/user_service.dart'; // For logging out logic if needed or types

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminDashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboardData(),
          ),
          IconButton(
            icon: const Icon(Icons.report_problem, color: Colors.amber), // Warning color
            tooltip: 'Manage Issues',
            onPressed: () => Navigator.pushNamed(context, AppRouter.adminIssues),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              // Navigation to login handled by auth wrapper
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verifications'),
            Tab(icon: Icon(Icons.gavel), text: 'Governance'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider),
                _buildVerificationTab(provider),
                _buildGovernanceTab(provider),
              ],
            ),
    );
  }

  // --- Overview Tab ---
  Widget _buildOverviewTab(AdminDashboardProvider provider) {
    final metrics = provider.systemMetrics;
    final stats = provider.verificationStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Analytics', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                'Meals Redistributed',
                '${metrics['completedDonationsThisMonth'] ?? 0}',
                Icons.restaurant,
                Colors.orange,
              ),
              _buildMetricCard(
                'Waste Reduced (kg)',
                '${metrics['wasteReduced'] ?? 0}',
                Icons.eco,
                Colors.green,
              ),
              _buildMetricCard(
                'Active Users',
                '${metrics['activeUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildMetricCard(
                'Pending Approvals',
                '${stats['pendingCount'] ?? 0}',
                Icons.mark_email_unread,
                Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Activity & Health', style: Theme.of(context).textTheme.headlineSmall),
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('System Status'),
              subtitle: Text('All services operational'),
              trailing: Text('Healthy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // --- Verification Tab ---
  Widget _buildVerificationTab(AdminDashboardProvider provider) {
    final pending = provider.pendingVerifications;

    if (pending.isEmpty) {
      return const Center(child: Text('No pending verifications'));
    }

    return ListView.builder(
      itemCount: pending.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = pending[index];
        final user = item['user'] ?? {};
        final submission = item['submission'] ?? {};
        final subId = item['id'];

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(child: Text((user['email'] ?? 'U')[0].toUpperCase())),
            title: Text(user['email'] ?? 'Unknown User'),
            subtitle: Text('Role: ${submission['userRole']} • ${submission['submittedAt'] != null ? DateFormat('MMM d').format((submission['submittedAt'] as dynamic).toDate()) : ''}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submitted Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(submission['documentInfo'] as List<dynamic>? ?? []).map((doc) => 
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.file_present),
                        title: Text(doc['type']),
                        subtitle: Text(doc['information']),
                      )
                    ).toList(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showRejectDialog(context, subId),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _approveSubmission(subId),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Approve'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approveSubmission(String submissionId) async {
      // In a real app we would get the current admin ID properly
      final adminId = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid ?? 'admin';
      await Provider.of<AdminDashboardProvider>(context, listen: false)
          .reviewVerification(submissionId, adminId, VerificationStatus.approved, null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved!')));
      }
  }

  void _showRejectDialog(BuildContext context, String submissionId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final adminId = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid ?? 'admin';
              await Provider.of<AdminDashboardProvider>(context, listen: false)
                  .reviewVerification(submissionId, adminId, VerificationStatus.rejected, noteController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- Governance Tab ---
  Widget _buildGovernanceTab(AdminDashboardProvider provider) {
    // Placeholder for search functionality
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search User by Email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              // Implementation would hook into provider to search users
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search not implemented in this demo')));
            },
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Center(
              child: Text(
                'Governance tools allow you to search for users and suspend them or reset their roles.\n\n(Use the search bar above)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
