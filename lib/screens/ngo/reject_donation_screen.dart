import 'package:flutter/material.dart';

class RejectDonationScreen extends StatelessWidget {
  const RejectDonationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reject Donation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reason for Rejection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(
                  value: "expired",
                  child: Text("Food expired / unsafe"),
                ),
                DropdownMenuItem(
                  value: "capacity",
                  child: Text("Capacity full"),
                ),
                DropdownMenuItem(
                  value: "other",
                  child: Text("Other"),
                ),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context); // back to dashboard
                },
                child: const Text("Confirm Rejection"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
