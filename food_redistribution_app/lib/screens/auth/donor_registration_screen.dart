import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/donor_profile.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';

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
  final _cityController = TextEditingController();
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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final donorProfile = DonorProfile(
      userId: '',
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

    final success = await authProvider.registerDonor(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      donorProfile: donorProfile,
    );

    setState(() => _isLoading = false);

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
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {IconData? prefixIcon, String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: AppTheme.textSecondary),
      hintStyle: TextStyle(color: AppTheme.textTertiary),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textTertiary, size: 20) : null,
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorRed, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      appBar: AppBar(
        title: const Text('Donor Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSectionCard(
                title: 'Account Details',
                icon: Icons.person_outline_rounded,
                children: [
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration('Email Address', prefixIcon: Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!value.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    obscureText: _obscurePassword,
                    decoration: _buildInputDecoration(
                      'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => (value != null && value.length < 6) 
                        ? 'Min 6 characters' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    obscureText: _obscureConfirmPassword,
                    decoration: _buildInputDecoration(
                      'Confirm Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) => (value != _passwordController.text) 
                        ? 'Passwords do not match' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCountryCode,
                          dropdownColor: AppTheme.primaryNavyLight,
                          style: TextStyle(color: AppTheme.textPrimary),
                          decoration: _buildInputDecoration('Code'),
                          items: _countryCodes.map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(code, style: TextStyle(color: AppTheme.textPrimary)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCountryCode = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          style: TextStyle(color: AppTheme.textPrimary),
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration('Phone Number', prefixIcon: Icons.phone_outlined),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Business Information',
                icon: Icons.store_outlined,
                children: [
                  DropdownButtonFormField<DonorType>(
                    value: _selectedDonorType,
                    dropdownColor: AppTheme.primaryNavyLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('Business Type', prefixIcon: Icons.category_outlined),
                    items: DonorType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getDonorTypeDisplayName(type), style: TextStyle(color: AppTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDonorType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('Business Name', prefixIcon: Icons.business_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _registrationNumberController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('Registration Number', prefixIcon: Icons.numbers_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _operatingHoursController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration(
                      'Operating Hours',
                      prefixIcon: Icons.access_time_rounded,
                      hintText: 'e.g., Mon-Fri 9AM-8PM',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Location',
                icon: Icons.location_on_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    dropdownColor: AppTheme.primaryNavyLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('Country', prefixIcon: Icons.public_rounded),
                    items: _countryStates.keys.map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country, style: TextStyle(color: AppTheme.textPrimary)),
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
                    dropdownColor: AppTheme.primaryNavyLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('State', prefixIcon: Icons.map_outlined),
                    items: _selectedCountry == null 
                      ? [] 
                      : _countryStates[_selectedCountry]!.map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state, style: TextStyle(color: AppTheme.textPrimary)),
                        )).toList(),
                    onChanged: _selectedCountry == null ? null : (val) => setState(() => _selectedState = val),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('City', prefixIcon: Icons.location_city_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: _buildInputDecoration('Street Address', prefixIcon: Icons.home_outlined),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zipCodeController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('ZIP / Postal Code', prefixIcon: Icons.pin_drop_outlined),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Donation Preferences',
                icon: Icons.set_meal_outlined,
                children: [
                  Text(
                    'What do you usually donate?',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _foodTypes.map((foodType) {
                      final isSelected = _selectedFoodTypes.contains(foodType);
                      return FilterChip(
                        label: Text(
                          foodType,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.accentTeal,
                        backgroundColor: AppTheme.surfaceGlass,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppTheme.accentTeal : AppTheme.surfaceGlassBorder,
                        ),
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
                  const SizedBox(height: 20),
                  Divider(color: AppTheme.surfaceGlassBorder),
                  _buildCheckboxTile(
                    'Pickup Available',
                    Icons.local_shipping_outlined,
                    _pickupAvailable,
                    (val) => setState(() => _pickupAvailable = val!),
                  ),
                  _buildCheckboxTile(
                    'Delivery Available',
                    Icons.delivery_dining_outlined,
                    _deliveryAvailable,
                    (val) => setState(() => _deliveryAvailable = val!),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: _isLoading ? 'Creating Account...' : 'Create Account',
                icon: _isLoading ? null : Icons.person_add_rounded,
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.accentTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(String title, IconData icon, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppTheme.accentTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppTheme.accentTeal : AppTheme.textTertiary,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentTeal.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.volunteer_activism_rounded,
            size: 40,
            color: AppTheme.accentTeal,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.textPrimary, AppTheme.accentCyan],
          ).createShader(bounds),
          child: Text(
            'Join the Movement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Register as a Donor to stop food waste.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accentTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.surfaceGlassBorder),
          const SizedBox(height: 16),
          ...children,
        ],
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
