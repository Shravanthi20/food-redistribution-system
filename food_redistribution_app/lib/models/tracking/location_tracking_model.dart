import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../enums.dart';

// Store each location where volunteer stopped by
class LocationUpdate {
  final String id;
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
    required this.id,
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

  // Convert to format Firebase understands
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volunteerId': volunteerId,
      'taskId': taskId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'metadata': metadata,
    };
  }

  // Read back from Firebase
  factory LocationUpdate.fromMap(Map<String, dynamic> map) {
    return LocationUpdate(
      id: map['id'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      taskId: map['taskId'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TrackingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TrackingStatus.idle,
      ),
      metadata: map['metadata'],
    );
  }
}

/// Represents a geofence event (entry/exit) - When volunteer enters or leaves pickup/delivery area
class GeofenceEvent {
  final String id;
  final String volunteerId;
  final String taskId;
  final GeofenceType type;
  final String eventType; // entry, exit
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final int radius; // in meters

  GeofenceEvent({
    required this.id,
    required this.volunteerId,
    required this.taskId,
    required this.type,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.radius,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volunteerId': volunteerId,
      'taskId': taskId,
      'type': type.name,
      'eventType': eventType,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'radius': radius,
    };
  }

  factory GeofenceEvent.fromMap(Map<String, dynamic> map) {
    return GeofenceEvent(
      id: map['id'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      taskId: map['taskId'] ?? '',
      type: GeofenceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GeofenceType.checkpoint,
      ),
      eventType: map['eventType'] ?? 'entry',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      radius: map['radius'] ?? 100,
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
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'taskId': taskId,
      'label': label,
      'metadata': metadata,
    };
  }
  
  factory Geofence.fromMap(Map<String, dynamic> map, {String? id}) {
    return Geofence(
      id: id ?? map['id'] ?? '',
      type: GeofenceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GeofenceType.checkpoint,
      ),
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      radius: (map['radius'] ?? 100).toDouble(),
      taskId: map['taskId'] ?? '',
      label: map['label'],
      metadata: map['metadata'],
    );
  }
}

// Summary of entire delivery journey
class TrackingMetrics {
  final String taskId;
  final String volunteerId;
  final double totalDistance; // in km
  final Duration totalDuration;
  final Duration pickupWaitTime;
  final Duration transitTime;
  final Duration deliveryWaitTime;
  final double averageSpeed; // km/h
  final int locationUpdates;
  final List<String> geofenceEvents;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> additionalMetrics;

  TrackingMetrics({
    required this.taskId,
    required this.volunteerId,
    required this.totalDistance,
    required this.totalDuration,
    required this.pickupWaitTime,
    required this.transitTime,
    required this.deliveryWaitTime,
    required this.averageSpeed,
    required this.locationUpdates,
    required this.geofenceEvents,
    required this.startTime,
    this.endTime,
    this.additionalMetrics = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'volunteerId': volunteerId,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration.inMinutes,
      'pickupWaitTime': pickupWaitTime.inMinutes,
      'transitTime': transitTime.inMinutes,
      'deliveryWaitTime': deliveryWaitTime.inMinutes,
      'averageSpeed': averageSpeed,
      'locationUpdates': locationUpdates,
      'geofenceEvents': geofenceEvents,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'additionalMetrics': additionalMetrics,
    };
  }

  factory TrackingMetrics.fromMap(Map<String, dynamic> map) {
    return TrackingMetrics(
      taskId: map['taskId'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      totalDistance: (map['totalDistance'] ?? 0).toDouble(),
      totalDuration: Duration(minutes: map['totalDuration'] ?? 0),
      pickupWaitTime: Duration(minutes: map['pickupWaitTime'] ?? 0),
      transitTime: Duration(minutes: map['transitTime'] ?? 0),
      deliveryWaitTime: Duration(minutes: map['deliveryWaitTime'] ?? 0),
      averageSpeed: (map['averageSpeed'] ?? 0).toDouble(),
      locationUpdates: map['locationUpdates'] ?? 0,
      geofenceEvents: List<String>.from(map['geofenceEvents'] ?? []),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      additionalMetrics: Map<String, dynamic>.from(map['additionalMetrics'] ?? {}),
    );
  }
}

// When delivery gets stuck or something goes wrong
class DelayAlert {
  final String id;
  final String taskId;
  final String volunteerId;
  final String type; // delay, failure, reassignment
  final String severity; // low, medium, high, critical
  final String reason; // traffic, volunteer_unavailable, etc.
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? resolutionAction;
  final Duration? estimatedDelay;

  DelayAlert({
    required this.id,
    required this.taskId,
    required this.volunteerId,
    required this.type,
    required this.severity,
    required this.reason,
    required this.detectedAt,
    this.resolvedAt,
    this.resolutionAction,
    this.estimatedDelay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'volunteerId': volunteerId,
      'type': type,
      'severity': severity,
      'reason': reason,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionAction': resolutionAction,
      'estimatedDelay': estimatedDelay?.inMinutes,
    };
  }

  factory DelayAlert.fromMap(Map<String, dynamic> map) {
    return DelayAlert(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      type: map['type'] ?? 'delay',
      severity: map['severity'] ?? 'medium',
      reason: map['reason'] ?? 'unknown',
      detectedAt: (map['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionAction: map['resolutionAction'],
      estimatedDelay: map['estimatedDelay'] != null
          ? Duration(minutes: map['estimatedDelay'])
          : null,
    );
  }
}

// Temporary storage when phone has no internet
class OfflineUpdate {
  final String id;
  final String type; // location, status, metric
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool isSynced;

  OfflineUpdate({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.syncedAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'isSynced': isSynced,
    };
  }

  factory OfflineUpdate.fromMap(Map<String, dynamic> map) {
    return OfflineUpdate(
      id: map['id'] ?? '',
      type: map['type'] ?? 'location',
      data: map['data'] ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      syncedAt: (map['syncedAt'] as Timestamp?)?.toDate(),
      isSynced: map['isSynced'] ?? false,
    );
  }
}

// Current status of tracking
class TrackingState {
  final bool isTracking;
  final bool isOnline;
  final LocationUpdate? currentLocation;
  final TrackingStatus? currentStatus;
  final String? currentTaskId;
  final int pendingUpdates;
  final DateTime? lastSync;

  TrackingState({
    required this.isTracking,
    required this.isOnline,
    this.currentLocation,
    this.currentStatus,
    this.currentTaskId,
    required this.pendingUpdates,
    this.lastSync,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isOnline,
    LocationUpdate? currentLocation,
    TrackingStatus? currentStatus,
    String? currentTaskId,
    int? pendingUpdates,
    DateTime? lastSync,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      currentStatus: currentStatus ?? this.currentStatus,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      pendingUpdates: pendingUpdates ?? this.pendingUpdates,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class TrackingSession {
  final String id;
  final String volunteerId;
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final TrackingStatus status;
  final List<LocationUpdate> updates;
  final Map<String, dynamic>? metadata;

  TrackingSession({
    required this.id,
    required this.volunteerId,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.updates = const [],
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volunteerId': volunteerId,
      'taskId': taskId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.name,
      'metadata': metadata,
    };
  }
}
