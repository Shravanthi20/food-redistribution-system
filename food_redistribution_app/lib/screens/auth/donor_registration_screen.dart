import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/donor_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(); // Manual city entry
  final _zipCodeController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _phoneController = TextEditingController();

  // Location State
  String? _selectedCountry;
  String? _selectedState;
  String _selectedCountryCode = '+91';

  // Data for Pickers
  final Map<String, List<String>> _countryStates = {
    'India': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
      'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi',
      'Other'
    ],
    'USA': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine',
      'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
      'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey',
      'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
      'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
      'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia',
      'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
    ],
  };

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  // Other State
  DonorType _selectedDonorType = DonorType.restaurant;
  List<String> _selectedFoodTypes = [];
  bool _pickupAvailable = false;
  bool _deliveryAvailable = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _operatingHoursController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry == null || _selectedState == null) {
      _showErrorSnackBar('Please select your Country and State');
      return;
    }

    if (_selectedFoodTypes.isEmpty) {
      _showErrorSnackBar('Please select at least one food type');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Create Donor Profile
    final donorProfile = DonorProfile(
      userId: '', // Will be set by service
      donorType: _selectedDonorType,
      businessName: _businessNameController.text.trim(),
      businessRegistrationNumber: _registrationNumberController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState!,
      zipCode: _zipCodeController.text.trim(),
      location: {}, 
      foodTypes: _selectedFoodTypes,
      operatingHours: _operatingHoursController.text.trim(),
      pickupAvailable: _pickupAvailable,
      deliveryAvailable: _deliveryAvailable,
      createdAt: DateTime.now(),
    );

    // Call Register
    final success = await authProvider.registerDonor(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      donorProfile: donorProfile,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.emailVerification);
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Donor Registration', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildSectionCard(
                      title: 'Account Details',
                      icon: Icons.person_outline,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (!value.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) => (value != null && value.length < 6) 
                              ? 'Min 6 characters' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (value) => (value != _passwordController.text) 
                              ? 'Passwords do not match' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCountryCode,
                                decoration: InputDecoration(
                                  labelText: 'Code',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                ),
                                items: _countryCodes.map((code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedCountryCode = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                keyboardType: TextInputType.phone,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Business Information',
                      icon: Icons.store_outlined,
                      children: [
                         DropdownButtonFormField<DonorType>(
                          value: _selectedDonorType,
                          decoration: InputDecoration(
                            labelText: 'Business Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: DonorType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getDonorTypeDisplayName(type)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedDonorType = val!),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _businessNameController,
                          label: 'Business Name',
                          prefixIcon: const Icon(Icons.business),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _registrationNumberController,
                          label: 'Registration Number',
                          prefixIcon: const Icon(Icons.numbers),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _operatingHoursController,
                          label: 'Operating Hours',
                          hintText: 'e.g., Mon-Fri 9AM-8PM',
                          prefixIcon: const Icon(Icons.access_time),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Location',
                      icon: Icons.location_on_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.public),
                          ),
                          items: _countryStates.keys.map((country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCountry = val;
                              _selectedState = null;
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.map),
                          ),
                          items: _selectedCountry == null 
                            ? [] 
                            : _countryStates[_selectedCountry]!.map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              )).toList(),
                          onChanged: _selectedCountry == null ? null : (val) => setState(() => _selectedState = val),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _cityController,
                          label: 'City',
                          prefixIcon: const Icon(Icons.location_city),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _addressController,
                          label: 'Street Address',
                          prefixIcon: const Icon(Icons.home_outlined),
                          maxLines: 2,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _zipCodeController,
                          label: 'ZIP / Postal Code',
                          prefixIcon: const Icon(Icons.pin_drop_outlined),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Donation Preferences',
                      icon: Icons.set_meal_outlined,
                      children: [
                        Text(
                          'What do you usually donate?',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _foodTypes.map((foodType) {
                            final isSelected = _selectedFoodTypes.contains(foodType);
                            return FilterChip(
                              label: Text(foodType),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primaryContainer,
                              checkmarkColor: theme.colorScheme.primary,
                              onSelected: (selected) {
                                setState(() {
                                  selected 
                                    ? _selectedFoodTypes.add(foodType) 
                                    : _selectedFoodTypes.remove(foodType);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        CheckboxListTile(
                          title: const Text('Pickup Available'),
                          secondary: const Icon(Icons.local_shipping_outlined),
                          value: _pickupAvailable,
                          onChanged: (val) => setState(() => _pickupAvailable = val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        CheckboxListTile(
                          title: const Text('Delivery Available'),
                          secondary: const Icon(Icons.delivery_dining_outlined),
                          value: _deliveryAvailable,
                          onChanged: (val) => setState(() => _deliveryAvailable = val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?', style: TextStyle(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.volunteer_activism, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Join the Movement',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Register as a Donor to stop food waste.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  String _getDonorTypeDisplayName(DonorType type) {
    switch (type) {
      case DonorType.restaurant: return 'Restaurant';
      case DonorType.supermarket: return 'Grocery Store';
      case DonorType.catering: return 'Catering Service';
      case DonorType.hotel: return 'Hotel';
      case DonorType.institutional: return 'Institutional Kitchen';
      case DonorType.bakery: return 'Bakery';
      case DonorType.individual: return 'Individual';
      case DonorType.other: return 'Other';
    }
  }
}
