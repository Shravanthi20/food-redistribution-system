import 'dart:math';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/audit_service.dart';

enum OptimizationStrategy {
  shortestDistance,
  fastestTime,
  fuelEfficient,
  trafficAware,
  multiStop,
}

class RoutePoint {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String type; // 'pickup', 'delivery', 'checkpoint'
  final DateTime? timeWindow;
  final int priority; // 1-10, higher = more important
  final Duration? serviceDuration;
  final Map<String, dynamic>? metadata;
  
  RoutePoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.type,
    this.timeWindow,
    this.priority = 5,
    this.serviceDuration,
    this.metadata,
  });
  
  double distanceTo(RoutePoint other) {
    return _calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }
  
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class OptimizedRoute {
  final String id;
  final List<RoutePoint> points;
  final double totalDistance;
  final Duration estimatedDuration;
  final OptimizationStrategy strategy;
  final double optimizationScore;
  final Map<String, dynamic> metrics;
  final DateTime calculatedAt;
  final List<String> warnings;
  
  OptimizedRoute({
    required this.id,
    required this.points,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.strategy,
    required this.optimizationScore,
    required this.metrics,
    required this.calculatedAt,
    this.warnings = const [],
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pointCount': points.length,
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration.inMinutes,
      'strategy': strategy.name,
      'optimizationScore': optimizationScore,
      'metrics': metrics,
      'calculatedAt': calculatedAt,
      'warnings': warnings,
    };
  }
}

class RouteOptimizationEngine {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final AuditService _auditService;
  
  // Optimization parameters
  static const double _averageSpeed = 30.0; // km/h in city
  static const double _serviceTimeMinutes = 10.0; // Average stop time
  static const int _maxIterations = 1000; // For genetic algorithm
  static const double _mutationRate = 0.1;
  
