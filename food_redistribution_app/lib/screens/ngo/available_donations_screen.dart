import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_donation.dart';

class AvailableDonationsScreen extends StatefulWidget {
  const AvailableDonationsScreen({Key? key}) : super(key: key);

  @override
  State<AvailableDonationsScreen> createState() => _AvailableDonationsScreenState();
}

class _AvailableDonationsScreenState extends State<AvailableDonationsScreen> {
  String _searchQuery = '';
  FoodType? _selectedFoodType;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<NGOProvider>(
      builder: (context, ngoProvider, child) {
        final filteredDonations = _filterDonations(ngoProvider.availableDonations);
        
        return Column(
          children: [
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search donations...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Food type filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedFoodType == null,
                          onSelected: (selected) {
                            setState(() => _selectedFoodType = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...FoodType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(type.name),
                            selected: _selectedFoodType == type,
                            onSelected: (selected) {
                              setState(() => _selectedFoodType = selected ? type : null);
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Donations list
            Expanded(
              child: filteredDonations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No available donations found'),
                          SizedBox(height: 8),
                          Text('Try adjusting your filters'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ngoProvider.refreshData(
                        Provider.of<AuthProvider>(context, listen: false).firebaseUser!.uid
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredDonations.length,
                        itemBuilder: (context, index) {
                          return _buildDonationCard(filteredDonations[index], ngoProvider);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<FoodDonation> _filterDonations(List<FoodDonation> donations) {
    return donations.where((donation) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!donation.title.toLowerCase().contains(query) &&
            !donation.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Filter by food type
      if (_selectedFoodType != null) {
        if (!donation.foodTypes.contains(_selectedFoodType!)) {
          return false;
        }
      }
      
      // Only show available donations
      return donation.status == DonationStatus.listed;
    }).toList();
  }

  Widget _buildDonationCard(FoodDonation donation, NGOProvider ngoProvider) {
    final timeUntilExpiry = donation.expiresAt.difference(DateTime.now());
    final isUrgent = timeUntilExpiry.inHours <= 12;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and urgency indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              donation.description,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Quantity and expiry
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${donation.quantity} ${donation.unit}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: isUrgent ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeUntilExpiry(timeUntilExpiry),
                        style: TextStyle(
                          color: isUrgent ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Food types
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: donation.foodTypes.map((type) => Chip(
                label: Text(type.name),
                backgroundColor: Colors.grey.withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 12),
              )).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Dietary info
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (donation.isVegetarian) 
                  const Chip(
                    label: Text('Vegetarian'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                if (donation.isVegan)
                  const Chip(
                    label: Text('Vegan'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                if (donation.isHalal)
                  const Chip(
                    label: Text('Halal'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.white),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDonationDetails(donation),
                    icon: const Icon(Icons.info),
                    label: const Text('View Details'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestDonation(donation, ngoProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeUntilExpiry(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Expired';
    }
  }

  void _viewDonationDetails(FoodDonation donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  donation.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(donation.description),
                
                const SizedBox(height: 16),
                
                _buildDetailRow('Quantity', '${donation.quantity} ${donation.unit}'),
                _buildDetailRow('Created', donation.createdAt.toString().substring(0, 16)),
                _buildDetailRow('Expires', donation.expiresAt.toString().substring(0, 16)),
                _buildDetailRow('Pickup Address', donation.pickupAddress),
                _buildDetailRow('Contact', donation.donorContactPhone),
                
                const SizedBox(height: 16),
                
                Text(
                  'Food Safety',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Safety Level', donation.safetyLevel.toString()),
                _buildDetailRow('Requires Refrigeration', donation.requiresRefrigeration ? 'Yes' : 'No'),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _requestDonation(donation, Provider.of<NGOProvider>(context, listen: false));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Request This Donation'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _requestDonation(FoodDonation donation, NGOProvider ngoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Donation'),
        content: Text(
          'This will create a food request that matches this donation. '
          'Would you like to proceed?\n\n'
          'Donation: ${donation.title}\n'
          'Quantity: ${donation.quantity} ${donation.unit}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createMatchingRequest(donation, ngoProvider);
            },
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }

  void _createMatchingRequest(FoodDonation donation, NGOProvider ngoProvider) {
    // Navigate to create request screen with pre-filled data based on the donation
    Navigator.pushNamed(
      context,
      '/ngo/create-request',
      arguments: {
        'prefillFromDonation': donation,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}