import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../models/volunteer_profile.dart'; // [NEW]

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;
  bool _isLoadingProfile = true; // [NEW]

  // Availability Options
  final List<String> _timeSlots = [
    "Morning (6AM-12PM)",
    "Afternoon (12PM-5PM)",
    "Evening (5PM-10PM)",
    "Weekends"
  ];
  List<String> _selectedAvailability = [];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).appUser;
    
    // Initialize with AppUser data first (fast)
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    
    // Fetch full volunteer profile for availability
    if (user != null) {
      _loadVolunteerProfile(user.uid);
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadVolunteerProfile(String uid) async {
    try {
      final profile = await _userService.getUserProfile(uid);
      if (profile is VolunteerProfile && mounted) {
        setState(() {
          _selectedAvailability = List.from(profile.availabilityHours);
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.appUser?.uid;

      if (uid == null) throw Exception("User not found");

      await _userService.updateUserProfile(
        userId: uid,
        profileData: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'availabilityHours': _selectedAvailability,
        },
      );

      // Force refresh of user data
      // (This works if AuthProvider listens to user changes or we trigger a reload)
      // For now, simpler to show success. AuthProvider real-time listener should catch it.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 24),
              
              // [NEW] Availability Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Active Timings",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingProfile 
                  ? const CircularProgressIndicator()
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _timeSlots.map((slot) {
                        final isSelected = _selectedAvailability.contains(slot);
                        return FilterChip(
                          label: Text(slot),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedAvailability.add(slot);
                              } else {
                                _selectedAvailability.remove(slot);
                              }
                            });
                          },
                          selectedColor: Colors.green.withOpacity(0.2),
                          checkmarkColor: Colors.green,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green[800] : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
