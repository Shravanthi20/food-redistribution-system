import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';

// Show current delivery/tracking status
class TrackingStatusCard extends StatelessWidget {
  final bool showFullDetails;

  const TrackingStatusCard({
    Key? key,
    this.showFullDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, trackingProvider, _) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tracking Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        trackingProvider.isOnline ? '🟢 Online' : '🔴 Offline',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: trackingProvider.isOnline
                          ? Colors.green[100]
                          : Colors.red[100],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusRow('Active Tracking:', trackingProvider.isTracking ? '✅ Yes' : '❌ No'),
                _buildStatusRow(
                  'Current Status:',
                  _getStatusEmoji(trackingProvider.currentStatus) + (trackingProvider.currentStatus ?? 'No task'),
                ),
                _buildStatusRow('Pending Syncs:', '${trackingProvider.pendingUpdates}'),
                if (showFullDetails) ...[
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Last Update:',
                    _formatTime(trackingProvider.lastSync),
                  ),
                  _buildStatusRow(
                    'Active Deliveries:',
                    '${trackingProvider.activeTasksCount}',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _getStatusEmoji(String? status) {
    const statusEmojis = {
      'listed': '📋 ',
      'matched': '✅ ',
      'picked': '📦 ',
      'delivered': '🎯 ',
    };
    return statusEmojis[status] ?? '⏳ ';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
