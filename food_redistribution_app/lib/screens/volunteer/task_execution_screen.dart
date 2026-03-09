import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_donation.dart';
import '../../services/food_donation_service.dart';
import '../../services/location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accessibility_provider.dart';

class TaskExecutionScreen extends StatefulWidget {
  final String donationId;

  const TaskExecutionScreen({super.key, required this.donationId});

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  final FoodDonationService _donationService = FoodDonationService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;

  int _getStepFromStatus(DonationStatus status) {
    switch (status) {
      case DonationStatus.matched:
        return 0; // Go to Pickup
      case DonationStatus.pickedUp:
        return 1; // En-Route
      case DonationStatus.inTransit:
        return 2; // Arrived / Delivered
      case DonationStatus.delivered:
        return 3; // Done
      default:
        return 0;
    }
  }

  Future<bool> _showConfirmationDialog(
    String title,
    String content,
    String confirmText,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleCancelTask() async {
    final confirmed = await _showConfirmationDialog(
      "Cancel Task?",
      "Are you sure you want to cancel this delivery task? This action cannot be undone.",
      "Yes, Cancel Task",
    );
    if (confirmed) {
      // In a real app, you might re-assign or un-match the task here
      await _updateStatus(DonationStatus.listed);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Task Execution",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            tooltip: "Cancel Task",
            onPressed: _handleCancelTask,
          ),
        ],
      ),
      body: StreamBuilder<FoodDonation?>(
        stream: _donationService.getDonationStream(widget.donationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Task not found"));
          }

          final donation = snapshot.data!;
          final status = donation.status;

          return Consumer<AccessibilityProvider>(
            builder: (context, accessibility, child) {
              return _buildContent(
                context,
                donation,
                status,
                accessibility.simplifiedMode,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FoodDonation donation,
    DonationStatus status,
    bool simplified,
  ) {
    int currentStep = _getStepFromStatus(status);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!simplified) _statusCard(status),
          if (!simplified) const SizedBox(height: 20),

          // Simplified Step-by-Step UI
          Expanded(
            child: Stepper(
              physics: const ClampingScrollPhysics(),
              currentStep: currentStep > 2
                  ? 2
                  : currentStep, // Max step is 2 (3 steps total)
              controlsBuilder: (context, details) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (currentStep == 0 && details.stepIndex == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildActionButton(
                      "Confirm Pickup",
                      Colors.green,
                      () async {
                        final confirmed = await _showConfirmationDialog(
                          "Confirm Pickup",
                          "Have you collected the food from the donor?",
                          "Yes, Picked Up",
                        );
                        if (confirmed && mounted) _updateStatus(DonationStatus.pickedUp);
                      },
                    ),
                  );
                }

                if (currentStep == 1 && details.stepIndex == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildActionButton(
                      "Mark En-route",
                      Colors.orange,
                      () async {
                        final authProv = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final confirmed = await _showConfirmationDialog(
                          "En-route?",
                          "Start location tracking and head to the destination?",
                          "Yes, Start Next Leg",
                        );
                        if (confirmed && mounted) {
                          final userId = authProv.appUser?.uid ?? '';
                          await _locationService.startLocationTracking(userId);
                          if (mounted) await _updateStatus(DonationStatus.inTransit);
                        }
                      },
                    ),
                  );
                }

                if (currentStep == 2 &&
                    details.stepIndex == 2 &&
                    status != DonationStatus.delivered) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildActionButton(
                      "Confirm Delivery",
                      Colors.blue,
                      () async {
                        final authProv = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final confirmed = await _showConfirmationDialog(
                          "Confirm Delivery",
                          "Has the food been successfully delivered to the NGO?",
                          "Yes, Delivered",
                        );
                        if (confirmed && mounted) {
                          final userId = authProv.appUser?.uid ?? '';
                          await _locationService.stopLocationTracking(userId);
                          await _updateStatus(DonationStatus.delivered);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Delivery Confirmed! Tracking Stopped.",
                              ),
                            ),
                          );
                          Navigator.pop(
                            context,
                          ); // Go back to dashboard on complete
                        }
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              steps: [
                Step(
                  title: Text(
                    "1. Pickup Food",
                    style: simplified
                        ? const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        Icons.store,
                        "Pickup Address",
                        donation.pickupAddress,
                        simplified,
                      ),
                      _infoRow(
                        Icons.restaurant,
                        "Items",
                        "${donation.quantity} ${donation.unit} of ${donation.foodTypes.map((e) => e.name).join(', ')}",
                        simplified,
                      ),
                    ],
                  ),
                  isActive: currentStep >= 0,
                  state:
                      currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text(
                    "2. Start Delivery Leg",
                    style: simplified
                        ? const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                  content: Text(
                    simplified
                        ? "Head to the drop location."
                        : "Start tracking and navigate to the NGO.",
                    style: const TextStyle(fontSize: 16),
                  ),
                  isActive: currentStep >= 1,
                  state:
                      currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text(
                    "3. Drop-off Food",
                    style: simplified
                        ? const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        Icons.location_on,
                        "Drop Address",
                        "Assigned NGO Location",
                        simplified,
                      ),
                      _infoRow(
                        Icons.timer,
                        "Deadline",
                        "Expires: ${_formatTime(donation.expiresAt)}",
                        simplified,
                      ),
                    ],
                  ),
                  isActive: currentStep >= 2,
                  state: status == DonationStatus.delivered
                      ? StepState.complete
                      : StepState.indexed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(DonationStatus newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _donationService.updateDonationStatus(
        donationId: widget.donationId,
        status: newStatus,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.check_circle_outline, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _statusCard(DonationStatus status) {
    Color color = Colors.grey;
    String statusText = status.name.toUpperCase();

    if (status == DonationStatus.pickedUp) color = Colors.green;
    if (status == DonationStatus.inTransit) color = Colors.orange;
    if (status == DonationStatus.delivered) color = Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            "Status: $statusText",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value, bool simplified) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: simplified ? 28 : 22,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!simplified)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: simplified ? 18 : 16,
                    fontWeight:
                        simplified ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
