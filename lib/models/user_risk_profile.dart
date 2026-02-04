import 'package:cloud_firestore/cloud_firestore.dart';

/// Risk indicator detected for user
class RiskIndicator {
  final String type;
  final String description;
  final DateTime detectedAt;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final bool resolved;
  final DateTime? resolvedAt;

  const RiskIndicator({
    required this.type,
    required this.description,
    required this.detectedAt,
    required this.severity,
    this.resolved = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'detectedAt': Timestamp.fromDate(detectedAt),
    'severity': severity,
    'resolved': resolved,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
  };

  factory RiskIndicator.fromJson(Map<String, dynamic> json) => RiskIndicator(
    type: json['type'] as String,
    description: json['description'] as String,
    detectedAt: (json['detectedAt'] as Timestamp).toDate(),
    severity: json['severity'] as String,
    resolved: json['resolved'] as bool? ?? false,
    resolvedAt: json['resolvedAt'] != null
        ? (json['resolvedAt'] as Timestamp).toDate()
        : null,
  );
}

/// Comprehensive user risk profile for fraud detection
class UserRiskProfile {
  final String userId;
  final double trustScore; // 0.0 - 1.0 (1.0 = highly trusted)
  final int totalClaims;
  final int suspiciousIncidents;
  final int flaggedIncidents;
  final DateTime accountCreated;
  final int daysActive;
  final List<String> flaggedBehaviors;
  final List<RiskIndicator> riskIndicators;
  final bool requiresEnhancedValidation;
  final DateTime lastUpdated;

  // Trust factors (positive indicators)
  final int consecutiveSafeMonths;
  final int communityEndorsements;
  final bool verifiedIdentity;
  final bool longTermMember; // >12 months

  // Claim patterns (for detection only, NO hard limits)
  final DateTime? lastClaimDate;
  final int claimsLast30Days;
  final int claimsLast90Days;
  final int claimsThisYear;
  final double averageClaimAmount;
  final List<String> claimPatterns; // ['weekend_claims', 'same_location', etc.]

  // Behavioral flags (for manual review, NOT auto-reject)
  final bool hasLocationAnomalies;
  final bool hasSensorAnomalies;
  final bool hasCostAnomalies;
  final bool hasFrequencyAnomalies;

  const UserRiskProfile({
    required this.userId,
    required this.trustScore,
    required this.totalClaims,
    required this.suspiciousIncidents,
    required this.flaggedIncidents,
    required this.accountCreated,
    required this.daysActive,
    required this.flaggedBehaviors,
    required this.riskIndicators,
    required this.requiresEnhancedValidation,
    required this.lastUpdated,
    required this.consecutiveSafeMonths,
    required this.communityEndorsements,
    required this.verifiedIdentity,
    required this.longTermMember,
    this.lastClaimDate,
    required this.claimsLast30Days,
    required this.claimsLast90Days,
    required this.claimsThisYear,
    required this.averageClaimAmount,
    required this.claimPatterns,
    required this.hasLocationAnomalies,
    required this.hasSensorAnomalies,
    required this.hasCostAnomalies,
    required this.hasFrequencyAnomalies,
  });

  /// Calculate trust score based on factors
  static double calculateTrustScore({
    required int totalClaims,
    required int suspiciousIncidents,
    required int consecutiveSafeMonths,
    required bool verifiedIdentity,
    required bool longTermMember,
    required int daysActive,
    required int flaggedIncidents,
  }) {
    double score = 0.5; // Start at neutral

    // Positive factors (increase trust)
    if (verifiedIdentity) score += 0.1;
    if (longTermMember) score += 0.1;
    score += (consecutiveSafeMonths * 0.01).clamp(0.0, 0.2); // Max +0.2
    score += (daysActive / 365 * 0.05).clamp(0.0, 0.1); // Max +0.1

    // Negative factors (decrease trust)
    if (totalClaims > 3) score -= 0.1;
    if (totalClaims > 5) score -= 0.2;
    score -= suspiciousIncidents * 0.15; // -0.15 per suspicious incident
    score -= flaggedIncidents * 0.2; // -0.2 per flagged incident

    return score.clamp(0.0, 1.0);
  }

