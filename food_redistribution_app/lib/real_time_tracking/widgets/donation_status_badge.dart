import 'package:flutter/material.dart';

import 'delivery_status_panel.dart' show sharedStatusLifecycleEngine;
import '../status_transition_validator.dart';

/// Compact badge showing current delivery status for a donation.
class DonationStatusBadge extends StatelessWidget {
  final Object deliveryId;
  final String? role; // optional role-aware visuals

  const DonationStatusBadge({Key? key, required this.deliveryId, this.role}) : super(key: key);

  Color _statusColor(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.Listed:
        return Colors.grey;
      case DeliveryStatus.Accepted:
        return Colors.blue;
      case DeliveryStatus.Assigned:
        return Colors.orange;
      case DeliveryStatus.PickedUp:
        return Colors.teal;
      case DeliveryStatus.Delivered:
        return Colors.green;
      default:
        return Colors.black45;
    }
  }

  IconData _statusIcon(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.Listed:
        return Icons.list;
      case DeliveryStatus.Accepted:
        return Icons.check;
      case DeliveryStatus.Assigned:
        return Icons.person_add;
      case DeliveryStatus.PickedUp:
        return Icons.local_shipping;
      case DeliveryStatus.Delivered:
        return Icons.home;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = deliveryId.toString();

    return StreamBuilder<MapEntry<String, DeliveryStatus>>(
      stream: sharedStatusLifecycleEngine.statusStream,
      builder: (context, snapshot) {
        DeliveryStatus? status = sharedStatusLifecycleEngine.getStatus(id);
        if (snapshot.hasData && snapshot.data!.key == id) {
          status = snapshot.data!.value;
        }

        final color = _statusColor(status);
        final icon = _statusIcon(status);

        // Sync indicator: online/offline
        final isOnline = sharedStatusLifecycleEngine.offlineQueue.isOnline;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              backgroundColor: color.withOpacity(0.12),
              avatar: Icon(icon, size: 16, color: color),
              label: Text(
                status == null ? 'Not listed' : status.toString().split('.').last,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: isOnline ? Colors.green : Colors.orange,
            ),
          ],
        );
      },
    );
  }
}
