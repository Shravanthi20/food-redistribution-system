import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';

class RejectTaskScreen extends StatefulWidget {
  final String? donationId;
  final String? assignmentId;

  const RejectTaskScreen({super.key, this.donationId, this.assignmentId});

  @override
  State<RejectTaskScreen> createState() => _RejectTaskScreenState();
}

class _RejectTaskScreenState extends State<RejectTaskScreen> {
  String selectedReason = "Not Available";
  bool _isSubmitting = false;

  final List<String> reasons = [
    "Not Available",
    "Too Far Distance",
    "Vehicle Issue",
    "Health / Emergency",
    "Other",
  ];

  final TextEditingController otherReasonController = TextEditingController();

  @override
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRejection() async {
    if (_isSubmitting) return;

    final reason = selectedReason == "Other"
        ? otherReasonController.text.trim()
        : selectedReason;

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reason")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get route arguments if not passed via constructor
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final donationId = widget.donationId ?? args?['donationId'];
      final assignmentId = widget.assignmentId ?? args?['assignmentId'];

      if (donationId != null && assignmentId != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final donationProvider =
            Provider.of<DonationProvider>(context, listen: false);
        final userId = authProvider.user?.uid ?? '';

        await donationProvider.rejectAssignment(
          assignmentId,
          donationId,
          userId,
          reason,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Task rejected: $reason")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rejecting task: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Reject Task",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a Reason",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                underline: const SizedBox(),
                items: reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            if (selectedReason == "Other")
              TextField(
                controller: otherReasonController,
                decoration: InputDecoration(
                  hintText: "Enter your reason",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitRejection,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit Rejection",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
