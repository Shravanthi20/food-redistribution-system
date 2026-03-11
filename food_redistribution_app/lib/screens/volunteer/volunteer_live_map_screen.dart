import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/food_donation.dart';
import '../../services/food_donation_service.dart';
import '../../services/location_service.dart';
import '../../widgets/live_tracking_map.dart';

class VolunteerLiveMapScreen extends StatelessWidget {
  final String donationId;

  const VolunteerLiveMapScreen({super.key, required this.donationId});

  @override
  Widget build(BuildContext context) {
    final donationService = FoodDonationService();
    final locationService = LocationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
      ),
      body: StreamBuilder<FoodDonation?>(
        stream: donationService.getDonationStream(donationId),
        builder: (context, donationSnapshot) {
          if (donationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final donation = donationSnapshot.data;
          if (donation == null) {
            return const Center(child: Text('Task not found'));
          }

          final pickupLocation = _parseLatLng(donation.pickupLocation);
          if (pickupLocation == null) {
            return const Center(child: Text('Pickup location unavailable'));
          }

          return FutureBuilder<LatLng?>(
            future: _fetchNgoLocation(donation),
            builder: (context, ngoSnapshot) {
              if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dropoffLocation = ngoSnapshot.data;
              if (dropoffLocation == null) {
                return const Center(child: Text('Drop location unavailable'));
              }

              final volunteerId = donation.assignedVolunteerId;
              if (volunteerId == null || volunteerId.isEmpty) {
                return _buildMapShell(
                  context,
                  donation: donation,
                  pickupLocation: pickupLocation,
                  dropoffLocation: dropoffLocation,
                  volunteerLocation: null,
                  lastUpdated: null,
                );
              }

              return StreamBuilder<Map<String, dynamic>>(
                stream: locationService.getUserLocationStream(volunteerId),
                builder: (context, locationSnapshot) {
                  final locationData =
                      locationSnapshot.data ?? <String, dynamic>{};
                  final volunteerLocation = _parseLatLng(locationData);
                  return _buildMapShell(
                    context,
                    donation: donation,
                    pickupLocation: pickupLocation,
                    dropoffLocation: dropoffLocation,
                    volunteerLocation: volunteerLocation,
                    lastUpdated: locationData['timestamp'],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMapShell(
    BuildContext context, {
    required FoodDonation donation,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required LatLng? volunteerLocation,
    required dynamic lastUpdated,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          donation.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track pickup, route, and delivery progress on the map.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 16),
        LiveTrackingMap(
          pickupLocation: pickupLocation,
          dropoffLocation: dropoffLocation,
          volunteerLocation: volunteerLocation,
          status: donation.status,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup: ${donation.pickupAddress}'),
                const SizedBox(height: 8),
                Text('Status: ${donation.status.name}'),
                const SizedBox(height: 8),
                Text(
                  volunteerLocation == null
                      ? 'Volunteer live location unavailable'
                      : 'Last location update: ${_formatTime(lastUpdated)}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<LatLng?> _fetchNgoLocation(FoodDonation donation) async {
    final orgId = donation.claimedByNGO;
    if (orgId != null && orgId.isNotEmpty) {
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .get();
      final orgLocation = _parseLatLng(orgDoc.data()?['location']);
      if (orgLocation != null) return orgLocation;
    }

    final userId = donation.assignedNGOId;
    if (userId != null && userId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final profile = (userDoc.data()?['profile'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final profileLocation = _parseLatLng(profile['location']);
      if (profileLocation != null) return profileLocation;
      final directLocation = _parseLatLng(userDoc.data()?['location']);
      if (directLocation != null) return directLocation;
    }

    return null;
  }

  LatLng? _parseLatLng(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final lat = map['latitude'] as num?;
    final lng = map['longitude'] as num?;
    if (lat == null || lng == null) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (timestamp is DateTime) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }
}
