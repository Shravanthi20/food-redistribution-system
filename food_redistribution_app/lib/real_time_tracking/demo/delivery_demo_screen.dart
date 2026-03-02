import 'package:flutter/material.dart';
import '../widgets/delivery_status_panel.dart';
import '../status_lifecycle_engine.dart';
import '../status_transition_validator.dart';
import '../lifecycle_log_service.dart';
import '../delivery_notification_engine.dart';
import '../delay_detection_service.dart';

class DeliveryDemoScreen extends StatefulWidget {
  const DeliveryDemoScreen({super.key});

  @override
  State<DeliveryDemoScreen> createState() => _DeliveryDemoScreenState();
}

class _DeliveryDemoScreenState extends State<DeliveryDemoScreen> {
  late final LifecycleLogService _log;
  late final DelayDetectionService _delay;
  late final DeliveryNotificationEngine _notifier;
  late final StatusLifecycleEngine _engine;
  final String demoId = 'DEMO-001';

  @override
  void initState() {
    super.initState();
    _log = LifecycleLogService();
    _delay = DelayDetectionService(
        pickupThreshold: const Duration(seconds: 10),
        deliveryThreshold: const Duration(seconds: 20));
    _notifier = DeliveryNotificationEngine();
    _engine = StatusLifecycleEngine(_log, _notifier, _delay);
  }

  @override
  void dispose() {
    _engine.dispose();
    _delay.dispose();
    _notifier.dispose();
    super.dispose();
  }

  Widget _controlButton(String label, DeliveryStatus status) {
    return ElevatedButton(
      onPressed: () => _engine.updateDeliveryStatus(demoId, status),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demo Delivery ID: $demoId',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DeliveryStatusPanel(role: 'donor', deliveryId: demoId),
            const SizedBox(height: 8),
            DeliveryStatusPanel(role: 'ngo', deliveryId: demoId),
            const SizedBox(height: 8),
            DeliveryStatusPanel(role: 'volunteer', deliveryId: demoId),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              _controlButton('Listed', DeliveryStatus.listed),
              _controlButton('Accepted', DeliveryStatus.accepted),
              _controlButton('Assigned', DeliveryStatus.assigned),
              _controlButton('PickedUp', DeliveryStatus.pickedUp),
              _controlButton('Delivered', DeliveryStatus.delivered),
            ])
          ],
        ),
      ),
    );
  }
}
