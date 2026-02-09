import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/query.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({Key? key}) : super(key: key);

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  QueryStatus? _selectedStatus;
  QueryType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Consumer<NGOProvider>(
      builder: (context, ngoProvider, child) {
        final filteredQueries = _filterQueries(ngoProvider.myQueries);
        
        return Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<QueryStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<QueryStatus>(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            ...QueryStatus.values.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplayName(status)),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedStatus = value),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: DropdownButtonFormField<QueryType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<QueryType>(
                              value: null,
                              child: Text('All Types'),
                            ),
                            ...QueryType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(_getTypeDisplayName(type)),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedType = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Queries list
            Expanded(
              child: filteredQueries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No queries found'),
                          SizedBox(height: 8),
                          Text('Try adjusting your filters'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ngoProvider.refreshData(
                        Provider.of<AuthProvider>(context, listen: false).firebaseUser!.uid
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredQueries.length,
                        itemBuilder: (context, index) {
                          return _buildQueryCard(filteredQueries[index], ngoProvider);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Query> _filterQueries(List<Query> queries) {
    return queries.where((query) {
      if (_selectedStatus != null && query.status != _selectedStatus) {
        return false;
      }
      if (_selectedType != null && query.type != _selectedType) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildQueryCard(Query query, NGOProvider ngoProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and priority
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(query.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeDisplayName(query.type),
                    style: TextStyle(
                      color: _getTypeColor(query.type),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(query.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityDisplayName(query.priority),
                    style: TextStyle(
                      color: _getPriorityColor(query.priority),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(query.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(query.status),
                    style: TextStyle(
                      color: _getStatusColor(query.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Subject
            Text(
              query.subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              query.description,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Metadata
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(query.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                
                const SizedBox(width: 16),
                
                if (query.updates.isNotEmpty) ...[
                  Icon(Icons.update, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Last updated ${_formatDate(query.updates.last.timestamp)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewQueryDetails(query),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                if (query.status == QueryStatus.open || query.status == QueryStatus.inReview)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateQuery(query, ngoProvider),
                      icon: const Icon(Icons.edit),
                      label: const Text('Update'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewQueryDetails(Query query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        query.subject,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(query.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusDisplayName(query.status),
                        style: TextStyle(
                          color: _getStatusColor(query.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Query info
                _buildDetailSection('Query Information', [
                  _buildDetailRow('Type', _getTypeDisplayName(query.type)),
                  _buildDetailRow('Priority', _getPriorityDisplayName(query.priority)),
                  _buildDetailRow('Created', query.createdAt.toString().substring(0, 16)),
                  if (query.donationId != null) _buildDetailRow('Related Donation', query.donationId!),
                  if (query.requestId != null) _buildDetailRow('Related Request', query.requestId!),
                  if (query.assignmentId != null) _buildDetailRow('Related Assignment', query.assignmentId!),
                ]),
                
                const SizedBox(height: 16),
                
                // Description
                _buildDetailSection('Description', [
                  Text(query.description),
                ]),
                
                const SizedBox(height: 16),
                
                // Updates
                if (query.updates.isNotEmpty) ...[
                  Text(
                    'Updates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...query.updates.map((update) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                update.updatedBy,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(update.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(update.content),
                        ],
                      ),
                    ),
                  )),
                ],
                
                const SizedBox(height: 24),
                
                // Action button
                if (query.status == QueryStatus.open || query.status == QueryStatus.inReview)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateQuery(query, Provider.of<NGOProvider>(context, listen: false));
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Add Update'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _updateQuery(Query query, NGOProvider ngoProvider) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add an update to query: ${query.subject}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Update message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                ngoProvider.addQueryUpdate(query.id, messageController.text.trim());
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Query update added successfully')),
                );
              }
            },
            child: const Text('Add Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getStatusDisplayName(QueryStatus status) {
    switch (status) {
      case QueryStatus.open:
        return 'Open';
      case QueryStatus.inReview:
        return 'In Review';
      case QueryStatus.resolved:
        return 'Resolved';
      case QueryStatus.closed:
        return 'Closed';
    }
  }

  String _getTypeDisplayName(QueryType type) {
    switch (type) {
      case QueryType.donationDispute:
        return 'Donation Dispute';
      case QueryType.requestDispute:
        return 'Request Dispute';
      case QueryType.qualityIssue:
        return 'Quality Issue';
      case QueryType.deliveryIssue:
        return 'Delivery Issue';
      case QueryType.matchingIssue:
        return 'Matching Issue';
      case QueryType.volunteerIssue:
        return 'Volunteer Issue';
      case QueryType.other:
        return 'Other';
    }
  }

  String _getPriorityDisplayName(QueryPriority priority) {
    switch (priority) {
      case QueryPriority.low:
        return 'Low';
      case QueryPriority.medium:
        return 'Medium';
      case QueryPriority.high:
        return 'High';
      case QueryPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getStatusColor(QueryStatus status) {
    switch (status) {
      case QueryStatus.open:
        return Colors.orange;
      case QueryStatus.inReview:
        return Colors.blue;
      case QueryStatus.resolved:
        return Colors.green;
      case QueryStatus.closed:
        return Colors.grey;
    }
  }

  Color _getTypeColor(QueryType type) {
    switch (type) {
      case QueryType.donationDispute:
        return Colors.red;
      case QueryType.requestDispute:
        return Colors.purple;
      case QueryType.qualityIssue:
        return Colors.amber;
      case QueryType.deliveryIssue:
        return Colors.blue;
      case QueryType.matchingIssue:
        return Colors.orange;
      case QueryType.volunteerIssue:
        return Colors.teal;
      case QueryType.other:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(QueryPriority priority) {
    switch (priority) {
      case QueryPriority.low:
        return Colors.green;
      case QueryPriority.medium:
        return Colors.orange;
      case QueryPriority.high:
        return Colors.red;
      case QueryPriority.urgent:
        return Colors.purple;
    }
  }
}