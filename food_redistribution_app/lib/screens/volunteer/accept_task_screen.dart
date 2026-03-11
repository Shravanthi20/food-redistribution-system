import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_donation.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';

class AcceptTaskScreen extends StatelessWidget {
  final FoodDonation? donation;

  const AcceptTaskScreen({super.key, this.donation});

  @override
  Widget build(BuildContext context) {
    // Get donation from constructor or route arguments
    final task = donation ??
        (ModalRoute.of(context)?.settings.arguments as FoodDonation?);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No task data available.')),
      );
    }

    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).appUser?.uid;
    final isAssignedToCurrentVolunteer =
        task.assignedVolunteerId == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Task Details",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isAssignedToCurrentVolunteer
                        ? Colors.green
                        : Colors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isAssignedToCurrentVolunteer
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: isAssignedToCurrentVolunteer
                        ? Colors.green
                        : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAssignedToCurrentVolunteer
                          ? "This task is assigned to you.\nProceed to pickup location."
                          : "This task is not assigned to you yet.\nAccept it from New Requests before starting pickup.",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Pickup Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.store,
              title: "Pickup Location",
              value: task.pickupAddress.isNotEmpty
                  ? task.pickupAddress
                  : "Contact donor for address",
            ),
            _infoCard(
              icon: Icons.restaurant,
              title: "Food Type",
              value:
                  "${task.foodTypes.map((e) => e.name).join(', ')} • ${task.quantity} ${task.unit}",
            ),
            _infoCard(
              icon: Icons.timer,
              title: "Time Window",
              value: _formatTimeWindow(task),
            ),
            if (task.specialInstructions != null &&
                task.specialInstructions!.isNotEmpty)
              _infoCard(
                icon: Icons.info_outline,
                title: "Special Instructions",
                value: task.specialInstructions!,
              ),
            if (task.donorContactPhone.isNotEmpty)
              _infoCard(
                icon: Icons.phone,
                title: "Donor Contact",
                value: task.donorContactPhone,
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAssignedToCurrentVolunteer ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (!isAssignedToCurrentVolunteer) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "This donation is not assigned to you. Accept it from New Requests before starting pickup.",
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    AppRouter.taskExecution,
                    arguments: {'donationId': task.id},
                  );
                },
                child: Text(
                  isAssignedToCurrentVolunteer
                      ? "Start Pickup"
                      : "Await Assignment",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back to Dashboard",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeWindow(FoodDonation task) {
    final now = DateTime.now();
    final remaining = task.availableUntil.difference(now);

    if (remaining.isNegative) {
      return "Pickup window expired";
    } else if (remaining.inMinutes < 60) {
      return "Within ${remaining.inMinutes} mins";
    } else if (remaining.inHours < 24) {
      return "Within ${remaining.inHours}h ${remaining.inMinutes % 60}m";
    } else {
      return "Available until ${task.availableUntil.day}/${task.availableUntil.month} ${task.availableUntil.hour}:${task.availableUntil.minute.toString().padLeft(2, '0')}";
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
