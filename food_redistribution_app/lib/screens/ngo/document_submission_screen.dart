import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';
import '../../models/user.dart';

class DocumentSubmissionScreen extends StatefulWidget {
  const DocumentSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<DocumentSubmissionScreen> createState() => _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState extends State<DocumentSubmissionScreen> {
  final GlobalKey&lt;FormState&gt; _formKey = GlobalKey&lt;FormState&gt;();
  final VerificationService _verificationService = VerificationService();
  
  bool _isSubmitting = false;
  UserRole? _userRole;
  
  // Document form data
  final Map&lt;String, TextEditingController&gt; _documentControllers = {};
  final Map&lt;String, String&gt; _documentInfo = {};
  
  // Document requirements by role
  final Map&lt;UserRole, List&lt;Map&lt;String, String&gt;&gt;&gt; _documentRequirements = {
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
    final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
    _userRole = authProvider.userRole;
    
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final documents = _documentRequirements[_userRole] ?? [];

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
              // Header Card
              Card(
                color: Colors.green.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.green.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Verification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please provide the required documents to verify your ${_userRole!.name.toUpperCase()} account',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Information Note
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'For security, please provide document details (numbers, references) rather than uploading files. All information is encrypted and secure.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
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
              
              // Document Forms
              Text(
                'Required Documents',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill out the information for each required document:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 16),
              
              ...documents.map((doc) =&gt; _buildDocumentCard(doc)).toList(),
              
              const SizedBox(height: 32),
              
              // Additional Information
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Any additional information that might help with verification...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _documentInfo['additional_info'] = value;
                        },
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
                  onPressed: _isSubmitting ? null : _submitDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
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
                            Text('Submitting Documents...'),
                          ],
                        )
                      : const Text(
                          'Submit for Verification',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () =&gt; Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Later',
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

  Widget _buildDocumentCard(Map&lt;String, String&gt; doc) {
    final type = doc['type']!;
    final description = doc['description']!;
    final hint = doc['hint']!;
    final controller = _documentControllers[type]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description, size: 20),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This document information is required';
                  }
                  if (value.trim().length &lt; 5) {
                    return 'Please provide more detailed information';
                  }
                  return null;
                },
                onChanged: (value) {
                  _documentInfo[type] = value.trim();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future&lt;void&gt; _submitDocuments() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if all required documents have information
    final documents = _documentRequirements[_userRole] ?? [];
    for (final doc in documents) {
      final type = doc['type']!;
      if (!_documentInfo.containsKey(type) || _documentInfo[type]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out information for: $type')),
        );
        return;
      }
    }

    setState(() =&gt; _isSubmitting = true);

    try {
      final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
      
      final submissionId = await _verificationService.submitVerificationInfo(
        userId: authProvider.firebaseUser!.uid,
        userRole: _userRole!,
        documentInfo: Map&lt;String, String&gt;.from(_documentInfo),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents submitted successfully! You will be notified once reviewed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        // Navigate to verification pending screen
        Navigator.pushReplacementNamed(context, '/verification-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() =&gt; _isSubmitting = false);
      }
    }
  }
}