import 'package:flutter/material.dart';
import '../status_lifecycle_engine.dart';
import '../status_transition_validator.dart';

class RealTimeStatusWidget extends StatelessWidget {
  final String deliveryId;
  final StatusLifecycleEngine engine;

  const RealTimeStatusWidget({
    super.key,
    required this.deliveryId,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEntry<String, DeliveryStatus>>(
      stream: engine.statusStream,
      builder: (context, snapshot) {
        DeliveryStatus? status = engine.getStatus(deliveryId);
        if (snapshot.hasData && snapshot.data!.key == deliveryId) {
          status = snapshot.data!.value;
        }

        return Row(
          children: [
            const Icon(Icons.location_on),
            const SizedBox(width: 8),
            Text('Status: ${status?.toString().split('.').last ?? 'Unknown'}'),
          ],
        );
      },
    );
  }
}
