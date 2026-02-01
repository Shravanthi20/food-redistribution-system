import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/user.dart';
import '../services/verification_service.dart';
import '../services/auth_service.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final VerificationService _verificationService = VerificationService();
  final AuthService _authService = AuthService();
  
  bool _isSubmitting = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildForm(),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Colors.blue.shade600,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Your ${_getUserRoleDisplay()} Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide your document information below for verification',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
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
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter document details below (no file uploads required):',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ..._buildRoleSpecificFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleSpecificFields() {
    switch (_currentUser!.role) {
      case UserRole.donor:
        return [
          FormBuilderTextField(
            name: 'business_license',
            decoration: const InputDecoration(
              labelText: 'Business License Number',
              hintText: 'Enter your business license number',
              prefixIcon: Icon(Icons.business),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(5),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'food_safety_cert',
            decoration: const InputDecoration(
              labelText: 'Food Safety Certificate Number',
              hintText: 'Enter your food safety certificate number',
              prefixIcon: Icon(Icons.food_bank),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'business_address',
            decoration: const InputDecoration(
              labelText: 'Business Address',
              hintText: 'Enter your complete business address',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
        ];
      
      case UserRole.ngo:
        return [
          FormBuilderTextField(
            name: 'ngo_registration',
            decoration: const InputDecoration(
              labelText: 'NGO Registration Number',
              hintText: 'Enter your NGO registration number',
              prefixIcon: Icon(Icons.assignment),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'tax_exemption',
            decoration: const InputDecoration(
              labelText: 'Tax Exemption Number',
              hintText: 'Enter your tax exemption number',
              prefixIcon: Icon(Icons.receipt),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'authorized_person',
            decoration: const InputDecoration(
              labelText: 'Authorized Person Name',
              hintText: 'Name of the authorized representative',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'organization_address',
            decoration: const InputDecoration(
              labelText: 'Organization Address',
              hintText: 'Enter your organization address',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
        ];
      
      case UserRole.volunteer:
        return [
          FormBuilderTextField(
            name: 'identity_number',
            decoration: const InputDecoration(
              labelText: 'Government ID Number',
              hintText: 'Enter your government ID number',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'phone_verification',
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your verified phone number',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.phoneNumber(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'emergency_contact',
            decoration: const InputDecoration(
              labelText: 'Emergency Contact',
              hintText: 'Name and phone of emergency contact',
              prefixIcon: Icon(Icons.contact_phone),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'current_address',
            decoration: const InputDecoration(
              labelText: 'Current Address',
              hintText: 'Enter your current residential address',
              prefixIcon: Icon(Icons.home),
            ),
            maxLines: 3,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
        ];
      
      default:
        return [
          FormBuilderTextField(
            name: 'general_info',
            decoration: const InputDecoration(
              labelText: 'Verification Information',
              hintText: 'Provide relevant verification details',
              prefixIcon: Icon(Icons.info),
            ),
            maxLines: 5,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
        ];
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit for Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = _formKey.currentState!.value;
      
      // Convert form data to document info map
      Map<String, String> documentInfo = {};
      formData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          documentInfo[key] = value.toString();
        }
      });

      await _verificationService.submitVerificationInfo(
        userId: _currentUser!.id,
        userRole: _currentUser!.role,
        documentInfo: documentInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification information submitted successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/verification-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getUserRoleDisplay() {
    switch (_currentUser!.role) {
      case UserRole.donor:
        return 'Business/Donor';
      case UserRole.ngo:
        return 'NGO/Organization';
      case UserRole.volunteer:
        return 'Volunteer';
      default:
        return 'User';
    }
  }
}