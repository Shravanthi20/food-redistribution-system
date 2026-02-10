import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({Key? key}) : super(key: key);

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  Map<String, dynamic>? _submissionDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.66).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    
    _loadSubmissionDetails();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissionDetails() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _submissionDetails = {
          'submissionId': 'VER${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          'status': 'pending',
          'submittedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'estimatedReviewTime': '24-48 hours',
          'documentsCount': 4,
          'priority': 'normal'
        };
        _isLoading = false;
      });
      _progressController.forward();
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
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.warningAmber.withOpacity(0.3),
                              AppTheme.warningAmber.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.warningAmber.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warningAmber.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          size: 50,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Status Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.textPrimary, AppTheme.accentCyan],
                  ).createShader(bounds),
                  child: Text(
                    'Verification in Progress',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Your documents are being reviewed by our verification team.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Progress Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: AppTheme.accentTeal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verification Progress',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Animated progress bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _progressAnimation.value,
                                  backgroundColor: AppTheme.surfaceGlass,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(_progressAnimation.value * 100).toInt()}% Complete',
                                    style: TextStyle(
                                      color: AppTheme.accentTeal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Step 2 of 3',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.surfaceGlassBorder),
                      const SizedBox(height: 16),
                      
                      _buildProgressStep(
                        'Documents Received',
                        'Your verification documents have been received',
                        true,
                        1,
                      ),
                      _buildProgressStep(
                        'Under Review',
                        'Our team is currently reviewing your submission',
                        true,
                        2,
                      ),
                      _buildProgressStep(
                        'Verification Complete',
                        'You will be notified of the final decision',
                        false,
                        3,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Submission Details Card
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
                              Icons.description_outlined,
                              color: AppTheme.accentCyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Submission Details',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow('Reference ID', _submissionDetails?['submissionId'] ?? 'N/A', Icons.tag_rounded),
                      _buildDetailRow('Status', 'PENDING', Icons.pending_rounded, statusColor: AppTheme.warningAmber),
                      _buildDetailRow('Submitted', _formatDateTime(_submissionDetails?['submittedAt']), Icons.schedule_rounded),
                      _buildDetailRow('Documents', '${_submissionDetails?['documentsCount'] ?? 0} items', Icons.folder_rounded),
                      _buildDetailRow('Est. Review', _submissionDetails?['estimatedReviewTime'] ?? '24-48 hours', Icons.timer_outlined),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // What Happens Next Card
                GlassCard(
                  isAccent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.successTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: AppTheme.successTeal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'What Happens Next?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildNextStepItem(
                        'Review Process',
                        'Our verification team will carefully review all submitted documents',
                        Icons.search_rounded,
                      ),
                      _buildNextStepItem(
                        'Notification',
                        'You will receive an in-app notification and email about the decision',
                        Icons.notifications_active_outlined,
                      ),
                      _buildNextStepItem(
                        'Account Activation',
                        'If approved, your account will be activated and all features unlocked',
                        Icons.verified_user_outlined,
                      ),
                      _buildNextStepItem(
                        'Additional Information',
                        'If more information is needed, we will contact you with specific requests',
                        Icons.info_outline_rounded,
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
                        text: 'Update Documents',
                        icon: Icons.edit_document,
                        outlined: true,
                        onPressed: () => Navigator.pushReplacementNamed(context, '/document-submission'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Go to Dashboard',
                        icon: Icons.dashboard_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Help Section
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  tintColor: AppTheme.infoCyan,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.infoCyan.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: AppTheme.infoCyan,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you have questions about the verification process or need to provide additional information, please contact our support team.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        text: 'Contact Support',
                        icon: Icons.support_agent_rounded,
                        outlined: true,
                        gradientColors: [AppTheme.infoCyan, AppTheme.accentCyanSoft],
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Opening support...'),
                              backgroundColor: AppTheme.primaryNavyLight,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
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

  Widget _buildProgressStep(String title, String description, bool isCompleted, int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: isCompleted 
                ? LinearGradient(colors: [AppTheme.accentTeal, AppTheme.accentTealLight])
                : null,
              color: isCompleted ? null : AppTheme.surfaceGlass,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? Colors.transparent : AppTheme.surfaceGlassBorder,
                width: 1.5,
              ),
              boxShadow: isCompleted ? [
                BoxShadow(
                  color: AppTheme.accentTeal.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
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
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppTheme.textPrimary : AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.successTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.successTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
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
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
