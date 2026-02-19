import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/tracking/analytics_aggregation_service.dart';

/// Admin Analytics & Predictions Screen
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AnalyticsAggregationService _analyticsService = AnalyticsAggregationService();
  
  String _selectedRegion = 'all';
  int _selectedMetricDays = 7;
  List<String> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('delivery_tasks')
          .get();

      final regions = <String>{'all'};
      for (var doc in snapshot.docs) {
        final region = doc.data()['region'] as String?;
        if (region != null) {
          regions.add(region);
        }
      }

      setState(() {
        _regions = regions.toList();
      });
    } catch (e) {
      debugPrint('Error loading regions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Predictions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    items: _regions.map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRegion = value ?? 'all');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMetricDays,
                    isExpanded: true,
                    items: [7, 14, 30, 60].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('Last $days days'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMetricDays = value ?? 7);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Metrics
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Duration Analytics
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsService.getPickupDurationHistory(days: _selectedMetricDays),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⏱️ Duration Metrics',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricColumn(
                              'Avg Pickup',
                              '${data['averagePickupTime']} min',
                            ),
                            _buildMetricColumn(
                              'Avg Delivery',
                              '${data['averageDeliveryTime']} min',
                            ),
                            _buildMetricColumn(
                              'Total Deliveries',
                              data['totalDeliveries'].toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Regional Stats
            FutureBuilder<Map<String, dynamic>>(
              future: _selectedRegion == 'all'
                  ? Future.value({})
                  : _analyticsService.getRegionalStats(region: _selectedRegion),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 ${_selectedRegion.toUpperCase()} Performance',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          'Total Deliveries',
                          data['totalDeliveries'].toString(),
                        ),
                        _buildMetricRow(
                          'Performance Index',
                          '${data['performanceIndex']}%',
                          color: double.parse(data['performanceIndex'] as String) > 80
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Predictions Section
            const Text(
              'Predictions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Volunteer Demand Prediction
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsService.predictVolunteerDemandAdvanced(daysAhead: _selectedMetricDays),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!;
                final shortfall = (data['shortfall'] as int?) ?? 0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👥 Volunteer Demand Forecast',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          'Predicted Daily Demand',
                          data['predictedDailyDemand'].toString(),
                        ),
                        _buildMetricRow(
                          'Required Volunteers',
                          data['requiredVolunteers'].toString(),
                        ),
                        _buildMetricRow(
                          'Current Available',
                          data['currentVolunteerCount'].toString(),
                        ),
                        if (shortfall > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⚠️ SHORTFALL: $shortfall volunteers needed - Action: ${data['recommendAction']?.toString().replaceAll('_', ' ')}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Surplus Risk Prediction
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsService.predictSurplusRisk(daysAhead: _selectedMetricDays),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!;
                final trend = data['trend'] as String? ?? 'neutral';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🍱 Donation Surplus Forecast',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          'Predicted Daily Donations',
                          data['predictedDailyDonations'].toString(),
                        ),
                        _buildMetricRow(
                          'Total (${_selectedMetricDays} days)',
                          data['predictedTotalDonations'].toString(),
                        ),
                        _buildMetricRow(
                          'Trend',
                          trend.toUpperCase(),
                          color: trend == 'increasing'
                              ? Colors.orange
                              : trend == 'decreasing'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                        _buildMetricRow(
                          'Risk Level',
                          data['riskLevel'].toString().toUpperCase(),
                          color: data['riskLevel'] == 'high'
                              ? Colors.red
                              : data['riskLevel'] == 'medium'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Supply-Demand Gap Analysis
            if (_selectedRegion != 'all')
              FutureBuilder<Map<String, dynamic>>(
                future: _analyticsService.getRegionalSupplyDemandGap(_selectedRegion),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final data = snapshot.data!;
                  final status = data['status'] as String? ?? 'balanced';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '📊 Supply-Demand Gap',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor: status == 'critical'
                                    ? Colors.red.withOpacity(0.2)
                                    : status == 'warning'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMetricRow(
                            'Total Supply (kg)',
                            data['totalSupplyWeight'].toString(),
                          ),
                          _buildMetricRow(
                            'NGO Capacity (kg)',
                            data['totalNGOCapacity'].toString(),
                          ),
                          _buildMetricRow(
                            'Gap (%)',
                            data['gapPercentage'].toString(),
                            color: double.parse(data['gapPercentage'] as String) > 20
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
