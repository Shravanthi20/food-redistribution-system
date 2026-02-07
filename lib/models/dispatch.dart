import 'enums.dart';
import 'volunteer_profile.dart';

class DispatchCriteria {
  final double maxDistance;
  final List<VehicleType> allowedTransport;
  final int minRating;
  final bool requiresExperience;
  final DispatchPriority priority;
  final DateTime? requiredBy;
  
  const DispatchCriteria({
    this.maxDistance = 25.0,
    this.allowedTransport = const [VehicleType.car, VehicleType.motorcycle],
    this.minRating = 3,
    this.requiresExperience = false,
    this.priority = DispatchPriority.scheduled,
    this.requiredBy,
  });
}

class DispatchResult {
  final String volunteerId;
  final String taskId;
  final double score;
  final double distance;
  final double estimatedDuration;
  final VolunteerProfile? volunteer;
  final String reasoning;
  final DateTime estimatedArrival;
  final Map<String, dynamic> metadata;
  
  DispatchResult({
    required this.volunteerId,
    required this.taskId,
    required this.score,
    required this.distance,
    required this.estimatedDuration,
    this.volunteer,
    required this.reasoning,
    required this.estimatedArrival,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'taskId': taskId,
      'score': score,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'reasoning': reasoning,
      'estimatedArrival': estimatedArrival.toIso8601String(),
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

class DeliveryTask {
  final String id;
  final String donationId;
  final String pickupAddress;
  final String deliveryAddress;
  final Map<String, double> pickupLocation;
  final Map<String, double> deliveryLocation;
  final DateTime scheduledTime;
  final DispatchPriority priority;
  final String? specialInstructions;
  final List<String> requiredSkills;
  final double estimatedWeight;
  final int estimatedVolume;
  final DeliveryStatus status;
  final String? assignedVolunteerId;
  
  DeliveryTask({
    required this.id,
    required this.donationId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.scheduledTime,
    required this.priority,
    this.specialInstructions,
    this.requiredSkills = const [],
    this.estimatedWeight = 0.0,
    this.estimatedVolume = 0,
    this.status = DeliveryStatus.pending,
    this.assignedVolunteerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'scheduledTime': scheduledTime.toIso8601String(),
      'priority': priority.name,
      'specialInstructions': specialInstructions,
      'requiredSkills': requiredSkills,
      'estimatedWeight': estimatedWeight,
      'estimatedVolume': estimatedVolume,
      'status': status.name,
      'assignedVolunteerId': assignedVolunteerId,
    };
  }

  factory DeliveryTask.fromMap(Map<String, dynamic> map, {String? id}) {
    return DeliveryTask(
      id: id ?? map['id'] ?? '',
      donationId: map['donationId'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      pickupLocation: Map<String, double>.from(map['pickupLocation'] ?? {}),
      deliveryLocation: Map<String, double>.from(map['deliveryLocation'] ?? {}),
      scheduledTime: map['scheduledTime'] != null ? DateTime.parse(map['scheduledTime']) : DateTime.now(),
      priority: DispatchPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => DispatchPriority.scheduled),
      specialInstructions: map['specialInstructions'],
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      estimatedWeight: (map['estimatedWeight'] as num?)?.toDouble() ?? 0.0,
      estimatedVolume: map['estimatedVolume'] ?? 0,
      status: DeliveryStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DeliveryStatus.pending),
      assignedVolunteerId: map['assignedVolunteerId'],
    );
  }
}
