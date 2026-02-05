import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

enum TrackingStatus {
  idle,
  enRoute,
  atPickup,
  collected,
  inTransit,
  nearDelivery,
  delivered,
  completed,
}

enum GeofenceType {
  pickup,
  delivery,
  checkpoint,
}

class LocationUpdate {
  final String volunteerId;
  final String taskId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final TrackingStatus status;
  final Map<String, dynamic>? metadata;
  
  LocationUpdate({
    required this.volunteerId,
    required this.taskId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    required this.status,
    this.metadata,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'taskId': taskId,
      'location': GeoPoint(latitude, longitude),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp,
      'status': status.toString(),
      'metadata': metadata,
    };
  }
  
  factory LocationUpdate.fromMap(Map<String, dynamic> map) {
    final geoPoint = map['location'] as GeoPoint?;
    return LocationUpdate(
      volunteerId: map['volunteerId'],
      taskId: map['taskId'],
      latitude: geoPoint?.latitude ?? map['latitude'],
      longitude: geoPoint?.longitude ?? map['longitude'],
      accuracy: map['accuracy']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: TrackingStatus.values.firstWhere(
        (s) => s.toString() == map['status'],
        orElse: () => TrackingStatus.idle,
      ),
      metadata: map['metadata'],
    );
  }
}

class Geofence {
  final String id;
  final GeofenceType type;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String taskId;
  final String? label;
  final Map<String, dynamic>? metadata;
  
  Geofence({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.taskId,
    this.label,
    this.metadata,
  });
  
  bool contains(double lat, double lng) {
    final distance = Geolocator.distanceBetween(
      latitude, longitude, lat, lng
    );
    return distance <= radius;
  }
}

class TrackingMetrics {
  final String taskId;
  final double totalDistance;
  final Duration totalDuration;
  final Duration pickupWaitTime;
  final Duration transitTime;
  final Duration deliveryWaitTime;
  final double averageSpeed;
  final int locationUpdates;
  final List<String> geofenceEvents;
  final Map<String, dynamic> additionalMetrics;
  
  TrackingMetrics({
    required this.taskId,
    required this.totalDistance,
    required this.totalDuration,
    required this.pickupWaitTime,
    required this.transitTime,
    required this.deliveryWaitTime,
    required this.averageSpeed,
    required this.locationUpdates,
    required this.geofenceEvents,
    required this.additionalMetrics,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration.inMinutes,
      'pickupWaitTime': pickupWaitTime.inMinutes,
      'transitTime': transitTime.inMinutes,
      'deliveryWaitTime': deliveryWaitTime.inMinutes,
      'averageSpeed': averageSpeed,
      'locationUpdates': locationUpdates,
      'geofenceEvents': geofenceEvents,
      'additionalMetrics': additionalMetrics,
      'completedAt': DateTime.now(),
    };
  }
}

class RealTimeTrackingService {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  
  StreamSubscription<Position>? _locationSubscription;
  final Map<String, Timer> _activeTrackers = {};
  final Map<String, List<Geofence>> _taskGeofences = {};
  final Map<String, List<LocationUpdate>> _trackingHistory = {};
  
