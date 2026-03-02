import 'package:flutter/material.dart';
import '../delay_detection_service.dart';

class DelayAlertWidget extends StatelessWidget {
  final String deliveryId;
  final DelayDetectionService detector;

  const DelayAlertWidget({Key? key, required this.deliveryId, required this.detector}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DelayAlert>(
      stream: detector.alerts,
      builder: (context, snapshot) {
        final hasAlert = snapshot.hasData && snapshot.data!.deliveryId == deliveryId;
        if (!hasAlert) return SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(8),
          color: Colors.red.shade300,
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(snapshot.data!.message, style: TextStyle(color: Colors.white))),
            ],
          ),
        );
      },
    );
  }
}
