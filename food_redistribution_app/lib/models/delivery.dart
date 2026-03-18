import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_schema.dart';
import 'enums.dart';
import 'location.dart';

/// Delivery model for active delivery tasks
/// Stored in /deliveries collection
class Delivery {
  final String id;
  final String donationId;
  final String donorId;
  final String ngoId;
  final String? volunteerId;
  final DeliveryStatus status;
  
  // Locations
  final Location pickupLocation;
  final Location dropoffLocation;
  
  // Timing
  final DateTime? scheduledPickup;
  final DateTime? actualPickup;
  final DateTime? scheduledDelivery;
  final DateTime? actualDelivery;
  
  // Task details
  final String? notes;
  final int? estimatedDurationMinutes;
  final double? distanceKm;
  final String? vehicleRequired;
  
  // Ratings and feedback
  final double? donorRating;
  final double? ngoRating;
  final double? volunteerRating;
  final String? donorFeedback;
  final String? ngoFeedback;
  
  // Hygiene verification
  final Map<String, dynamic>? hygieneChecklist;
  final bool hygieneVerified;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  Delivery({
    required this.id,
    required this.donationId,
    required this.donorId,
    required this.ngoId,
    this.volunteerId,
    this.status = DeliveryStatus.pending,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.scheduledPickup,
    this.actualPickup,
    this.scheduledDelivery,
    this.actualDelivery,
    this.notes,
    this.estimatedDurationMinutes,
    this.distanceKm,
    this.vehicleRequired,
    this.donorRating,
    this.ngoRating,
    this.volunteerRating,
    this.donorFeedback,
    this.ngoFeedback,
    this.hygieneChecklist,
    this.hygieneVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Delivery.fromFirestore(DocumentSnapshot doc) {
    return Delivery.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  factory Delivery.fromMap(Map<String, dynamic> data, {String? id}) {
    return Delivery(
      id: id ?? data['id'] ?? '',
      donationId: data[Fields.donationId] ?? '',
      donorId: data[Fields.donorId] ?? '',
      ngoId: data[Fields.ngoId] ?? '',
      volunteerId: data[Fields.volunteerId],
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == data[Fields.status],
        orElse: () => DeliveryStatus.pending,
      ),
      pickupLocation: data[Fields.pickupLocation] != null
          ? Location.fromJson(data[Fields.pickupLocation])
          : Location(latitude: 0, longitude: 0, address: ''),
      dropoffLocation: data['dropoffLocation'] != null
          ? Location.fromJson(data['dropoffLocation'])
          : Location(latitude: 0, longitude: 0, address: ''),
      scheduledPickup: _parseTimestamp(data['scheduledPickup']),
      actualPickup: _parseTimestamp(data['actualPickup']),
      scheduledDelivery: _parseTimestamp(data['scheduledDelivery']),
      actualDelivery: _parseTimestamp(data['actualDelivery']),
      notes: data['notes'],
      estimatedDurationMinutes: data['estimatedDurationMinutes'],
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      vehicleRequired: data['vehicleRequired'],
      donorRating: (data['donorRating'] as num?)?.toDouble(),
      ngoRating: (data['ngoRating'] as num?)?.toDouble(),
      volunteerRating: (data['volunteerRating'] as num?)?.toDouble(),
      donorFeedback: data['donorFeedback'],
      ngoFeedback: data['ngoFeedback'],
      hygieneChecklist: data['hygieneChecklist'],
      hygieneVerified: data['hygieneVerified'] ?? false,
      createdAt: _parseTimestamp(data[Fields.createdAt]) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data[Fields.updatedAt]),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      Fields.donationId: donationId,
      Fields.donorId: donorId,
      Fields.ngoId: ngoId,
      Fields.volunteerId: volunteerId,
      Fields.status: status.name,
      Fields.pickupLocation: pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'scheduledPickup': scheduledPickup != null ? Timestamp.fromDate(scheduledPickup!) : null,
      'actualPickup': actualPickup != null ? Timestamp.fromDate(actualPickup!) : null,
      'scheduledDelivery': scheduledDelivery != null ? Timestamp.fromDate(scheduledDelivery!) : null,
      'actualDelivery': actualDelivery != null ? Timestamp.fromDate(actualDelivery!) : null,
      'notes': notes,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'distanceKm': distanceKm,
      'vehicleRequired': vehicleRequired,
      'donorRating': donorRating,
      'ngoRating': ngoRating,
      'volunteerRating': volunteerRating,
      'donorFeedback': donorFeedback,
      'ngoFeedback': ngoFeedback,
      'hygieneChecklist': hygieneChecklist,
      'hygieneVerified': hygieneVerified,
      Fields.createdAt: Timestamp.fromDate(createdAt),
      Fields.updatedAt: updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Delivery copyWith({
    String? donationId,
    String? donorId,
    String? ngoId,
    String? volunteerId,
    DeliveryStatus? status,
    Location? pickupLocation,
    Location? dropoffLocation,
    DateTime? scheduledPickup,
    DateTime? actualPickup,
    DateTime? scheduledDelivery,
    DateTime? actualDelivery,
    String? notes,
    int? estimatedDurationMinutes,
    double? distanceKm,
    String? vehicleRequired,
    double? donorRating,
    double? ngoRating,
    double? volunteerRating,
    String? donorFeedback,
    String? ngoFeedback,
    Map<String, dynamic>? hygieneChecklist,
    bool? hygieneVerified,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id,
      donationId: donationId ?? this.donationId,
      donorId: donorId ?? this.donorId,
      ngoId: ngoId ?? this.ngoId,
      volunteerId: volunteerId ?? this.volunteerId,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      scheduledPickup: scheduledPickup ?? this.scheduledPickup,
      actualPickup: actualPickup ?? this.actualPickup,
      scheduledDelivery: scheduledDelivery ?? this.scheduledDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      notes: notes ?? this.notes,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      vehicleRequired: vehicleRequired ?? this.vehicleRequired,
      donorRating: donorRating ?? this.donorRating,
      ngoRating: ngoRating ?? this.ngoRating,
      volunteerRating: volunteerRating ?? this.volunteerRating,
      donorFeedback: donorFeedback ?? this.donorFeedback,
      ngoFeedback: ngoFeedback ?? this.ngoFeedback,
      hygieneChecklist: hygieneChecklist ?? this.hygieneChecklist,
      hygieneVerified: hygieneVerified ?? this.hygieneVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  // Status helpers
  bool get isPending => status == DeliveryStatus.pending;
  bool get isAssigned => status == DeliveryStatus.assigned;
  bool get isPickedUp => status == DeliveryStatus.pickedUp;
  bool get isInTransit => status == DeliveryStatus.inTransit;
  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isCancelled => status == DeliveryStatus.cancelled;
  bool get isActive => !isDelivered && !isCancelled;

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Delivery checkpoint for tracking progress
class DeliveryCheckpoint {
  final String id;
  final String deliveryId;
  final DeliveryStatus status;
  final Location location;
  final DateTime timestamp;
  final String? note;
  final String? photoUrl;

  DeliveryCheckpoint({
    required this.id,
    required this.deliveryId,
    required this.status,
    required this.location,
    required this.timestamp,
    this.note,
    this.photoUrl,
  });

  factory DeliveryCheckpoint.fromMap(Map<String, dynamic> data, {String? id}) {
    return DeliveryCheckpoint(
      id: id ?? data['id'] ?? '',
      deliveryId: data['deliveryId'] ?? '',
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      location: data['location'] != null
          ? Location.fromJson(data['location'])
          : Location(latitude: 0, longitude: 0, address: ''),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryId': deliveryId,
      'status': status.name,
      'location': location.toJson(),
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'photoUrl': photoUrl,
    };
  }
}
