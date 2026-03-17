import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_request.dart';

class UpdateDemandScreen extends StatefulWidget {
  final FoodRequest? foodRequest;

  const UpdateDemandScreen({Key? key, this.foodRequest}) : super(key: key);

  @override
  State<UpdateDemandScreen> createState() => _UpdateDemandScreenState();
}

class _UpdateDemandScreenState extends State<UpdateDemandScreen> {
  final GlobalKey&lt;FormState&gt; _formKey = GlobalKey&lt;FormState&gt;();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _beneficiariesController;
  
  // Selection states
  late List&lt;FoodCategory&gt; _selectedFoodTypes;
  late RequestUrgency _selectedUrgency;
  late String _selectedUnit;
  late DateTime _selectedNeededBy;
  late List&lt;String&gt; _selectedServingPopulation;
  late bool _requiresRefrigeration;
  late List&lt;String&gt; _selectedDietaryRestrictions;
  
  bool _isSubmitting = false;
  
  // Options
  final List&lt;String&gt; _units = ['kg', 'servings', 'packets', 'boxes', 'bags', 'liters', 'pieces'];
  final List&lt;String&gt; _servingPopulations = [
    'Children', 'Elderly', 'Families', 'Homeless', 'Students', 'Workers', 'Refugees', 'All ages'
  ];
  final List&lt;String&gt; _dietaryRestrictions = [
    'Vegetarian', 'Vegan', 'Halal', 'Kosher', 'Gluten-free', 'Dairy-free', 'Nut-free', 'No restrictions'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.foodRequest != null) {
      final request = widget.foodRequest!;
      _titleController = TextEditingController(text: request.title);
      _descriptionController = TextEditingController(text: request.description);
      _quantityController = TextEditingController(text: request.requiredQuantity.toString());
      _beneficiariesController = TextEditingController(text: request.expectedBeneficiaries.toString());
      
      _selectedFoodTypes = List.from(request.requiredFoodTypes);
      _selectedUrgency = request.urgency;
      _selectedUnit = request.unit;
      _selectedNeededBy = request.neededBy;
      _selectedServingPopulation = List.from(request.servingPopulation);
      _requiresRefrigeration = request.requiresRefrigeration;
      _selectedDietaryRestrictions = List.from(request.dietaryRestrictions);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _quantityController = TextEditingController();
      _beneficiariesController = TextEditingController();
      
      _selectedFoodTypes = [];
      _selectedUrgency = RequestUrgency.medium;
      _selectedUnit = 'kg';
      _selectedNeededBy = DateTime.now().add(const Duration(days: 7));
      _selectedServingPopulation = [];
      _requiresRefrigeration = false;
      _selectedDietaryRestrictions = [];
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodRequest != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Food Request' : 'Create Food Request'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Cancel Request',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Updating Request',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Changes will be saved and matched donations will be notified',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Request Title',
                  hintText: 'e.g., Meals for 50 children',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your food requirements and the people you serve...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quantity and Urgency
              _buildSectionTitle('Quantity &amp; Urgency'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Invalid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<RequestUrgency>(
                value: _selectedUrgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: RequestUrgency.values.map((urgency) {
                  return DropdownMenuItem(
                    value: urgency,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(urgency),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getUrgencyText(urgency)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (RequestUrgency? newValue) {
                  setState(() {
                    _selectedUrgency = newValue!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Needed By Date
              InkWell(
                onTap: _selectNeededByDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Needed By',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    '${_selectedNeededBy.day}/${_selectedNeededBy.month}/${_selectedNeededBy.year}',
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _beneficiariesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected Beneficiaries',
                  hintText: 'Number of people this will feed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expected beneficiaries';
                  }
                  if (int.tryParse(value) == null || int.parse(value) &lt;= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Food Types
              _buildSectionTitle('Food Requirements'),
              const SizedBox(height: 16),
              
              Text(
                'Food Types Needed:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FoodCategory.values.map((category) {
                  final isSelected = _selectedFoodTypes.contains(category);
                  return FilterChip(
                    label: Text(_getFoodCategoryText(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFoodTypes.add(category);
                        } else {
                          _selectedFoodTypes.remove(category);
                        }
                      });
                    },
                    selectedColor: Colors.orange.shade100,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Serving Population
              _buildSectionTitle('Serving Population'),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _servingPopulations.map((population) {
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
                    selectedColor: Colors.blue.shade100,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Special Requirements
              _buildSectionTitle('Special Requirements'),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Requires Refrigeration'),
                subtitle: const Text('Cold storage needed'),
                value: _requiresRefrigeration,
                onChanged: (bool? value) {
                  setState(() {
                    _requiresRefrigeration = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Dietary Restrictions:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietaryRestrictions.map((restriction) {
                  final isSelected = _selectedDietaryRestrictions.contains(restriction);
                  return FilterChip(
                    label: Text(restriction),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDietaryRestrictions.add(restriction);
                        } else {
                          _selectedDietaryRestrictions.remove(restriction);
                        }
                      });
                    },
                    selectedColor: Colors.green.shade100,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Updating...'),
                          ],
                        )
                      : Text(
                          isEditing ? 'Update Request' : 'Create Request',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.orange.shade700,
      ),
    );
  }

  Color _getUrgencyColor(RequestUrgency urgency) {
    switch (urgency) {
      case RequestUrgency.low:
        return Colors.green;
      case RequestUrgency.medium:
        return Colors.orange;
      case RequestUrgency.high:
        return Colors.red;
      case RequestUrgency.critical:
        return Colors.red.shade800;
    }
  }

  String _getUrgencyText(RequestUrgency urgency) {
    switch (urgency) {
      case RequestUrgency.low:
        return 'Low - Can wait several days';
      case RequestUrgency.medium:
        return 'Medium - Needed within 1-2 days';
      case RequestUrgency.high:
        return 'High - Needed within hours';
      case RequestUrgency.critical:
        return 'Critical - Emergency need';
    }
  }

  String _getFoodCategoryText(FoodCategory category) {
    return category.name.replaceFirst(category.name[0], category.name[0].toUpperCase());
  }

  Future&lt;void&gt; _selectNeededByDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedNeededBy,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedNeededBy) {
      setState(() {
        _selectedNeededBy = picked;
      });
    }
  }

  Future&lt;void&gt; _submitUpdate() async {
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

    setState(() =&gt; _isSubmitting = true);

    try {
      final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
      final ngoProvider = Provider.of&lt;NGOProvider&gt;(context, listen: false);
      
      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
          'requiredFoodTypes': _selectedFoodTypes.map((e) => e.name).toList(),
        'requiredQuantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'urgency': _selectedUrgency.name,
        'neededBy': _selectedNeededBy.toIso8601String(),
        'servingPopulation': _selectedServingPopulation,
        'expectedBeneficiaries': int.parse(_beneficiariesController.text),
        'requiresRefrigeration': _requiresRefrigeration,
        'dietaryRestrictions': _selectedDietaryRestrictions,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      bool success;
      if (widget.foodRequest != null) {
        success = await ngoProvider.updateFoodRequest(
          widget.foodRequest!.id,
          updates,
          authProvider.firebaseUser!.uid,
        );
      } else {
        // This would be a create operation - redirect to create screen or handle differently
        success = false;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${ngoProvider.errorMessage ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
          setState(() => _isSubmitting = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this food request? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Keep Request'),
                onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Request'),
              onPressed: () {
                Navigator.pop(context);
                _deleteRequest();
              },
            ),
          ],
        );
      },
    );
  }

  Future&lt;void&gt; _deleteRequest() async {
    if (widget.foodRequest == null) return;
    
    setState(() =&gt; _isSubmitting = true);
    
    try {
      final authProvider = Provider.of&lt;AuthProvider&gt;(context, listen: false);
      final ngoProvider = Provider.of&lt;NGOProvider&gt;(context, listen: false);
      
      final success = await ngoProvider.cancelFoodRequest(
        widget.foodRequest!.id,
        authProvider.firebaseUser!.uid,
        'Cancelled by user',
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${ngoProvider.errorMessage ?? 'Failed to cancel request'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() =&gt; _isSubmitting = false);
      }
    }
  }
}