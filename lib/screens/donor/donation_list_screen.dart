import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_donation.dart';
import 'donation_detail_screen.dart';

class DonationListScreen extends StatefulWidget {
  const DonationListScreen({Key? key}) : super(key: key);

  @override
  State<DonationListScreen> createState() => _DonationListScreenState();
}

class _DonationListScreenState extends State<DonationListScreen> {
  DonationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonations();
    });
  }

  Future<void> _loadDonations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    
    final userId = authProvider.appUser?.uid;
    if (userId != null) {
      await donationProvider.loadMyDonations(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donations'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<DonationStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Donations'),
              ),
              ...DonationStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(_getStatusDisplayName(status)),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      body: Consumer<DonationProvider>(
        builder: (context, donationProvider, child) {
          if (donationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var donations = donationProvider.myDonations;
          
          if (_filterStatus != null) {
            donations = donations.where((d) => d.status == _filterStatus).toList();
          }

          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == null 
                      ? 'No donations yet'
                      : 'No ${_getStatusDisplayName(_filterStatus!).toLowerCase()} donations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first donation to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDonations,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index];
                return _buildDonationCard(donation);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(FoodDonation donation) {
    final statusColor = _getStatusColor(donation.status);
    final isActive = donation.status == DonationStatus.listed || 
                     donation.status == DonationStatus.matched;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationDetailScreen(donation: donation),
            ),
          ).then((updated) {
            if (updated == true) {
              _loadDonations();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusDisplayName(donation.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                donation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${donation.quantity} ${donation.unit}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${_formatDateTime(donation.expiresAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (donation.isUrgent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editDonation(donation),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelDonation(donation),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editDonation(FoodDonation donation) {
    // Navigate to edit screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
    );
  }

  Future<void> _cancelDonation(FoodDonation donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Donation'),
        content: const Text('Are you sure you want to cancel this donation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      
      final userId = authProvider.appUser?.uid;
      if (userId != null) {
        final success = await donationProvider.cancelDonation(
          donation.id,
          userId,
          'Cancelled by donor',
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted && donationProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(donationProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
