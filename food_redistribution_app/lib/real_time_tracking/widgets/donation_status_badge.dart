import 'package:flutter/material.dart';

import 'delivery_status_panel.dart' show sharedStatusLifecycleEngine;
import '../status_transition_validator.dart';

/// Compact badge showing current delivery status for a donation.
class DonationStatusBadge extends StatelessWidget {
  final Object deliveryId;
  final String? role; // optional role-aware visuals

  const DonationStatusBadge({super.key, required this.deliveryId, this.role});

  Color _statusColor(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.listed:
        return Colors.grey;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.assigned:
        return Colors.orange;
      case DeliveryStatus.pickedUp:
        return Colors.teal;
      case DeliveryStatus.delivered:
        return Colors.green;
      default:
        return Colors.black45;
    }
  }

  IconData _statusIcon(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.listed:
        return Icons.list;
      case DeliveryStatus.accepted:
        return Icons.check;
      case DeliveryStatus.assigned:
        return Icons.person_add;
      case DeliveryStatus.pickedUp:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
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
              backgroundColor: color.withAlpha((0.12 * 255).round()),
              avatar: Icon(icon, size: 16, color: color),
              label: Text(
                status == null
                    ? 'Not listed'
                    : status.toString().split('.').last,
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
