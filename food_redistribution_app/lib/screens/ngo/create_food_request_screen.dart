import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_request.dart';
import '../../services/location_service.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class CreateFoodRequestScreen extends StatefulWidget {
  const CreateFoodRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateFoodRequestScreen> createState() => _CreateFoodRequestScreenState();
}

class _CreateFoodRequestScreenState extends State<CreateFoodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  
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
  Widget build(BuildContext context) {
    return GradientScaffold(
      showAnimatedBackground: true,
      appBar: GlassAppBar(
        title: 'Create Food Request',
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _titleController,
                label: 'Request Title',
                hintText: 'e.g., Urgent Food for 50 Children',
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hintText: 'Describe your food requirements and context',
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              
              const SizedBox(height: 24),
              
              // Food Requirements
              Text(
                'Food Requirements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Quantity is required';
                        if (int.tryParse(value!) == null) return 'Enter valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      dropdownColor: AppTheme.surfaceGlassDark,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accentTeal),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'servings', child: Text('Servings')),
                        DropdownMenuItem(value: 'kg', child: Text('Kg')),
                        DropdownMenuItem(value: 'packets', child: Text('Packets')),
                        DropdownMenuItem(value: 'meals', child: Text('Meals')),
                      ],
                      onChanged: (value) => setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Food Types
              Text(
                'Required Food Types:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FoodCategory.values.map((category) => FilterChip(
                  label: Text(category.name),
                  selected: _selectedFoodTypes.contains(category),
                  backgroundColor: AppTheme.surfaceGlassDark.withOpacity(0.5),
                  selectedColor: AppTheme.accentTeal.withOpacity(0.3),
                  checkmarkColor: AppTheme.textPrimary,
                  labelStyle: TextStyle(
                    color: _selectedFoodTypes.contains(category) ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                  side: const BorderSide(color: Colors.white24),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFoodTypes.add(category);
                      } else {
                        _selectedFoodTypes.remove(category);
                      }
                    });
                  },
                )).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Dietary Restrictions
              Text(
                'Dietary Restrictions:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['vegetarian', 'vegan', 'halal', 'kosher', 'gluten-free', 'dairy-free']
                    .map((restriction) => FilterChip(
                      label: Text(restriction),
                      selected: _selectedDietaryRestrictions.contains(restriction),
                      backgroundColor: AppTheme.surfaceGlassDark.withOpacity(0.5),
                      selectedColor: AppTheme.accentTeal.withOpacity(0.3),
                      checkmarkColor: AppTheme.textPrimary,
                      labelStyle: TextStyle(
                        color: _selectedDietaryRestrictions.contains(restriction) ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                      side: const BorderSide(color: Colors.white24),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDietaryRestrictions.add(restriction);
                          } else {
                            _selectedDietaryRestrictions.remove(restriction);
                          }
                        });
                      },
                    )).toList(),
              ),
              
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Requires Refrigeration', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Check if temperature controlled storage is needed', style: TextStyle(color: AppTheme.textSecondary)),
                activeColor: AppTheme.accentTeal,
                value: _requiresRefrigeration,
                onChanged: (value) => setState(() => _requiresRefrigeration = value),
              ),
              
              const SizedBox(height: 24),
              
              // Timing and Urgency
              Text(
                'Timing & Urgency',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<RequestUrgency>(
                value: _selectedUrgency,
                dropdownColor: AppTheme.surfaceGlassDark,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Urgency Level',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentTeal),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                items: RequestUrgency.values.map((urgency) => 
                  DropdownMenuItem(
                    value: urgency,
                    child: Text('${urgency.name.toUpperCase()} - ${_getUrgencyDescription(urgency)}'),
                  ),
                ).toList(),
                onChanged: (value) => setState(() => _selectedUrgency = value!),
              ),
              
              const SizedBox(height: 16),
              
              ListTile(
                title: const Text('Needed By', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text('${_selectedNeededBy.toString().substring(0, 16)}', style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.accentTeal),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedNeededBy,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedNeededBy),
                    );
                    
                    if (time != null) {
                      setState(() {
                        _selectedNeededBy = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _beneficiariesController,
                label: 'Expected Number of Beneficiaries',
                hintText: 'How many people will this food serve?',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Number of beneficiaries is required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Serving Population
              Text(
                'Serving Population:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['children', 'elderly', 'families', 'homeless', 'students', 'patients', 'workers']
                    .map((population) => FilterChip(
                      label: Text(population),
                      selected: _selectedServingPopulation.contains(population),
                      backgroundColor: AppTheme.surfaceGlassDark.withOpacity(0.5),
                      selectedColor: AppTheme.accentTeal.withOpacity(0.3),
                      checkmarkColor: AppTheme.textPrimary,
                      labelStyle: TextStyle(
                        color: _selectedServingPopulation.contains(population) ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                      side: const BorderSide(color: Colors.white24),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServingPopulation.add(population);
                          } else {
                            _selectedServingPopulation.remove(population);
                          }
                        });
                      },
                    )).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Location
              Text(
                'Delivery Location',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                title: const Text('Set Delivery Location', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(_deliveryLocation != null 
                    ? 'Location set' 
                    : 'Tap to set your delivery location', style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.location_on, color: AppTheme.accentTeal),
                onTap: _setDeliveryLocation,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
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
      setState(() {
        _deliveryLocation = {
        'latitude': location?.latitude ?? 0.0,
        'longitude': location?.longitude ?? 0.0,
          'address': 'Current Location', // In a real app, reverse geocode this
        };
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
    
    if (_deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set delivery location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ngoProvider = Provider.of<NGOProvider>(context, listen: false);

      final requestId = await ngoProvider.createFoodRequest(
        ngoId: authProvider.firebaseUser!.uid,
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
            SnackBar(content: Text(ngoProvider.errorMessage ?? 'Failed to create request')),
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
    super.dispose();
  }
}