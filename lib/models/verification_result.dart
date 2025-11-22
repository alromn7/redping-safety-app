import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';
import 'sos_session.dart'; // For LocationInfo

/// Enumeration of detection types
enum DetectionType { crash, fall }

/// Enumeration of detection reasons
enum DetectionReason {
  none,
  sharpDeceleration,
  highJerk,
  impactSpike,
  stationaryImpact,
  freeFallImpact,
}

/// Enumeration of verification outcomes
enum VerificationOutcome {
  userConfirmedOK,
  falseAlarmDetected,
  genuineIncident,
  uncertainIncident,
  noResponse,
}

/// Enumeration of user interaction types
enum InteractionType {
  cancelTap,
  okResponse,
  screenTouch,
  deviceMovement,
  voiceResponse,
}

/// Detection context information
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

  /// Create copy with updated fields
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

/// Detection event information
class DetectionEvent extends Equatable {
  final DetectionType type;
  final DetectionReason reason;
  final DetectionContext context;
  final DateTime timestamp;

  DetectionEvent({
    required this.type,
    required this.reason,
    required this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [type, reason, context, timestamp];
}

/// Verification result from AI analysis
class VerificationResult extends Equatable {
  final VerificationOutcome outcome;
  final double confidence; // 0.0 to 1.0
  final String reason;
  final DetectionContext context;
  final DateTime timestamp;
  final List<String>? evidencePoints;
  final Map<String, dynamic>? analysisData;

  VerificationResult({
    required this.outcome,
    required this.confidence,
    required this.reason,
    required this.context,
    DateTime? timestamp,
    this.evidencePoints,
    this.analysisData,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create copy with updated fields
  VerificationResult copyWith({
    VerificationOutcome? outcome,
    double? confidence,
    String? reason,
    DetectionContext? context,
    DateTime? timestamp,
    List<String>? evidencePoints,
    Map<String, dynamic>? analysisData,
  }) {
    return VerificationResult(
      outcome: outcome ?? this.outcome,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      evidencePoints: evidencePoints ?? this.evidencePoints,
      analysisData: analysisData ?? this.analysisData,
    );
  }

  /// Check if this is a genuine incident requiring SOS
  /// TEST MODE: Lower threshold to 30% for easier testing (vs 60% production)
  bool get requiresSOS {
    // LAB: When dialogs are suppressed, never escalate to SOS from verification
    if (AppConstants.labSuppressAllSOSDialogs) {
      return false;
    }

    // Production threshold: only escalate if genuine OR uncertain with high confidence
    return outcome == VerificationOutcome.genuineIncident ||
        (outcome == VerificationOutcome.uncertainIncident && confidence >= 0.6);
  }

  /// Get confidence level description
  String get confidenceDescription {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  /// Get outcome description
  String get outcomeDescription {
    switch (outcome) {
      case VerificationOutcome.userConfirmedOK:
        return 'User confirmed they are OK';
      case VerificationOutcome.falseAlarmDetected:
        return 'False alarm detected by AI';
      case VerificationOutcome.genuineIncident:
        return 'Genuine incident confirmed';
      case VerificationOutcome.uncertainIncident:
        return 'Uncertain - requires attention';
      case VerificationOutcome.noResponse:
        return 'No response from user';
    }
  }

  @override
  List<Object?> get props => [
    outcome,
    confidence,
    reason,
    context,
    timestamp,
    evidencePoints,
    analysisData,
  ];
}

/// Verification statistics for analytics
class VerificationStats extends Equatable {
  final int totalDetections;
  final int falseAlarms;
  final int genuineIncidents;
  final int userConfirmed;
  final double averageConfidence;
  final DateTime lastUpdated;

  const VerificationStats({
    this.totalDetections = 0,
    this.falseAlarms = 0,
    this.genuineIncidents = 0,
    this.userConfirmed = 0,
    this.averageConfidence = 0.0,
    required this.lastUpdated,
  });

  /// Calculate false alarm rate
  double get falseAlarmRate {
    return totalDetections > 0 ? falseAlarms / totalDetections : 0.0;
  }

  /// Calculate accuracy rate
  double get accuracyRate {
    return totalDetections > 0
        ? (genuineIncidents + userConfirmed) / totalDetections
        : 0.0;
  }

  /// Add detection result to stats
  VerificationStats addResult(VerificationResult result) {
    return VerificationStats(
      totalDetections: totalDetections + 1,
      falseAlarms:
          falseAlarms +
          (result.outcome == VerificationOutcome.falseAlarmDetected ? 1 : 0),
      genuineIncidents:
          genuineIncidents +
          (result.outcome == VerificationOutcome.genuineIncident ? 1 : 0),
      userConfirmed:
          userConfirmed +
          (result.outcome == VerificationOutcome.userConfirmedOK ? 1 : 0),
      averageConfidence:
          ((averageConfidence * totalDetections) + result.confidence) /
          (totalDetections + 1),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    totalDetections,
    falseAlarms,
    genuineIncidents,
    userConfirmed,
    averageConfidence,
    lastUpdated,
  ];
}
