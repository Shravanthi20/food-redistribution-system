import 'package:flutter/material.dart';
import '../status_lifecycle_engine.dart';

class SyncStatusIndicator extends StatelessWidget {
  final StatusLifecycleEngine engine;

  const SyncStatusIndicator({Key? key, required this.engine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPending = engine.offlineQueue.hasPending;
    final isOnline = engine.offlineQueue.isOnline;

    return Row(
      children: [
        if (!isOnline) ...[
          Icon(Icons.cloud_off, color: Colors.orange),
          SizedBox(width: 6),
          Text('Offline', style: TextStyle(color: Colors.orange)),
        ] else if (hasPending) ...[
          SizedBox(width: 2),
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 6),
          Text('Syncing', style: TextStyle(color: Colors.blue)),
        ] else ...[
          Icon(Icons.cloud_done, color: Colors.green),
          SizedBox(width: 6),
          Text('Synced', style: TextStyle(color: Colors.green)),
        ]
      ],
    );
  }
}
