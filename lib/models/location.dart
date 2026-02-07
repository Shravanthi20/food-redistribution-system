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
}
