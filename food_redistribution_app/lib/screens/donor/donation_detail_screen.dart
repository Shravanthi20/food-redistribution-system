import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // [NEW] for Timestamp
import '../../models/food_donation.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/donation_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // [NEW]
import '../../widgets/live_tracking_map.dart'; // [NEW]
import '../../utils/app_router.dart'; // [NEW]
import '../../utils/app_theme.dart';
import '../admin/user_selection_screen.dart';
import '../../services/location_service.dart'; // Import LocationService

class DonationDetailScreen extends StatelessWidget {
  final FoodDonation initialDonation; // Renamed from donation to initialDonation

  const DonationDetailScreen({Key? key, required this.initialDonation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<FoodDonation?>(
        stream: donationProvider.getDonationStream(initialDonation.id),
        initialData: initialDonation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
             return const Center(child: Text('Donation not found')); // Handle deletion
          }

          final donation = snapshot.data!;

          return Column(
            children: [
              // Offline Banner
              StreamBuilder<bool>(
                stream: donationProvider.connectionStatus,
                initialData: true,
                builder: (context, connSnapshot) {
                  if (connSnapshot.hasData && connSnapshot.data == false) {
                     return Container(
                       color: Colors.red,
                       padding: const EdgeInsets.all(8),
                       width: double.infinity,
                       child: const Text(
                         'You are offline. Changes will sync when you reconnect.',
                         style: TextStyle(color: Colors.white),
                         textAlign: TextAlign.center,
                       ),
                     );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: _getStatusColor(donation.status).withOpacity(0.1),
                        child: Column(
                          children: [
                            Icon(
                              _getStatusIcon(donation.status),
                              size: 60,
                              color: _getStatusColor(donation.status),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getStatusDisplayName(donation.status),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _getStatusColor(donation.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (donation.isUrgent) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'URGENT DONATION',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Basic Information
                      _buildSection(
                        context,
                        'Basic Information',
                        [
                          _buildInfoRow(Icons.title, 'Title', donation.title),
                          _buildInfoRow(Icons.description, 'Description', donation.description),
                          _buildInfoRow(Icons.restaurant, 'Quantity', '${donation.quantity} ${donation.unit}'),
                        ],
                      ),

                      const Divider(height: 1),

                      // Food Details
                      _buildSection(
                        context,
                        'Food Details',
                        [
                          _buildChipRow('Food Types', donation.foodTypes.map((t) => _getFoodTypeDisplayName(t)).toList()),
                          if (donation.isVegetarian || donation.isVegan || donation.isHalal)
                            _buildChipRow('Dietary', [
                              if (donation.isVegan) 'Vegan',
                              if (donation.isVegetarian && !donation.isVegan) 'Vegetarian',
                              if (donation.isHalal) 'Halal',
                            ]),
                          if (donation.allergenInfo != null && donation.allergenInfo!.isNotEmpty)
                            _buildInfoRow(Icons.warning_amber, 'Allergen Info', donation.allergenInfo!),
                        ],
                      ),

                      const Divider(height: 1),

                      // Safety & Storage
                      _buildSection(
                        context,
                        'Safety & Storage',
                        [
                          _buildInfoRow(Icons.shield, 'Safety Level', _getSafetyLevelDisplayName(donation.safetyLevel)),
                          _buildInfoRow(Icons.ac_unit, 'Refrigeration', donation.requiresRefrigeration ? 'Required' : 'Not Required'),
                        ],
                      ),

                      const Divider(height: 1),

                      // Time Information
                      _buildSection(
                        context,
                        'Time Information',
                        [
                          _buildInfoRow(Icons.schedule, 'Prepared At', _formatDateTime(donation.preparedAt)),
                          _buildInfoRow(Icons.alarm, 'Expires At', _formatDateTime(donation.expiresAt)),
                          _buildInfoRow(Icons.access_time, 'Available From', _formatDateTime(donation.availableFrom)),
                          _buildInfoRow(Icons.access_time_filled, 'Available Until', _formatDateTime(donation.availableUntil)),
                        ],
                      ),

                      const Divider(height: 1),

                      // Pickup Information
                      _buildSection(
                        context,
                        'Pickup Information',
                        [
                          _buildInfoRow(Icons.location_on, 'Address', donation.pickupAddress),
                          _buildInfoRow(Icons.phone, 'Contact Phone', donation.donorContactPhone),
                          if (donation.specialInstructions != null && donation.specialInstructions!.isNotEmpty)
                            _buildInfoRow(Icons.info_outline, 'Special Instructions', donation.specialInstructions!),
                        ],
                      ),

                      const Divider(height: 1),

                      // Tracking & Live Location
                      if (donation.status != DonationStatus.listed) ...[
                         _buildSection(
                          context,
                          'Tracking',
                          [
                            if (donation.assignedNGOId != null)
                              _buildInfoRow(Icons.business, 'Assigned NGO', donation.assignedNGOId!),
                            if (donation.assignedVolunteerId != null)
                              _buildInfoRow(Icons.person, 'Assigned Volunteer', donation.assignedVolunteerId!),
                            _buildInfoRow(Icons.calendar_today, 'Created At', _formatDateTime(donation.createdAt)),
                            if (donation.updatedAt != null)
                              _buildInfoRow(Icons.update, 'Updated At', _formatDateTime(donation.updatedAt!)),
                          ],
                        ),
                        // Live Tracking Section
                        if (donation.status == DonationStatus.inTransit && donation.assignedVolunteerId != null)
                          _buildLiveTracking(context, donation),
                      ],


                      const SizedBox(height: 24),
                      
                      // Admin Controls
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.appUser?.role != UserRole.admin) return const SizedBox.shrink();
                          
                          return _buildSection(
                            context,
                            'Admin Controls',
                            [
                              if (donation.status == DonationStatus.listed)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.bolt, color: Colors.orange),
                                  label: const Text('Force Match NGO'),
                                  onPressed: () => _forceMatchNGO(context, donation),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                  ),
                                ),
                              
                              if (donation.status == DonationStatus.matched || donation.status == DonationStatus.pickedUp)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.person_search, color: Colors.purple),
                                  label: const Text('Reassign Volunteer'),
                                  onPressed: () => _reassignVolunteer(context, donation),
                                   style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(color: Colors.purple),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context, initialDonation), // Note: using initialData context for brevity, but ideally this would update with stream data too if status changes interactively affect available actions. Assuming Read-Only for now due to complexity.
    );
  }

  Widget _buildLiveTracking(BuildContext context, FoodDonation donation) {
    // NOTE: In a real app, you would inject the LocationService properly.
    final LocationService _locationService = LocationService(); 
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoCyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( // Header
             children: [
               Icon(Icons.location_searching, color: AppTheme.infoCyan),
               const SizedBox(width: 8),
               Text(
                 'Live Volunteer Location', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.infoCyan)
               ),
               const Spacer(),
               // Blink indicator could go here
             ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<Map<String, dynamic>>(
            stream: _locationService.getUserLocationStream(donation.assignedVolunteerId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Locating volunteer...');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return const Text('Volunteer location unavailable');
              }
              
              final data = snapshot.data!;
              // Calculate last seen
              // final timestamp = data['timestamp'];

                  return Column(
                    children: [
                       LiveTrackingMap(
                         pickupLocation: _parseGeoPoint(donation.pickupLocation) ?? const LatLng(0, 0),
                         dropoffLocation: const LatLng(37.7749, -122.4194), // Placeholder for NGO location until fetched
                         volunteerLocation: LatLng(
                            (data['latitude'] as num).toDouble(),
                            (data['longitude'] as num).toDouble(),
                         ),
                         status: donation.status,
                       ),
                       const SizedBox(height: 8),
                       Text('Last update: ${_formatTime(data['timestamp'])}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: Colors.green[50],
                labelStyle: const TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context, FoodDonation donation) { // Using pure donation for bottom bar static check for now
    if (donation.status != DonationStatus.listed && 
        donation.status != DonationStatus.matched) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Edit functionality
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                   Navigator.pushNamed(
                     context, 
                     AppRouter.issueReporting,
                     arguments: {'donationId': donation.id},
                   );
                },
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return Colors.blue;
      case DonationStatus.matched:
        return Colors.orange;
      case DonationStatus.pickedUp:
        return Colors.purple;
      case DonationStatus.inTransit:
        return Colors.indigo;
      case DonationStatus.delivered:
        return Colors.green;
      case DonationStatus.cancelled:
        return Colors.red;
      case DonationStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return Icons.list_alt;
      case DonationStatus.matched:
        return Icons.connect_without_contact;
      case DonationStatus.pickedUp:
        return Icons.done;
      case DonationStatus.inTransit:
        return Icons.local_shipping;
      case DonationStatus.delivered:
        return Icons.check_circle;
      case DonationStatus.cancelled:
        return Icons.cancel;
      case DonationStatus.expired:
        return Icons.event_busy;
    }
  }

  String _getStatusDisplayName(DonationStatus status) {
    switch (status) {
      case DonationStatus.listed:
        return 'Listed';
      case DonationStatus.matched:
        return 'Matched';
      case DonationStatus.pickedUp:
        return 'Picked Up';
      case DonationStatus.inTransit:
        return 'In Transit';
      case DonationStatus.delivered:
        return 'Delivered';
      case DonationStatus.cancelled:
        return 'Cancelled';
      case DonationStatus.expired:
        return 'Expired';
    }
  }

  String _getFoodTypeDisplayName(FoodType type) {
    return type.name.toUpperCase()[0] + type.name.substring(1);
  }

  String _getSafetyLevelDisplayName(FoodSafetyLevel level) {
    switch (level) {
      case FoodSafetyLevel.high:
        return 'High';
      case FoodSafetyLevel.medium:
        return 'Medium';
      case FoodSafetyLevel.low:
        return 'Low';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _forceMatchNGO(BuildContext context, FoodDonation donation) async {
    final ngoId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionScreen(
          role: UserRole.ngo, 
          title: 'Select NGO (Sorted by Distance)',
          origin: _parseGeoPoint(donation.pickupLocation),
        ),
      ),
    );

    if (ngoId != null && context.mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final donationProvider = Provider.of<DonationProvider>(context, listen: false);
        
        await donationProvider.foodDonationService.forceAssignNGO(
          donationId: donation.id, 
          adminId: authProvider.user!.uid, 
          ngoId: ngoId,
          reason: 'Manual Admin Override',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NGO assigned successfully')),
          );
          Navigator.pop(context); // Refresh/Close
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _reassignVolunteer(BuildContext context, FoodDonation donation) async {
    final volId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionScreen(
          role: UserRole.volunteer, 
          title: 'Select Volunteer (Sorted by Distance)',
          origin: _parseGeoPoint(donation.pickupLocation),
        ),
      ),
    );

    if (volId != null && context.mounted) {
       try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final donationProvider = Provider.of<DonationProvider>(context, listen: false);
        
        await donationProvider.foodDonationService.forceAssignVolunteer(
          donationId: donation.id, 
          adminId: authProvider.user!.uid, 
          volunteerId: volId,
          reason: 'Manual Admin Override',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Volunteer reassigned successfully')),
          );
          Navigator.pop(context); // Refresh/Close
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  LatLng? _parseGeoPoint(Map<String, dynamic>? location) {
    if (location == null) return null;
    final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final dt = timestamp.toDate();
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
