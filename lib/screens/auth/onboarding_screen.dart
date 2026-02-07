import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  final dynamic userRole;

  const OnboardingScreen({Key? key, this.userRole}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;
    
    // If user data is not loaded yet
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // IMMEDIATE FIX: Donors do not need verification. Redirect immediately.
    if (user.role == UserRole.donor) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToDashboard(context, user.role);
       });
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check Onboarding State
    if (user.onboardingState == OnboardingState.documentSubmitted) {
      return _buildUnderReviewScreen(context);
    } else if (user.onboardingState == OnboardingState.verified || 
               user.onboardingState == OnboardingState.active) {
       // Should have been redirected by Splash/AuthWrapper, but handle here just in case
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToDashboard(context, user.role);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Default: registered state, needs document upload
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verification Required'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context, user.role),
              const SizedBox(height: 40),
              
              // Upload Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined, 
                      size: 48, 
                      color: Theme.of(context).primaryColor
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Registration Certificate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Supported formats: PDF, JPG, PNG',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_selectedFile != null)
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(_selectedFile!.name),
                        subtitle: Text('${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _selectedFile = null),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Select Document'),
                      ),
                  ],
                ),
              ),
              
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _uploadError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              const Spacer(),
              
              ElevatedButton(
                onPressed: _selectedFile != null ? () => _submitDocument(context, user) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Submit for Verification'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnderReviewScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Pending'),
        leading: const SizedBox(), // Hide back button
        actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
            )
          ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_filled, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 32),
              const Text(
                'Under Review',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your documents have been submitted and are currently being reviewed by our admin team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will receive an email once your account is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserRole role) {
    String title;
    String description;

    switch (role) {
      case UserRole.ngo:
        title = 'NGO Verification';
        description = 'Please upload your NGO Registration Certificate (Trust/Society/Section 8) to verify your organization.';
        break;
      case UserRole.volunteer:
        title = 'ID Verification';
        description = 'Please upload a valid Government ID proof (Aadhar/Driving License) to verify your identity.';
        break;
      default:
        title = 'Verification';
        description = 'Please upload your verification documents.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      // Check permissions if needed (usually handled by file_picker)
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // Important for web/upload
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error picking file: $e';
      });
    }
  }

  Future<void> _submitDocument(BuildContext context, AppUser user) async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload File
      final url = await _authService.uploadVerificationCertificate(user.uid, _selectedFile!);
      
      if (url == null) {
        throw Exception('File upload failed');
      }

      // 2. Submit Request & Update State
      await _userService.submitVerificationDocuments(
        userId: user.uid,
        certificateUrl: url,
        role: user.role,
      );

      // 3. Refresh Provider State (Optional, logic usually listens to stream)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateOnboardingState(OnboardingState.documentSubmitted);

    } catch (e) {
      setState(() {
        _uploadError = 'Submission failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  void _navigateToDashboard(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.donor:
        Navigator.pushReplacementNamed(context, AppRouter.donorDashboard);
        break;
      case UserRole.ngo:
        Navigator.pushReplacementNamed(context, AppRouter.ngoDashboard);
        break;
      case UserRole.volunteer:
        Navigator.pushReplacementNamed(context, AppRouter.volunteerDashboard);
        break;
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
        break;
    }
  }
}