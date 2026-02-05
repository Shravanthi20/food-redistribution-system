import 'package:flutter/material.dart';

class InspectDeliveryScreen extends StatefulWidget {
  const InspectDeliveryScreen({super.key});

  @override
  State<InspectDeliveryScreen> createState() =>
      _InspectDeliveryScreenState();
}

class _InspectDeliveryScreenState extends State<InspectDeliveryScreen> {
  bool packagingOk = false;
  bool appearanceOk = false;
  final TextEditingController temperatureController =
      TextEditingController();

  bool get isSafe =>
      packagingOk &&
      appearanceOk &&
      temperatureController.text.isNotEmpty;

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
          children: const [
            Text("Inspect Delivery",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 2),
            Text("Batch #FS-4829",
                style: TextStyle(
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
              children: const [
                Text("DONOR INFORMATION",
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey)),
                SizedBox(height: 6),
                Text("Whole Foods Market",
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Mixed Produce & Bakery • Arrived 10:45 AM",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/food_sample.jpg", // replace with Firebase image later
              height: 60,
              width: 60,
              fit: BoxFit.cover,
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
        onPressed: () {
          // Firebase: mark donation as unsafe
        },
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
        onPressed: isSafe ? () {} : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
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
