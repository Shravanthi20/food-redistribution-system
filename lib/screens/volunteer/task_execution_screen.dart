import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_donation.dart';
import '../../services/food_donation_service.dart';
import '../../services/location_service.dart';
import '../../providers/auth_provider.dart';

class TaskExecutionScreen extends StatefulWidget {
  final String donationId;

  const TaskExecutionScreen({Key? key, required this.donationId}) : super(key: key);

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  final FoodDonationService _donationService = FoodDonationService();
  final LocationService _locationService = LocationService();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Task Execution", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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

          return _buildContent(context, donation, status);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FoodDonation donation, DonationStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusCard(status),
          const SizedBox(height: 20),
          
          const Text("Pickup & Drop Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          _infoRow(Icons.store, "Pickup", donation.pickupAddress),
          // In a real app, Drop address would be from the assigned NGO
          _infoRow(Icons.location_on, "Drop", "Assigned NGO Location"), 
          _infoRow(Icons.restaurant, "Food", "${donation.quantity} ${donation.unit} of ${donation.foodTypes.join(', ')}"),
          _infoRow(Icons.timer, "Deadline", "Expires: ${_formatDate(donation.expiresAt)}"),

          const SizedBox(height: 25),

          if (_isLoading)
             const Center(child: CircularProgressIndicator())
          else ...[
             // ACTION BUTTONS
             if (status == DonationStatus.matched)
               _buildActionButton(
                 "Confirm Pickup", 
                 Colors.green, 
                 () => _updateStatus(DonationStatus.pickedUp)
               ),
             
             if (status == DonationStatus.pickedUp)
               _buildActionButton(
                 "Mark En-route", 
                 Colors.orange, 
                 () async {
                   // Start Tracking
                   final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;
                   await _locationService.startLocationTracking(userId);
                   await _updateStatus(DonationStatus.inTransit);
                 }
               ),
            
             if (status == DonationStatus.inTransit)
               _buildActionButton(
                 "Confirm Delivery", 
                 Colors.blue, 
                 () async {
                   final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;
                   await _locationService.stopLocationTracking(userId);
                   await _updateStatus(DonationStatus.delivered);
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Delivery Confirmed! Tracking Stopped.")),
                      );
                      Navigator.pop(context);
                   }
                 }
               ),
          ]
        ],
      ),
    );
  }

  Future<void> _updateStatus(DonationStatus newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _donationService.updateDonationStatus(
        donationId: widget.donationId, 
        status: newStatus
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _statusCard(DonationStatus status) {
    Color color = Colors.grey;
    String statusText = status.name;

    switch(status) {
      case DonationStatus.pickedUp: color = Colors.green; break;
      case DonationStatus.inTransit: color = Colors.orange; break;
      case DonationStatus.delivered: color = Colors.blue; break;
      default: break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 10),
          Text(
            "Current Status: $statusText",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime dt) {
    return "${dt.hour}:${dt.minute}";
  }
}