  RealTimeTrackingService({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required NotificationService notificationService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService,
       _notificationService = notificationService,
       _auditService = auditService;

  /// Start tracking for a volunteer task
  Future<bool> startTracking({
    required String volunteerId,
    required String taskId,
    int updateIntervalSeconds = 30,
  }) async {
    try {
      // Stop any existing tracking for this volunteer
      await stopTracking(volunteerId);
      
      // Check location permissions
      final hasPermission = await _locationService.requestPermission();
      if (!hasPermission) {
        await _auditService.logEvent(
          'tracking_permission_denied',
          'Location permission denied for volunteer $volunteerId',
          riskLevel: RiskLevel.high,
          metadata: {'volunteerId': volunteerId, 'taskId': taskId},
        );
        return false;
      }
      
      // Set up geofences for the task
      await _setupGeofences(taskId);
      
      // Initialize tracking history
      _trackingHistory[volunteerId] = [];
      
      // Start periodic location updates
      _activeTrackers[volunteerId] = Timer.periodic(
        Duration(seconds: updateIntervalSeconds),
        (timer) => _updateLocation(volunteerId, taskId),
      );
      
      // Update volunteer status
      await _firestoreService.updateDocument('volunteer_profiles', volunteerId, {
        'isTracking': true,
        'trackingStarted': DateTime.now(),
        'currentTaskId': taskId,
      });
      
      await _auditService.logEvent(
        'tracking_started',
        'Real-time tracking started for volunteer $volunteerId on task $taskId',
        riskLevel: RiskLevel.low,
        metadata: {
          'volunteerId': volunteerId,
          'taskId': taskId,
          'updateInterval': updateIntervalSeconds,
        },
      );
      
      return true;
    } catch (e) {
      await _auditService.logEvent(
        'tracking_start_error',
        'Failed to start tracking for volunteer $volunteerId: $e',
        riskLevel: RiskLevel.high,
        metadata: {
          'volunteerId': volunteerId,
          'taskId': taskId,
          'error': e.toString(),
        },
      );
      return false;
    }
  }
  
  /// Stop tracking for a volunteer
  Future<void> stopTracking(String volunteerId) async {
    // Cancel timer
    _activeTrackers[volunteerId]?.cancel();
    _activeTrackers.remove(volunteerId);
    
    // Update volunteer status
    await _firestoreService.updateDocument('volunteer_profiles', volunteerId, {
      'isTracking': false,
      'trackingEnded': DateTime.now(),
    });
    
    // Calculate and store tracking metrics if there's history
    if (_trackingHistory[volunteerId]?.isNotEmpty == true) {
      final taskId = _trackingHistory[volunteerId]!.first.taskId;
      final metrics = await _calculateTrackingMetrics(volunteerId, taskId);
      await _storeTrackingMetrics(metrics);
    }
    
    // Clean up
    _trackingHistory.remove(volunteerId);
    _taskGeofences.entries
        .where((entry) => entry.value.any((g) => g.taskId == volunteerId))
        .forEach((entry) => _taskGeofences.remove(entry.key));
    
    await _auditService.logEvent(
      'tracking_stopped',
      'Real-time tracking stopped for volunteer $volunteerId',
      riskLevel: RiskLevel.low,
      metadata: {'volunteerId': volunteerId},
    );
  }
  
  /// Update volunteer location
  Future<void> _updateLocation(String volunteerId, String taskId) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return;
      
      // Determine current status based on geofences
      final status = await _determineTrackingStatus(
        volunteerId,
        taskId,
        position.latitude,
        position.longitude,
      );
      
      final locationUpdate = LocationUpdate(
        volunteerId: volunteerId,
        taskId: taskId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
        status: status,
        metadata: {
          'altitude': position.altitude,
          'speedAccuracy': position.speedAccuracy,
          'headingAccuracy': position.headingAccuracy,
        },
      );
      
      // Store location update
      await _storeLocationUpdate(locationUpdate);
      
      // Add to tracking history
      _trackingHistory[volunteerId]?.add(locationUpdate);
      
      // Check geofence events
      await _checkGeofenceEvents(locationUpdate);
      
      // Send real-time updates to stakeholders
      await _broadcastLocationUpdate(locationUpdate);
      
    } catch (e) {
      await _auditService.logEvent(
        'location_update_error',
        'Error updating location for volunteer $volunteerId: $e',
        riskLevel: RiskLevel.medium,
        metadata: {
          'volunteerId': volunteerId,
          'taskId': taskId,
          'error': e.toString(),
        },
      );
    }
  }
  
