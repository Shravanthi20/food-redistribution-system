import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_donation_service.dart';
import '../../models/food_donation.dart';

class RejectDonationScreen extends StatefulWidget {
  final FoodDonation? donation;

  const RejectDonationScreen({Key? key, this.donation}) : super(key: key);

  @override
  State<RejectDonationScreen> createState() => _RejectDonationScreenState();
}

class _RejectDonationScreenState extends State<RejectDonationScreen> {
  final GlobalKey&lt;FormState&gt; _formKey = GlobalKey&lt;FormState&gt;();
  final TextEditingController _reasonController = TextEditingController();
  final FoodDonationService _donationService = FoodDonationService();
  bool _isSubmitting = false;
  String? _selectedReason;

  final List&lt;String&gt; _commonReasons = [
    'Food safety concerns',
    'Inappropriate food type for our beneficiaries',
    'Insufficient quantity',
    'Logistical issues - cannot arrange pickup',
    'Past expiry date or too close to expiry',
    'Does not meet dietary restrictions',
    'Quality concerns from description',
    'Already fulfilled similar request',
    'Transportation constraints',
    'Other (specify below)'
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reject Donation'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: widget.donation == null 
        ? const Center(child: Text('No donation selected'))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Card
              Card(
                color: Colors.red.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejecting Donation',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please provide a clear reason to help the donor understand the decision.',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Donation Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donation Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Title', widget.donation!.title),
                      _buildInfoRow('Description', widget.donation!.description),
                      _buildInfoRow('Quantity', '${widget.donation!.quantity} ${widget.donation!.unit}'),
                      _buildInfoRow('Food Type', widget.donation!.foodType.name.toUpperCase()),
                      _buildInfoRow('Expiry', widget.donation!.expiryDateTime.toString().split(' ')[0]),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Reason Selection
              Text(
                'Reason for Rejection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the most appropriate reason:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // Common Reasons
              Column(
                children: _commonReasons.map((reason) {
                  return RadioListTile&lt;String&gt;(
                    title: Text(
                      reason,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                        if (value != 'Other (specify below)') {
                          _reasonController.text = value ?? '';
                        } else {
                          _reasonController.clear();
                        }
                      });
                    },
                    activeColor: Colors.red.shade700,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Additional Details
              Text(
                _selectedReason == 'Other (specify below)' 
                  ? 'Please specify the reason:' 
                  : 'Additional details (optional):',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _selectedReason == 'Other (specify below)' 
                    ? 'Please provide specific details...'
                    : 'Any additional context or feedback for the donor...',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (_selectedReason == null) {
                    return 'Please select a reason for rejection';
                  }
                  if (_selectedReason == 'Other (specify below)' && 
                      (value == null || value.trim().isEmpty)) {
                    return 'Please specify the reason for rejection';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRejection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Rejecting...'),
                          ],
                        )
                      : const Text(
                          'Reject Donation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future&lt;void&gt; _submitRejection() async {
    if (!_formKey.currentState!.validate()) return;

setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      String finalReason = _selectedReason == 'Other (specify below)' 
        ? _reasonController.text.trim()
        : _reasonController.text.trim().isEmpty 
          ? _selectedReason! 
          : '$_selectedReason. Additional details: ${_reasonController.text.trim()}';

      await _donationService.reviewDonation(
        donationId: widget.donation!.id,
        ngoId: authProvider.firebaseUser!.uid,
        accept: false,
        reason: finalReason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
          setState(() => _isSubmitting = false);
      }
    }
  }
}