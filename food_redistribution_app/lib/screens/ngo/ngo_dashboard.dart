import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_request.dart';
import 'create_food_request_screen.dart';
import 'food_request_detail_screen.dart';
import 'available_donations_screen.dart';
import 'queries_screen.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({Key? key}) : super(key: key);

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ngoProvider = Provider.of<NGOProvider>(context, listen: false);
      
      if (authProvider.firebaseUser != null) {
        ngoProvider.loadNGOData(authProvider.firebaseUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NGOProvider, AuthProvider>(
      builder: (context, ngoProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NGO Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (authProvider.firebaseUser != null) {
                    ngoProvider.refreshData(authProvider.firebaseUser!.uid);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, authProvider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.restaurant), text: 'My Requests'),
                Tab(icon: Icon(Icons.local_shipping), text: 'Available'),
                Tab(icon: Icon(Icons.help), text: 'Queries'),
              ],
            ),
          ),
          body: ngoProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(ngoProvider, authProvider),
                    _buildMyRequestsTab(ngoProvider, authProvider),
                    _buildAvailableDonationsTab(ngoProvider, authProvider),
                    _buildQueriesTab(ngoProvider, authProvider),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createFoodRequest(context, authProvider),
            icon: const Icon(Icons.add),
            label: const Text('Create Request'),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(NGOProvider ngoProvider, AuthProvider authProvider) {
    final stats = ngoProvider.dashboardStats;
    
    return RefreshIndicator(
        onRefresh: () => ngoProvider.refreshData(authProvider.firebaseUser!.uid),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your food requests and track donations.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics cards
            Text(
              'Request Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Requests',
                    '${stats['totalRequests'] ?? 0}',
                    Icons.restaurant_menu,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '${stats['pendingRequests'] ?? 0}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Matched',
                    '${stats['matchedRequests'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Critical',
                    '${stats['criticalRequests'] ?? 0}',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            _buildStatCard(
              'Total Beneficiaries',
              '${stats['totalBeneficiaries'] ?? 0}',
              Icons.people,
              Colors.purple,
            ),
            
            const SizedBox(height: 24),
            
            // Recent requests
            Text(
              'Recent Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            ...ngoProvider.myRequests.take(3).map((request) => 
              _buildRequestCard(request, ngoProvider, authProvider)),
            
            if (ngoProvider.myRequests.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View All Requests'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab(NGOProvider ngoProvider, AuthProvider authProvider) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Matched'),
              Tab(text: 'Urgent'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestsList(ngoProvider.myRequests, ngoProvider, authProvider),
                _buildRequestsList(ngoProvider.pendingRequests, ngoProvider, authProvider),
                _buildRequestsList(ngoProvider.matchedRequests, ngoProvider, authProvider),
                _buildRequestsList(ngoProvider.urgentRequests, ngoProvider, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDonationsTab(NGOProvider ngoProvider, AuthProvider authProvider) {
    return AvailableDonationsScreen();
  }

  Widget _buildQueriesTab(NGOProvider ngoProvider, AuthProvider authProvider) {
    return const QueriesScreen();
  }

  Widget _buildRequestsList(List<FoodRequest> requests, NGOProvider ngoProvider, AuthProvider authProvider) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No food requests found'),
            SizedBox(height: 8),
            Text('Create a request to get started'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ngoProvider.refreshData(authProvider.firebaseUser!.uid),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index], ngoProvider, authProvider);
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(FoodRequest request, NGOProvider ngoProvider, AuthProvider authProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(request.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(request.status),
            color: _getStatusColor(request.status),
          ),
        ),
        title: Text(request.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.requiredQuantity} ${request.unit} • ${request.expectedBeneficiaries} beneficiaries'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(request.status.name.toUpperCase()),
                  backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getStatusColor(request.status)),
                ),
                const SizedBox(width: 8),
                if (request.urgency == RequestUrgency.critical || request.urgency == RequestUrgency.high)
                  Chip(
                    label: Text(request.urgency.name.toUpperCase()),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodRequestDetailScreen(requestId: request.id),
          ),
        ),
      ),
    );
  }

  void _createFoodRequest(BuildContext context, AuthProvider authProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateFoodRequestScreen(),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.matched:
        return Colors.blue;
      case RequestStatus.fulfilled:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.pending;
      case RequestStatus.matched:
        return Icons.handshake;
      case RequestStatus.fulfilled:
        return Icons.check_circle;
      case RequestStatus.cancelled:
        return Icons.cancel;
      case RequestStatus.expired:
        return Icons.timer_off;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}