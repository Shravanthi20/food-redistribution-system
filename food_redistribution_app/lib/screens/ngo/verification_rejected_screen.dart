import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';

class VerificationRejectedScreen extends StatefulWidget {
  const VerificationRejectedScreen({Key? key}) : super(key: key);

  @override
  State<VerificationRejectedScreen> createState() => _VerificationRejectedScreenState();
}

class _VerificationRejectedScreenState extends State<VerificationRejectedScreen> 
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _rejectionDetails;
  bool _isLoading = true;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _loadRejectionDetails();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadRejectionDetails() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _rejectionDetails = {
          'submissionId': 'VER${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
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
      
      // Play shake animation after loading
      Future.delayed(const Duration(milliseconds: 300), () {
        _shakeController.forward().then((_) => _shakeController.reverse());
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.accentTeal,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Animated Status Icon with Glow
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * 
                          ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1), 0),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.errorRed.withOpacity(0.3),
                              AppTheme.errorRed.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorRed.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 50,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Status Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.textPrimary, AppTheme.errorRed.withOpacity(0.8)],
                  ).createShader(bounds),
                  child: Text(
                    'Verification Not Approved',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Your document submission has been reviewed and requires additional information or corrections.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Review Details Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.errorRed,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Review Details',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow('Reference ID', _rejectionDetails?['submissionId'] ?? 'N/A', Icons.tag_rounded),
                      _buildDetailRow('Reviewed', _formatDateTime(_rejectionDetails?['rejectedAt']), Icons.schedule_rounded),
                      _buildDetailRow('Reviewed By', _rejectionDetails?['reviewedBy'] ?? 'N/A', Icons.person_rounded),
                      _buildDetailRow('Primary Issue', _rejectionDetails?['reason'] ?? 'N/A', Icons.warning_rounded, 
                          statusColor: AppTheme.errorRed),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Feedback Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  tintColor: AppTheme.warningAmber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.feedback_outlined,
                              color: AppTheme.warningAmber,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Specific Feedback',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Please address the following issues before resubmitting:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.warningAmber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...(_rejectionDetails?['feedback'] as List<String>? ?? [])
                          .map((feedback) => _buildFeedbackItem(feedback))
                          .toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Next Steps Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.list_alt_rounded,
                              color: AppTheme.accentCyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'What to Do Next',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      ...(_rejectionDetails?['nextSteps'] as List<String>? ?? [])
                          .asMap()
                          .entries
                          .map((entry) => _buildNextStepItem(entry.key + 1, entry.value))
                          .toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Resubmission Info
                if (_rejectionDetails?['canResubmit'] == true)
                  GlassCard(
                    isAccent: true,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.successTeal.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.successTeal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Resubmission Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can resubmit your documents after addressing the feedback above.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.successTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Deadline: ${_formatDate(_rejectionDetails?['resubmissionDeadline'])}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.successTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 28),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'Resubmit Docs',
                        icon: Icons.upload_file_rounded,
                        onPressed: () => Navigator.pushReplacementNamed(context, '/document-submission'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Get Support',
                        icon: Icons.support_agent_rounded,
                        outlined: true,
                        onPressed: () => _showSupportDialog(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.dashboard_rounded, color: AppTheme.textSecondary),
                    label: Text(
                      'Return to Dashboard',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? AppTheme.textPrimary,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.errorRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorRed.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              feedback,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentCyan, AppTheme.accentTeal],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCyan.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
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
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryNavyLight.withOpacity(0.95),
                  AppTheme.primaryNavy.withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceGlassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.infoCyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: AppTheme.infoCyan,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need help with your verification? Our support team can assist you with:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                _buildSupportItem('Understanding the feedback'),
                _buildSupportItem('Document requirements'),
                _buildSupportItem('Technical submission issues'),
                _buildSupportItem('Deadline extensions'),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceGlassBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Reference ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rejectionDetails?['submissionId'] ?? 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Include this ID when contacting support',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Email',
                        icon: Icons.email_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Opening email support...'),
                              backgroundColor: AppTheme.primaryNavyLight,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.accentTeal,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
