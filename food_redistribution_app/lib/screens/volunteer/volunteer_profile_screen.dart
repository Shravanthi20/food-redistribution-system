import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../models/volunteer_profile.dart'; // [NEW]

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _maxRadiusController =
      TextEditingController(text: '25');
  final _locationService = LocationService();

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
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.profile.address ?? '';
    _latitudeController.text =
        user?.profile.location?.latitude.toString() ?? '';
    _longitudeController.text =
        user?.profile.location?.longitude.toString() ?? '';
    _maxRadiusController.text = user?.profile.maxRadius?.toString() ?? '25';

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
          _addressController.text = profile.address;
          _latitudeController.text =
              (profile.location['latitude'] as num?)?.toString() ?? '';
          _longitudeController.text =
              (profile.location['longitude'] as num?)?.toString() ?? '';
          _maxRadiusController.text = profile.maxRadius.toString();
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _maxRadiusController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to fetch current location')),
        );
      }
      return;
    }

    final address = await _locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        ) ??
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    if (!mounted) return;
    setState(() {
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
      _addressController.text = address;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.appUser?.uid;

      if (uid == null) throw Exception("User not found");

      final latitude = double.tryParse(_latitudeController.text.trim());
      final longitude = double.tryParse(_longitudeController.text.trim());
      final maxRadius = int.tryParse(_maxRadiusController.text.trim()) ?? 25;

      Map<String, dynamic>? locationData;
      final enteredAddress = _addressController.text.trim();
      if (latitude != null && longitude != null) {
        locationData = _locationService.buildLocationData(
          latitude: latitude,
          longitude: longitude,
          address: enteredAddress,
        );
      } else if (enteredAddress.isNotEmpty) {
        final geocoded = await _locationService.geocodeAddress(enteredAddress);
        if (geocoded != null) {
          locationData = {
            ...geocoded,
            'address': enteredAddress,
          };
        }
      }

      await _userService.updateUserProfile(
        userId: uid,
        profileData: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'availabilityHours': _selectedAvailability,
          'address': enteredAddress,
          'maxRadius': maxRadius,
          if (locationData != null) 'location': locationData,
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

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Base Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use Current Location"),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxRadiusController,
                decoration: const InputDecoration(
                  labelText: "Max Radius (km)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.route),
                ),
                keyboardType: TextInputType.number,
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
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                          checkmarkColor: Colors.green,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.green[800] : Colors.black87,
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
