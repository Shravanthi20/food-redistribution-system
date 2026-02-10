import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';
import '../../models/user.dart';
import '../../utils/app_router.dart';
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
        _showSuccessSnackBar('Documents submitted successfully! Your account is under review.');
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildDocumentInfo(),
              const SizedBox(height: 24),
              _buildRequiredDocuments(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.verified_user,
              size: 48,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'Account Verification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide the required documents to verify your donor account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'For security, please provide document details (numbers, references) rather than uploading files. All information is encrypted and secure.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please fill out the information for each required document:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ..._documentRequirements.map((doc) => _buildDocumentCard(doc)).toList(),
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, String> doc) {
    final type = doc['type']!;
    final isRequired = doc['required'] == 'true';
    final isUploading = _uploading[type] ?? false;
    final hasFile = _selectedFiles[type] != null;
    final isUploaded = _uploadedUrls[type] != null && _uploadedUrls[type]!.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRequired ? Icons.circle : Icons.circle_outlined,
                  size: 8,
                  color: isRequired ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              doc['description']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            
            // File upload section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isUploaded ? Colors.green : (hasFile ? Colors.orange : Colors.grey.shade300),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isUploaded ? Colors.green.shade50 : (hasFile ? Colors.orange.shade50 : Colors.grey.shade50),
              ),
              child: Column(
                children: [
                  if (isUploading)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  else if (isUploaded)
                    Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedFiles[type]?.name ?? 'Document'} uploaded successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          hasFile ? Icons.upload_file : Icons.cloud_upload_outlined,
                          size: 32,
                          color: hasFile ? Colors.orange.shade600 : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasFile ? 'Tap to upload ${_selectedFiles[type]?.name}' : doc['hint']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hasFile ? Colors.orange.shade700 : Colors.grey.shade600,
                            fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : () => _pickFile(type),
                    icon: Icon(hasFile ? Icons.refresh : Icons.attach_file),
                    label: Text(hasFile ? 'Choose Different File' : 'Choose File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUploaded ? Colors.green : null,
                      foregroundColor: isUploaded ? Colors.white : null,
                    ),
                  ),
                ),
                if (hasFile && !isUploaded && !isUploading) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _uploadFile(type),
                    child: const Text('Upload'),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Additional info text field
            TextFormField(
              controller: _documentControllers[type],
              decoration: InputDecoration(
                labelText: 'Additional Information (Optional)',
                hintText: 'Document number, expiry date, or other details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitDocuments,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Submit Documents for Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}