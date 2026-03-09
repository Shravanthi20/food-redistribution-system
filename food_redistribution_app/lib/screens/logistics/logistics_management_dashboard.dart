import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analytics_service.dart';

class LogisticsManagementDashboard extends StatefulWidget {
  const LogisticsManagementDashboard({super.key});

  @override
  LogisticsManagementDashboardState createState() =>
      LogisticsManagementDashboardState();
}

class LogisticsManagementDashboardState
    extends State<LogisticsManagementDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  String _selectedTimeRange = '24h';
  bool _isLoading = true;

  // KPI data
  int _totalDeliveries = 0;
  double _foodRescuedKg = 0;
  double _successRate = 0;
  int _activeVolunteers = 0;
  int _totalVolunteers = 0;

  // Chart data
  List<FlSpot> _deliveryTrends = [];
  Map<String, int> _volunteerStatuses = {};
  Map<String, int> _foodTypeCounts = {};
  List<MapEntry<String, int>> _dailyDeliveries = [];

  // Performance data
  Map<String, dynamic> _systemAnalytics = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadKPIs(),
        _loadChartData(),
        _loadPerformanceData(),
      ]);
    } catch (e) {
      debugPrint('Error loading logistics data: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Duration _getTimeRange() {
    switch (_selectedTimeRange) {
      case '1h':
        return const Duration(hours: 1);
      case '7d':
        return const Duration(days: 7);
      case '30d':
        return const Duration(days: 30);
      default:
        return const Duration(hours: 24);
    }
  }

  Future<void> _loadKPIs() async {
    final cutoff = DateTime.now().subtract(_getTimeRange());
    final cutoffTs = Timestamp.fromDate(cutoff);

    // Total deliveries in range
    final deliveredSnap = await _firestore
        .collection('donations')
        .where('status', isEqualTo: 'delivered')
        .where('updatedAt', isGreaterThan: cutoffTs)
        .get();
    _totalDeliveries = deliveredSnap.docs.length;

    // Food rescued (quantity * 0.5 kg estimate)
    double totalKg = 0;
    for (var doc in deliveredSnap.docs) {
      final qty = (doc.data()['quantity'] as num?)?.toDouble() ?? 0;
      totalKg += qty * 0.5;
    }
    _foodRescuedKg = totalKg;

    // Success rate
    final allInRange = await _firestore
        .collection('donations')
        .where('updatedAt', isGreaterThan: cutoffTs)
        .get();
    final terminated = allInRange.docs.where((d) {
      final s = d.data()['status'] as String?;
      return s == 'delivered' || s == 'cancelled' || s == 'expired';
    }).length;
    _successRate = terminated > 0
        ? (deliveredSnap.docs.length / terminated) * 100
        : 0;

    // Active volunteers
    final volSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();
    _totalVolunteers = volSnap.docs.length;
    _activeVolunteers = volSnap.docs.where((d) {
      final data = d.data();
      return data['isOnline'] == true ||
          (data['updatedAt'] != null &&
              (data['updatedAt'] as Timestamp).toDate().isAfter(cutoff));
    }).length;
  }

  Future<void> _loadChartData() async {
    final range = _getTimeRange();
    final cutoff = DateTime.now().subtract(range);
    final cutoffTs = Timestamp.fromDate(cutoff);

    // Delivery trends (group by day or hour)
    final donationsSnap = await _firestore
        .collection('donations')
        .where('status', isEqualTo: 'delivered')
        .where('updatedAt', isGreaterThan: cutoffTs)
        .get();

    // Group by time buckets
    Map<int, int> buckets = {};
    int numBuckets = _selectedTimeRange == '1h' ? 6 : 7;
    for (int i = 0; i < numBuckets; i++) {
      buckets[i] = 0;
    }
    for (var doc in donationsSnap.docs) {
      final ts = (doc.data()['updatedAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final elapsed = DateTime.now().difference(ts);
      final bucketSize = range.inMinutes / numBuckets;
      int bucket = numBuckets - 1 - (elapsed.inMinutes / bucketSize).floor();
      bucket = bucket.clamp(0, numBuckets - 1);
      buckets[bucket] = (buckets[bucket] ?? 0) + 1;
    }
    _deliveryTrends = buckets.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // Volunteer statuses
    final volSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();
    int online = 0, busy = 0, offline = 0;
    for (var doc in volSnap.docs) {
      final data = doc.data();
      // Check if assigned to active delivery
      final activeDelivery = await _firestore
          .collection('delivery_tasks')
          .where('assignedVolunteerId', isEqualTo: doc.id)
          .where('status', whereIn: ['in_transit', 'picking_up'])
          .limit(1)
          .get();
      if (activeDelivery.docs.isNotEmpty) {
        busy++;
      } else if (data['isOnline'] == true) {
        online++;
      } else {
        offline++;
      }
    }
    _volunteerStatuses = {'Active': online, 'Busy': busy, 'Offline': offline};

    // Food type distribution
    final allDonations = await _firestore
        .collection('donations')
        .where('createdAt', isGreaterThan: cutoffTs)
        .get();
    Map<String, int> typeCounts = {};
    for (var doc in allDonations.docs) {
      final types = doc.data()['foodTypes'];
      if (types is List) {
        for (var t in types) {
          final name = t.toString();
          typeCounts[name] = (typeCounts[name] ?? 0) + 1;
        }
      }
    }
    _foodTypeCounts = typeCounts;

    // Daily deliveries for bar chart
    Map<String, int> daily = {};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var name in dayNames) {
      daily[name] = 0;
    }
    for (var doc in donationsSnap.docs) {
      final ts = (doc.data()['updatedAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final dayName = dayNames[ts.weekday - 1];
      daily[dayName] = (daily[dayName] ?? 0) + 1;
    }
    _dailyDeliveries = daily.entries.toList();
  }

  Future<void> _loadPerformanceData() async {
    _systemAnalytics = await _analytics.getSystemAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Logistics Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildTimeRangeSelector(),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPICards(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildOperationalMetrics(),
                  const SizedBox(height: 24),
                  _buildResourceManagement(),
                  const SizedBox(height: 24),
                  _buildPerformanceAnalysis(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        underline: Container(),
        items: ['1h', '24h', '7d', '30d']
            .map((range) => DropdownMenuItem(value: range, child: Text(range)))
            .toList(),
        onChanged: (value) {
          setState(() => _selectedTimeRange = value!);
          _loadAllData();
        },
      ),
    );
  }

  Widget _buildKPICards() {
    final foodStr = _foodRescuedKg >= 1000
        ? '${(_foodRescuedKg / 1000).toStringAsFixed(1)}K kg'
        : '${_foodRescuedKg.toStringAsFixed(0)} kg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Key Performance Indicators',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildKPICard('Total Deliveries', '$_totalDeliveries',
                    '', Colors.blue, Icons.local_shipping)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildKPICard(
                    'Food Rescued', foodStr, '', Colors.green, Icons.eco)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildKPICard(
                    'Success Rate',
                    '${_successRate.toStringAsFixed(1)}%',
                    '',
                    Colors.purple,
                    Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildKPICard(
                    'Active Volunteers',
                    '$_activeVolunteers',
                    '/$_totalVolunteers',
                    Colors.teal,
                    Icons.people)),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, String change, Color color, IconData icon) {
    final isPositive = !change.startsWith('-');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildDeliveryTrendsChart()),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildVolunteerDistributionChart()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildRouteEfficiencyChart()),
            const SizedBox(width: 16),
            Expanded(child: _buildFoodTypeDistributionChart()),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryTrendsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _deliveryTrends.isEmpty
                ? const Center(child: Text('No delivery data yet'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _deliveryTrends,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerDistributionChart() {
    final total = _volunteerStatuses.values.fold(0, (a, b) => a + b);
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Volunteer Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: total == 0
                ? const Center(child: Text('No volunteers found'))
                : PieChart(
                    PieChartData(
                      sections: _volunteerStatuses.entries.map((e) {
                        final pct = total > 0
                            ? (e.value / total * 100).toStringAsFixed(0)
                            : '0';
                        Color color;
                        switch (e.key) {
                          case 'Active':
                            color = Colors.green;
                            break;
                          case 'Busy':
                            color = Colors.orange;
                            break;
                          default:
                            color = Colors.grey;
                        }
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: color,
                          title: '${e.key}\n$pct%',
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteEfficiencyChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deliveries by Day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _dailyDeliveries.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < _dailyDeliveries.length) {
                                return Text(_dailyDeliveries[idx].key,
                                    style: const TextStyle(fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _dailyDeliveries.asMap().entries.map((e) {
                        final colors = [
                          Colors.blue, Colors.green, Colors.orange,
                          Colors.purple, Colors.teal, Colors.red, Colors.indigo
                        ];
                        return BarChartGroupData(x: e.key, barRods: [
                          BarChartRodData(
                            toY: e.value.value.toDouble(),
                            color: colors[e.key % colors.length],
                            width: 20,
                          )
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTypeDistributionChart() {
    final total = _foodTypeCounts.values.fold(0, (a, b) => a + b);
    final chartColors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final entries = _foodTypeCounts.entries.toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Food Type Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No food type data'))
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: entries.asMap().entries.map((e) {
                              final pct = total > 0
                                  ? (e.value.value / total * 100).toStringAsFixed(0)
                                  : '0';
                              return PieChartSectionData(
                                value: e.value.value.toDouble(),
                                color: chartColors[e.key % chartColors.length],
                                title: '$pct%',
                                titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                              );
                            }).toList(),
                            sectionsSpace: 1,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: entries.asMap().entries.map((e) {
                            return _buildLegendItem(
                              e.value.key,
                              chartColors[e.key % chartColors.length],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOperationalMetrics() {
    final completed = _systemAnalytics['completedDonationsThisMonth'] ?? 0;
    final total = _systemAnalytics['totalDonationsThisMonth'] ?? 0;
    final wasteReduced = _systemAnalytics['wasteReduced'] ?? 0.0;
    final successPct = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operational Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              _buildMetricRow('Donations This Month', '$total',
                  '', Colors.blue),
              const Divider(),
              _buildMetricRow('Completed Deliveries', '$completed',
                  '', Colors.green),
              const Divider(),
              _buildMetricRow(
                  'Completion Rate', '$successPct%', '', 
                  double.tryParse(successPct) != null && double.parse(successPct) >= 80 
                      ? Colors.green : Colors.orange),
              const Divider(),
              _buildMetricRow(
                  'Food Waste Reduced', 
                  '${(wasteReduced as double).toStringAsFixed(1)} kg',
                  '', Colors.green),
              const Divider(),
              _buildMetricRow(
                  'Active Volunteers', '$_activeVolunteers/$_totalVolunteers',
                  '', _activeVolunteers > _totalVolunteers * 0.5 
                      ? Colors.green : Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
      String metric, String value, String target, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(metric,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(target, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResourceManagement() {
    final volUtilPct = _totalVolunteers > 0
        ? (_activeVolunteers / _totalVolunteers * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resource Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildResourceCard(
                    'Available Volunteers',
                    '$_activeVolunteers/$_totalVolunteers',
                    'Capacity utilization $volUtilPct%',
                    Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildResourceCard(
                    'Deliveries (Period)',
                    '$_totalDeliveries',
                    'In selected time range',
                    Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildResourceCard(
                    'Food Rescued',
                    '${_foodRescuedKg.toStringAsFixed(1)} kg',
                    'Estimated weight saved',
                    Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildResourceCard(
                    'Success Rate',
                    '${_successRate.toStringAsFixed(1)}%',
                    'Delivered vs cancelled',
                    Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis() {
    final activeUsers = _systemAnalytics['activeUsers'] ?? 0;
    final monthlyTotal = _systemAnalytics['totalDonationsThisMonth'] ?? 0;
    final monthlyCompleted = _systemAnalytics['completedDonationsThisMonth'] ?? 0;

    // Find top food type
    String topFoodType = 'N/A';
    if (_foodTypeCounts.isNotEmpty) {
      final sorted = _foodTypeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topFoodType = sorted.first.key;
    }

    // Find busiest day 
    String busiestDay = 'N/A';
    if (_dailyDeliveries.isNotEmpty) {
      final sorted = _dailyDeliveries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value > 0) busiestDay = sorted.first.key;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance Analysis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              _buildPerformanceItem('Most Donated Food Type', topFoodType,
                  '${_foodTypeCounts[topFoodType] ?? 0} donations', Icons.restaurant, Colors.green),
              const Divider(),
              _buildPerformanceItem('Active Users (30d)', '$activeUsers users',
                  'Active this month', Icons.people, Colors.blue),
              const Divider(),
              _buildPerformanceItem('Busiest Day', busiestDay,
                  'Most deliveries', Icons.schedule, Colors.orange),
              const Divider(),
              _buildPerformanceItem('Monthly Donations', '$monthlyTotal created',
                  '$monthlyCompleted completed', Icons.volunteer_activism, Colors.purple),
              const Divider(),
              _buildPerformanceItem('Delivery Success', 
                  '${_successRate.toStringAsFixed(1)}%',
                  'Based on completed vs terminated', Icons.check_circle, Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(
      String title, String value, String metric, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(value,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(metric, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _refreshData() {
    _loadAllData();
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Text(
          'Logistics Summary ($_selectedTimeRange):\n\n'
          '• Deliveries: $_totalDeliveries\n'
          '• Food Rescued: ${_foodRescuedKg.toStringAsFixed(1)} kg\n'
          '• Success Rate: ${_successRate.toStringAsFixed(1)}%\n'
          '• Active Volunteers: $_activeVolunteers/$_totalVolunteers\n'
          '\nCopy this summary to share.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
