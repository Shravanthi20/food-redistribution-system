import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/firestore_service.dart';
import '../services/audit_service.dart';

enum MetricType {
  counter,
  gauge,
  histogram,
  timer,
  percentage,
}

enum MetricCategory {
  foodWaste,
  deliveryPerformance,
  volunteerEngagement,
  userActivity,
  systemHealth,
  socialImpact,
  resourceUtilization,
  costEffectiveness,
}

enum AggregationPeriod {
  hour,
  day,
  week,
  month,
  quarter,
  year,
}

class Metric {
  final String id;
  final String name;
  final MetricType type;
  final MetricCategory category;
  final String description;
  final String unit;
  final Map<String, String> tags;
  final bool isActive;
  final DateTime createdAt;
  
  Metric({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.description,
    this.unit = '',
    this.tags = const {},
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'category': category.toString(),
      'description': description,
      'unit': unit,
      'tags': tags,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

class MetricDataPoint {
  final String metricId;
  final double value;
  final DateTime timestamp;
  final Map<String, String> dimensions;
  final Map<String, dynamic> metadata;
  
  MetricDataPoint({
    required this.metricId,
    required this.value,
    required this.timestamp,
    this.dimensions = const {},
    this.metadata = const {},
  });
  
  Map<String, dynamic> toMap() {
    return {
      'metricId': metricId,
      'value': value,
      'timestamp': timestamp,
      'dimensions': dimensions,
      'metadata': metadata,
    };
  }
}

class KPITarget {
  final String metricId;
  final double targetValue;
  final String operator; // '>', '<', '>=', '<=', '=='
  final AggregationPeriod period;
  final bool isActive;
  
  KPITarget({
    required this.metricId,
    required this.targetValue,
    required this.operator,
    required this.period,
    this.isActive = true,
  });
}

class Dashboard {
  final String id;
  final String name;
  final String description;
  final List<String> metricIds;
  final List<String> userRoles;
  final Map<String, dynamic> layout;
  final bool isPublic;
  final DateTime createdAt;
  
  Dashboard({
    required this.id,
    required this.name,
    required this.description,
    required this.metricIds,
    this.userRoles = const [],
    this.layout = const {},
    this.isPublic = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class AnalyticsReport {
  final String id;
  final String name;
  final String description;
  final List<String> metricIds;
  final Map<String, dynamic> filters;
  final AggregationPeriod period;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  
  AnalyticsReport({
    required this.id,
    required this.name,
    required this.description,
    required this.metricIds,
    this.filters = const {},
    required this.period,
    required this.generatedAt,
    required this.data,
  });
}

class AnalyticsMetricsService {
  final FirestoreService _firestoreService;
  final AuditService _auditService;
  
  final Map<String, Metric> _metrics = {};
  final Map<String, KPITarget> _kpiTargets = {};
  final List<MetricDataPoint> _buffer = [];
  
  static const int _bufferSize = 100;
  static const Duration _flushInterval = Duration(minutes: 5);
  
  AnalyticsMetricsService({
    required FirestoreService firestoreService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _auditService = auditService {
    _initializeMetrics();
    _initializeKPITargets();
    _startPeriodicFlush();
  }
  
  /// Initialize core metrics
  void _initializeMetrics() {
    final coreMetrics = [
      // Food Waste Metrics
      Metric(
        id: 'food_rescued_kg',
        name: 'Food Rescued',
        type: MetricType.counter,
        category: MetricCategory.foodWaste,
        description: 'Total kilograms of food rescued from waste',
        unit: 'kg',
      ),
      
      Metric(
        id: 'food_redistribution_rate',
        name: 'Food Redistribution Rate',
        type: MetricType.percentage,
        category: MetricCategory.foodWaste,
        description: 'Percentage of available food successfully redistributed',
        unit: '%',
      ),
      
      Metric(
        id: 'food_waste_prevented',
        name: 'Food Waste Prevented',
        type: MetricType.counter,
        category: MetricCategory.foodWaste,
        description: 'Total food waste prevented through redistribution',
        unit: 'kg',
      ),
      
      // Delivery Performance Metrics
      Metric(
        id: 'delivery_success_rate',
        name: 'Delivery Success Rate',
        type: MetricType.percentage,
        category: MetricCategory.deliveryPerformance,
        description: 'Percentage of successful deliveries',
        unit: '%',
      ),
      
      Metric(
        id: 'average_delivery_time',
        name: 'Average Delivery Time',
        type: MetricType.timer,
        category: MetricCategory.deliveryPerformance,
        description: 'Average time from pickup to delivery',
        unit: 'minutes',
      ),
      
      Metric(
        id: 'route_optimization_savings',
        name: 'Route Optimization Savings',
        type: MetricType.gauge,
        category: MetricCategory.deliveryPerformance,
        description: 'Distance and time saved through route optimization',
        unit: 'km',
      ),
      
      Metric(
        id: 'delivery_delays',
        name: 'Delivery Delays',
        type: MetricType.counter,
        category: MetricCategory.deliveryPerformance,
        description: 'Number of delayed deliveries',
        unit: 'count',
      ),
      
      // Volunteer Engagement Metrics
      Metric(
        id: 'active_volunteers',
        name: 'Active Volunteers',
        type: MetricType.gauge,
        category: MetricCategory.volunteerEngagement,
        description: 'Number of currently active volunteers',
        unit: 'count',
      ),
      
      Metric(
        id: 'volunteer_retention_rate',
        name: 'Volunteer Retention Rate',
        type: MetricType.percentage,
        category: MetricCategory.volunteerEngagement,
        description: 'Percentage of volunteers retained over time',
        unit: '%',
      ),
      
      Metric(
        id: 'volunteer_tasks_completed',
        name: 'Volunteer Tasks Completed',
        type: MetricType.counter,
        category: MetricCategory.volunteerEngagement,
        description: 'Total number of tasks completed by volunteers',
        unit: 'count',
      ),
      
      Metric(
        id: 'volunteer_satisfaction_score',
        name: 'Volunteer Satisfaction',
        type: MetricType.gauge,
        category: MetricCategory.volunteerEngagement,
        description: 'Average volunteer satisfaction score',
        unit: 'score',
      ),
      
      // User Activity Metrics
      Metric(
        id: 'daily_active_users',
        name: 'Daily Active Users',
        type: MetricType.gauge,
        category: MetricCategory.userActivity,
        description: 'Number of users active in the last 24 hours',
        unit: 'count',
      ),
      
      Metric(
        id: 'user_registration_rate',
        name: 'User Registration Rate',
        type: MetricType.counter,
        category: MetricCategory.userActivity,
        description: 'Rate of new user registrations',
        unit: 'per day',
      ),
      
      Metric(
        id: 'donation_posting_frequency',
        name: 'Donation Posting Frequency',
        type: MetricType.counter,
        category: MetricCategory.userActivity,
        description: 'Frequency of new donation postings',
        unit: 'per hour',
      ),
      
      // System Health Metrics
      Metric(
        id: 'system_uptime',
        name: 'System Uptime',
        type: MetricType.percentage,
        category: MetricCategory.systemHealth,
        description: 'System availability percentage',
        unit: '%',
      ),
      
      Metric(
        id: 'api_response_time',
        name: 'API Response Time',
        type: MetricType.timer,
        category: MetricCategory.systemHealth,
        description: 'Average API response time',
        unit: 'ms',
      ),
      
      Metric(
        id: 'error_rate',
        name: 'System Error Rate',
        type: MetricType.percentage,
        category: MetricCategory.systemHealth,
        description: 'Percentage of system errors',
        unit: '%',
      ),
      
      // Social Impact Metrics
      Metric(
        id: 'beneficiaries_served',
        name: 'Beneficiaries Served',
        type: MetricType.counter,
        category: MetricCategory.socialImpact,
        description: 'Total number of people who received food',
        unit: 'people',
      ),
      
      Metric(
        id: 'community_partnerships',
        name: 'Community Partnerships',
        type: MetricType.gauge,
        category: MetricCategory.socialImpact,
        description: 'Number of active community partnerships',
        unit: 'count',
      ),
      
      Metric(
        id: 'environmental_impact',
        name: 'CO2 Emissions Saved',
        type: MetricType.counter,
        category: MetricCategory.socialImpact,
        description: 'CO2 emissions prevented through food waste reduction',
        unit: 'kg CO2',
      ),
      
      // Resource Utilization Metrics
      Metric(
        id: 'vehicle_utilization_rate',
        name: 'Vehicle Utilization Rate',
        type: MetricType.percentage,
        category: MetricCategory.resourceUtilization,
        description: 'Percentage of vehicle capacity utilized',
        unit: '%',
      ),
      
      Metric(
        id: 'storage_capacity_used',
        name: 'Storage Capacity Used',
        type: MetricType.percentage,
        category: MetricCategory.resourceUtilization,
        description: 'Percentage of storage capacity utilized',
        unit: '%',
      ),
      
      // Cost Effectiveness Metrics
      Metric(
        id: 'cost_per_kg_redistributed',
        name: 'Cost per KG Redistributed',
        type: MetricType.gauge,
        category: MetricCategory.costEffectiveness,
        description: 'Cost efficiency of food redistribution',
        unit: 'currency/kg',
      ),
      
      Metric(
        id: 'operational_cost_savings',
        name: 'Operational Cost Savings',
        type: MetricType.counter,
        category: MetricCategory.costEffectiveness,
        description: 'Cost savings achieved through optimization',
        unit: 'currency',
      ),
    ];
    
    for (final metric in coreMetrics) {
      _metrics[metric.id] = metric;
    }
  }
  
  /// Initialize KPI targets
  void _initializeKPITargets() {
    final targets = [
      KPITarget(
        metricId: 'food_redistribution_rate',
        targetValue: 85.0,
        operator: '>=',
        period: AggregationPeriod.month,
      ),
      KPITarget(
        metricId: 'delivery_success_rate',
        targetValue: 95.0,
        operator: '>=',
        period: AggregationPeriod.week,
      ),
      KPITarget(
        metricId: 'volunteer_retention_rate',
        targetValue: 80.0,
        operator: '>=',
        period: AggregationPeriod.month,
      ),
      KPITarget(
        metricId: 'average_delivery_time',
        targetValue: 45.0,
        operator: '<=',
        period: AggregationPeriod.day,
      ),
      KPITarget(
        metricId: 'system_uptime',
        targetValue: 99.5,
        operator: '>=',
        period: AggregationPeriod.month,
      ),
    ];
    
    for (final target in targets) {
      _kpiTargets[target.metricId] = target;
    }
  }
  
  /// Record a metric data point
  Future<void> recordMetric({
    required String metricId,
    required double value,
    Map<String, String> dimensions = const {},
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) async {
    try {
      final metric = _metrics[metricId];
      if (metric == null || !metric.isActive) {
        return;
      }
      
      final dataPoint = MetricDataPoint(
        metricId: metricId,
        value: value,
        timestamp: timestamp ?? DateTime.now(),
        dimensions: dimensions,
        metadata: metadata,
      );
      
      _buffer.add(dataPoint);
      
      // Flush if buffer is full
      if (_buffer.length >= _bufferSize) {
        await _flushBuffer();
      }
      
      // Check if KPI target is met
      await _checkKPITarget(metricId, value);
      
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'metric_record_error',
          'metricId': metricId,
          'value': value,
          'error': e.toString(),
        },
      );
    }
  }
  
  /// Increment a counter metric
  Future<void> incrementCounter({
    required String metricId,
    double increment = 1.0,
    Map<String, String> dimensions = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    await recordMetric(
      metricId: metricId,
      value: increment,
      dimensions: dimensions,
      metadata: metadata,
    );
  }
  
  /// Set a gauge value
  Future<void> setGauge({
    required String metricId,
    required double value,
    Map<String, String> dimensions = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    await recordMetric(
      metricId: metricId,
      value: value,
      dimensions: dimensions,
      metadata: metadata,
    );
  }
  
  /// Record a timer measurement
  Future<void> recordTimer({
    required String metricId,
    required Duration duration,
    Map<String, String> dimensions = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    await recordMetric(
      metricId: metricId,
      value: duration.inMilliseconds.toDouble(),
      dimensions: dimensions,
      metadata: metadata,
    );
  }
  
  /// Record a percentage value
  Future<void> recordPercentage({
    required String metricId,
    required double percentage,
    Map<String, String> dimensions = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    final clampedValue = math.max(0.0, math.min(100.0, percentage));
    await recordMetric(
      metricId: metricId,
      value: clampedValue,
      dimensions: dimensions,
      metadata: metadata,
    );
  }
  
  /// Get aggregated metrics data
  Future<Map<String, dynamic>> getAggregatedMetrics({
    required List<String> metricIds,
    required DateTime startDate,
    required DateTime endDate,
    required AggregationPeriod period,
    Map<String, String> filters = const {},
  }) async {
    try {
      final result = <String, dynamic>{};
      
      for (final metricId in metricIds) {
        final metric = _metrics[metricId];
        if (metric == null) continue;
        
        final query = _firestoreService.queryCollection(
          'metric_data_points',
          where: [
            {'field': 'metricId', 'operator': '==', 'value': metricId},
            {'field': 'timestamp', 'operator': '>=', 'value': startDate},
            {'field': 'timestamp', 'operator': '<=', 'value': endDate},
          ],
        );
        
        final docs = await query;
        final dataPoints = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return MetricDataPoint(
            metricId: data['metricId'],
            value: (data['value'] as num).toDouble(),
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            dimensions: Map<String, String>.from(data['dimensions'] ?? {}),
            metadata: data['metadata'] ?? {},
          );
        }).toList();
        
        // Apply filters
        final filteredPoints = _applyFilters(dataPoints, filters);
        
        // Aggregate by period
        final aggregated = _aggregateByPeriod(filteredPoints, period, metric.type);
        
        result[metricId] = {
          'metric': metric.toMap(),
          'aggregatedData': aggregated,
          'summary': _calculateSummaryStats(filteredPoints, metric.type),
        };
      }
      
      return result;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'metrics_aggregation_error',
          'metricIds': metricIds,
          'error': e.toString(),
        },
      );
      return {};
    }
  }
  
  /// Generate analytics report
  Future<AnalyticsReport> generateReport({
    required String name,
    required List<String> metricIds,
    Map<String, String> filters = const {},
    required AggregationPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(_getPeriodDuration(period) * 4);
    final end = endDate ?? DateTime.now();
    
    final aggregatedData = await getAggregatedMetrics(
      metricIds: metricIds,
      startDate: start,
      endDate: end,
      period: period,
      filters: filters,
    );
    
    // Calculate insights and trends
    final insights = await _calculateInsights(aggregatedData, period);
    final trends = _calculateTrends(aggregatedData);
    final kpiStatus = _calculateKPIStatus(metricIds);
    
    final report = AnalyticsReport(
      id: _generateReportId(),
      name: name,
      description: 'Analytics report for ${period.name} period',
      metricIds: metricIds,
      filters: filters,
      period: period,
      generatedAt: DateTime.now(),
      data: {
        'aggregatedMetrics': aggregatedData,
        'insights': insights,
        'trends': trends,
        'kpiStatus': kpiStatus,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
          'type': period.name,
        },
      },
    );
    
    // Store report
    await _firestoreService.addDocument('analytics_reports', {
      'id': report.id,
      'name': report.name,
      'description': report.description,
      'metricIds': report.metricIds,
      'filters': report.filters,
      'period': period.name,
      'generatedAt': report.generatedAt,
      'data': report.data,
    });
    
    await _auditService.logEvent(
      eventType: AuditEventType.adminAction,
      userId: 'admin', // Placeholder or get current user
      riskLevel: AuditRiskLevel.low,
      additionalData: {
        'action': 'analytics_report_generated',
        'reportId': report.id,
        'metricCount': metricIds.length,
        'period': period.name,
      },
    );
    
    return report;
  }
  
  /// Get real-time dashboard data
  Future<Map<String, dynamic>> getDashboardData({
    required String dashboardId,
    Map<String, String> filters = const {},
  }) async {
    try {
      // Get dashboard configuration
      final dashboardDoc = await _firestoreService.getDocument('dashboards', dashboardId);
      if (dashboardDoc == null) {
        throw ArgumentError('Dashboard $dashboardId not found');
      }
      
      final dashboardData = dashboardDoc.data() as Map<String, dynamic>;
      final metricIds = List<String>.from(dashboardData['metricIds'] ?? []);
      
      // Get recent metrics (last hour for real-time)
      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(hours: 1));
      
      final recentMetrics = await getAggregatedMetrics(
        metricIds: metricIds,
        startDate: startTime,
        endDate: endTime,
        period: AggregationPeriod.hour,
        filters: filters,
      );
      
      // Get current KPI status
      final kpiStatus = _calculateKPIStatus(metricIds);
      
      // Calculate real-time insights
      final realTimeInsights = await _calculateRealTimeInsights(metricIds);
      
      return {
        'dashboard': dashboardData,
        'metrics': recentMetrics,
        'kpiStatus': kpiStatus,
        'realTimeInsights': realTimeInsights,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'dashboard_data_error',
          'dashboardId': dashboardId,
          'error': e.toString(),
        },
      );
      return {};
    }
  }
  
  /// Helper methods
  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty) return;
    
    try {
      final batch = _firestoreService.batch();
      
      for (final dataPoint in _buffer) {
        final docRef = _firestoreService.collection('metric_data_points').doc();
        batch.set(docRef, dataPoint.toMap());
      }
      
      await batch.commit();
      _buffer.clear();
      
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'metric_buffer_flush_error',
          'bufferSize': _buffer.length,
          'error': e.toString(),
        },
      );
    }
  }
  
  void _startPeriodicFlush() {
    Timer.periodic(_flushInterval, (_) => _flushBuffer());
  }
  
  Future<void> _checkKPITarget(String metricId, double value) async {
    final target = _kpiTargets[metricId];
    if (target == null || !target.isActive) return;
    
    bool targetMet = false;
    switch (target.operator) {
      case '>':
        targetMet = value > target.targetValue;
        break;
      case '<':
        targetMet = value < target.targetValue;
        break;
      case '>=':
        targetMet = value >= target.targetValue;
        break;
      case '<=':
        targetMet = value <= target.targetValue;
        break;
      case '==':
        targetMet = value == target.targetValue;
        break;
    }
    
    if (!targetMet) {
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: 'system',
        riskLevel: AuditRiskLevel.medium,
        additionalData: {
          'action': 'kpi_target_missed',
          'metricId': metricId,
          'currentValue': value,
          'targetValue': target.targetValue,
          'operator': target.operator,
        },
      );
    }
  }
  
