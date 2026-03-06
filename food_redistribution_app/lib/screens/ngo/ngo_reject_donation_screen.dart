import 'package:flutter/material.dart';
import '../../services/hygiene_service.dart';

class NgoRejectDonationScreen extends StatefulWidget {
  final String donationId;
  final String ngoId;
  final String donorId;

  const NgoRejectDonationScreen({
    super.key,
    required this.donationId,
    required this.ngoId,
    required this.donorId,
  });

  @override
  State<NgoRejectDonationScreen> createState() =>
      _NgoRejectDonationScreenState();
}

class _NgoRejectDonationScreenState extends State<NgoRejectDonationScreen> {
  final HygieneService _hygieneService = HygieneService();
  final TextEditingController _additionalInfoController =
      TextEditingController();

  String? _selectedReason;
  bool _isSubmitting = false;

  static const List<String> _rejectionReasons = [
    'Food is expired or near expiry',
    'Poor packaging / damaged packaging',
    'Signs of contamination or spoilage',
    'Quantity does not match listing',
    'Food type not suitable for our recipients',
    'Inadequate food safety information',
    'Temperature requirements not met',
    'Other (specify below)',
  ];

  Future<void> _submitRejection() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a rejection reason.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _hygieneService.rejectDonation(
        donationId: widget.donationId,
        ngoId: widget.ngoId,
        reason: _selectedReason!,
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty
            ? _additionalInfoController.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation rejected. Donor has been notified.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2535),
        foregroundColor: Colors.white,
        title: const Text('Reject Donation',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildWarningBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Rejection Reason *',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  ..._rejectionReasons
                      .map((reason) => _buildReasonTile(reason)),
                  const SizedBox(height: 20),
                  const Text('Additional Information (optional)',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _additionalInfoController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Provide more context if needed...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A2535),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D3748)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D3748)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.redAccent.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This action will notify the donor. Please provide an accurate reason.',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.redAccent.withValues(alpha: 0.15)
              : const Color(0xFF1A2535),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.redAccent : const Color(0xFF2D3748),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.redAccent : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(reason,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2535),
        border: Border(top: BorderSide(color: Color(0xFF2D3748))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_selectedReason != null && !_isSubmitting)
              ? _submitRejection
              : null,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cancel_outlined),
          label: const Text('Confirm Rejection',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF2D3748),
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }
}
