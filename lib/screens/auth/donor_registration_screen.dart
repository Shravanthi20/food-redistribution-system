import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/donor_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _operatingHoursController = TextEditingController();

  DonorType _selectedDonorType = DonorType.restaurant;
  final List<String> _selectedFoodTypes = [];
  bool _pickupAvailable = false;
  bool _deliveryAvailable = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _foodTypes = [
    'Cooked Meals', 'Raw Vegetables', 'Fruits', 'Dairy Products',
    'Packaged Foods', 'Beverages', 'Bakery Items', 'Grains & Cereals',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _operatingHoursController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one food type'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final donorProfile = DonorProfile(
      userId: '',
      donorType: _selectedDonorType,
      businessName: _businessNameController.text.trim(),
      businessRegistrationNumber: _registrationNumberController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      location: {},
      foodTypes: _selectedFoodTypes,
      operatingHours: _operatingHoursController.text.trim(),
      pickupAvailable: _pickupAvailable,
      deliveryAvailable: _deliveryAvailable,
      createdAt: DateTime.now(),
    );

    final success = await authProvider.registerDonor(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      donorProfile: donorProfile,
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Establish Donor Profile', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
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
                    _buildSectionHeader('Account Security', 'Secure your donor dashboard access'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'OFFICIAL EMAIL',
                      hintText: 'contact@business.com',
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
                            validator: (value) => (value != null && value.length < 6) ? 'Min 6 chars' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'CONFIRM',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) => (value != _passwordController.text) ? 'Mismatch' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('Verification Details', 'Institutional data for trust verification'),
                    const SizedBox(height: 24),
                    _buildDropdownLabel('BUSINESS ENTITY TYPE'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<DonorType>(
                          value: _selectedDonorType,
                          items: DonorType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getDonorTypeDisplayName(type), style: theme.textTheme.bodyLarge),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedDonorType = v!),
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _businessNameController,
                      label: 'LEGAL TRADING NAME',
                      hintText: 'e.g. Green Earth Catering',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _registrationNumberController,
                      label: 'REGISTRATION / TAX ID',
                      hintText: 'Official business ID',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('Logistics & Capabilities', 'Define your redistribution capacity'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _addressController,
                      label: 'PHYSICAL ADDRESS',
                      maxLines: 2,
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(flex: 2, child: CustomTextField(controller: _cityController, label: 'CITY')),
                        const SizedBox(width: 12),
                        Expanded(child: CustomTextField(controller: _zipCodeController, label: 'ZIP', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDropdownLabel('FOOD CATEGORIES OFFERED'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _foodTypes.map((type) {
                        final isSelected = _selectedFoodTypes.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (s) => setState(() => s ? _selectedFoodTypes.add(type) : _selectedFoodTypes.remove(type)),
                          backgroundColor: Colors.transparent,
                          selectedColor: colorScheme.primary.withOpacity(0.12),
                          checkmarkColor: colorScheme.primary,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? colorScheme.primary : AppTheme.slate200),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    _buildCapabilityToggle(
                      'Pickup Availability', 
                      'Volunteers can collect directly from your site', 
                      _pickupAvailable, 
                      (v) => setState(() => _pickupAvailable = v)
                    ),
                    _buildCapabilityToggle(
                      'Delivery Logistics', 
                      'You possess the capacity to deliver to local hubs', 
                      _deliveryAvailable, 
                      (v) => setState(() => _deliveryAvailable = v)
                    ),
                    
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Initialize Donor Status'),
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

  Widget _buildDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: Colors.grey[600])),
    );
  }

  Widget _buildCapabilityToggle(String title, String sub, bool val, Function(bool) onC) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        value: val,
        onChanged: onC,
        activeColor: AppTheme.primaryEmerald,
      ),
    );
  }

  String _getDonorTypeDisplayName(DonorType type) {
    return type.name[0].toUpperCase() + type.name.substring(1).replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}');
  }
}