  List<MetricDataPoint> _applyFilters(
    List<MetricDataPoint> dataPoints,
    Map<String, String> filters,
  ) {
    if (filters.isEmpty) return dataPoints;
    
    return dataPoints.where((point) {
      return filters.entries.every((filter) {
        return point.dimensions[filter.key] == filter.value;
      });
    }).toList();
  }
  
  Map<String, dynamic> _aggregateByPeriod(
    List<MetricDataPoint> dataPoints,
    AggregationPeriod period,
    MetricType metricType,
  ) {
    final grouped = <String, List<double>>{};
    
    for (final point in dataPoints) {
      final periodKey = _getPeriodKey(point.timestamp, period);
      grouped[periodKey] = (grouped[periodKey] ?? [])..add(point.value);
    }
    
    final aggregated = <String, double>{};
    for (final entry in grouped.entries) {
      switch (metricType) {
        case MetricType.counter:
          aggregated[entry.key] = entry.value.reduce((a, b) => a + b);
          break;
        case MetricType.gauge:
        case MetricType.percentage:
          aggregated[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
          break;
        case MetricType.timer:
        case MetricType.histogram:
          aggregated[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
          break;
      }
    }
    
    return aggregated;
  }
  
  Map<String, dynamic> _calculateSummaryStats(
    List<MetricDataPoint> dataPoints,
    MetricType metricType,
  ) {
    if (dataPoints.isEmpty) {
      return {'count': 0, 'sum': 0, 'avg': 0, 'min': 0, 'max': 0};
    }
    
    final values = dataPoints.map((p) => p.value).toList();
    values.sort();
    
    return {
      'count': values.length,
      'sum': values.reduce((a, b) => a + b),
      'avg': values.reduce((a, b) => a + b) / values.length,
      'min': values.first,
      'max': values.last,
      'median': values[values.length ~/ 2],
      'p95': values[(values.length * 0.95).floor()],
    };
  }
  
  String _getPeriodKey(DateTime timestamp, AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.hour:
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:00';
      case AggregationPeriod.day:
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      case AggregationPeriod.week:
        final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
        return '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      case AggregationPeriod.month:
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      case AggregationPeriod.quarter:
        final quarter = (timestamp.month - 1) ~/ 3 + 1;
        return '${timestamp.year}-Q$quarter';
      case AggregationPeriod.year:
        return timestamp.year.toString();
    }
  }
  
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    return (dayOfYear / 7).ceil();
  }
  
