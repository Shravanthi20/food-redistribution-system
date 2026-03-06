import 'package:flutter/material.dart';
import '../../services/dispatch_service.dart';
import '../../services/real_time_tracking_service.dart';
import '../../services/route_optimization_service.dart';
// import '../../services/matching_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../models/matching.dart';

class DeliveryCoordinationScreen extends StatefulWidget {
  const DeliveryCoordinationScreen({super.key});

  @override
  DeliveryCoordinationScreenState createState() =>
      DeliveryCoordinationScreenState();
}

class DeliveryCoordinationScreenState
    extends State<DeliveryCoordinationScreen> {
  // ignore: unused_field
  late final VolunteerDispatchService _dispatchService;
  // ignore: unused_field
  late final RealTimeTrackingService _trackingService;
  // ignore: unused_field
  late final RouteOptimizationEngine _routeService;
  // late FoodDonationMatchingService _matchingService;

  final List<DeliveryTask> _activeTasks = [];
  // ignore: unused_field
  final List<MatchingResult> _availableMatches = [];
  DeliveryTask? _selectedTask;
  bool _isLoading = false;
  // ignore: unused_field
  String _searchQuery = '';

  // TextControllers for create task dialog
  final _donationIdController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadActiveTasks();
  }

  void _initializeServices() {
    // Initialize services with providers
    // These would be injected via dependency injection in a real app
  }

  Future<void> _loadActiveTasks() async {
    setState(() => _isLoading = true);
    try {
      // Load active delivery tasks
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      // _activeTasks = await _dispatchService.getActiveTasks();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delivery Coordination',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTasks,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildSearchAndFilters(),
            _buildTaskSummary(),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 1, child: _buildTasksList()),
                  Container(width: 1, color: Colors.grey[300]),
                  Expanded(flex: 2, child: _buildTaskDetails()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewDeliveryTask(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks, volunteers, or locations...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterChip('All Tasks', true),
          const SizedBox(width: 8),
          _buildFilterChip('Urgent', false),
          const SizedBox(width: 8),
          _buildFilterChip('In Transit', false),
          const SizedBox(width: 8),
          _buildFilterChip('Delayed', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        // Implement filtering logic
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildTaskSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildSummaryCard(
              'Active Tasks', '${_activeTasks.length}', Colors.blue),
          const SizedBox(width: 12),
          _buildSummaryCard('In Transit', '3', Colors.orange),
          const SizedBox(width: 12),
          _buildSummaryCard('Completed Today', '12', Colors.green),
          const SizedBox(width: 12),
          _buildSummaryCard('Delayed', '1', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Active Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _activeTasks.length + 3, // Demo data
              itemBuilder: (context, index) => _buildTaskCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(int index) {
    // Demo task data
    final demoTasks = [
      {
        'id': 'TASK-001',
        'donor': 'Central Kitchen',
        'ngo': 'Hope Foundation',
        'volunteer': 'John Smith',
        'status': 'In Transit',
        'priority': 'High',
        'distance': '2.3 km',
        'eta': '15 min',
        'color': Colors.orange,
      },
      {
        'id': 'TASK-002',
        'donor': 'Green Cafe',
        'ngo': 'Food Bank Network',
        'volunteer': 'Maria Garcia',
        'status': 'At Pickup',
        'priority': 'Medium',
        'distance': '1.8 km',
        'eta': '8 min',
        'color': Colors.blue,
      },
      {
        'id': 'TASK-003',
        'donor': 'Metro Restaurant',
        'ngo': 'Community Kitchen',
        'volunteer': 'Unassigned',
        'status': 'Pending',
        'priority': 'Urgent',
        'distance': '5.2 km',
        'eta': 'TBD',
        'color': Colors.red,
      },
    ];

    if (index >= demoTasks.length) return Container();

    final task = demoTasks[index];
    final isSelected = _selectedTask?.id == task['id'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Theme.of(context).primaryColor)
            : null,
      ),
      child: ListTile(
        onTap: () => setState(() {
          // _selectedTask = task;
        }),
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: task['color'] as Color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(task['id'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task['donor']} → ${task['ngo']}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(task['volunteer'] as String,
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Text(task['distance'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (task['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task['status'] as String,
                style: TextStyle(
                    fontSize: 10,
                    color: task['color'] as Color,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 2),
            Text('ETA: ${task['eta']}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetails() {
    if (_selectedTask == null) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Select a task to view details',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskHeader(),
          const Divider(height: 32),
          _buildLocationDetails(),
          const SizedBox(height: 16),
          _buildVolunteerInfo(),
          const SizedBox(height: 16),
          _buildTrackingMap(),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('TASK-001',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('In Transit',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Food delivery from Central Kitchen to Hope Foundation',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(Icons.schedule, 'Priority: High', Colors.red),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.route, '2.3 km', Colors.blue),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.timer, 'ETA: 15 min', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Route Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildLocationCard(
          icon: Icons.restaurant,
          title: 'Pickup Location',
          subtitle: 'Central Kitchen',
          address: '123 Main Street, Downtown',
          status: 'Completed',
          statusColor: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildLocationCard(
          icon: Icons.home,
          title: 'Delivery Location',
          subtitle: 'Hope Foundation',
          address: '456 Community Avenue, North District',
          status: 'En Route',
          statusColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String address,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                Text(address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Volunteer Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('JS', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('John Smith',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('4.8 ⭐ • 127 deliveries completed'),
                    Text('Phone: +1 (555) 123-4567',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _callVolunteer(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.blue),
                    onPressed: () => _messageVolunteer(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live Tracking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Live Map View',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Last updated: 2 minutes ago',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _optimizeRoute(),
            icon: const Icon(Icons.route),
            label: const Text('Optimize Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _reassignVolunteer(),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Reassign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _markComplete(),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _createNewDeliveryTask() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateTaskDialog(),
    );
  }

  Widget _buildCreateTaskDialog() {
    return AlertDialog(
      title: const Text('Create New Delivery Task'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _donationIdController,
              label: 'Donation ID',
              hintText: 'Enter donation identifier',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pickupAddressController,
              label: 'Pickup Address',
              hintText: 'Enter pickup location',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _deliveryAddressController,
              label: 'Delivery Address',
              hintText: 'Enter delivery location',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Priority Level',
                border: OutlineInputBorder(),
              ),
              items: ['Low', 'Medium', 'High', 'Urgent']
                  .map((priority) =>
                      DropdownMenuItem(value: priority, child: Text(priority)))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _createTask();
          },
          child: const Text('Create Task'),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coordination Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-assign volunteers'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Real-time notifications'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Route optimization'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _callVolunteer() {
    // Implement phone call functionality
  }

  void _messageVolunteer() {
    // Implement messaging functionality
  }

  void _optimizeRoute() {
    // Implement route optimization
  }

  void _reassignVolunteer() {
    // Implement volunteer reassignment
  }

  void _markComplete() {
    // Implement task completion
  }

  void _createTask() {
    // Implement task creation
  }
}
