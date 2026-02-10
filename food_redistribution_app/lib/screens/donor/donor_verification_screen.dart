import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';
import 'dart:io';

class DonorVerificationScreen extends StatefulWidget {
  const DonorVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DonorVerificationScreen> createState() => _DonorVerificationScreenState();
}

class _DonorVerificationScreenState extends State<DonorVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final VerificationService _verificationService = VerificationService();
  
  bool _isSubmitting = false;
  
  // Document data
  final Map<String, TextEditingController> _documentControllers = {};
  final Map<String, PlatformFile?> _selectedFiles = {};
  final Map<String, String?> _uploadedUrls = {};
  final Map<String, bool> _uploading = {};
  
  // Donor document requirements
  final List<Map<String, String>> _documentRequirements = [
    {
      'type': 'Business License',
      'description': 'Business registration or license (if applicable)',
      'hint': 'Upload business license or registration certificate',
      'required': 'false'
    },
    {
      'type': 'Food Safety Certificate',
      'description': 'Food handling certification (for businesses)',
      'hint': 'Upload food safety certificate or FSSAI license',
      'required': 'false'
    },
    {
      'type': 'Identity Document',
      'description': 'Government-issued identity verification',
      'hint': 'Upload Aadhaar, PAN card, or driver license',
      'required': 'true'
    },
    {
      'type': 'Address Proof',
      'description': 'Current address verification',
      'hint': 'Upload utility bill, rental agreement, or address proof',
      'required': 'true'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (var controller in _documentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final doc in _documentRequirements) {
      final type = doc['type']!;
      _documentControllers[type] = TextEditingController();
      _uploading[type] = false;
    }
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFiles[documentType] = result.files.first;
        });
        
        // Auto-upload the file
        await _uploadFile(documentType);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  Future<void> _uploadFile(String documentType) async {
    final file = _selectedFiles[documentType];
    if (file == null) return;

    setState(() {
      _uploading[documentType] = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;
      
      if (userId == null) throw Exception('User not authenticated');

      final fileName = '${userId}_${documentType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
      final ref = FirebaseStorage.instance.ref().child('verification_documents/donors/$userId/$fileName');

      UploadTask uploadTask;
      if (file.path != null) {
        uploadTask = ref.putFile(File(file.path!));
      } else if (file.bytes != null) {
        uploadTask = ref.putData(file.bytes!);
      } else {
        throw Exception('No file data available');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadedUrls[documentType] = downloadUrl;
        _uploading[documentType] = false;
      });

      _showSuccessSnackBar('$documentType uploaded successfully');
    } catch (e) {
      setState(() {
        _uploading[documentType] = false;
      });
      _showErrorSnackBar('Failed to upload $documentType: $e');
    }
  }

  Future<void> _submitDocuments() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least required documents are uploaded
    bool hasRequiredDocs = true;
    for (final doc in _documentRequirements) {
      if (doc['required'] == 'true') {
        final type = doc['type']!;
        if (_uploadedUrls[type] == null || _uploadedUrls[type]!.isEmpty) {
          hasRequiredDocs = false;
          break;
        }
      }
    }

    if (!hasRequiredDocs) {
      _showErrorSnackBar('Please upload all required documents');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;
      
      if (userId == null) throw Exception('User not authenticated');

      // Prepare submission data
      final submissionData = <String, dynamic>{};
      for (final doc in _documentRequirements) {
        final type = doc['type']!;
        submissionData[type] = {
          'fileUrl': _uploadedUrls[type] ?? '',
          'additionalInfo': _documentControllers[type]?.text ?? '',
        };
      }

      await _verificationService.submitDonorVerification(userId, submissionData);

      if (mounted) {
        _showSuccessSnackBar('Documents submitted successfully!');
        Navigator.pushReplacementNamed(context, AppRouter.donorDashboard);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit documents: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDocumentInfo(),
              const SizedBox(height: 28),
              _buildRequiredDocuments(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      isAccent: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 40,
              color: AppTheme.accentTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Account Verification',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide the required documents to verify your donor account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return GlassContainer(
      tintColor: AppTheme.infoCyan,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.infoCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppTheme.infoCyan,
              size: 22,
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload documents securely. Supported formats: JPG, PNG, PDF',
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
    );
  }

  Widget _buildRequiredDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            'Upload and provide information for each document:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ..._documentRequirements.asMap().entries.map(
            (entry) => _buildDocumentCard(entry.value, entry.key + 1)).toList(),
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, String> doc, int index) {
    final type = doc['type']!;
    final isRequired = doc['required'] == 'true';
    final isUploading = _uploading[type] ?? false;
    final hasFile = _selectedFiles[type] != null;
    final isUploaded = _uploadedUrls[type] != null && _uploadedUrls[type]!.isNotEmpty;

    Color statusColor = AppTheme.textTertiary;
    if (isUploaded) {
      statusColor = AppTheme.successTeal;
    } else if (hasFile) {
      statusColor = AppTheme.warningAmber;
    }

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
                if (isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Optional',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                doc['description']!,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // File upload section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: statusColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  if (isUploading)
                    Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: AppTheme.accentTeal,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Uploading...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    )
                  else if (isUploaded)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successTeal.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: AppTheme.successTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_selectedFiles[type]?.name ?? 'Document'} uploaded',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.successTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          hasFile ? Icons.upload_file_rounded : Icons.cloud_upload_outlined,
                          size: 32,
                          color: hasFile ? AppTheme.warningAmber : AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasFile 
                              ? 'Tap to upload ${_selectedFiles[type]?.name}' 
                              : doc['hint']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hasFile ? AppTheme.warningAmber : AppTheme.textSecondary,
                            fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: hasFile ? 'Change File' : 'Choose File',
                    icon: hasFile ? Icons.refresh_rounded : Icons.attach_file_rounded,
                    outlined: !isUploaded,
                    onPressed: isUploading ? null : () => _pickFile(type),
                  ),
                ),
                if (hasFile && !isUploaded && !isUploading) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      text: 'Upload',
                      icon: Icons.cloud_upload_rounded,
                      onPressed: () => _uploadFile(type),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional info text field
            TextFormField(
              controller: _documentControllers[type],
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Additional Information',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: 'Document number, expiry date, or other details...',
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
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GradientButton(
      text: _isSubmitting ? 'Submitting...' : 'Submit for Verification',
      icon: _isSubmitting ? null : Icons.send_rounded,
      onPressed: _isSubmitting ? null : _submitDocuments,
      isLoading: _isSubmitting,
    );
  }
}