  RouteOptimizationEngine({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService,
       _auditService = auditService;

  /// Optimize route for multiple delivery points
  Future<OptimizedRoute> optimizeRoute({
    required List<RoutePoint> points,
    required RoutePoint startPoint,
    RoutePoint? endPoint,
    OptimizationStrategy strategy = OptimizationStrategy.shortestDistance,
    Map<String, dynamic>? constraints,
  }) async {
    try {
      if (points.isEmpty) {
        throw ArgumentError('Route points cannot be empty');
      }
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'route_optimization_started',
          'message': 'Starting route optimization for ${points.length} points',
          'pointCount': points.length,
          'strategy': strategy.name,
          'hasConstraints': constraints?.isNotEmpty ?? false,
        },
      );
      
      OptimizedRoute optimizedRoute;
      
      switch (strategy) {
        case OptimizationStrategy.shortestDistance:
          optimizedRoute = await _optimizeForDistance(points, startPoint, endPoint);
          break;
        case OptimizationStrategy.fastestTime:
          optimizedRoute = await _optimizeForTime(points, startPoint, endPoint);
          break;
        case OptimizationStrategy.fuelEfficient:
          optimizedRoute = await _optimizeForFuel(points, startPoint, endPoint);
          break;
        case OptimizationStrategy.trafficAware:
          optimizedRoute = await _optimizeForTraffic(points, startPoint, endPoint);
          break;
        case OptimizationStrategy.multiStop:
          optimizedRoute = await _optimizeMultiStop(points, startPoint, endPoint, constraints);
          break;
      }
      
      // Store optimization result for analytics
      await _storeOptimizationResult(optimizedRoute);
      
      await _auditService.logEvent(
        eventType: AuditEventType.adminAction,
        userId: 'system',
        riskLevel: AuditRiskLevel.low,
        additionalData: {
          'action': 'route_optimization_completed',
          'message': 'Route optimization completed with score ${optimizedRoute.optimizationScore.toStringAsFixed(2)}',
          'routeId': optimizedRoute.id,
          'totalDistance': optimizedRoute.totalDistance,
          'estimatedDuration': optimizedRoute.estimatedDuration.inMinutes,
          'optimizationScore': optimizedRoute.optimizationScore,
        },
      );
      
      return optimizedRoute;
    } catch (e) {
      await _auditService.logEvent(
        eventType: AuditEventType.systemError,
        userId: 'system',
        riskLevel: AuditRiskLevel.high,
        additionalData: {
          'action': 'route_optimization_error',
          'pointCount': points.length,
          'strategy': strategy.name,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
  
  /// Optimize route for shortest total distance
  Future<OptimizedRoute> _optimizeForDistance(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Use nearest neighbor with 2-opt improvement for TSP
    final optimizedPoints = <RoutePoint>[startPoint];
    final remainingPoints = List<RoutePoint>.from(points);
    var currentPoint = startPoint;
    double totalDistance = 0;
    
    // Nearest neighbor construction
    while (remainingPoints.isNotEmpty) {
      RoutePoint? nearestPoint;
      double nearestDistance = double.infinity;
      
      for (final point in remainingPoints) {
        final distance = currentPoint.distanceTo(point);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestPoint = point;
        }
      }
      
      if (nearestPoint != null) {
        optimizedPoints.add(nearestPoint);
        totalDistance += nearestDistance;
        currentPoint = nearestPoint;
        remainingPoints.remove(nearestPoint);
      }
    }
    
    // Add distance to end point if specified
    if (endPoint != null) {
      optimizedPoints.add(endPoint);
      totalDistance += currentPoint.distanceTo(endPoint);
    }
    
    // Apply 2-opt improvement
    final improvedRoute = _apply2OptImprovement(optimizedPoints);
    totalDistance = _calculateTotalDistance(improvedRoute.points);
    
    final estimatedDuration = Duration(
      minutes: ((totalDistance / _averageSpeed * 60) + 
                (improvedRoute.points.length * _serviceTimeMinutes)).round(),
    );
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: improvedRoute.points,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      strategy: OptimizationStrategy.shortestDistance,
      optimizationScore: _calculateDistanceScore(totalDistance, improvedRoute.points.length),
      metrics: {
        'averageDistancePerStop': totalDistance / improvedRoute.points.length,
        'optimizationMethod': 'nearest_neighbor_2opt',
        'improvementIterations': improvedRoute.metrics['iterations'] ?? 0,
      },
      calculatedAt: DateTime.now(),
      warnings: _generateRouteWarnings(improvedRoute.points, totalDistance),
    );
  }
  
  /// Optimize route for fastest time
  Future<OptimizedRoute> _optimizeForTime(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Consider time windows and traffic patterns
    final sortedPoints = List<RoutePoint>.from(points);
    
    // Sort by time windows if available
    sortedPoints.sort((a, b) {
      if (a.timeWindow != null && b.timeWindow != null) {
        return a.timeWindow!.compareTo(b.timeWindow!);
      }
      return a.priority.compareTo(b.priority);
    });
    
    final optimizedPoints = <RoutePoint>[startPoint, ...sortedPoints];
    if (endPoint != null) {
      optimizedPoints.add(endPoint);
    }
    
    final totalDistance = _calculateTotalDistance(optimizedPoints);
    final estimatedDuration = Duration(
      minutes: ((totalDistance / (_averageSpeed * 1.2)) * 60 + // Traffic factor
                (optimizedPoints.length * _serviceTimeMinutes)).round(),
    );
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: optimizedPoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      strategy: OptimizationStrategy.fastestTime,
      optimizationScore: _calculateTimeScore(estimatedDuration, optimizedPoints.length),
      metrics: {
        'timeWindowViolations': _countTimeWindowViolations(optimizedPoints),
        'trafficFactor': 1.2,
        'averageServiceTime': _serviceTimeMinutes,
      },
      calculatedAt: DateTime.now(),
    );
  }
  
  /// Optimize route for fuel efficiency
  Future<OptimizedRoute> _optimizeForFuel(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Consider elevation changes and traffic patterns
    final fuelOptimizedPoints = await _optimizeForFuelConsumption(
      points, startPoint, endPoint
    );
    
    final totalDistance = _calculateTotalDistance(fuelOptimizedPoints);
    final estimatedFuelLiters = _estimateFuelConsumption(totalDistance, fuelOptimizedPoints);
    
    final estimatedDuration = Duration(
      minutes: ((totalDistance / (_averageSpeed * 0.9)) * 60 + // Eco-driving factor
                (fuelOptimizedPoints.length * _serviceTimeMinutes)).round(),
    );
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: fuelOptimizedPoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      strategy: OptimizationStrategy.fuelEfficient,
      optimizationScore: _calculateFuelScore(estimatedFuelLiters, totalDistance),
      metrics: {
        'estimatedFuelLiters': estimatedFuelLiters,
        'fuelEfficiency': totalDistance / estimatedFuelLiters, // km/L
        'ecoFactor': 0.9,
      },
      calculatedAt: DateTime.now(),
    );
  }
  
