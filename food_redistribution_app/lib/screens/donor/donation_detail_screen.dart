import 'package:flutter/material.dart';
import '../../models/food_donation.dart';

class DonationDetailScreen extends StatelessWidget {
  final FoodDonation donation;

  const DonationDetailScreen({Key? key, required this.donation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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

            // Tracking Information
            if (donation.status != DonationStatus.listed)
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

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
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

  Widget? _buildBottomBar(BuildContext context) {
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
                  // Cancel functionality
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
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
}