  /// Set up geofences for task locations
  Future<void> _setupGeofences(String taskId) async {
    try {
      final taskDoc = await _firestoreService.getDocument('delivery_tasks', taskId);
      if (taskDoc == null) return;
      
      final taskData = taskDoc.data() as Map<String, dynamic>;
      final geofences = <Geofence>[];
      
      // Pickup location geofence
      final pickupLocation = taskData['pickupLocation'] as Map<String, dynamic>;
      geofences.add(Geofence(
        id: '${taskId}_pickup',
        type: GeofenceType.pickup,
        latitude: pickupLocation['latitude'],
        longitude: pickupLocation['longitude'],
        radius: 100, // 100 meters
        taskId: taskId,
        label: 'Pickup Location',
      ));
      
      // Delivery location geofence
      final deliveryLocation = taskData['deliveryLocation'] as Map<String, dynamic>;
      geofences.add(Geofence(
        id: '${taskId}_delivery',
        type: GeofenceType.delivery,
        latitude: deliveryLocation['latitude'],
        longitude: deliveryLocation['longitude'],
        radius: 100, // 100 meters
        taskId: taskId,
        label: 'Delivery Location',
      ));
      
      _taskGeofences[taskId] = geofences;
      
    } catch (e) {
      await _auditService.logEvent(
        'geofence_setup_error',
        'Error setting up geofences for task $taskId: $e',
        riskLevel: RiskLevel.medium,
        metadata: {'taskId': taskId, 'error': e.toString()},
      );
    }
  }
  
  /// Determine tracking status based on location and geofences
  Future<TrackingStatus> _determineTrackingStatus(
    String volunteerId,
    String taskId,
    double latitude,
    double longitude,
  ) async {
    final geofences = _taskGeofences[taskId] ?? [];
    
    for (final geofence in geofences) {
      if (geofence.contains(latitude, longitude)) {
        switch (geofence.type) {
          case GeofenceType.pickup:
            // Check if food has been collected
            final taskDoc = await _firestoreService.getDocument('delivery_tasks', taskId);
            final taskData = taskDoc?.data() as Map<String, dynamic>?;
            final isCollected = taskData?['foodCollected'] == true;
            
            return isCollected ? TrackingStatus.collected : TrackingStatus.atPickup;
            
          case GeofenceType.delivery:
            return TrackingStatus.nearDelivery;
            
          case GeofenceType.checkpoint:
            return TrackingStatus.inTransit;
        }
      }
    }
    
    // Check if volunteer is en route to pickup or delivery
    final history = _trackingHistory[volunteerId] ?? [];
    if (history.isNotEmpty) {
      final lastStatus = history.last.status;
      
      switch (lastStatus) {
        case TrackingStatus.atPickup:
        case TrackingStatus.collected:
          return TrackingStatus.inTransit;
        default:
          return TrackingStatus.enRoute;
      }
    }
    
    return TrackingStatus.enRoute;
  }
  
  /// Check for geofence entry/exit events
  Future<void> _checkGeofenceEvents(LocationUpdate update) async {
    final geofences = _taskGeofences[update.taskId] ?? [];
    
    for (final geofence in geofences) {
      final isInside = geofence.contains(update.latitude, update.longitude);
      
      // Check if this is a new entry
      final history = _trackingHistory[update.volunteerId] ?? [];
      final previousUpdate = history.length > 1 ? history[history.length - 2] : null;
      
      bool wasInside = false;
      if (previousUpdate != null) {
        wasInside = geofence.contains(previousUpdate.latitude, previousUpdate.longitude);
      }
      
      // Geofence entry event
      if (isInside && !wasInside) {
        await _handleGeofenceEntry(update, geofence);
      }
      
      // Geofence exit event
      if (!isInside && wasInside) {
        await _handleGeofenceExit(update, geofence);
      }
    }
  }
  
