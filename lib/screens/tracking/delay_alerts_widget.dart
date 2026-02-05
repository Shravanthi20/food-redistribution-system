import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';

// Display all active delay alerts with actions
class DelayAlertsWidget extends StatelessWidget {
  final bool compact;
  final VoidCallback? onResolveCallback;

  const DelayAlertsWidget({
    super.key,
    this.compact = false,
    this.onResolveCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, trackingProvider, _) {
        if (trackingProvider.delayAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.red[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delay Alerts (${trackingProvider.delayAlerts.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...trackingProvider.delayAlerts.map((alert) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                                      '${alert.type} - ${alert.severity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (alert.reason.isNotEmpty)
                                      Text(
                                        alert.reason,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (!compact)
                                ElevatedButton(
                                  onPressed: () {
                                    trackingProvider.resolveDelayAlert(
                                      alert.id,
                                      resolution: 'Resolved by user',
                                    );
                                    onResolveCallback?.call();
                                  },
                                  child: const Text('Resolve'),
                                ),
                            ],
                          ),
                        ],
                     ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
