import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class LogisticsManagementDashboard extends StatefulWidget {
  @override
  _LogisticsManagementDashboardState createState() => _LogisticsManagementDashboardState();
}

class _LogisticsManagementDashboardState extends State<LogisticsManagementDashboard> {
  String _selectedTimeRange = '24h';
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Logistics Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildTimeRangeSelector(),
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(icon: Icon(Icons.export), onPressed: _exportData),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPICards(),
            SizedBox(height: 24),
            _buildChartsSection(),
            SizedBox(height: 24),
            _buildOperationalMetrics(),
            SizedBox(height: 24),
            _buildResourceManagement(),
            SizedBox(height: 24),
            _buildPerformanceAnalysis(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        underline: Container(),
        items: ['1h', '24h', '7d', '30d']
            .map((range) => DropdownMenuItem(value: range, child: Text(range)))
            .toList(),
        onChanged: (value) => setState(() => _selectedTimeRange = value!),
      ),
    );
  }
  
  Widget _buildKPICards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key Performance Indicators', 
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKPICard('Total Deliveries', '247', '+12%', Colors.blue, Icons.local_shipping)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Food Rescued', '1.2K kg', '+8%', Colors.green, Icons.eco)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Avg Delivery Time', '32 min', '-5%', Colors.orange, Icons.timer)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Efficiency Rate', '94.2%', '+3%', Colors.purple, Icons.trending_up)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKPICard('Active Volunteers', '28', '+2', Colors.teal, Icons.people)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Route Optimization', '87%', '+11%', Colors.indigo, Icons.route)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Cost per Delivery', '\$4.20', '-8%', Colors.red, Icons.attach_money)),
            SizedBox(width: 12),
            Expanded(child: _buildKPICard('Customer Satisfaction', '4.7/5', '+0.2', Colors.amber, Icons.star)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildKPICard(String title, String value, String change, Color color, IconData icon) {
    final isPositive = !change.startsWith('-');
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
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
          SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analytics Dashboard', 
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildDeliveryTrendsChart()),
            SizedBox(width: 16),
            Expanded(flex: 1, child: _buildVolunteerDistributionChart()),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildRouteEfficiencyChart()),
            SizedBox(width: 16),
            Expanded(child: _buildFoodTypeDistributionChart()),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDeliveryTrendsChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6), FlSpot(3, 5),
                      FlSpot(4, 7), FlSpot(5, 8), FlSpot(6, 6), FlSpot(7, 9),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    dotData: FlDotData(show: false),
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
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volunteer Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 65, color: Colors.green, title: 'Active\n65%'),
                  PieChartSectionData(value: 20, color: Colors.orange, title: 'Busy\n20%'),
                  PieChartSectionData(value: 10, color: Colors.red, title: 'Offline\n10%'),
                  PieChartSectionData(value: 5, color: Colors.grey, title: 'Break\n5%'),
                ],
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route Efficiency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][value.toInt()]),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: Colors.blue, width: 20)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 92, color: Colors.green, width: 20)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 78, color: Colors.orange, width: 20)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 94, color: Colors.purple, width: 20)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 88, color: Colors.teal, width: 20)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodTypeDistributionChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food Type Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: 35, color: Colors.red, title: '35%'),
                        PieChartSectionData(value: 25, color: Colors.blue, title: '25%'),
                        PieChartSectionData(value: 20, color: Colors.green, title: '20%'),
                        PieChartSectionData(value: 20, color: Colors.orange, title: '20%'),
                      ],
                      sectionsSpace: 1,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Prepared Meals', Colors.red),
                    _buildLegendItem('Fresh Produce', Colors.blue),
                    _buildLegendItem('Bakery Items', Colors.green),
                    _buildLegendItem('Packaged Goods', Colors.orange),
                  ],
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
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildOperationalMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Operational Metrics', 
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildMetricRow('Average Pickup Time', '8 minutes', 'Target: 10 min', Colors.green),
              Divider(),
              _buildMetricRow('Average Delivery Time', '24 minutes', 'Target: 30 min', Colors.green),
              Divider(),
              _buildMetricRow('Route Deviation', '12%', 'Target: <15%', Colors.orange),
              Divider(),
              _buildMetricRow('Food Waste Reduction', '89%', 'Target: 85%', Colors.green),
              Divider(),
              _buildMetricRow('Volunteer Utilization', '76%', 'Target: 80%', Colors.orange),
              Divider(),
              _buildMetricRow('Customer Response Time', '3.2 min', 'Target: 5 min', Colors.green),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricRow(String metric, String value, String target, Color statusColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(metric, style: TextStyle(fontWeight: FontWeight.w500))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12),
          Text(target, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildResourceManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resource Management', 
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildResourceCard('Active Vehicles', '18/25', 'Fleet utilization 72%', Colors.blue)),
            SizedBox(width: 12),
            Expanded(child: _buildResourceCard('Available Volunteers', '28/40', 'Capacity utilization 70%', Colors.green)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildResourceCard('Storage Capacity', '85%', '2.1 tons remaining', Colors.orange)),
            SizedBox(width: 12),
            Expanded(child: _buildResourceCard('Operational Budget', '67%', '\$8,400 remaining', Colors.purple)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildResourceCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Analysis', 
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildPerformanceItem('Most Efficient Route', 'Downtown Circuit', '94% efficiency', Icons.route, Colors.green),
              Divider(),
              _buildPerformanceItem('Top Performing Volunteer', 'Maria Garcia', '4.9★ rating', Icons.person, Colors.blue),
              Divider(),
              _buildPerformanceItem('Peak Demand Time', '6:00 PM - 8:00 PM', '40% of daily volume', Icons.schedule, Colors.orange),
              Divider(),
              _buildPerformanceItem('Cost Optimization', 'Route Consolidation', '\$340 saved this week', Icons.savings, Colors.purple),
              Divider(),
              _buildPerformanceItem('Quality Score', 'Delivery Accuracy', '97.2% success rate', Icons.check_circle, Colors.green),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPerformanceItem(String title, String value, String metric, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(metric, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
  
  void _refreshData() {
    setState(() => _isLoading = true);
    // Simulate data refresh
    Future.delayed(Duration(seconds: 2), () => setState(() => _isLoading = false));
  }
  
  void _exportData() {
    // Implement data export functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Text('Export logistics data for the selected time range?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Export')),
        ],
      ),
    );
  }
}