  /// Create initial profile for new user
  factory UserRiskProfile.initial(String userId, DateTime accountCreated) {
    return UserRiskProfile(
      userId: userId,
      trustScore: 0.5, // Neutral starting score
      totalClaims: 0,
      suspiciousIncidents: 0,
      flaggedIncidents: 0,
      accountCreated: accountCreated,
      daysActive: 0,
      flaggedBehaviors: [],
      riskIndicators: [],
      requiresEnhancedValidation: false,
      lastUpdated: DateTime.now(),
      consecutiveSafeMonths: 0,
      communityEndorsements: 0,
      verifiedIdentity: false,
      longTermMember: false,
      claimsLast30Days: 0,
      claimsLast90Days: 0,
      claimsThisYear: 0,
      averageClaimAmount: 0.0,
      claimPatterns: [],
      hasLocationAnomalies: false,
      hasSensorAnomalies: false,
      hasCostAnomalies: false,
      hasFrequencyAnomalies: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'trustScore': trustScore,
    'totalClaims': totalClaims,
    'suspiciousIncidents': suspiciousIncidents,
    'flaggedIncidents': flaggedIncidents,
    'accountCreated': Timestamp.fromDate(accountCreated),
    'daysActive': daysActive,
    'flaggedBehaviors': flaggedBehaviors,
    'riskIndicators': riskIndicators
        .map((indicator) => indicator.toJson())
        .toList(),
    'requiresEnhancedValidation': requiresEnhancedValidation,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'consecutiveSafeMonths': consecutiveSafeMonths,
    'communityEndorsements': communityEndorsements,
    'verifiedIdentity': verifiedIdentity,
    'longTermMember': longTermMember,
    'lastClaimDate': lastClaimDate != null
        ? Timestamp.fromDate(lastClaimDate!)
        : null,
    'claimsLast30Days': claimsLast30Days,
    'claimsLast90Days': claimsLast90Days,
    'claimsThisYear': claimsThisYear,
    'averageClaimAmount': averageClaimAmount,
    'claimPatterns': claimPatterns,
    'hasLocationAnomalies': hasLocationAnomalies,
    'hasSensorAnomalies': hasSensorAnomalies,
    'hasCostAnomalies': hasCostAnomalies,
    'hasFrequencyAnomalies': hasFrequencyAnomalies,
  };

  factory UserRiskProfile.fromJson(Map<String, dynamic> json) {
    return UserRiskProfile(
      userId: json['userId'] as String,
      trustScore: (json['trustScore'] as num).toDouble(),
      totalClaims: json['totalClaims'] as int,
      suspiciousIncidents: json['suspiciousIncidents'] as int? ?? 0,
      flaggedIncidents: json['flaggedIncidents'] as int? ?? 0,
      accountCreated: (json['accountCreated'] as Timestamp).toDate(),
      daysActive: json['daysActive'] as int,
      flaggedBehaviors: List<String>.from(
        json['flaggedBehaviors'] as List? ?? [],
      ),
      riskIndicators:
          (json['riskIndicators'] as List<dynamic>?)
              ?.map(
                (indicator) =>
                    RiskIndicator.fromJson(indicator as Map<String, dynamic>),
              )
              .toList() ??
          [],
      requiresEnhancedValidation:
          json['requiresEnhancedValidation'] as bool? ?? false,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      consecutiveSafeMonths: json['consecutiveSafeMonths'] as int? ?? 0,
      communityEndorsements: json['communityEndorsements'] as int? ?? 0,
      verifiedIdentity: json['verifiedIdentity'] as bool? ?? false,
      longTermMember: json['longTermMember'] as bool? ?? false,
      lastClaimDate: json['lastClaimDate'] != null
          ? (json['lastClaimDate'] as Timestamp).toDate()
          : null,
      claimsLast30Days: json['claimsLast30Days'] as int? ?? 0,
      claimsLast90Days: json['claimsLast90Days'] as int? ?? 0,
      claimsThisYear: json['claimsThisYear'] as int? ?? 0,
      averageClaimAmount:
          (json['averageClaimAmount'] as num?)?.toDouble() ?? 0.0,
      claimPatterns: List<String>.from(json['claimPatterns'] as List? ?? []),
      hasLocationAnomalies: json['hasLocationAnomalies'] as bool? ?? false,
      hasSensorAnomalies: json['hasSensorAnomalies'] as bool? ?? false,
      hasCostAnomalies: json['hasCostAnomalies'] as bool? ?? false,
      hasFrequencyAnomalies: json['hasFrequencyAnomalies'] as bool? ?? false,
    );
  }

  /// Human-readable summary
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Trust Score: ${(trustScore * 100).toStringAsFixed(1)}%');
    buffer.writeln('Total Claims: $totalClaims');
    buffer.writeln('Safe Months: $consecutiveSafeMonths');

    if (requiresEnhancedValidation) {
      buffer.writeln('\n⚠️ Enhanced Validation Required');
    }

    if (flaggedIncidents > 0) {
      buffer.writeln('\n🚩 Flagged Incidents: $flaggedIncidents');
    }

    if (riskIndicators.isNotEmpty) {
      buffer.writeln('\nActive Risk Indicators:');
      for (final indicator in riskIndicators.where((i) => !i.resolved)) {
        buffer.writeln('  • ${indicator.description} (${indicator.severity})');
      }
    }

    return buffer.toString();
  }

  /// Check if user is trusted
  bool get isTrusted => trustScore >= 0.7;

  /// Check if user is high risk (requires manual review, NOT auto-block)
  bool get isHighRisk => trustScore <= 0.3;

  /// Check for suspicious claim frequency patterns (for review, NOT limits)
  /// Note: Per blueprint - "All users can ALWAYS request rescue service"
  bool get hasSuspiciousFrequency {
    return claimsLast30Days >= 2 || claimsThisYear >= 4;
  }

  /// Note: NO HARD CLAIM LIMITS per Safety Fund Blueprint
  /// "Equality of Rescue – All users receive rescue assistance regardless of status"
  /// Fraud prevention uses pattern detection + manual review, not auto-rejection
}
