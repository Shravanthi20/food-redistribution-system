import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_request.dart';
import '../../services/location_service.dart';
import '../../models/food_donation.dart';

class CreateFoodRequestScreen extends StatefulWidget {
  const CreateFoodRequestScreen({super.key});

  @override
  State<CreateFoodRequestScreen> createState() =>
      _CreateFoodRequestScreenState();
}

class _CreateFoodRequestScreenState extends State<CreateFoodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  final _deliveryAddressController = TextEditingController();

  final List<FoodCategory> _selectedFoodTypes = [];
  final List<String> _selectedServingPopulation = [];
  final List<String> _selectedDietaryRestrictions = [];

  String _selectedUnit = 'servings';
  RequestUrgency _selectedUrgency = RequestUrgency.medium;
  DateTime _selectedNeededBy = DateTime.now().add(const Duration(days: 1));
  bool _requiresRefrigeration = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? _deliveryLocation;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> &&
          args.containsKey('prefillFromDonation')) {
        final donation = args['prefillFromDonation'] as FoodDonation;
        _prefillFromDonation(donation);
      }
    });
  }

  void _prefillFromDonation(FoodDonation donation) {
    setState(() {
      _titleController.text = 'Request: ${donation.title}';
      _descriptionController.text =
          'Automatically generated request for donation: ${donation.description}';
      _quantityController.text = donation.quantity.toString();
      _selectedUnit = donation.unit;
      _selectedFoodTypes.clear();
      _selectedFoodTypes.addAll(
        donation.foodTypes.map((t) => _mapFoodTypeToCategory(t)),
      );
      _requiresRefrigeration = donation.requiresRefrigeration;
      _deliveryAddressController.text = donation.pickupAddress;
      // Pre-select dietary restrictions based on donation flags
      _selectedDietaryRestrictions.clear();
      if (donation.isVegetarian) _selectedDietaryRestrictions.add('vegetarian');
      if (donation.isVegan) _selectedDietaryRestrictions.add('vegan');
      if (donation.isHalal) _selectedDietaryRestrictions.add('halal');
    });
  }

  FoodCategory _mapFoodTypeToCategory(FoodType type) {
    switch (type) {
      case FoodType.vegetables:
        return FoodCategory.vegetables;
      case FoodType.fruits:
        return FoodCategory.fruits;
      case FoodType.grains:
        return FoodCategory.grains;
      case FoodType.dairy:
        return FoodCategory.dairy;
      case FoodType.meat:
      case FoodType.seafood:
        return FoodCategory.meat;
      case FoodType.bakery:
        return FoodCategory.bakery;
      case FoodType.beverages:
        return FoodCategory.beverages;
      case FoodType.cooked:
        return FoodCategory.readyToEat;
      default:
        return FoodCategory.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Food Request'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Request Title',
                  hintText: 'e.g., Urgent Food for 50 Children',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your food requirements and context',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
              ),

              const SizedBox(height: 24),

              // Food Requirements
              Text(
                'Food Requirements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Quantity is required';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'servings', child: Text('Servings')),
                        DropdownMenuItem(value: 'kg', child: Text('Kg')),
                        DropdownMenuItem(
                            value: 'packets', child: Text('Packets')),
                        DropdownMenuItem(value: 'meals', child: Text('Meals')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Food Types
              const Text('Required Food Types:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FoodCategory.values
                    .map((category) => FilterChip(
                          label: Text(category.name),
                          selected: _selectedFoodTypes.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFoodTypes.add(category);
                              } else {
                                _selectedFoodTypes.remove(category);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Dietary Restrictions
              const Text('Dietary Restrictions:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'vegetarian',
                  'vegan',
                  'halal',
                  'kosher',
                  'gluten-free',
                  'dairy-free'
                ]
                    .map((restriction) => FilterChip(
                          label: Text(restriction),
                          selected: _selectedDietaryRestrictions
                              .contains(restriction),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDietaryRestrictions.add(restriction);
                              } else {
                                _selectedDietaryRestrictions
                                    .remove(restriction);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Requires Refrigeration'),
                subtitle: const Text(
                    'Check if temperature controlled storage is needed'),
                value: _requiresRefrigeration,
                onChanged: (value) =>
                    setState(() => _requiresRefrigeration = value),
              ),

              const SizedBox(height: 24),

              // Timing and Urgency
              Text(
                'Timing & Urgency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<RequestUrgency>(
                initialValue: _selectedUrgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency Level',
                  border: OutlineInputBorder(),
                ),
                items: RequestUrgency.values
                    .map(
                      (urgency) => DropdownMenuItem(
                        value: urgency,
                        child: Text(
                            '${urgency.name.toUpperCase()} - ${_getUrgencyDescription(urgency)}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedUrgency = value!),
              ),

              const SizedBox(height: 16),

              ListTile(
                title: const Text('Needed By'),
                subtitle: Text(_selectedNeededBy.toString().substring(0, 16)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedNeededBy,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );

                  if (date != null) {
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedNeededBy),
                    );

                    if (time != null) {
                      setState(() {
                        _selectedNeededBy = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: 24),

              // Beneficiaries
              Text(
                'Beneficiaries',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _beneficiariesController,
                decoration: const InputDecoration(
                  labelText: 'Expected Number of Beneficiaries',
                  hintText: 'How many people will this food serve?',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Number of beneficiaries is required';
                  }
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Serving Population
              const Text('Serving Population:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'children',
                  'elderly',
                  'families',
                  'homeless',
                  'students',
                  'patients',
                  'workers'
                ]
                    .map((population) => FilterChip(
                          label: Text(population),
                          selected:
                              _selectedServingPopulation.contains(population),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServingPopulation.add(population);
                              } else {
                                _selectedServingPopulation.remove(population);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 24),

              // Location
              Text(
                'Delivery Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter the NGO delivery address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 12),

              ListTile(
                title: const Text('Use Current Location'),
                subtitle: Text(_deliveryLocation != null
                    ? (_deliveryLocation!['address'] as String? ??
                        'Location set')
                    : 'Tap to use this device location'),
                trailing: const Icon(Icons.location_on),
                onTap: _setDeliveryLocation,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Create Food Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUrgencyDescription(RequestUrgency urgency) {
    switch (urgency) {
      case RequestUrgency.low:
        return 'Can wait several days';
      case RequestUrgency.medium:
        return 'Needed within 1-2 days';
      case RequestUrgency.high:
        return 'Needed within hours';
      case RequestUrgency.critical:
        return 'Emergency - immediate need';
    }
  }

  void _setDeliveryLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to fetch a valid delivery location'),
            ),
          );
        }
        return;
      }

      final address = await _locationService.reverseGeocode(
            location.latitude,
            location.longitude,
          ) ??
          'Current Location';

      if (!mounted) return;
      setState(() {
        _deliveryAddressController.text = address;
        _deliveryLocation = _locationService.buildLocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ngoProvider = Provider.of<NGOProvider>(context, listen: false);

    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food type')),
      );
      return;
    }

    if (_selectedServingPopulation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select serving population')),
      );
      return;
    }

    final enteredAddress = _deliveryAddressController.text.trim();
    if (enteredAddress.isNotEmpty) {
      final geocoded = await _locationService.geocodeAddress(enteredAddress);
      if (geocoded == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to locate the delivery address')),
        );
        return;
      }

      _deliveryLocation = {
        ...geocoded,
        'address': enteredAddress,
      };
    } else if (_deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a delivery address or use current location')),
      );
      return;
    }

    final latitude = (_deliveryLocation!['latitude'] as num?)?.toDouble();
    final longitude = (_deliveryLocation!['longitude'] as num?)?.toDouble();
    if (latitude == null ||
        longitude == null ||
        (latitude == 0.0 && longitude == 0.0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a valid delivery location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final requestId = await ngoProvider.createFoodRequest(
        uid: authProvider.firebaseUser!.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        requiredFoodTypes: _selectedFoodTypes,
        requiredQuantity: int.parse(_quantityController.text),
        unit: _selectedUnit,
        urgency: _selectedUrgency,
        neededBy: _selectedNeededBy,
        deliveryLocation: _deliveryLocation!,
        servingPopulation: _selectedServingPopulation,
        expectedBeneficiaries: int.parse(_beneficiariesController.text),
        requiresRefrigeration: _requiresRefrigeration,
        dietaryRestrictions: _selectedDietaryRestrictions,
      );

      if (requestId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food request created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    ngoProvider.errorMessage ?? 'Failed to create request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _beneficiariesController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }
}
