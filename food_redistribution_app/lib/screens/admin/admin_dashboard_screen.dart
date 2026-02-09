import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audit_service.dart';
import '../../services/security_service.dart';
import '../../services/user_service.dart';
import '../../services/verification_service.dart';
import '../../models/user.dart';
import '../../providers/theme_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final AuditService _auditService = AuditService();
  final SecurityService _securityService = SecurityService();
  final UserService _userService = UserService();
  final VerificationService _verificationService = VerificationService();
  
  Map<String, dynamic> userStats = {};
  Map<String, dynamic> securityStats = {};
  Map<String, dynamic> verificationStats = {};
  List<Map<String, dynamic>> pendingVerifications = [];
  List<Map<String, dynamic>> recentAuditLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        _userService.getUserStatistics(),
        _securityService.getSecurityStats(),
        _verificationService.getVerificationStats(),
        _verificationService.getPendingVerifications(),
        _auditService.getAuditLogs(limit: 10),
      ]);
      
      setState(() {
        userStats = results[0] as Map<String, dynamic>;
        securityStats = results[1] as Map<String, dynamic>;
        verificationStats = results[2] as Map<String, dynamic>;
        pendingVerifications = results[3] as List<Map<String, dynamic>>;
        recentAuditLogs = results[4] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle Theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verifications'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildVerificationsTab(),
                _buildSecurityTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '${userStats['totalUsers'] ?? 0}', Icons.people, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Pending', '${verificationStats['pendingCount'] ?? 0}', Icons.pending_actions, Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Security Alerts', '${securityStats['currentlyLockedAccounts'] ?? 0}', Icons.warning_amber, Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('New Users (30d)', '${userStats['newUsersThisMonth'] ?? 0}', Icons.trending_up, Colors.green)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...recentAuditLogs.take(5).map((log) => _buildAuditLogTile(log)).toList(),
                  if (recentAuditLogs.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No recent activity'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildUserRoleStat('Donors', userStats['donors'] ?? 0, Colors.green)),
                    Expanded(child: _buildUserRoleStat('NGOs', userStats['ngos'] ?? 0, Colors.blue)),
                    Expanded(child: _buildUserRoleStat('Volunteers', userStats['volunteers'] ?? 0, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildUserStatusStat('Verified', userStats['verified'] ?? 0, Colors.green)),
                    Expanded(child: _buildUserStatusStat('Suspended', userStats['suspended'] ?? 0, Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // User Management Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Search Users'),
                  subtitle: const Text('Find and manage specific users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Create Admin User'),
                  subtitle: const Text('Add new administrator'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCreateAdminDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Manage Suspensions'),
                  subtitle: const Text('Review suspended accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/admin/suspensions'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Verification Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildVerificationStat('Pending', verificationStats['pendingCount'] ?? 0, Colors.orange)),
                    Expanded(child: _buildVerificationStat('Approved', verificationStats['approvedCount'] ?? 0, Colors.green)),
                    Expanded(child: _buildVerificationStat('Rejected', verificationStats['rejectedCount'] ?? 0, Colors.red)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (verificationStats['approvalRate'] ?? 0) / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Approval Rate: ${(verificationStats['approvalRate'] ?? 0).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Pending Verifications
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Requests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/admin/verifications'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...pendingVerifications.take(5).map((verification) => _buildVerificationTile(verification)).toList(),
                if (pendingVerifications.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('No pending verifications'),
                    subtitle: Text('All requests processsed'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Security Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Overview (24h)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSecurityStat('Failed Logins', securityStats['failedLoginsLast24h'] ?? 0, Colors.red)),
                    Expanded(child: _buildSecurityStat('Successful Logins', securityStats['successfulLoginsLast24h'] ?? 0, Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSecurityStat('Locked Accounts', securityStats['currentlyLockedAccounts'] ?? 0, Colors.orange),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Security Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Audit Logs'),
                  subtitle: const Text('View system audit trail'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/admin/audit-logs'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: const Text('Unlock Accounts'),
                  subtitle: const Text('Manually unlock user accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/admin/unlock-accounts'),
                ),
                ListTile(
                  leading: const Icon(Icons.warning_amber),
                  title: const Text('Security Alerts'),
                  subtitle: const Text('Review security incidents'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/admin/security-alerts'),
                ),
              ],
            ),
          ), 
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRoleStat(String role, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(role, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildUserStatusStat(String status, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(status, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildVerificationStat(String status, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(status, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildSecurityStat(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTile(Map<String, dynamic> log) {
    IconData icon;
    Color color;
    
    switch (log['eventType']) {
      case 'userLogin':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'userLogout':
        icon = Icons.logout;
        color = Colors.blue;
        break;
      case 'verificationApproved':
        icon = Icons.verified_user;
        color = Colors.green;
        break;
      case 'userSuspended':
        icon = Icons.block;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color, size: 16),
      ),
      title: Text(_formatEventType(log['eventType'])),
      subtitle: Text(_formatTimestamp(log['timestamp'])),
      trailing: Text(
        log['riskLevel']?.toUpperCase() ?? 'LOW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getRiskColor(log['riskLevel']),
        ),
      ),
    );
  }

  Widget _buildVerificationTile(Map<String, dynamic> verification) {
    final submission = verification['submission'] as Map<String, dynamic>;
    final user = verification['user'] as Map<String, dynamic>;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.shade100,
        child: Icon(Icons.pending_actions, color: Colors.orange.shade700),
      ),
      title: Text(user['email'] ?? 'Unknown User'),
      subtitle: Text('${submission['userRole']} • ${_formatTimestamp(submission['submittedAt'])}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(
        context, 
        '/admin/verify-user',
        arguments: verification,
      ),
    );
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'userLogin':
        return 'User Login';
      case 'userLogout':
        return 'User Logout';
      case 'verificationApproved':
        return 'Verification Approved';
      case 'userSuspended':
        return 'User Suspended';
      default:
        return eventType;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        dateTime = timestamp.toDate();
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
      default:
        return Colors.green.shade600;
    }
  }

  void _showCreateAdminDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon')),
    );
  }
}