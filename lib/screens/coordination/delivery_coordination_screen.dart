import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/dispatch_service.dart';
import '../../services/real_time_tracking_service.dart';
import '../../services/route_optimization_service.dart';
import '../../services/matching_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../models/enums.dart';
import '../../models/dispatch.dart';
import '../../models/matching.dart';

class DeliveryCoordinationScreen extends StatefulWidget {
  @override
  _DeliveryCoordinationScreenState createState() => _DeliveryCoordinationScreenState();
}

class _DeliveryCoordinationScreenState extends State<DeliveryCoordinationScreen> {
  late VolunteerDispatchService _dispatchService;
  late RealTimeTrackingService _trackingService;
  late RouteOptimizationService _routeService;
  late FoodDonationMatchingService _matchingService;
  
  List<DeliveryTask> _activeTasks = [];
  List<MatchingResult> _availableMatches = [];
  DeliveryTask? _selectedTask;
  bool _isLoading = false;
  String _searchQuery = '';
  
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
      await Future.delayed(Duration(seconds: 1)); // Simulate loading
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
        title: Text('Delivery Coordination', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadActiveTasks,
          ),
          IconButton(
            icon: Icon(Icons.settings),
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
        icon: Icon(Icons.add),
        label: Text('New Task'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks, volunteers, or locations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(width: 12),
          _buildFilterChip('All Tasks', true),
          SizedBox(width: 8),
          _buildFilterChip('Urgent', false),
          SizedBox(width: 8),
          _buildFilterChip('In Transit', false),
          SizedBox(width: 8),
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
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }
  
  Widget _buildTaskSummary() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildSummaryCard('Active Tasks', '${_activeTasks.length}', Colors.blue),
          SizedBox(width: 12),
          _buildSummaryCard('In Transit', '3', Colors.orange),
          SizedBox(width: 12),
          _buildSummaryCard('Completed Today', '12', Colors.green),
          SizedBox(width: 12),
          _buildSummaryCard('Delayed', '1', Colors.red),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Active Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
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
        title: Text(task['id'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task['donor']} → ${task['ngo']}'),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(task['volunteer'] as String, style: TextStyle(fontSize: 12)),
                Spacer(),
                Text(task['distance'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (task['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task['status'] as String,
                style: TextStyle(fontSize: 10, color: task['color'] as Color, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 2),
            Text('ETA: ${task['eta']}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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
              SizedBox(height: 16),
              Text('Select a task to view details', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskHeader(),
          Divider(height: 32),
          _buildLocationDetails(),
          SizedBox(height: 16),
          _buildVolunteerInfo(),
          SizedBox(height: 16),
          _buildTrackingMap(),
          Spacer(),
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
            Text('TASK-001', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('In Transit', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text('Food delivery from Central Kitchen to Hope Foundation', style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(Icons.schedule, 'Priority: High', Colors.red),
            SizedBox(width: 8),
            _buildInfoChip(Icons.route, '2.3 km', Colors.blue),
            SizedBox(width: 8),
            _buildInfoChip(Icons.timer, 'ETA: 15 min', Colors.green),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
  
  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Route Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        _buildLocationCard(
          icon: Icons.restaurant,
          title: 'Pickup Location',
          subtitle: 'Central Kitchen',
          address: '123 Main Street, Downtown',
          status: 'Completed',
          statusColor: Colors.green,
        ),
        SizedBox(height: 8),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                Text(address, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVolunteerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volunteer Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('JS', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('John Smith', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('4.8 ⭐ • 127 deliveries completed'),
                    Text('Phone: +1 (555) 123-4567', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _callVolunteer(),
                  ),
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.blue),
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
        Text('Live Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
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
                SizedBox(height: 8),
                Text('Live Map View', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 4),
                Text('Last updated: 2 minutes ago', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
            icon: Icon(Icons.route),
            label: Text('Optimize Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _reassignVolunteer(),
            icon: Icon(Icons.swap_horiz),
            label: Text('Reassign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _markComplete(),
            icon: Icon(Icons.check_circle),
            label: Text('Mark Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
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
      title: Text('Create New Delivery Task'),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Donation ID',
              hint: 'Enter donation identifier',
            ),
            SizedBox(height: 12),
            CustomTextField(
              label: 'Pickup Address',
              hint: 'Enter pickup location',
            ),
            SizedBox(height: 12),
            CustomTextField(
              label: 'Delivery Address',
              hint: 'Enter delivery location',
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Priority Level',
                border: OutlineInputBorder(),
              ),
              items: ['Low', 'Medium', 'High', 'Urgent']
                  .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _createTask();
          },
          child: Text('Create Task'),
        ),
      ],
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coordination Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Auto-assign volunteers'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Real-time notifications'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Route optimization'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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
