import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({Key? key}) : super(key: key);

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation&lt;double&gt; _pulseAnimation;
  final VerificationService _verificationService = VerificationService();
  
  Map&lt;String, dynamic&gt;? _submissionDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween&lt;double&gt;(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    
    _loadSubmissionDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future&lt;void&gt; _loadSubmissionDetails() async {
    try {
      final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
      // In a real app, you'd load the submission details from the service
      // For now, we'll simulate the data structure
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _submissionDetails = {
          'submissionId': 'VER${DateTime.now().millisecondsSinceEpoch}',
          'status': 'pending',
          'submittedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'estimatedReviewTime': '24-48 hours',
          'documentsCount': 4,
          'priority': 'normal'
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
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Animated Status Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade300, width: 3),
                    ),
                    child: Icon(
                      Icons.access_time,
                      size: 60,
                      color: Colors.amber.shade700,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Status Title
            Text(
              'Verification in Progress',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Your documents are being reviewed by our verification team. You will be notified once the process is complete.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Submission Details Card
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
                          Icons.description,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Submission Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildDetailRow(
                      'Reference ID',
                      _submissionDetails?['submissionId'] ?? 'N/A',
                      Icons.tag,
                    ),
                    _buildDetailRow(
                      'Status',
                      _submissionDetails?['status']?.toString().toUpperCase() ?? 'PENDING',
                      Icons.info_outline,
                    ),
                    _buildDetailRow(
                      'Submitted',
                      _formatDateTime(_submissionDetails?['submittedAt']),
                      Icons.schedule,
                    ),
                    _buildDetailRow(
                      'Documents',
                      '${_submissionDetails?['documentsCount'] ?? 0} items submitted',
                      Icons.folder,
                    ),
                    _buildDetailRow(
                      'Est. Review Time',
                      _submissionDetails?['estimatedReviewTime'] ?? '24-48 hours',
                      Icons.timer,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Progress Indicator
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildProgressStep(
                      'Documents Received',
                      'Your verification documents have been received',
                      true,
                      Colors.green,
                    ),
                    _buildProgressStep(
                      'Under Review',
                      'Our team is currently reviewing your submission',
                      true,
                      Colors.blue,
                    ),
                    _buildProgressStep(
                      'Verification Complete',
                      'You will be notified of the final decision',
                      false,
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Next Steps Card
            Card(
              color: Colors.green.shade50,
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
                          Icons.lightbulb_outline,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'What Happens Next?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildNextStepItem(
                      'Review Process',
                      'Our verification team will carefully review all submitted documents'
                    ),
                    _buildNextStepItem(
                      'Notification',
                      'You will receive an in-app notification and email about the decision'
                    ),
                    _buildNextStepItem(
                      'Account Activation',
                      'If approved, your account will be activated and all features unlocked'
                    ),
                    _buildNextStepItem(
                      'Additional Information',
                      'If more information is needed, we will contact you with specific requests'
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/document-submission');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Documents'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Go to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Help Section
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you have questions about the verification process or need to provide additional information, please contact our support team.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // In a real app, this would open support chat or email
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support contact feature would open here'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildProgressStep(String title, String description, bool isCompleted, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.radio_button_unchecked,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? color : Colors.grey[600],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
}