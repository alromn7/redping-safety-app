import 'package:equatable/equatable.dart';
import 'sos_session.dart'; // For LocationInfo

/// Enumeration of detection types (heuristic ACFD)
enum DetectionType { crash, fall }

/// Enumeration of detection reasons (heuristic ACFD)
enum DetectionReason {
  none,
  sharpDeceleration,
  highJerk,
  impactSpike,
  stationaryImpact,
  freeFallImpact,
}

/// Detection context information captured at the start of a detection window.
class DetectionContext extends Equatable {
  final DetectionType type;
  final DetectionReason reason;
  final DateTime timestamp;
  final double magnitude;
  final double? deceleration;
  final double? jerk;
  final LocationInfo? location;
  final Map<String, dynamic>? additionalData;

  const DetectionContext({
    required this.type,
    required this.reason,
    required this.timestamp,
    required this.magnitude,
    this.deceleration,
    this.jerk,
    this.location,
    this.additionalData,
  });

  DetectionContext copyWith({
    DetectionType? type,
    DetectionReason? reason,
    DateTime? timestamp,
    double? magnitude,
    double? deceleration,
    double? jerk,
    LocationInfo? location,
    Map<String, dynamic>? additionalData,
  }) {
    return DetectionContext(
      type: type ?? this.type,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      magnitude: magnitude ?? this.magnitude,
      deceleration: deceleration ?? this.deceleration,
      jerk: jerk ?? this.jerk,
      location: location ?? this.location,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  List<Object?> get props => [
    type,
    reason,
    timestamp,
    magnitude,
    deceleration,
    jerk,
    location,
    additionalData,
  ];
}
