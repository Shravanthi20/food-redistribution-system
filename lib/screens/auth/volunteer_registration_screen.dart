import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/volunteer_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasVehicle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final volunteerProfile = VolunteerProfile(
      userId: '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      hasVehicle: _hasVehicle,
      isAvailable: true,
      createdAt: DateTime.now(),
    );

    final success = await authProvider.registerVolunteer(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      volunteerProfile: volunteerProfile,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.emailVerification);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Volunteer Enrollment', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Individual Access', 'Create your volunteer profile'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'PERSONAL EMAIL',
                      hintText: 'yourname@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'SECURE PASSWORD',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('Personal Identity', 'Verify your contact information'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(controller: _firstNameController, label: 'FIRST NAME')),
                        const SizedBox(width: 16),
                        Expanded(child: CustomTextField(controller: _lastNameController, label: 'LAST NAME')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'MOBILE NUMBER',
                      keyboardType: TextInputType.phone,
                      hintText: '+1 234 567 890',
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _cityController,
                      label: 'CURRENT CITY',
                    ),
                    
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: SwitchListTile(
                        title: const Text('I have a vehicle for transport', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: const Text('Bicycle, motorcycle, or car', style: TextStyle(fontSize: 12)),
                        value: _hasVehicle,
                        onChanged: (v) => setState(() => _hasVehicle = v),
                        activeColor: AppTheme.primaryEmerald,
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Initialize Volunteer Status'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}