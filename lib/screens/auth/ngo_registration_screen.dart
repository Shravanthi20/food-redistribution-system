import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ngo_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class NGORegistrationScreen extends StatefulWidget {
  const NGORegistrationScreen({Key? key}) : super(key: key);

  @override
  State<NGORegistrationScreen> createState() => _NGORegistrationScreenState();
}

class _NGORegistrationScreenState extends State<NGORegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final ngoProfile = NGOProfile(
      userId: '',
      organizationName: _orgNameController.text.trim(),
      registrationNumber: _regNumberController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      isVerified: false,
      createdAt: DateTime.now(),
    );

    final success = await authProvider.registerNGO(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      ngoProfile: ngoProfile,
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
        title: Text('NGO Accreditation', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
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
                    _buildSectionHeader('Organization Access', 'Define credentials for your primary account'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'INSTITUTIONAL EMAIL',
                      hintText: 'admin@organization.org',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'CONFIRM',
                            obscureText: _confirmPasswordController.text != _passwordController.text,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('Institutional Profile', 'Official data for distribution trust'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _orgNameController,
                      label: 'LEGAL ENTITY NAME',
                      hintText: 'Official NGO Name',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _regNumberController,
                      label: 'NON-PROFIT REG. NUMBER',
                      hintText: 'Registration ID',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _addressController,
                      label: 'OFFICE / SHELTER ADDRESS',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'MISSION DESCRIPTION',
                      hintText: 'Describe your food distribution goals...',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 80),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Submit for Accreditation'),
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