import 'package:flutter/material.dart';
import '../status_lifecycle_engine.dart';

class SyncStatusIndicator extends StatelessWidget {
  final StatusLifecycleEngine engine;

  const SyncStatusIndicator({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final hasPending = engine.offlineQueue.hasPending;
    final isOnline = engine.offlineQueue.isOnline;

    return Row(
      children: [
        if (!isOnline) ...[
          const Icon(Icons.cloud_off, color: Colors.orange),
          const SizedBox(width: 6),
          const Text('Offline', style: TextStyle(color: Colors.orange)),
        ] else if (hasPending) ...[
          const SizedBox(width: 2),
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 6),
          const Text('Syncing', style: TextStyle(color: Colors.blue)),
        ] else ...[
          const Icon(Icons.cloud_done, color: Colors.green),
          const SizedBox(width: 6),
          const Text('Synced', style: TextStyle(color: Colors.green)),
        ]
      ],
    );
  }
}
