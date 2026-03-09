import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/volunteer_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({super.key});

  @override
  State<VolunteerRegistrationScreen> createState() =>
      _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState
    extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _maxRadiusController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasVehicle = false;
  final List<String> _selectedAvailabilityHours = [];
  final List<String> _selectedWorkingDays = [];
  final List<String> _selectedPreferredTasks = [];

  final List<String> _availabilityHoursOptions = [
    'Morning (6AM-12PM)',
    'Afternoon (12PM-6PM)',
    'Evening (6PM-12AM)',
    'Night (12AM-6AM)',
  ];

  final List<String> _workingDaysOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _preferredTasksOptions = [
    'Food Pickup',
    'Food Delivery',
    'Food Sorting',
    'Kitchen Help',
    'Distribution Support',
    'Documentation',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _vehicleTypeController.dispose();
    _drivingLicenseController.dispose();
    _maxRadiusController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
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
      vehicleType: _hasVehicle
          ? VehicleType.values.firstWhere(
              (e) => e.name == _vehicleTypeController.text.trim().toLowerCase(),
              orElse: () => VehicleType.car,
            )
          : VehicleType.none,
      drivingLicense:
          _hasVehicle ? _drivingLicenseController.text.trim() : null,
      availabilityHours: _selectedAvailabilityHours,
      workingDays: _selectedWorkingDays,
      maxRadius: int.tryParse(_maxRadiusController.text.trim()) ?? 10,
      preferredTasks: _selectedPreferredTasks,
      emergencyContact: _emergencyContactController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Volunteer Enrollment',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'Individual Access', 'Create your volunteer profile'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'PERSONAL EMAIL',
                      hintText: 'yourname@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value)) {
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
                            label: 'SECURE PASSWORD',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                              if (value.length < 6) {
                          return 'Min 6 chars';
                        }
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
                              icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _buildSectionHeader(
                        'Personal Identity', 'Verify your contact information'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: CustomTextField(
                                controller: _firstNameController,
                                label: 'FIRST NAME',
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: CustomTextField(
                                controller: _lastNameController,
                                label: 'LAST NAME',
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'MOBILE NUMBER',
                      keyboardType: TextInputType.phone,
                      hintText: '+1 234 567 890',
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _cityController,
                      label: 'CURRENT CITY',
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: SwitchListTile(
                        title: const Text('I have a vehicle for transport',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: const Text('Bicycle, motorcycle, or car',
                            style: TextStyle(fontSize: 12)),
                        value: _hasVehicle,
                        onChanged: (v) => setState(() => _hasVehicle = v),
                        activeThumbColor: AppTheme.primaryEmerald,
                      ),
                    ),
                    if (_hasVehicle) ...[
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _vehicleTypeController,
                        label: 'VEHICLE TYPE',
                        hintText: 'e.g., Car, Motorcycle, Bicycle',
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _drivingLicenseController,
                        label: 'DRIVING LICENSE',
                        hintText: 'License number',
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _maxRadiusController,
                      label: 'MAX TRAVEL RADIUS (KM)',
                      keyboardType: TextInputType.number,
                      hintText: 'e.g., 10',
                    ),
                    const SizedBox(height: 48),
                    _buildSectionHeader(
                        'Emergency Contact', 'For safety and coordination'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emergencyContactController,
                      label: 'EMERGENCY CONTACT NAME',
                      hintText: 'Full name',
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _emergencyPhoneController,
                      label: 'EMERGENCY PHONE',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 48),
                    _buildSectionHeader(
                        'Working Days', 'When are you available?'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _workingDaysOptions.map((day) {
                        final isSelected = _selectedWorkingDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (s) => setState(() => s
                              ? _selectedWorkingDays.add(day)
                              : _selectedWorkingDays.remove(day)),
                          backgroundColor: Colors.transparent,
                          selectedColor: colorScheme.primary.withValues(alpha: 0.12),
                          checkmarkColor: colorScheme.primary,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : AppTheme.slate200),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Availability Hours', 'Preferred time slots'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availabilityHoursOptions.map((hours) {
                        final isSelected =
                            _selectedAvailabilityHours.contains(hours);
                        return FilterChip(
                          label: Text(hours),
                          selected: isSelected,
                          onSelected: (s) => setState(() => s
                              ? _selectedAvailabilityHours.add(hours)
                              : _selectedAvailabilityHours.remove(hours)),
                          backgroundColor: Colors.transparent,
                          selectedColor: colorScheme.primary.withValues(alpha: 0.12),
                          checkmarkColor: colorScheme.primary,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : AppTheme.slate200),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Preferred Tasks', 'What would you like to help with?'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferredTasksOptions.map((task) {
                        final isSelected =
                            _selectedPreferredTasks.contains(task);
                        return FilterChip(
                          label: Text(task),
                          selected: isSelected,
                          onSelected: (s) => setState(() => s
                              ? _selectedPreferredTasks.add(task)
                              : _selectedPreferredTasks.remove(task)),
                          backgroundColor: Colors.transparent,
                          selectedColor: colorScheme.primary.withValues(alpha: 0.12),
                          checkmarkColor: colorScheme.primary,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : AppTheme.slate200),
                          ),
                        );
                      }).toList(),
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
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
