import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/dispatch_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/audit_service.dart';
import '../../models/enums.dart' show DeliveryStatus;
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class DeliveryCoordinationScreen extends StatefulWidget {
  const DeliveryCoordinationScreen({super.key});

  @override
  DeliveryCoordinationScreenState createState() =>
      DeliveryCoordinationScreenState();
}

class DeliveryCoordinationScreenState
    extends State<DeliveryCoordinationScreen> {
  late final VolunteerDispatchService _dispatchService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<DeliveryTask> _activeTasks = [];
  DeliveryTask? _selectedTask;
  bool _isLoading = false;
  String _searchQuery = '';

  // Real-time stats
  int _inTransitCount = 0;
  int _completedTodayCount = 0;
  int _delayedCount = 0;

  // Selected task detail data
  Map<String, dynamic>? _selectedDonationData;
  Map<String, dynamic>? _selectedVolunteerData;

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
    _dispatchService = VolunteerDispatchService(
      firestoreService: FirestoreService(),
      locationService: LocationService(),
      notificationService: NotificationService(),
      auditService: AuditService(),
    );
  }

  Future<void> _loadActiveTasks() async {
    setState(() => _isLoading = true);
    try {
      // Load active delivery tasks from Firestore
      final tasksSnapshot = await _firestore
          .collection('delivery_tasks')
          .where('status',
              whereIn: ['pending', 'assigned', 'pickedUp', 'inTransit'])
          .orderBy('scheduledTime', descending: true)
          .limit(50)
          .get();

      _activeTasks.clear();
      for (final doc in tasksSnapshot.docs) {
        try {
          _activeTasks.add(DeliveryTask.fromMap(doc.data(), id: doc.id));
        } catch (_) {}
      }

      // Count stats
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      _inTransitCount = _activeTasks
          .where((t) => t.status == DeliveryStatus.inTransit)
          .length;

      final completedSnapshot = await _firestore
          .collection('delivery_tasks')
          .where('status', isEqualTo: 'delivered')
          .where('scheduledTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();
      _completedTodayCount = completedSnapshot.docs.length;

      _delayedCount = _activeTasks.where((t) {
        final scheduled = t.scheduledTime;
        return scheduled.isBefore(now) &&
            t.status != DeliveryStatus.delivered &&
            t.status != DeliveryStatus.cancelled;
      }).length;
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTaskDetails(DeliveryTask task) async {
    try {
      // Load donation data
      final donationDoc =
          await _firestore.collection('donations').doc(task.donationId).get();
      _selectedDonationData = donationDoc.data();

      // Load volunteer data if assigned
      if (task.assignedVolunteerId != null) {
        final volunteerDoc = await _firestore
            .collection('users')
            .doc(task.assignedVolunteerId)
            .get();
        _selectedVolunteerData = volunteerDoc.data();
      } else {
        _selectedVolunteerData = null;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading task details: $e');
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
          _buildSummaryCard('In Transit', '$_inTransitCount', Colors.orange),
          const SizedBox(width: 12),
          _buildSummaryCard(
              'Completed Today', '$_completedTodayCount', Colors.green),
          const SizedBox(width: 12),
          _buildSummaryCard('Delayed', '$_delayedCount', Colors.red),
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
    final filtered = _searchQuery.isEmpty
        ? _activeTasks
        : _activeTasks
            .where((t) =>
                t.pickupAddress
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                t.deliveryAddress
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                t.donationId.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No active tasks'
                          : 'No tasks match "$_searchQuery"',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildTaskCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DeliveryTask task) {
    final isSelected = _selectedTask?.id == task.id;
    final statusColor = _getStatusColor(task.status);
    final statusText = task.status.name;

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
        onTap: () {
          setState(() => _selectedTask = task);
          _loadTaskDetails(task);
        },
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(task.id.length > 8 ? task.id.substring(0, 8) : task.id,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task.pickupAddress} → ${task.deliveryAddress}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.assignedVolunteerId ?? 'Unassigned',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
                fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.grey;
      case DeliveryStatus.assigned:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.teal;
      case DeliveryStatus.inTransit:
        return Colors.orange;
      case DeliveryStatus.arrived:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
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
    if (_selectedTask == null) return const SizedBox.shrink();
    final task = _selectedTask!;
    final statusColor = _getStatusColor(task.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(task.id.length > 12 ? task.id.substring(0, 12) : task.id,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(task.status.name,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'From ${task.pickupAddress} to ${task.deliveryAddress}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
                Icons.schedule,
                'Priority: ${task.priority.name}',
                task.priority == DispatchPriority.immediate ||
                        task.priority == DispatchPriority.urgent
                    ? Colors.red
                    : Colors.blue),
            const SizedBox(width: 8),
            if (task.specialInstructions != null)
              _buildInfoChip(
                  Icons.info, task.specialInstructions!, Colors.grey),
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
    if (_selectedTask == null) return const SizedBox.shrink();
    final task = _selectedTask!;
    final pickupDone = task.status != DeliveryStatus.pending &&
        task.status != DeliveryStatus.assigned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Route Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildLocationCard(
          icon: Icons.restaurant,
          title: 'Pickup Location',
          subtitle: _selectedDonationData?['title'] ?? 'Pickup',
          address: task.pickupAddress,
          status: pickupDone ? 'Completed' : 'Pending',
          statusColor: pickupDone ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 8),
        _buildLocationCard(
          icon: Icons.home,
          title: 'Delivery Location',
          subtitle: _selectedDonationData?['ngoName'] ?? 'Delivery',
          address: task.deliveryAddress,
          status: task.status == DeliveryStatus.delivered
              ? 'Delivered'
              : task.status == DeliveryStatus.inTransit
                  ? 'En Route'
                  : 'Waiting',
          statusColor: task.status == DeliveryStatus.delivered
              ? Colors.green
              : task.status == DeliveryStatus.inTransit
                  ? Colors.orange
                  : Colors.grey,
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
    final volunteerName = _selectedVolunteerData != null
        ? '${_selectedVolunteerData!['profile']?['firstName'] ?? ''} ${_selectedVolunteerData!['profile']?['lastName'] ?? ''}'
            .trim()
        : 'Unassigned';
    final initials = volunteerName.isNotEmpty && volunteerName != 'Unassigned'
        ? volunteerName
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
        : '?';
    final phone = _selectedVolunteerData?['profile']?['phone'] ?? '';
    final rating = _selectedVolunteerData?['profile']?['rating'];
    final completedTasks =
        _selectedVolunteerData?['profile']?['completedTasks'] ?? 0;

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
              CircleAvatar(
                backgroundColor: Colors.blue,
                child:
                    Text(initials, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(volunteerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (rating != null)
                      Text('$rating ⭐ • $completedTasks deliveries completed'),
                    if (phone.isNotEmpty)
                      Text('Phone: $phone',
                          style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              if (volunteerName != 'Unassigned') ...[
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: _callVolunteer,
                  tooltip: 'Call Volunteer',
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: _messageVolunteer,
                  tooltip: 'Message Volunteer',
                ),
              ],
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
        const Text('Tracking Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedTask != null
              ? StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('delivery_tasks')
                      .doc(_selectedTask!.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final status = data?['status'] ?? 'unknown';
                    final updatedAt = data?['updatedAt'] as Timestamp?;
                    final lastUpdate = updatedAt != null
                        ? '${DateTime.now().difference(updatedAt.toDate()).inMinutes} minutes ago'
                        : 'N/A';

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == 'inTransit'
                                ? Icons.local_shipping
                                : status == 'delivered'
                                    ? Icons.check_circle
                                    : Icons.hourglass_empty,
                            size: 48,
                            color: _getStatusColor(
                              DeliveryStatus.values.firstWhere(
                                (s) => s.name == status,
                                orElse: () => DeliveryStatus.pending,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: $status',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Last updated: $lastUpdate',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Select a task to view status',
                          style: TextStyle(color: Colors.grey[600])),
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
    // Launch phone dialer - not available in this context, show info
    if (_selectedVolunteerData != null) {
      final phone = _selectedVolunteerData!['profile']?['phone'] ?? '';
      if (phone.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Volunteer phone: $phone')),
        );
      }
    }
  }

  void _messageVolunteer() {
    if (_selectedVolunteerData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In-app messaging not yet available')),
      );
    }
  }

  void _optimizeRoute() {
    if (_selectedTask == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route optimization requested')),
    );
  }

  Future<void> _reassignVolunteer() async {
    if (_selectedTask == null) return;
    try {
      // Reset volunteer assignment
      await _firestore
          .collection('delivery_tasks')
          .doc(_selectedTask!.id)
          .update({
        'assignedVolunteerId': null,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task unassigned. Awaiting new volunteer.')),
      );
      _loadActiveTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markComplete() async {
    if (_selectedTask == null) return;
    try {
      await _firestore
          .collection('delivery_tasks')
          .doc(_selectedTask!.id)
          .update({
        'status': 'delivered',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Also update the donation status
      await _firestore
          .collection('donations')
          .doc(_selectedTask!.donationId)
          .update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed')),
      );
      setState(() => _selectedTask = null);
      _loadActiveTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createTask() async {
    final donationId = _donationIdController.text.trim();
    final pickupAddress = _pickupAddressController.text.trim();
    final deliveryAddress = _deliveryAddressController.text.trim();

    if (donationId.isEmpty ||
        pickupAddress.isEmpty ||
        deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await _dispatchService.createDeliveryTask(
        donationId: donationId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        pickupLocation: {'lat': 0.0, 'lng': 0.0},
        deliveryLocation: {'lat': 0.0, 'lng': 0.0},
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      );
      _donationIdController.clear();
      _pickupAddressController.clear();
      _deliveryAddressController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery task created')),
      );
      _loadActiveTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating task: $e')),
      );
    }
  }
}
