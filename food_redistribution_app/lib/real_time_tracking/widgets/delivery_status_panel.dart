import 'dart:async';

import 'package:flutter/material.dart';

import '../status_lifecycle_engine.dart';
import '../status_transition_validator.dart';
import '../delivery_notification_engine.dart';
import '../delay_detection_service.dart';
import '../lifecycle_log_service.dart';
import 'sync_status_indicator.dart';
import 'delay_alert_widget.dart';

/// DeliveryStatusPanel
/// Reusable, plug-and-play panel showing delivery status, delay alerts, and sync state.
///
/// Constructor:
/// - `role`: 'donor' | 'ngo' | 'volunteer'
/// - `deliveryId`: identifier for the delivery (String or int)
/// - `status`: optional manual status to bootstrap display
///
/// This widget uses the real-time engines created in this module. It creates
/// module-level singletons so multiple panels share state and streams.
class DeliveryStatusPanel extends StatefulWidget {
  final String role;
  final Object deliveryId;
  final DeliveryStatus? status;

  const DeliveryStatusPanel(
      {super.key, required this.role, required this.deliveryId, this.status});

  @override
  State<DeliveryStatusPanel> createState() => _DeliveryStatusPanelState();
}

// Module-level shared singletons so the panel works without editing existing app files.
final LifecycleLogService _sharedLogService = LifecycleLogService();
final DelayDetectionService _sharedDelayDetector = DelayDetectionService();
final DeliveryNotificationEngine _sharedNotifier = DeliveryNotificationEngine();
final StatusLifecycleEngine _sharedEngine = StatusLifecycleEngine(
    _sharedLogService, _sharedNotifier, _sharedDelayDetector);

/// Public accessor for the shared `StatusLifecycleEngine` used by the panel widgets.
StatusLifecycleEngine get sharedStatusLifecycleEngine => _sharedEngine;

class _DeliveryStatusPanelState extends State<DeliveryStatusPanel> {
  late StreamSubscription<MapEntry<String, DeliveryStatus>> _subStatus;
  late StreamSubscription<DelayAlert> _subDelay;
  DeliveryStatus? _currentStatus;
  DelayAlert? _currentDelayAlert;
  String? _lastNotification;

  String get _deliveryIdStr => widget.deliveryId.toString();

  @override
  void initState() {
    super.initState();

    // Bootstrap from optional passed status or engine current
    _currentStatus = widget.status ?? _sharedEngine.getStatus(_deliveryIdStr);

    // Listen to lifecycle engine stream and update when matching deliveryId
    _subStatus = _sharedEngine.statusStream.listen((entry) {
      if (entry.key == _deliveryIdStr) {
        setState(() {
          _currentStatus = entry.value;
        });
      }
    });

    // Listen to delay alerts and capture relevant ones
    _subDelay = _sharedDelayDetector.alerts.listen((alert) {
      if (alert.deliveryId == _deliveryIdStr) {
        setState(() {
          _currentDelayAlert = alert;
        });
      }
    });

    // Optionally listen to notification events to show inline messages
    _sharedNotifier.events.listen((ev) {
      if (ev.deliveryId == _deliveryIdStr) {
        setState(() {
          _lastNotification = '${ev.title}: ${ev.body}';
        });
        // ephemeral clear after a short delay
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted) setState(() => _lastNotification = null);
        });
      }
    });
  }

  @override
  void dispose() {
    _subStatus.cancel();
    _subDelay.cancel();
    super.dispose();
  }

  Widget _buildStatusRow() {
    final label = _currentStatus?.toString().split('.').last ?? 'Unknown';
    IconData icon;
    Color color = Colors.black87;
    switch (_currentStatus) {
      case DeliveryStatus.listed:
        icon = Icons.list;
        color = Colors.grey.shade700;
        break;
      case DeliveryStatus.accepted:
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case DeliveryStatus.assigned:
        icon = Icons.person_add;
        color = Colors.orange;
        break;
      case DeliveryStatus.pickedUp:
        icon = Icons.local_shipping;
        color = Colors.teal;
        break;
      case DeliveryStatus.delivered:
        icon = Icons.home;
        color = Colors.green;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Status: $label',
                style: TextStyle(fontSize: 16, color: color))),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRoleHint() {
    switch (widget.role.toLowerCase()) {
      case 'donor':
        return const Text('Role: Donor',
            style: TextStyle(fontWeight: FontWeight.w600));
      case 'ngo':
        return const Text('Role: NGO',
            style: TextStyle(fontWeight: FontWeight.w600));
      case 'volunteer':
        return const Text('Role: Volunteer',
            style: TextStyle(fontWeight: FontWeight.w600));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoleSpecific() {
    // Simple role-specific highlights — consumers can extend using engine APIs
    if (widget.role.toLowerCase() == 'donor') {
      return const Text('You will be notified of changes.',
          style: TextStyle(color: Colors.black54));
    }

    if (widget.role.toLowerCase() == 'ngo') {
      final visible = _currentStatus == DeliveryStatus.assigned ||
          _currentStatus == DeliveryStatus.pickedUp ||
          _currentStatus == DeliveryStatus.delivered;
      return Text(visible ? 'NGO: Assigned/Active' : 'NGO: Not assigned',
          style: const TextStyle(color: Colors.black54));
    }

    if (widget.role.toLowerCase() == 'volunteer') {
      final highlight = _currentStatus == DeliveryStatus.assigned ||
          _currentStatus == DeliveryStatus.pickedUp;
      return Text(
          highlight
              ? 'Volunteer: You have an assignment'
              : 'Volunteer: No assignment',
          style: const TextStyle(color: Colors.black54));
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRoleHint(),
                // sync indicator (reads engine.offlineQueue)
                SyncStatusIndicator(engine: _sharedEngine),
              ],
            ),

            const SizedBox(height: 8),

            _buildStatusRow(),

            const SizedBox(height: 8),

            _buildRoleSpecific(),

            if (_lastNotification != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade50,
                child: Row(children: [
                  const Icon(Icons.notifications, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_lastNotification!))
                ]),
              ),
            ],

            // Delay alert area
            const SizedBox(height: 8),
            // Inline summary for the most recent alert (if any)
            if (_currentDelayAlert != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Delay: ${_currentDelayAlert!.message}',
                    style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 8),
            ],

            DelayAlertWidget(
                deliveryId: _deliveryIdStr, detector: _sharedDelayDetector),
          ],
        ),
      ),
    );
  }
}
