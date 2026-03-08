import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/ngo_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class NGORegistrationScreen extends StatefulWidget {
  const NGORegistrationScreen({super.key});

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
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _storagCapacityController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  NGOType _selectedNGOType = NGOType.foodBank;
  final List<String> _selectedServingPopulation = [];
  final List<String> _selectedFoodTypes = [];
  bool _refrigerationAvailable = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _servingPopulationOptions = [
    'Orphans',
    'Elderly',
    'Homeless',
    'Low-income families',
    'Students',
    'Disabled persons',
    'Refugees',
    'Others',
  ];

  final List<String> _foodTypes = [
    'Cooked Meals',
    'Raw Vegetables',
    'Fruits',
    'Dairy Products',
    'Packaged Foods',
    'Beverages',
    'Bakery Items',
    'Grains & Cereals',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _capacityController.dispose();
    _storagCapacityController.dispose();
    _operatingHoursController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServingPopulation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one serving population'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preferred food type'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final ngoProfile = NGOProfile(
      userId: '',
      organizationName: _orgNameController.text.trim(),
      registrationNumber: _regNumberController.text.trim(),
      ngoType: _selectedNGOType,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      location: {
        'latitude': 37.7750,
        'longitude': -122.4180,
      },
      capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
      servingPopulation: _selectedServingPopulation,
      operatingHours: _operatingHoursController.text.trim(),
      preferredFoodTypes: _selectedFoodTypes,
      storageCapacity: int.tryParse(_storagCapacityController.text.trim()) ?? 0,
      refrigerationAvailable: _refrigerationAvailable,
      contactPerson: _contactPersonController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
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
    final colorScheme = theme.colorScheme;
    
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
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
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
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Min 6 chars';
                              return null;
                            },
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
                            validator: (value) {
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('Institutional Profile', 'Official data for distribution trust'),
                    const SizedBox(height: 24),

                    // NGO Type Dropdown
                    _buildDropdownLabel('ORGANIZATION TYPE'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<NGOType>(
                          value: _selectedNGOType,
                          items: NGOType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getNGOTypeDisplayName(type), style: theme.textTheme.bodyLarge),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedNGOType = v!),
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                      controller: _descriptionController,
                      label: 'MISSION DESCRIPTION',
                      hintText: 'Describe your food distribution goals...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 48),
                    _buildSectionHeader('Location & Contact', 'Your operational logistics'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _addressController,
                      label: 'OFFICE / SHELTER ADDRESS',
                      maxLines: 2,
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(flex: 2, child: CustomTextField(controller: _cityController, label: 'CITY', validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: CustomTextField(controller: _stateController, label: 'STATE')),
                        const SizedBox(width: 12),
                        Expanded(child: CustomTextField(controller: _zipCodeController, label: 'ZIP', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _contactPersonController,
                      label: 'CONTACT PERSON',
                      hintText: 'Primary contact name',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _contactPhoneController,
                      label: 'CONTACT PHONE',
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _operatingHoursController,
                      label: 'OPERATING HOURS',
                      hintText: 'e.g., Mon-Fri 9:00-18:00',
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),

                    const SizedBox(height: 48),
                    _buildSectionHeader('Capacity & Storage', 'Define your redistribution capability'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _capacityController,
                            label: 'DAILY CAPACITY (PEOPLE)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (int.tryParse(value) == null) return 'Enter a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _storagCapacityController,
                            label: 'STORAGE CAPACITY (KG)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (int.tryParse(value) == null) return 'Enter a number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCapabilityToggle(
                      'Refrigeration Available',
                      'We have refrigeration facilities for storage',
                      _refrigerationAvailable,
                      (v) => setState(() => _refrigerationAvailable = v),
                    ),

                    const SizedBox(height: 48),
                    _buildSectionHeader('Serving Population', 'Who does your organization serve?'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _servingPopulationOptions.map((pop) {
                        final isSelected = _selectedServingPopulation.contains(pop);
                        return FilterChip(
                          label: Text(pop),
                          selected: isSelected,
                          onSelected: (s) => setState(() => s ? _selectedServingPopulation.add(pop) : _selectedServingPopulation.remove(pop)),
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
                    _buildDropdownLabel('PREFERRED FOOD TYPES'),
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

  String _getNGOTypeDisplayName(NGOType type) {
    return type.name[0].toUpperCase() + type.name.substring(1).replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}');
  }
}