  Duration _getPeriodDuration(AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.hour:
        return Duration(hours: 1);
      case AggregationPeriod.day:
        return Duration(days: 1);
      case AggregationPeriod.week:
        return Duration(days: 7);
      case AggregationPeriod.month:
        return Duration(days: 30);
      case AggregationPeriod.quarter:
        return Duration(days: 90);
      case AggregationPeriod.year:
        return Duration(days: 365);
    }
  }
  
  Future<Map<String, dynamic>> _calculateInsights(
    Map<String, dynamic> aggregatedData,
    AggregationPeriod period,
  ) async {
    // AI-driven insights calculation
    final insights = <String, dynamic>{};
    
    // Calculate trends, anomalies, and recommendations
    for (final entry in aggregatedData.entries) {
      final metricId = entry.key;
      final data = entry.value['aggregatedData'] as Map<String, dynamic>;
      
      insights[metricId] = {
        'trend': _calculateTrend(data),
        'anomalies': _detectAnomalies(data),
        'recommendations': _generateRecommendations(metricId, data),
      };
    }
    
    return insights;
  }
  
  Map<String, dynamic> _calculateTrends(Map<String, dynamic> aggregatedData) {
    final trends = <String, dynamic>{};
    
    for (final entry in aggregatedData.entries) {
      final data = entry.value['aggregatedData'] as Map<String, dynamic>;
      trends[entry.key] = _calculateTrend(data);
    }
    
    return trends;
  }
  
  String _calculateTrend(Map<String, dynamic> data) {
    if (data.length < 2) return 'insufficient_data';
    
    final values = data.values.cast<double>().toList();
    final firstHalf = values.take(values.length ~/ 2).toList();
    final secondHalf = values.skip(values.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final percentChange = ((secondAvg - firstAvg) / firstAvg) * 100;
    
    if (percentChange > 10) return 'increasing';
    if (percentChange < -10) return 'decreasing';
    return 'stable';
  }
  
  List<String> _detectAnomalies(Map<String, dynamic> data) {
    // Simple anomaly detection using statistical methods
    final anomalies = <String>[];
    final values = data.values.cast<double>().toList();
    
    if (values.length < 3) return anomalies;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    
    data.forEach((key, value) {
      final v = value as double;
      if ((v - mean).abs() > 2 * stdDev) {
        anomalies.add(key);
      }
    });
    
    return anomalies;
  }
  
  List<String> _generateRecommendations(String metricId, Map<String, dynamic> data) {
    final recommendations = <String>[];
    final metric = _metrics[metricId];
    if (metric == null) return recommendations;
    
    // Generate context-aware recommendations
    switch (metric.category) {
      case MetricCategory.foodWaste:
        recommendations.addAll([
          'Optimize pickup scheduling to reduce food expiry',
          'Increase volunteer capacity during peak donation times',
          'Improve donor education on food quality standards',
        ]);
        break;
      case MetricCategory.deliveryPerformance:
        recommendations.addAll([
          'Review route optimization parameters',
          'Consider adding delivery vehicles during high-demand periods',
          'Implement predictive scheduling based on historical data',
        ]);
        break;
      case MetricCategory.volunteerEngagement:
        recommendations.addAll([
          'Enhance volunteer recognition programs',
          'Improve onboarding and training processes',
          'Create more flexible scheduling options',
        ]);
        break;
      default:
        recommendations.add('Monitor trends and adjust strategies accordingly');
    }
    
    return recommendations;
  }
  
  Map<String, dynamic> _calculateKPIStatus(List<String> metricIds) {
    final kpiStatus = <String, dynamic>{};
    
    for (final metricId in metricIds) {
      final target = _kpiTargets[metricId];
      if (target != null) {
        kpiStatus[metricId] = {
          'hasTarget': true,
          'targetValue': target.targetValue,
          'operator': target.operator,
          'period': target.period.name,
          'isActive': target.isActive,
        };
      } else {
        kpiStatus[metricId] = {'hasTarget': false};
      }
    }
    
    return kpiStatus;
  }
  
  Future<Map<String, dynamic>> _calculateRealTimeInsights(List<String> metricIds) async {
    // Calculate real-time insights for dashboard
    final insights = <String, dynamic>{};
    
    // Get current hour data
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    
    for (final metricId in metricIds) {
      final metric = _metrics[metricId];
      if (metric == null) continue;
      
      // Simple real-time calculation
      insights[metricId] = {
        'status': 'normal',
        'change': 'stable',
        'alertLevel': 'none',
      };
    }
    
    return insights;
  }
  
  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}';
  }
}
