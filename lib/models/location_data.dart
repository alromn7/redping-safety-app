import 'package:equatable/equatable.dart';

/// Model representing location data
class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? country;
  final double? accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.country,
    this.accuracy,
    required this.timestamp,
  });

  /// Create a copy of this location data with updated fields
  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      accuracy: json['accuracy'] as double?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    address,
    city,
    state,
    country,
    accuracy,
    timestamp,
  ];
}
