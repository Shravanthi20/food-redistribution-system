import 'package:flutter/material.dart';
import '../status_lifecycle_engine.dart';
import 'real_time_status_widget.dart';

class LiveTrackingPanel extends StatelessWidget {
  final String deliveryId;
  final StatusLifecycleEngine engine;

  const LiveTrackingPanel({Key? key, required this.deliveryId, required this.engine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Tracking', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            // Placeholder map area - plug-and-play
            Container(
              height: 140,
              color: Colors.grey.shade200,
              child: Center(child: Text('Map / Live location placeholder')),
            ),
            SizedBox(height: 8),
            RealTimeStatusWidget(deliveryId: deliveryId, engine: engine),
          ],
        ),
      ),
    );
  }
}
