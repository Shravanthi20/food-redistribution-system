import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_donation.dart';

class ImpactReportsScreen extends StatefulWidget {
  const ImpactReportsScreen({Key? key}) : super(key: key);

  @override
  State<ImpactReportsScreen> createState() => _ImpactReportsScreenState();
}

class _ImpactReportsScreenState extends State<ImpactReportsScreen> {
  String _selectedPeriod = 'This Month';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
      if (user != null) {
        Provider.of<DonationProvider>(context, listen: false).loadMyDonations(user.uid);
      }
    });
  }

  Map<String, dynamic> _calculateImpactStats(List<FoodDonation> donations) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'All Time':
      default:
        startDate = DateTime(2000);
    }

    final filteredDonations = donations.where((d) => 
      d.createdAt.isAfter(startDate)
    ).toList();

    final delivered = filteredDonations.where((d) => 
      d.status == DonationStatus.delivered
    ).toList();

    int totalMeals = 0;
    int totalPeople = 0;
    double totalWeight = 0;
    int totalDonations = filteredDonations.length;
    int completedDonations = delivered.length;

    for (var donation in delivered) {
      totalMeals += donation.estimatedMeals;
      totalPeople += donation.estimatedPeopleServed;
      totalWeight += donation.quantity;
    }

    // Calculate completion rate
    double completionRate = totalDonations > 0 
      ? (completedDonations / totalDonations) * 100 
      : 0;

    // Calculate CO2 saved (approximate: 1kg food = 2.5kg CO2)
    double co2Saved = totalWeight * 2.5;

    return {
      'totalDonations': totalDonations,
      'completedDonations': completedDonations,
      'totalMeals': totalMeals,
      'totalPeople': totalPeople,
      'totalWeight': totalWeight,
      'completionRate': completionRate,
      'co2Saved': co2Saved,
      'donations': filteredDonations,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Reports'),
        elevation: 0,
      ),
      body: Consumer<DonationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myDonations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = _calculateImpactStats(provider.myDonations);

          return RefreshIndicator(
            onRefresh: () async {
              final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
              if (user != null) {
                await provider.loadMyDonations(user.uid);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),

                // Impact Statistics Cards
                _buildStatCard(
                  context,
                  'Total Donations',
                  stats['totalDonations'].toString(),
                  Icons.volunteer_activism,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                
                _buildStatCard(
                  context,
                  'Completed Deliveries',
                  stats['completedDonations'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  context,
                  'Meals Provided',
                  stats['totalMeals'].toString(),
                  Icons.restaurant,
                  Colors.orange,
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  context,
                  'People Served',
                  stats['totalPeople'].toString(),
                  Icons.people,
                  Colors.purple,
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  context,
                  'Food Donated',
                  '${stats['totalWeight'].toStringAsFixed(1)} kg',
                  Icons.scale,
                  Colors.teal,
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  context,
                  'CO₂ Emissions Saved',
                  '${stats['co2Saved'].toStringAsFixed(1)} kg',
                  Icons.eco,
                  Colors.greenAccent.shade700,
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  context,
                  'Completion Rate',
                  '${stats['completionRate'].toStringAsFixed(1)}%',
                  Icons.show_chart,
                  Colors.indigo,
                ),
                const SizedBox(height: 32),

                // Donation Breakdown by Type
                if (stats['donations'].isNotEmpty) ...[
                  Text(
                    'Donation Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDonationBreakdown(stats['donations']),
                  const SizedBox(height: 32),
                ],

                // Recent Impact Timeline
                if (stats['completedDonations'] > 0) ...[
                  Text(
                    'Recent Impact',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImpactTimeline(stats['donations']),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['This Week', 'This Month', 'Last 3 Months', 'This Year', 'All Time']
                  .map((period) => ChoiceChip(
                        label: Text(period),
                        selected: _selectedPeriod == period,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          }
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationBreakdown(List<FoodDonation> donations) {
    final deliveredDonations = donations.where((d) => 
      d.status == DonationStatus.delivered
    ).toList();

    if (deliveredDonations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No completed donations in this period'),
          ),
        ),
      );
    }

    // Count by food type
    Map<String, int> typeCount = {};
    for (var donation in deliveredDonations) {
      for (var type in donation.foodTypes) {
        typeCount[type.name] = (typeCount[type.name] ?? 0) + 1;
      }
    }

    final sortedTypes = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedTypes.map((entry) {
            final percentage = (entry.value / deliveredDonations.length) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImpactTimeline(List<FoodDonation> donations) {
    final deliveredDonations = donations
        .where((d) => d.status == DonationStatus.delivered)
        .toList()
      ..sort((a, b) => b.deliveredAt?.compareTo(a.deliveredAt ?? DateTime.now()) ?? 0);

    if (deliveredDonations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No completed deliveries in this period'),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: deliveredDonations.length > 10 ? 10 : deliveredDonations.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final donation = deliveredDonations[index];
          final deliveryDate = donation.deliveredAt ?? donation.createdAt;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      '${deliveryDate.day}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getMonthName(deliveryDate.month),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.estimatedMeals} meals',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.estimatedPeopleServed} people',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (donation.claimedByNGO != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            donation.ngoName ?? 'NGO',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
