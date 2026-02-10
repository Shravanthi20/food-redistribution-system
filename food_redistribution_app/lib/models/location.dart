import 'dart:math' as math;

class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? landmark;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.landmark,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] ?? '',
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'landmark': landmark,
    };
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  Map<String, double> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Calculate distance to another location using the Haversine formula
  /// Returns distance in kilometers
  double distanceTo(Location other) {
    const double earthRadius = 6371.0; // km
    
    // Convert to radians
    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLon = (other.longitude - longitude) * math.pi / 180;
    
    // Haversine formula
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) *
              math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}
