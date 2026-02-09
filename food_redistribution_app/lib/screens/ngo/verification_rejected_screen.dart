import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';

class VerificationRejectedScreen extends StatefulWidget {
  const VerificationRejectedScreen({Key? key}) : super(key: key);

  @override
  State<VerificationRejectedScreen> createState() => _VerificationRejectedScreenState();
}

class _VerificationRejectedScreenState extends State<VerificationRejectedScreen> {
  Map&lt;String, dynamic&gt;? _rejectionDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRejectionDetails();
  }

  Future&lt;void&gt; _loadRejectionDetails() async {
    try {
      final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
      // In a real app, you'd load the rejection details from the service
      // For now, we'll simulate the data structure
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _rejectionDetails = {
          'submissionId': 'VER${DateTime.now().millisecondsSinceEpoch}',
          'rejectedAt': DateTime.now().subtract(const Duration(hours: 6)),
          'reviewedBy': 'Verification Team',
          'reason': 'Document Quality Issues',
          'feedback': [
            'NGO registration certificate image is unclear - please provide a clearer photo or scan',
            'Tax exemption document appears to be expired - please submit current certificate',
            'Contact information on submitted documents does not match profile details'
          ],
          'nextSteps': [
            'Review the feedback provided below',
            'Gather updated or clearer document images',
            'Resubmit your verification application',
            'Contact support if you need assistance'
          ],
          'canResubmit': true,
          'resubmissionDeadline': DateTime.now().add(const Duration(days: 30)),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Status Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade300, width: 3),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade700,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Title
            Text(
              'Verification Not Approved',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Your document submission has been reviewed and requires additional information or corrections.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Rejection Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Review Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildDetailRow(
                      'Reference ID',
                      _rejectionDetails?['submissionId'] ?? 'N/A',
                      Icons.tag,
                    ),
                    _buildDetailRow(
                      'Reviewed',
                      _formatDateTime(_rejectionDetails?['rejectedAt']),
                      Icons.schedule,
                    ),
                    _buildDetailRow(
                      'Reviewed By',
                      _rejectionDetails?['reviewedBy'] ?? 'N/A',
                      Icons.person,
                    ),
                    _buildDetailRow(
                      'Primary Issue',
                      _rejectionDetails?['reason'] ?? 'N/A',
                      Icons.warning,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Feedback Card
            Card(
              color: Colors.amber.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Specific Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Please address the following issues before resubmitting:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...(_rejectionDetails?['feedback'] as List&lt;String&gt;? ?? [])
                        .map((feedback) =&gt; _buildFeedbackItem(feedback))
                        .toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Next Steps Card
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'What to Do Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ...(_rejectionDetails?['nextSteps'] as List&lt;String&gt;? ?? [])
                        .asMap()
                        .entries
                        .map((entry) =&gt; _buildNextStepItem(entry.key + 1, entry.value))
                        .toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resubmission Info
            if (_rejectionDetails?['canResubmit'] == true) ...[
              Card(
                color: Colors.green.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.green.shade700,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Resubmission Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can resubmit your documents after addressing the feedback above. Deadline: ${_formatDate(_rejectionDetails?['resubmissionDeadline'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/document-submission');
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Resubmit Documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // In a real app, this would open support chat or email
                      _showSupportDialog();
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Return to Dashboard'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(String feedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedback,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(int step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes &lt; 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours &lt; 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need help with your verification? Our support team can assist you with:'),
              const SizedBox(height: 12),
              const Text('• Understanding the feedback'),
              const Text('• Document requirements'),
              const Text('• Technical submission issues'),
              const Text('• Deadline extensions'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference ID: ${_rejectionDetails?['submissionId']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Include this ID when contacting support',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () =&gt; Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('Email Support'),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email support feature would open here'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}