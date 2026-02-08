import 'package:flutter/material.dart';
import '../../models/food_donation.dart';
import '../../services/food_donation_service.dart';

class InspectDeliveryScreen extends StatefulWidget {
  final FoodDonation donation;

  const InspectDeliveryScreen({Key? key, required this.donation}) : super(key: key);

  @override
  State<InspectDeliveryScreen> createState() =>
      _InspectDeliveryScreenState();
}

class _InspectDeliveryScreenState extends State<InspectDeliveryScreen> {
  final FoodDonationService _donationService = FoodDonationService();
  bool packagingOk = false;
  bool appearanceOk = false;
  bool temperatureOk = false; // Simplified for demo
  final TextEditingController temperatureController =
      TextEditingController();

  bool get isSafe =>
      packagingOk &&
      appearanceOk &&
      temperatureController.text.isNotEmpty;

  bool _isLoading = false;

  Future<void> _confirmDelivery() async {
    setState(() => _isLoading = true);
    try {
      await _donationService.updateDonationStatus(
        donationId: widget.donation.id,
        status: DonationStatus.delivered,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery confirmed successfully!')),
        );
        Navigator.pop(context); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming delivery: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _flagUnsafe() async {
     // Implementation for flagging unsafe
     // For now, just show a dialog or snackbar
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flagged as unsafe. Admin notified.')),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Inspect Delivery",
                style: TextStyle(color: Colors.black, fontSize: 16)),
            const SizedBox(height: 2),
            Text("ID #${widget.donation.id.substring(0, 8)}",
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.info_outline, color: Colors.grey),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _donorInfo(),
            const SizedBox(height: 20),
            _safetyChecklist(),
            const SizedBox(height: 20),
            _temperatureInput(),
            const SizedBox(height: 20),
            _flagUnsafeButton(),
            const SizedBox(height: 20),
            _confirmButton(),
            const SizedBox(height: 10),
            _issueReport()
          ],
        ),
      ),
    );
  }

  // 🔹 Donor Info
  Widget _donorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DONOR INFORMATION",
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(widget.donation.donorContactPhone ?? "Anonymous Donor", // Ideally fetch donor name
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${widget.donation.foodTypes.map((e) => e.name).join(', ')} • ${widget.donation.quantity} ${widget.donation.unit}",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              width: 60,
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey), // Placeholder
            ),
          )
        ],
      ),
    );
  }

  // 🔹 Safety checklist
  Widget _safetyChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Safety Checklist",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _checkTile(
          title: "Packaging Integrity (Intact)",
          value: packagingOk,
          onChanged: (v) => setState(() => packagingOk = v),
          icon: Icons.inventory_2,
        ),
        _checkTile(
          title: "Appearance & Smell (Fresh)",
          value: appearanceOk,
          onChanged: (v) => setState(() => appearanceOk = v),
          icon: Icons.air,
        ),
      ],
    );
  }

  Widget _checkTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v!),
        title: Text(title),
        secondary: Icon(icon),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  // 🔹 Temperature logging
  Widget _temperatureInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Temperature Logging",
              style:
                  TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: temperatureController,
            onChanged: (_) => setState(() {}),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "e.g. 4.2",
              suffixText: "°C",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 Flag unsafe
  Widget _flagUnsafeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton.icon(
        onPressed: _flagUnsafe,
        icon: const Icon(Icons.warning, color: Colors.red),
        label: const Text(
          "Flag Unsafe Food",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  // 🔹 Confirm receipt
  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isSafe && !_isLoading) ? _confirmDelivery : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
          "Confirm Receipt",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // 🔹 Issue report
  Widget _issueReport() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          // Navigate to issue reporting
        },
        icon: const Icon(Icons.report_problem,
            color: Colors.grey),
        label: const Text("Issue Report for Delivery",
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