  /// Handle geofence entry events
  Future<void> _handleGeofenceEntry(LocationUpdate update, Geofence geofence) async {
    String eventTitle;
    String eventBody;
    
    switch (geofence.type) {
      case GeofenceType.pickup:
        eventTitle = 'Volunteer at Pickup Location';
        eventBody = 'Volunteer has arrived at the pickup location';
        
        // Update task status
        await _firestoreService.updateDocument('delivery_tasks', update.taskId, {
          'status': 'volunteer_arrived_pickup',
          'volunteerArrivedPickupAt': DateTime.now(),
        });
        break;
        
      case GeofenceType.delivery:
        eventTitle = 'Volunteer at Delivery Location';
        eventBody = 'Volunteer has arrived at the delivery location';
        
        // Update task status
        await _firestoreService.updateDocument('delivery_tasks', update.taskId, {
          'status': 'volunteer_arrived_delivery',
          'volunteerArrivedDeliveryAt': DateTime.now(),
        });
        break;
        
      case GeofenceType.checkpoint:
        eventTitle = 'Checkpoint Reached';
        eventBody = 'Volunteer passed through checkpoint';
        break;
    }
    
    // Send notifications
    await _notificationService.sendToStakeholders(
      taskId: update.taskId,
      title: eventTitle,
      body: eventBody,
      data: {
        'type': 'geofence_entry',
        'geofenceType': geofence.type.toString(),
        'volunteerId': update.volunteerId,
      },
    );
    
    await _auditService.logEvent(
      'geofence_entry',
      'Volunteer ${update.volunteerId} entered ${geofence.type} geofence for task ${update.taskId}',
      riskLevel: RiskLevel.low,
      metadata: {
        'volunteerId': update.volunteerId,
        'taskId': update.taskId,
        'geofenceType': geofence.type.toString(),
        'geofenceId': geofence.id,
      },
    );
  }
  
  /// Handle geofence exit events
  Future<void> _handleGeofenceExit(LocationUpdate update, Geofence geofence) async {
    switch (geofence.type) {
      case GeofenceType.pickup:
        // Assume food was collected when leaving pickup
        await _firestoreService.updateDocument('delivery_tasks', update.taskId, {
          'status': 'food_collected',
          'foodCollectedAt': DateTime.now(),
        });
        
        await _notificationService.sendToStakeholders(
          taskId: update.taskId,
          title: 'Food Collected',
          body: 'Volunteer has collected the food and is en route to delivery',
          data: {
            'type': 'food_collected',
            'volunteerId': update.volunteerId,
          },
        );
        break;
        
      case GeofenceType.delivery:
        // Handle delivery completion
        await _handleDeliveryCompletion(update);
        break;
        
      case GeofenceType.checkpoint:
        // Log checkpoint passage
        break;
    }
  }
  
