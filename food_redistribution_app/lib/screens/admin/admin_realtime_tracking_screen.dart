import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/tracking/location_tracking_model.dart';

/// Admin Real-Time Tracking Management Screen
class AdminRealTimeTrackingScreen extends StatefulWidget {
  const AdminRealTimeTrackingScreen({Key? key}) : super(key: key);

  @override
  State<AdminRealTimeTrackingScreen> createState() => _AdminRealTimeTrackingScreenState();
}

class _AdminRealTimeTrackingScreenState extends State<AdminRealTimeTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // all, active, delayed, completed
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Tracking'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters and Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by volunteer, task ID, or location',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Status filter chips
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Tasks'),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'all');
                      },
                    ),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _filterStatus == 'active',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'active');
                      },
                    ),
                    FilterChip(
                      label: const Text('Delayed'),
                      selected: _filterStatus == 'delayed',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'delayed');
                      },
                    ),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: _filterStatus == 'completed',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'completed');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tracking list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tracking data available'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildTrackingCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Query<Object?> _buildQuery() {
    var query = _firestore.collection('delivery_tasks').orderBy('updatedAt', descending: true);

    // Apply status filter
    if (_filterStatus == 'active') {
      query = query.where('status', whereIn: ['assigned', 'picked_up', 'in_transit']);
    } else if (_filterStatus == 'delayed') {
      query = query.where('isDelayed', isEqualTo: true);
    } else if (_filterStatus == 'completed') {
      query = query.where('status', isEqualTo: 'delivered');
    }

    return query.limit(100);
  }

  Widget _buildTrackingCard(Map<String, dynamic> data, String taskId) {
    final volunteerId = data['volunteerId'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'unknown';
    final isDelayed = data['isDelayed'] as bool? ?? false;
    final lastUpdateTime = (data['lastLocationUpdate'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task: $taskId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Volunteer: $volunteerId',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location and timing info
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Last update: ${_formatTime(lastUpdateTime)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (isDelayed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'DELAYED - Intervention may be needed',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewTracking(taskId),
                  icon: const Icon(Icons.map),
                  label: const Text('View Map'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewDetails(taskId),
                  icon: const Icon(Icons.info),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
      case 'in_transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Never';
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  void _viewTracking(String taskId) {
    // Navigate to tracking map view
    Navigator.of(context).pushNamed(
      '/admin/tracking-map',
      arguments: taskId,
    );
  }

  void _viewDetails(String taskId) {
    // Show task details dialog
    showDialog(
      context: context,
      builder: (context) => _buildDetailsDialog(taskId),
    );
  }

  Widget _buildDetailsDialog(String taskId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('delivery_tasks').doc(taskId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Task not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Task Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRow('Task ID', taskId),
                _buildDetailRow('Volunteer', data['volunteerId'] ?? 'N/A'),
                _buildDetailRow('Status', (data['status'] as String? ?? 'unknown').toUpperCase()),
                _buildDetailRow('NGO', data['ngoId'] ?? 'N/A'),
                _buildDetailRow('Food Type', data['foodType'] ?? 'N/A'),
                _buildDetailRow('Quantity', data['quantity']?.toString() ?? 'N/A'),
                if (data['assignedAt'] != null)
                  _buildDetailRow('Assigned', _formatDateTime(data['assignedAt'])),
                if (data['pickedUpAt'] != null)
                  _buildDetailRow('Picked Up', _formatDateTime(data['pickedUpAt'])),
                if (data['deliveredAt'] != null)
                  _buildDetailRow('Delivered', _formatDateTime(data['deliveredAt'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split('.')[0];
    }
    return 'N/A';
  }
}
