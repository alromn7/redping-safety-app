import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Sensor reading data structure
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double? magnitude;
  final String? sensorType;

  const SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    this.magnitude,
    this.sensorType,
  });

  /// Calculate magnitude from x, y, z components
  double get calculatedMagnitude => magnitude ?? _calculateMagnitude();

  double _calculateMagnitude() {
    return (x * x + y * y + z * z).sqrt();
  }

  /// Create copy with updated fields
  SensorReading copyWith({
    DateTime? timestamp,
    double? x,
    double? y,
    double? z,
    double? magnitude,
    String? sensorType,
  }) {
    return SensorReading(
      timestamp: timestamp ?? this.timestamp,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      magnitude: magnitude ?? this.magnitude,
      sensorType: sensorType ?? this.sensorType,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'x': x,
      'y': y,
      'z': z,
      'magnitude': magnitude,
      'sensorType': sensorType,
    };
  }

  /// Create from JSON
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      magnitude: json['magnitude'] as double?,
      sensorType: json['sensorType'] as String?,
    );
  }

  @override
  List<Object?> get props => [timestamp, x, y, z, magnitude, sensorType];
}

/// Extension for math operations
extension SensorMath on double {
  double sqrt() {
    return math.sqrt(this);
  }
}
