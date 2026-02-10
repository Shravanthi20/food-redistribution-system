import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ngo_provider.dart';
import '../../models/food_request.dart';
import '../../services/matching_service.dart';

class FoodRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const FoodRequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<FoodRequestDetailScreen> createState() => _FoodRequestDetailScreenState();
}

class _FoodRequestDetailScreenState extends State<FoodRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ngoProvider = Provider.of<NGOProvider>(context, listen: false);
      ngoProvider.findPotentialMatches(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NGOProvider>(
      builder: (context, ngoProvider, child) {
        final request = ngoProvider.getRequestById(widget.requestId);
        
        if (request == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request Not Found')),
            body: const Center(child: Text('Food request not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(request.title),
            actions: [
              if (request.status == RequestStatus.pending)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(value, request, ngoProvider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Request')),
                    const PopupMenuItem(value: 'cancel', child: Text('Cancel Request')),
                    const PopupMenuItem(value: 'find_matches', child: Text('Find Matches')),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and urgency chips
                Row(
                  children: [
                    Chip(
                      label: Text(request.status.name.toUpperCase()),
                      backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
                      labelStyle: TextStyle(color: _getStatusColor(request.status)),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(request.urgency.name.toUpperCase()),
                      backgroundColor: _getUrgencyColor(request.urgency).withOpacity(0.1),
                      labelStyle: TextStyle(color: _getUrgencyColor(request.urgency)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Basic information card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Description', request.description),
                        _buildInfoRow('Quantity', '${request.requiredQuantity} ${request.unit}'),
                        _buildInfoRow('Expected Beneficiaries', request.expectedBeneficiaries.toString()),
                        _buildInfoRow('Needed By', request.neededBy.toString().substring(0, 16)),
                        _buildInfoRow('Created', request.createdAt.toString().substring(0, 16)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Food requirements card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Food Requirements',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        
                        const Text('Required Food Types:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: request.requiredFoodTypes.map((type) => 
                            Chip(label: Text(type.name))).toList(),
                        ),
                        
                        if (request.dietaryRestrictions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Dietary Restrictions:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: request.dietaryRestrictions.map((restriction) => 
                              Chip(
                                label: Text(restriction),
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              )).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              request.requiresRefrigeration 
                                  ? Icons.ac_unit 
                                  : Icons.room_outlined,
                              color: request.requiresRefrigeration 
                                  ? Colors.blue 
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              request.requiresRefrigeration 
                                  ? 'Requires Refrigeration' 
                                  : 'No Refrigeration Required',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Serving population card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serving Population',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: request.servingPopulation.map((population) => 
                            Chip(
                              label: Text(population),
                              backgroundColor: Colors.green.withOpacity(0.1),
                            )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Matched donation (if matched)
                if (request.matchedDonationId != null) 
                  _buildMatchedDonationCard(request, ngoProvider),
                
                // Potential matches (if pending)
                if (request.status == RequestStatus.pending && ngoProvider.potentialMatches.isNotEmpty)
                  _buildPotentialMatchesCard(ngoProvider, request),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _buildMatchedDonationCard(FoodRequest request, NGOProvider ngoProvider) {
    final donation = ngoProvider.getDonationById(request.matchedDonationId!);
    
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Matched Donation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
                ),
              ],
            ),
            
            if (donation != null) ...[
              const SizedBox(height: 12),
              Text('Donation: ${donation.title}'),
              Text('Quantity: ${donation.quantity} ${donation.unit}'),
                Text('Expires: ${donation.expiresAt.toString().substring(0, 16)}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Navigate to donation details or contact donor
                },
                child: const Text('View Donation Details'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text('Donation ID: '),
              Text(request.matchedDonationId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPotentialMatchesCard(NGOProvider ngoProvider, FoodRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Potential Matches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => ngoProvider.findPotentialMatches(widget.requestId),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            ...ngoProvider.potentialMatches.take(5).map((match) => 
              _buildMatchCard(match, request, ngoProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(RequestDonationMatchingResult match, FoodRequest request, NGOProvider ngoProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(match.score).withOpacity(0.1),
          child: Text(
            '${(match.score * 100).round()}%',
            style: TextStyle(
              color: _getScoreColor(match.score),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(match.donation.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.donation.quantity} ${match.donation.unit} • ${match.distance.toStringAsFixed(1)}km away'),
            Text(
              match.reasoning,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _acceptMatch(match, request, ngoProvider),
          child: const Text('Accept'),
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.matched:
        return Colors.blue;
      case RequestStatus.fulfilled:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.expired:
        return Colors.grey;
    }
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
        return Colors.deepPurple;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _handleAction(String action, FoodRequest request, NGOProvider ngoProvider) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
      case 'cancel':
        _cancelRequest(request, ngoProvider);
        break;
      case 'find_matches':
        ngoProvider.findPotentialMatches(widget.requestId);
        break;
    }
  }

  void _cancelRequest(FoodRequest request, NGOProvider ngoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this food request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await ngoProvider.cancelFoodRequest(
                request.id,
                request.ngoId,
                'Cancelled by NGO',
              );
              
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request cancelled successfully')),
                  );
                  Navigator.pop(context);
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ngoProvider.errorMessage ?? 'Failed to cancel request')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _acceptMatch(RequestDonationMatchingResult match, FoodRequest request, NGOProvider ngoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Match'),
        content: Text('Accept this donation match?\n\nDonation: ${match.donation.title}\nCompatibility: ${(match.score * 100).round()}%'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await ngoProvider.acceptDonationMatch(
                request.id,
                match.donationId,
                request.ngoId,
              );
              
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match accepted successfully!')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ngoProvider.errorMessage ?? 'Failed to accept match')),
                  );
                }
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}