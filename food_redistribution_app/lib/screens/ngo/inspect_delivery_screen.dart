import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_donation_service.dart';
import '../../models/food_donation.dart';

class InspectDeliveryScreen extends StatefulWidget {
  final FoodDonation donation;

  const InspectDeliveryScreen({Key? key, required this.donation}) : super(key: key);

  @override
  State<InspectDeliveryScreen> createState() => _InspectDeliveryScreenState();
}

class _InspectDeliveryScreenState extends State<InspectDeliveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final FoodDonationService _donationService = FoodDonationService();
  bool _isSubmitting = false;
  
  // Hygiene Checklist
  final Map<String, bool> _hygieneChecklist = {
    'Temperature appropriate': false,
    'Packaging intact': false,
    'No unusual smell': false,
    'Color looks normal': false,
    'No visible contamination': false,
    'Proper labeling present': false,
    'Within expiry date': false,
    'Quantity matches description': false,
  };
  
  bool? _overallApproval;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill expiry check based on donation date
    final now = DateTime.now();
    final expiry = widget.donation.expiryDateTime;
    _hygieneChecklist['Within expiry date'] = expiry.isAfter(now);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspect Food Delivery'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Delivery Inspection',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Food Item', widget.donation.title),
                      _buildInfoRow('Expected Quantity', '${widget.donation.quantity} ${widget.donation.unit}'),
                      _buildInfoRow('Food Type', widget.donation.foodTypes.map((e) => e.name.toUpperCase()).join(', ')),
                      _buildInfoRow('Expiry Date', widget.donation.expiryDateTime.toString().split(' ')[0]),
                      _buildInfoRow('Description', widget.donation.description),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hygiene Safety Checklist
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Food Safety Checklist',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please verify each item carefully before accepting the delivery:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Column(
                        children: _hygieneChecklist.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(entry.key),
                            subtitle: entry.key == 'Within expiry date' && !entry.value
                              ? Text(
                                  'Warning: Food appears to be expired',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                            value: entry.value,
                            onChanged: (bool? value) {
                              setState(() {
                                _hygieneChecklist[entry.key] = value ?? false;
                                _updateOverallApproval();
                              });
                            },
                            activeColor: Colors.green.shade700,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Overall Decision
              Card(
                elevation: 2,
                color: _overallApproval == true 
                  ? Colors.green.shade50 
                  : _overallApproval == false 
                    ? Colors.red.shade50 
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection Decision',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      RadioListTile<bool>(
                        title: const Text('Accept Delivery'),
                        subtitle: Text(
                          'Food meets safety standards and can be distributed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        value: true,
                        groupValue: _overallApproval,
                        onChanged: (bool? value) {
                          setState(() {
                            _overallApproval = value;
                          });
                        },
                        activeColor: Colors.green.shade700,
                      ),
                      
                      RadioListTile<bool>(
                        title: const Text('Reject Delivery'),
                        subtitle: Text(
                          'Food does not meet safety standards',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        value: false,
                        groupValue: _overallApproval,
                        onChanged: (bool? value) {
                          setState(() {
                            _overallApproval = value;
                          });
                        },
                        activeColor: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Rejection Reason (if rejecting)
              if (_overallApproval == false) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason for Rejection',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _rejectionReasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Please specify why the delivery is being rejected...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_overallApproval == false && 
                                (value == null || value.trim().isEmpty)) {
                              return 'Please provide a reason for rejection';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Inspector Notes
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspector Notes (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Any additional observations or comments...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _overallApproval == null ? null : _submitInspection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _overallApproval == true 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
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
                            Text('Processing...'),
                          ],
                        )
                      : Text(
                          _overallApproval == true ? 'Accept Delivery' : 'Reject Delivery',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    'Cancel Inspection',
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
            width: 100,
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

  void _updateOverallApproval() {
    // Auto-suggest approval based on checklist
    final criticalChecks = [
      'Temperature appropriate',
      'No unusual smell',
      'No visible contamination',
      'Within expiry date'
    ];
    
      final criticalPassed = criticalChecks.every((check) => _hygieneChecklist[check] == true);
final totalChecked = _hygieneChecklist.values.where((v) => v == true).length;
    
      if (!criticalPassed || totalChecked < 6) {
      // Don't auto-reject, but suggest caution
      // Let the user decide
    }
  }

  Future<void> _submitInspection() async {
    if (!_formKey.currentState!.validate()) return;

setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      String? reason;
      if (_overallApproval == false) {
        reason = _rejectionReasonController.text.trim();
      }
      
      await _donationService.reviewDonation(
        donationId: widget.donation.id,
        ngoId: authProvider.firebaseUser!.uid,
        accept: _overallApproval!,
        reason: reason,
        hygieneChecklist: {
          ..._hygieneChecklist,
          'inspectorNotes': _notesController.text.trim(),
          'inspectionDate': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _overallApproval! 
                ? 'Delivery accepted successfully!' 
                : 'Delivery rejected and feedback sent.'
            ),
            backgroundColor: _overallApproval! ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, _overallApproval);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing inspection: $e'),
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