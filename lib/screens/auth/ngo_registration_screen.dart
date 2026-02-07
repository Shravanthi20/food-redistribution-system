import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/ngo_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';

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
  final _organizationNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _capacityController = TextEditingController();
  final _storagCapacityController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  NGOType _selectedNGOType = NGOType.foodBank;
  List<String> _selectedServingPopulation = [];
  List<String> _selectedFoodTypes = [];
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
    _organizationNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _operatingHoursController.dispose();
    _capacityController.dispose();
    _storagCapacityController.dispose();
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preferred food type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }


    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final ngoProfile = NGOProfile(
      userId: '', // Will be set by the service
      organizationName: _organizationNameController.text.trim(),
      registrationNumber: _registrationNumberController.text.trim(),
      ngoType: _selectedNGOType,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      location: {}, // Will be set later with geocoding
      capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
      servingPopulation: _selectedServingPopulation,
      operatingHours: _operatingHoursController.text.trim(),
      preferredFoodTypes: _selectedFoodTypes,
      storageCapacity: int.tryParse(_storagCapacityController.text.trim()) ?? 0,
      refrigerationAvailable: _refrigerationAvailable,
      contactPerson: _contactPersonController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await authProvider.registerNGO(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      ngoProfile: ngoProfile,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.documentSubmission);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Registration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Join as an NGO Partner',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us distribute food to those in need',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Account Information
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Organization Information
                    Text(
                      'Organization Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // NGO Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Type',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<NGOType>(
                          value: _selectedNGOType,
                          decoration: const InputDecoration(),
                          items: NGOType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getNGOTypeDisplayName(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedNGOType = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _organizationNameController,
                      label: 'Organization Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter organization name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _registrationNumberController,
                      label: 'Registration Number',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter registration number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _addressController,
                      label: 'Organization Address',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter organization address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _cityController,
                            label: 'City',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _stateController,
                            label: 'State',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter state';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _zipCodeController,
                            label: 'ZIP Code',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter ZIP code';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Verification Documents

                    
                    const SizedBox(height: 32),

                    // Contact Information
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _contactPersonController,
                      label: 'Contact Person Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact person name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _contactPhoneController,
                      label: 'Contact Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _operatingHoursController,
                      label: 'Operating Hours',
                      hintText: 'e.g., Mon-Fri 9:00-18:00',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter operating hours';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Capacity Information
                    Text(
                      'Capacity Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _capacityController,
                            label: 'Daily Capacity (people)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter capacity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _storagCapacityController,
                            label: 'Storage Capacity (kg)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter storage capacity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Refrigeration Available'),
                      subtitle: const Text('We have refrigeration facilities for storage'),
                      value: _refrigerationAvailable,
                      onChanged: (value) {
                        setState(() {
                          _refrigerationAvailable = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Serving Population
                    Text(
                      'Serving Population',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _servingPopulationOptions.map((population) {
                        final isSelected = _selectedServingPopulation.contains(population);
                        return FilterChip(
                          label: Text(population),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServingPopulation.add(population);
                              } else {
                                _selectedServingPopulation.remove(population);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Preferred Food Types
                    Text(
                      'Preferred Food Types',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _foodTypes.map((foodType) {
                        final isSelected = _selectedFoodTypes.contains(foodType);
                        return FilterChip(
                          label: Text(foodType),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFoodTypes.add(foodType);
                              } else {
                                _selectedFoodTypes.remove(foodType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Create NGO Account'),
                    ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRouter.login);
                          },
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

  String _getNGOTypeDisplayName(NGOType type) {
    switch (type) {
      case NGOType.orphanage:
        return 'Orphanage';
      case NGOType.oldAgeHome:
        return 'Old Age Home';
      case NGOType.school:
        return 'School';
      case NGOType.hospital:
        return 'Hospital';
      case NGOType.communityCenter:
        return 'Community Center';
      case NGOType.foodBank:
        return 'Food Bank';
      case NGOType.shelter:
        return 'Shelter';
      case NGOType.other:
        return 'Other';
    }
  }
}