  /// Handle delivery completion
  Future<void> _handleDeliveryCompletion(LocationUpdate update) async {
    await _firestoreService.updateDocument('delivery_tasks', update.taskId, {
      'status': 'delivered',
      'deliveredAt': DateTime.now(),
      'deliveryCompletedBy': update.volunteerId,
    });
    
    // Stop tracking for this volunteer
    await stopTracking(update.volunteerId);
    
    await _notificationService.sendToStakeholders(
      taskId: update.taskId,
      title: 'Delivery Completed',
      body: 'Food delivery has been completed successfully',
      data: {
        'type': 'delivery_completed',
        'volunteerId': update.volunteerId,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
    
    await _auditService.logEvent(
      'delivery_completed',
      'Delivery completed for task ${update.taskId} by volunteer ${update.volunteerId}',
      riskLevel: RiskLevel.low,
      metadata: {
        'taskId': update.taskId,
        'volunteerId': update.volunteerId,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Store location update in database
  Future<void> _storeLocationUpdate(LocationUpdate update) async {
    await _firestoreService.addDocument('location_updates', update.toMap());
    
    // Also update the current location in the volunteer profile
    await _firestoreService.updateDocument('volunteer_profiles', update.volunteerId, {
      'currentLocation': {
        'latitude': update.latitude,
        'longitude': update.longitude,
        'timestamp': update.timestamp,
      },
      'lastLocationUpdate': update.timestamp,
    });
  }
  
  /// Broadcast location update to real-time listeners
  Future<void> _broadcastLocationUpdate(LocationUpdate update) async {
    // Update real-time tracking document for live updates
    await _firestoreService.setDocument('real_time_tracking', update.taskId, {
      'volunteerId': update.volunteerId,
      'currentLocation': {
        'latitude': update.latitude,
        'longitude': update.longitude,
      },
      'status': update.status.toString(),
      'lastUpdate': update.timestamp,
      'metadata': update.metadata,
    });
  }
  
  /// Calculate tracking metrics for completed task
  Future<TrackingMetrics> _calculateTrackingMetrics(String volunteerId, String taskId) async {
    final history = _trackingHistory[volunteerId] ?? [];
    if (history.isEmpty) {
      return TrackingMetrics(
        taskId: taskId,
        totalDistance: 0,
        totalDuration: Duration.zero,
        pickupWaitTime: Duration.zero,
        transitTime: Duration.zero,
        deliveryWaitTime: Duration.zero,
        averageSpeed: 0,
        locationUpdates: 0,
        geofenceEvents: [],
        additionalMetrics: {},
      );
    }
    
    // Calculate total distance
    double totalDistance = 0;
    for (int i = 1; i < history.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        history[i-1].latitude, history[i-1].longitude,
        history[i].latitude, history[i].longitude,
      );
    }
    totalDistance /= 1000; // Convert to kilometers
    
    // Calculate duration
    final totalDuration = history.last.timestamp.difference(history.first.timestamp);
    
    // Calculate average speed
    final averageSpeed = totalDuration.inHours > 0 ? totalDistance / totalDuration.inHours : 0;
    
    // Calculate phase durations
    Duration pickupWaitTime = Duration.zero;
    Duration transitTime = Duration.zero;
    Duration deliveryWaitTime = Duration.zero;
    
    DateTime? pickupArrival;
    DateTime? pickupDeparture;
    DateTime? deliveryArrival;
    
    for (final update in history) {
      switch (update.status) {
        case TrackingStatus.atPickup:
          pickupArrival ??= update.timestamp;
          break;
        case TrackingStatus.collected:
          pickupDeparture = update.timestamp;
          if (pickupArrival != null) {
            pickupWaitTime = pickupDeparture.difference(pickupArrival);
          }
          break;
        case TrackingStatus.nearDelivery:
          deliveryArrival = update.timestamp;
          if (pickupDeparture != null) {
            transitTime = deliveryArrival.difference(pickupDeparture);
          }
          break;
        case TrackingStatus.delivered:
          if (deliveryArrival != null) {
            deliveryWaitTime = update.timestamp.difference(deliveryArrival);
          }
          break;
        default:
          break;
      }
    }
    
    return TrackingMetrics(
      taskId: taskId,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      pickupWaitTime: pickupWaitTime,
      transitTime: transitTime,
      deliveryWaitTime: deliveryWaitTime,
      averageSpeed: averageSpeed,
      locationUpdates: history.length,
      geofenceEvents: [], // Will be populated from audit logs
      additionalMetrics: {
        'maxSpeed': history.map((h) => h.speed ?? 0).reduce((a, b) => a > b ? a : b),
        'statusChanges': _countStatusChanges(history),
      },
    );
  }
  
  int _countStatusChanges(List<LocationUpdate> history) {
    if (history.length < 2) return 0;
    
    int changes = 0;
    for (int i = 1; i < history.length; i++) {
      if (history[i].status != history[i-1].status) {
        changes++;
      }
    }
    return changes;
  }
  
  /// Store tracking metrics for analytics
  Future<void> _storeTrackingMetrics(TrackingMetrics metrics) async {
    await _firestoreService.addDocument('tracking_metrics', metrics.toMap());
  }
  
  /// Get real-time tracking stream for a task
  Stream<DocumentSnapshot> getTrackingStream(String taskId) {
    return _firestoreService.getDocumentStream('real_time_tracking', taskId);
  }
  
  /// Get tracking history for a task
  Future<List<LocationUpdate>> getTrackingHistory(String taskId) async {
    final docs = await _firestoreService.queryCollection(
      'location_updates',
      where: [{'field': 'taskId', 'operator': '==', 'value': taskId}],
      orderBy: [{'field': 'timestamp', 'descending': false}],
    );
    
    return docs.map((doc) => LocationUpdate.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
  
  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    for (final timer in _activeTrackers.values) {
      timer.cancel();
    }
    _activeTrackers.clear();
    _trackingHistory.clear();
    _taskGeofences.clear();
  }
}