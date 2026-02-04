import 'package:cloud_firestore/cloud_firestore.dart';

/// Risk level classification for fraud detection
enum FraudRiskLevel { low, medium, high, critical }

extension FraudRiskLevelExt on FraudRiskLevel {
  String get displayName {
    switch (this) {
      case FraudRiskLevel.low:
        return 'Low Risk';
      case FraudRiskLevel.medium:
        return 'Medium Risk';
      case FraudRiskLevel.high:
        return 'High Risk';
      case FraudRiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get icon {
    switch (this) {
      case FraudRiskLevel.low:
        return '✅';
      case FraudRiskLevel.medium:
        return '⚠️';
      case FraudRiskLevel.high:
        return '🔴';
      case FraudRiskLevel.critical:
        return '🚨';
    }
  }

  bool get requiresManualReview {
    return this == FraudRiskLevel.high || this == FraudRiskLevel.critical;
  }

  bool get autoReject {
    return this == FraudRiskLevel.critical;
  }
}

/// Red flag categories for fraud detection
enum RedFlagCategory {
  frequencyPattern, // Multiple claims in short time
  locationAnomaly, // GPS inconsistencies
  sensorValidation, // Fake crash/fall detection
  behavioralPattern, // Suspicious timing/patterns
  costAnomaly, // Inflated costs
  timePattern, // Weekend/holiday patterns
}

/// Individual red flag detected
class RedFlag {
  final RedFlagCategory category;
  final String description;
  final double severity; // 0.0 - 1.0
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;

  const RedFlag({
    required this.category,
    required this.description,
    required this.severity,
    required this.detectedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'category': category.name,
    'description': description,
    'severity': severity,
    'detectedAt': detectedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory RedFlag.fromJson(Map<String, dynamic> json) => RedFlag(
    category: RedFlagCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => RedFlagCategory.behavioralPattern,
    ),
    description: json['description'] as String,
    severity: (json['severity'] as num).toDouble(),
    detectedAt: DateTime.parse(json['detectedAt'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Comprehensive fraud risk score for an incident
class FraudRiskScore {
  final String incidentId;
  final String userId;
  final FraudRiskLevel level;
  final double score; // 0.0 - 1.0 (0 = no risk, 1 = definite fraud)
  final List<RedFlag> redFlags;
  final bool requiresManualReview;
  final bool autoReject;
  final DateTime calculatedAt;
  final Map<String, dynamic> analysisData;

  // Risk score breakdown
  final double frequencyScore;
  final double locationScore;
  final double sensorScore;
  final double behavioralScore;
  final double costScore;
  final double timeScore;

  const FraudRiskScore({
    required this.incidentId,
    required this.userId,
    required this.level,
    required this.score,
    required this.redFlags,
    required this.requiresManualReview,
    required this.autoReject,
    required this.calculatedAt,
    required this.analysisData,
    required this.frequencyScore,
    required this.locationScore,
    required this.sensorScore,
    required this.behavioralScore,
    required this.costScore,
    required this.timeScore,
  });

  /// Determine risk level from score
  static FraudRiskLevel calculateRiskLevel(double score) {
    if (score >= 0.8) return FraudRiskLevel.critical;
    if (score >= 0.6) return FraudRiskLevel.high;
    if (score >= 0.4) return FraudRiskLevel.medium;
    return FraudRiskLevel.low;
  }

  /// Create score with calculated risk level
  factory FraudRiskScore.calculate({
    required String incidentId,
    required String userId,
    required double score,
    required List<RedFlag> redFlags,
    required DateTime calculatedAt,
    required Map<String, dynamic> analysisData,
    required double frequencyScore,
    required double locationScore,
    required double sensorScore,
    required double behavioralScore,
    required double costScore,
    required double timeScore,
  }) {
    final level = calculateRiskLevel(score);
    return FraudRiskScore(
      incidentId: incidentId,
      userId: userId,
      level: level,
      score: score,
      redFlags: redFlags,
      requiresManualReview: level.requiresManualReview,
      autoReject: level.autoReject,
      calculatedAt: calculatedAt,
      analysisData: analysisData,
      frequencyScore: frequencyScore,
      locationScore: locationScore,
      sensorScore: sensorScore,
      behavioralScore: behavioralScore,
      costScore: costScore,
      timeScore: timeScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'incidentId': incidentId,
    'userId': userId,
    'level': level.name,
    'score': score,
    'redFlags': redFlags.map((flag) => flag.toJson()).toList(),
    'requiresManualReview': requiresManualReview,
    'autoReject': autoReject,
    'calculatedAt': Timestamp.fromDate(calculatedAt),
    'analysisData': analysisData,
    'breakdown': {
      'frequency': frequencyScore,
      'location': locationScore,
      'sensor': sensorScore,
      'behavioral': behavioralScore,
      'cost': costScore,
      'time': timeScore,
    },
  };

  factory FraudRiskScore.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    return FraudRiskScore(
      incidentId: json['incidentId'] as String,
      userId: json['userId'] as String,
      level: FraudRiskLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => FraudRiskLevel.low,
      ),
      score: (json['score'] as num).toDouble(),
      redFlags:
          (json['redFlags'] as List<dynamic>?)
              ?.map((flag) => RedFlag.fromJson(flag as Map<String, dynamic>))
              .toList() ??
          [],
      requiresManualReview: json['requiresManualReview'] as bool? ?? false,
      autoReject: json['autoReject'] as bool? ?? false,
      calculatedAt: (json['calculatedAt'] as Timestamp).toDate(),
      analysisData: json['analysisData'] as Map<String, dynamic>? ?? {},
      frequencyScore: (breakdown['frequency'] as num?)?.toDouble() ?? 0.0,
      locationScore: (breakdown['location'] as num?)?.toDouble() ?? 0.0,
      sensorScore: (breakdown['sensor'] as num?)?.toDouble() ?? 0.0,
      behavioralScore: (breakdown['behavioral'] as num?)?.toDouble() ?? 0.0,
      costScore: (breakdown['cost'] as num?)?.toDouble() ?? 0.0,
      timeScore: (breakdown['time'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Human-readable summary
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln(
      '${level.icon} ${level.displayName} (${(score * 100).toStringAsFixed(1)}%)',
    );

    if (redFlags.isNotEmpty) {
      buffer.writeln('\nRed Flags:');
      for (final flag in redFlags) {
        buffer.writeln('  • ${flag.description}');
      }
    }

    if (requiresManualReview) {
      buffer.writeln('\n⚠️ Requires Manual Review');
    }

    if (autoReject) {
      buffer.writeln('\n🚫 Auto-Reject Recommended');
    }

    return buffer.toString();
  }
}