  /// Optimize route considering traffic patterns
  Future<OptimizedRoute> _optimizeForTraffic(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Simulate traffic-aware optimization
    final trafficOptimizedPoints = await _optimizeForTrafficPatterns(
      points, startPoint, endPoint
    );
    
    final totalDistance = _calculateTotalDistance(trafficOptimizedPoints);
    final trafficFactor = _calculateTrafficFactor();
    
    final estimatedDuration = Duration(
      minutes: ((totalDistance / (_averageSpeed / trafficFactor)) * 60 +
                (trafficOptimizedPoints.length * _serviceTimeMinutes)).round(),
    );
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: trafficOptimizedPoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      strategy: OptimizationStrategy.trafficAware,
      optimizationScore: _calculateTrafficScore(estimatedDuration, totalDistance),
      metrics: {
        'trafficFactor': trafficFactor,
        'peakHourAdjustment': _isPeakHour() ? 1.5 : 1.0,
        'trafficOptimizationSavings': _calculateTrafficSavings(totalDistance, trafficFactor),
      },
      calculatedAt: DateTime.now(),
    );
  }
  
  /// Optimize multi-stop route with constraints
  Future<OptimizedRoute> _optimizeMultiStop(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
    Map<String, dynamic>? constraints,
  ) async {
    final maxStops = constraints?['maxStops'] ?? points.length;
    final maxDistance = constraints?['maxDistance'] ?? 100.0;
    final maxDuration = Duration(minutes: constraints?['maxDurationMinutes'] ?? 480); // 8 hours
    
    // Select best points if exceeding max stops
    var selectedPoints = points;
    if (points.length > maxStops) {
      selectedPoints = _selectBestPoints(points, maxStops);
    }
    
    // Apply genetic algorithm for complex multi-stop optimization
    final optimizedPoints = await _applyGeneticAlgorithm(
      selectedPoints, startPoint, endPoint, constraints
    );
    
    final totalDistance = _calculateTotalDistance(optimizedPoints);
    final estimatedDuration = Duration(
      minutes: ((totalDistance / _averageSpeed) * 60 +
                (optimizedPoints.length * _serviceTimeMinutes)).round(),
    );
    
    final warnings = <String>[];
    if (totalDistance > maxDistance) {
      warnings.add('Route exceeds maximum distance constraint');
    }
    if (estimatedDuration > maxDuration) {
      warnings.add('Route exceeds maximum duration constraint');
    }
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: optimizedPoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      strategy: OptimizationStrategy.multiStop,
      optimizationScore: _calculateMultiStopScore(optimizedPoints, constraints),
      metrics: {
        'selectedStops': optimizedPoints.length,
        'maxStopsConstraint': maxStops,
        'maxDistanceConstraint': maxDistance,
        'maxDurationConstraint': maxDuration.inMinutes,
        'constraintViolations': warnings.length,
      },
      calculatedAt: DateTime.now(),
      warnings: warnings,
    );
  }
  
  /// Apply 2-opt improvement to TSP solution
  OptimizedRoute _apply2OptImprovement(List<RoutePoint> route) {
    var bestRoute = List<RoutePoint>.from(route);
    var bestDistance = _calculateTotalDistance(bestRoute);
    bool improved = true;
    int iterations = 0;
    
    while (improved && iterations < _maxIterations) {
      improved = false;
      
      for (int i = 1; i < bestRoute.length - 2; i++) {
        for (int j = i + 1; j < bestRoute.length; j++) {
          if (j - i == 1) continue; // Skip adjacent edges
          
          // Create new route by reversing segment between i and j
          final newRoute = List<RoutePoint>.from(bestRoute);
          _reverseSegment(newRoute, i, j);
          
          final newDistance = _calculateTotalDistance(newRoute);
          if (newDistance < bestDistance) {
            bestRoute = newRoute;
            bestDistance = newDistance;
            improved = true;
          }
        }
      }
      iterations++;
    }
    
    return OptimizedRoute(
      id: _generateRouteId(),
      points: bestRoute,
      totalDistance: bestDistance,
      estimatedDuration: Duration(minutes: 0), // Will be calculated later
      strategy: OptimizationStrategy.shortestDistance,
      optimizationScore: 0, // Will be calculated later
      metrics: {'iterations': iterations},
      calculatedAt: DateTime.now(),
    );
  }
  
  void _reverseSegment(List<RoutePoint> route, int i, int j) {
    while (i < j) {
      final temp = route[i];
      route[i] = route[j];
      route[j] = temp;
      i++;
      j--;
    }
  }
  
  /// Calculate total distance of route
  double _calculateTotalDistance(List<RoutePoint> points) {
    if (points.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += points[i].distanceTo(points[i + 1]);
    }
    return totalDistance;
  }
  
  /// Helper optimization methods
  Future<List<RoutePoint>> _optimizeForFuelConsumption(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Prioritize points with lower elevation changes and less traffic
    final sortedPoints = List<RoutePoint>.from(points);
    sortedPoints.sort((a, b) {
      // Simple heuristic: prefer points closer to center to reduce elevation changes
      final centerLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final centerLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
      
      final distanceA = RoutePoint._calculateDistance(a.latitude, a.longitude, centerLat, centerLng);
      final distanceB = RoutePoint._calculateDistance(b.latitude, b.longitude, centerLat, centerLng);
      
      return distanceA.compareTo(distanceB);
    });
    
    return [startPoint, ...sortedPoints, if (endPoint != null) endPoint];
  }
  
  Future<List<RoutePoint>> _optimizeForTrafficPatterns(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
  ) async {
    // Simple traffic optimization: avoid peak hours routes
    final trafficOptimized = List<RoutePoint>.from(points);
    
    if (_isPeakHour()) {
      // Reorder to avoid high-traffic areas (simplified)
      trafficOptimized.sort((a, b) => a.priority.compareTo(b.priority));
    }
    
    return [startPoint, ...trafficOptimized, if (endPoint != null) endPoint];
  }
  
  Future<List<RoutePoint>> _applyGeneticAlgorithm(
    List<RoutePoint> points,
    RoutePoint startPoint,
    RoutePoint? endPoint,
    Map<String, dynamic>? constraints,
  ) async {
    // Simplified genetic algorithm implementation
    const populationSize = 50;
    final generations = min(_maxIterations ~/ 10, 100);
    
    // Generate initial population
    var population = <List<RoutePoint>>[];
    for (int i = 0; i < populationSize; i++) {
      final shuffled = List<RoutePoint>.from(points)..shuffle();
      population.add([startPoint, ...shuffled, if (endPoint != null) endPoint]);
    }
    
    for (int gen = 0; gen < generations; gen++) {
      // Evaluate fitness (shorter distance = higher fitness)
      population.sort((a, b) => _calculateTotalDistance(a).compareTo(_calculateTotalDistance(b)));
      
      // Select best half
      population = population.take(populationSize ~/ 2).toList();
      
      // Generate offspring
      while (population.length < populationSize) {
        final parent1 = population[Random().nextInt(population.length ~/ 2)];
        final parent2 = population[Random().nextInt(population.length ~/ 2)];
        final offspring = _crossover(parent1, parent2);
        
        if (Random().nextDouble() < _mutationRate) {
          _mutate(offspring);
        }
        
        population.add(offspring);
      }
    }
    
    // Return best solution
    population.sort((a, b) => _calculateTotalDistance(a).compareTo(_calculateTotalDistance(b)));
    return population.first;
  }
  
  List<RoutePoint> _crossover(List<RoutePoint> parent1, List<RoutePoint> parent2) {
    // Order crossover (OX)
    final size = parent1.length;
    final start = Random().nextInt(size - 2) + 1; // Skip start point
    final end = start + Random().nextInt(size - start - 1);
    
    final offspring = List<RoutePoint?>.filled(size, null);
    
    // Copy segment from parent1
    for (int i = start; i <= end; i++) {
      offspring[i] = parent1[i];
    }
    
    // Fill remaining positions from parent2
    int currentPos = 0;
    for (final point in parent2) {
      if (!offspring.contains(point)) {
        while (offspring[currentPos] != null) {
          currentPos++;
        }
        offspring[currentPos] = point;
      }
    }
    
    return offspring.cast<RoutePoint>();
  }
  
  void _mutate(List<RoutePoint> route) {
    if (route.length <= 3) return; // Skip if too small
    
    // Swap mutation (avoid start/end points)
    final i = Random().nextInt(route.length - 2) + 1;
    final j = Random().nextInt(route.length - 2) + 1;
    
    final temp = route[i];
    route[i] = route[j];
    route[j] = temp;
  }
  
  List<RoutePoint> _selectBestPoints(List<RoutePoint> points, int maxStops) {
    // Select points based on priority and distribution
    final sortedPoints = List<RoutePoint>.from(points);
    sortedPoints.sort((a, b) => b.priority.compareTo(a.priority));
    
    return sortedPoints.take(maxStops).toList();
  }
  
  /// Scoring and metrics functions
  double _calculateDistanceScore(double totalDistance, int pointCount) {
    // Lower distance = higher score
    final averageDistance = totalDistance / pointCount;
    return max(0, 100 - averageDistance * 2);
  }
  
  double _calculateTimeScore(Duration duration, int pointCount) {
    // Shorter time = higher score
    final averageTimePerStop = duration.inMinutes / pointCount;
    return max(0, 100 - averageTimePerStop);
  }
  
  double _calculateFuelScore(double fuelLiters, double distance) {
    // Better fuel efficiency = higher score
    final efficiency = distance / fuelLiters; // km/L
    return min(100, efficiency * 10);
  }
  
  double _calculateTrafficScore(Duration duration, double distance) {
    // Consider traffic impact
    final speed = distance / (duration.inMinutes / 60);
    return min(100, speed * 2);
  }
  
  double _calculateMultiStopScore(List<RoutePoint> points, Map<String, dynamic>? constraints) {
    // Composite score for multi-stop optimization
    final distance = _calculateTotalDistance(points);
    final distanceScore = _calculateDistanceScore(distance, points.length);
    
    // Penalty for constraint violations
    double penalty = 0;
    if (constraints != null) {
      final maxDistance = constraints['maxDistance'] ?? double.infinity;
      if (distance > maxDistance) {
        penalty += 20;
      }
    }
    
    return max(0, distanceScore - penalty);
  }
  
  /// Helper functions
  double _estimateFuelConsumption(double distance, List<RoutePoint> points) {
    // Estimate fuel consumption in liters
    const double baseFuelRate = 0.08; // L/km
    const double stopPenalty = 0.5; // L per stop
    
    return (distance * baseFuelRate) + (points.length * stopPenalty);
  }
  
  double _calculateTrafficFactor() {
    // Simple traffic factor based on time of day
    final hour = DateTime.now().hour;
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      return 1.8; // Peak hours
    } else if (hour >= 10 && hour <= 16) {
      return 1.2; // Moderate traffic
    } else {
      return 1.0; // Low traffic
    }
  }
  
  bool _isPeakHour() {
    final hour = DateTime.now().hour;
    return (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
  }
  
  double _calculateTrafficSavings(double distance, double trafficFactor) {
    // Calculate time savings from traffic-aware routing
    return distance * (trafficFactor - 1.0) / _averageSpeed * 60; // minutes saved
  }
  
  int _countTimeWindowViolations(List<RoutePoint> points) {
    int violations = 0;
    DateTime currentTime = DateTime.now();
    
    for (final point in points) {
      if (point.timeWindow != null && currentTime.isAfter(point.timeWindow!)) {
        violations++;
      }
      // Add service time
      currentTime = currentTime.add(Duration(minutes: _serviceTimeMinutes.round()));
    }
    
    return violations;
  }
  
  List<String> _generateRouteWarnings(List<RoutePoint> points, double totalDistance) {
    final warnings = <String>[];
    
    if (totalDistance > 100) {
      warnings.add('Route exceeds 100km - consider breaking into multiple trips');
    }
    
    if (points.length > 15) {
      warnings.add('High number of stops - may cause driver fatigue');
    }
    
    // Check for time window conflicts
    if (_countTimeWindowViolations(points) > 0) {
      warnings.add('Some time windows may not be achievable');
    }
    
    return warnings;
  }
  
  String _generateRouteId() {
    return 'route_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Store optimization result for analytics
  Future<void> _storeOptimizationResult(OptimizedRoute route) async {
    await _firestoreService.create('route_optimizations', route.id, route.toMap());
  }
}
