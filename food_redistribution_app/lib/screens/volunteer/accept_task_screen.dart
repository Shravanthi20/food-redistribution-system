import 'package:flutter/material.dart';
import '../../models/food_donation.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Task Accepted",
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
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You have successfully accepted the task.\nProceed to pickup location.",
                      style: TextStyle(
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
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.taskExecution,
                    arguments: {'donationId': task.id},
                  );
                },
                child: const Text(
                  "Start Pickup",
                  style: TextStyle(fontSize: 16, color: Colors.white),
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
