import 'package:flutter/material.dart';
import '../delay_detection_service.dart';

class DelayAlertWidget extends StatelessWidget {
  final String deliveryId;
  final DelayDetectionService detector;

  const DelayAlertWidget({
    super.key,
    required this.deliveryId,
    required this.detector,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DelayAlert>(
      stream: detector.alerts,
      builder: (context, snapshot) {
        final hasAlert =
            snapshot.hasData && snapshot.data!.deliveryId == deliveryId;
        if (!hasAlert) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.red.shade300,
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.data!.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
