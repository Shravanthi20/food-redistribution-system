import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';

class DocumentSubmissionScreen extends StatefulWidget {
  const DocumentSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<DocumentSubmissionScreen> createState() => _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState extends State<DocumentSubmissionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final VerificationService _verificationService = VerificationService();
  
  bool _isSubmitting = false;
  UserRole? _userRole;
  
  // Document form data
  final Map<String, TextEditingController> _documentControllers = {};
  final Map<String, String> _documentInfo = {};
  
  // Document requirements by role
  final Map<UserRole, List<Map<String, String>>> _documentRequirements = {
    UserRole.ngo: [
      {
        'type': 'NGO Registration Certificate',
        'description': 'Official registration number or certificate details',
        'hint': 'Enter your NGO registration number or certificate details...'
      },
      {
        'type': 'Tax Exemption Certificate',
        'description': 'Tax exemption certificate number (if applicable)',
        'hint': 'Enter tax exemption certificate number or write "Not Applicable"...'
      },
      {
        'type': 'Food Safety Certificate',
        'description': 'Food handling and safety certification details',
        'hint': 'Enter food safety certificate number or training details...'
      },
      {
        'type': 'Organization Address Proof',
        'description': 'Official address verification document details',
        'hint': 'Enter utility bill details, lease agreement, or address proof...'
      },
      {
        'type': 'Authorized Representative ID',
        'description': 'Government-issued ID of the person registering',
        'hint': 'Enter ID type and number (e.g., Passport: 123456789)...'
      },
    ],
    UserRole.donor: [
      {
        'type': 'Business License',
        'description': 'Business registration or license details (if applicable)',
        'hint': 'Enter business license number or write "Individual Donor"...'
      },
      {
        'type': 'Food Safety Certificate',
        'description': 'Food handling certification (for businesses)',
        'hint': 'Enter food safety certificate or write "Not Applicable"...'
      },
      {
        'type': 'Identity Document',
        'description': 'Government-issued identity verification',
        'hint': 'Enter ID type and number (e.g., Driver License: 123456789)...'
      },
      {
        'type': 'Address Proof',
        'description': 'Current address verification',
        'hint': 'Enter utility bill details or address proof...'
      },
    ],
    UserRole.volunteer: [
      {
        'type': 'Identity Document',
        'description': 'Government-issued identity verification',
        'hint': 'Enter ID type and number (e.g., National ID: 123456789)...'
      },
      {
        'type': 'Address Proof',
        'description': 'Current residential address verification',
        'hint': 'Enter utility bill details or address proof...'
      },
      {
        'type': 'Background Check',
        'description': 'Police clearance or background verification',
        'hint': 'Enter clearance certificate number or reference...'
      },
      {
        'type': 'Emergency Contact',
        'description': 'Emergency contact person details',
        'hint': 'Enter name and phone number of emergency contact...'
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserRole();
    });
  }

  void _initializeUserRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userRole = authProvider.appUser?.role;
    
    if (_userRole != null && _documentRequirements.containsKey(_userRole)) {
      for (final doc in _documentRequirements[_userRole]!) {
        final type = doc['type']!;
        _documentControllers[type] = TextEditingController();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _documentControllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return GradientScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentTeal, strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final documents = _documentRequirements[_userRole] ?? [];

    return GradientScaffold(
      showAnimatedBackground: true,
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              GlassCard(
                isAccent: true,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: AppTheme.accentTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verify your ${_userRole!.name.toUpperCase()} account',
                            style: TextStyle(
                              color: AppTheme.accentTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Information Note
              GlassContainer(
                tintColor: AppTheme.infoCyan,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.infoCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Provide document details (numbers, references) rather than uploading files. All information is encrypted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Document Forms Header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentTeal, AppTheme.accentCyan],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Required Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Fill out the information for each required document:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              ...documents.asMap().entries.map((entry) => 
                _buildDocumentCard(entry.value, entry.key + 1)).toList(),
              
              const SizedBox(height: 24),
              
              // Additional Information
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.textTertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.note_add_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.textTertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      maxLines: 3,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Any additional information that might help with verification...',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        filled: true,
                        fillColor: AppTheme.surfaceGlass,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.accentTeal, width: 1.5),
                        ),
                      ),
                      onSaved: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          _documentInfo['additional_info'] = value.trim();
                        }
                      },
                      onChanged: (value) {
                        _documentInfo['additional_info'] = value;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              GradientButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit for Verification',
                icon: _isSubmitting ? null : Icons.send_rounded,
                onPressed: _isSubmitting ? null : _submitDocuments,
                isLoading: _isSubmitting,
              ),
              
              const SizedBox(height: 12),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.schedule_rounded, color: AppTheme.textSecondary),
                  label: Text(
                    'Submit Later',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
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
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, String> doc, int index) {
    final type = doc['type']!;
    final description = doc['description']!;
    final hint = doc['hint']!;
    final controller = _documentControllers[type]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentTeal, AppTheme.accentCyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentTeal.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorRed.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surfaceGlass,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.accentTeal, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.errorRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.errorRed, width: 1.5),
                ),
                prefixIcon: Icon(Icons.description_outlined, 
                    size: 20, color: AppTheme.textTertiary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This document information is required';
                }
                if (value.trim().length < 5) {
                  return 'Please provide more detailed information';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  _documentInfo[type] = value.trim();
                }
              },
              onChanged: (value) {
                _documentInfo[type] = value.trim();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDocuments() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    for (final doc in _documentRequirements[_userRole] ?? []) {
      final type = doc['type']!;
      final controller = _documentControllers[type];
      if (controller != null && controller.text.trim().isNotEmpty) {
        _documentInfo[type] = controller.text.trim();
      }
    }
    
    final documents = _documentRequirements[_userRole] ?? [];
    List<String> missingDocs = [];
    
    for (final doc in documents) {
      final type = doc['type']!;
      if (!_documentInfo.containsKey(type) || _documentInfo[type]!.trim().isEmpty) {
        missingDocs.add(type);
      }
    }
    
    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out: ${missingDocs.join(", ")}'),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.firebaseUser?.uid == null) {
        throw Exception('User not authenticated. Please login again.');
      }
      
      print('Submitting verification with data: $_documentInfo');
      
      final submissionId = await _verificationService.submitVerificationInfo(
        userId: authProvider.firebaseUser!.uid,
        userRole: _userRole!,
        documentInfo: Map<String, String>.from(_documentInfo),
      );

      print('Submission successful with ID: $submissionId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documents submitted successfully!'),
            backgroundColor: AppTheme.successTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/verification-pending');
      }
    } catch (e) {
      print('Error submitting documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
