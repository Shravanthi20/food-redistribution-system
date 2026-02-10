import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_donation_service.dart';
import '../../models/food_donation.dart';

class ClarifyRequestScreen extends StatefulWidget {
  final FoodDonation? donation;

  const ClarifyRequestScreen({Key? key, this.donation}) : super(key: key);

  @override
  State<ClarifyRequestScreen> createState() => _ClarifyRequestScreenState();
}

class _ClarifyRequestScreenState extends State<ClarifyRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _clarificationController = TextEditingController();
  final FoodDonationService _donationService = FoodDonationService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _clarificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Clarification'),
        backgroundColor: Colors.orange.shade700,
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
              // Donation Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Donation Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Title', widget.donation!.title),
                      _buildInfoRow('Description', widget.donation!.description),
                      _buildInfoRow('Quantity', '${widget.donation!.quantity} ${widget.donation!.unit}'),
                      _buildInfoRow('Food Type', widget.donation!.foodTypes.map((e) => e.name).join(', ').toUpperCase()),
                      _buildInfoRow('Expiry', widget.donation!.expiryDateTime.toString().split(' ')[0]),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Clarification Request Section
              Text(
                'Request Clarification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What additional information do you need from the donor?',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clarificationController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Clarification Request',
                  hintText: 'Please provide more details about...\n\nSpecific questions you might ask:\n• Food preparation methods\n• Exact pickup location\n• Special handling requirements\n• Additional dietary information',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your clarification request';
                  }
                  if (value.trim().length < 10) {
                    return 'Please be more specific (at least 10 characters)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Questions (Optional)
              Text(
                'Common Questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap any question below to add it to your request:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickQuestion('What cooking methods were used?'),
                  _buildQuickQuestion('Are there any special storage requirements?'),
                  _buildQuickQuestion('Can you provide exact pickup address?'),
                  _buildQuickQuestion('What ingredients were used?'),
                  _buildQuickQuestion('Is this suitable for children?'),
                  _buildQuickQuestion('How should this be reheated?'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitClarificationRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
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
                            Text('Sending Request...'),
                          ],
                        )
                      : const Text(
                          'Send Clarification Request',
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

  Widget _buildQuickQuestion(String question) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_clarificationController.text.isNotEmpty) {
            _clarificationController.text += '\n\n• $question';
          } else {
            _clarificationController.text = '• $question';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(20),
          color: Colors.orange.shade50,
        ),
        child: Text(
          question,
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _submitClarificationRequest() async {
    if (!_formKey.currentState!.validate()) return;

setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await _donationService.requestClarification(
        donationId: widget.donation!.id,
        ngoId: authProvider.firebaseUser!.uid,
        clarificationRequest: _clarificationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clarification request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending request: $e'),
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