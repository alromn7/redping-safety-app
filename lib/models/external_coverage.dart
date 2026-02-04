/// External coverage types that users may already have.
///
/// This SMART DESIGN keeps the Safety Fund sustainable by:
/// - Using existing insurance/coverage FIRST
/// - Safety Fund only covers remaining gaps
/// - Reduces fund utilization while maintaining value
/// - App Store compliant (not competing with insurance)
/// - Keeps user's Safety Fund journey progressing
enum ExternalCoverageType {
  workCover, // WorkCover insurance (employer)
  privateHealth, // Private health insurance
  roadsideAssist, // RACV, NRMA, AAA, etc.
  travelInsurance, // Travel insurance
  ambulanceCover, // Ambulance Victoria, etc.
  privateSAR, // Private SAR membership
  militaryRescue, // Military rescue entitlement
  miningRescue, // Mining company rescue
  remoteWorkerRescue, // Remote worker rescue coverage
}

extension ExternalCoverageTypeExtension on ExternalCoverageType {
  String get displayName {
    switch (this) {
      case ExternalCoverageType.workCover:
        return 'WorkCover Insurance';
      case ExternalCoverageType.privateHealth:
        return 'Private Health Insurance';
      case ExternalCoverageType.roadsideAssist:
        return 'Roadside Assistance';
      case ExternalCoverageType.travelInsurance:
        return 'Travel Insurance';
      case ExternalCoverageType.ambulanceCover:
        return 'Ambulance Cover';
      case ExternalCoverageType.privateSAR:
        return 'Private SAR Membership';
      case ExternalCoverageType.militaryRescue:
        return 'Military Rescue';
      case ExternalCoverageType.miningRescue:
        return 'Mining Company Rescue';
      case ExternalCoverageType.remoteWorkerRescue:
        return 'Remote Worker Coverage';
    }
  }

  String get icon {
    switch (this) {
      case ExternalCoverageType.workCover:
        return '🏢';
      case ExternalCoverageType.privateHealth:
        return '🏥';
      case ExternalCoverageType.roadsideAssist:
        return '🚗';
      case ExternalCoverageType.travelInsurance:
        return '✈️';
      case ExternalCoverageType.ambulanceCover:
        return '🚑';
      case ExternalCoverageType.privateSAR:
        return '🚁';
      case ExternalCoverageType.militaryRescue:
        return '🪖';
      case ExternalCoverageType.miningRescue:
        return '⛏️';
      case ExternalCoverageType.remoteWorkerRescue:
        return '🏜️';
    }
  }

  String get description {
    switch (this) {
      case ExternalCoverageType.workCover:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.privateHealth:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.roadsideAssist:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.travelInsurance:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.ambulanceCover:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.privateSAR:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.militaryRescue:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.miningRescue:
        return 'Use this first - Safety Fund is backup only';
      case ExternalCoverageType.remoteWorkerRescue:
        return 'Use this first - Safety Fund is backup only';
    }
  }
}

/// User's external coverage configuration.
///
/// LEGAL COMPLIANCE: NOT insurance - community pooling only!
///
/// User Choice System:
/// - Users CAN use Safety Fund anytime (rescue NEVER blocked)
/// - Journey penalties encourage using external coverage first
/// - Higher user share if they skip their own insurance
///
/// Penalty System:
/// - Has external + uses it: Journey continues, normal benefits
/// - Has external + uses Safety Fund: 40/60 penalty split
/// - No external: Normal journey progression (80-100% fund share)
///
/// Why penalties?
/// - $5/month = $60/year contribution
/// - One $3,000 rescue = 50 members' contributions
/// - Community fund needs users to use external first
/// - Penalty makes using Safety Fund more expensive than using external
///
/// This keeps us legally compliant:
/// - NOT insurance (user choice system) ✅
/// - NOT blocking rescue (always available) ✅
/// - Penalties = pricing, not coverage denial ✅
/// - Communication platform with community pooling ✅
class ExternalCoverageProfile {
  final String userId;
  final bool smartExternalCoverageEnabled; // Master toggle
  final List<ExternalCoverageType> activeCoverages;
  final DateTime? lastUpdated;

  // User preferences
  final bool autoUseExternal; // Automatically use external coverage first
  final bool notifyBeforeExternalUse; // Ask user before using external

  const ExternalCoverageProfile({
    required this.userId,
    required this.smartExternalCoverageEnabled,
    required this.activeCoverages,
    this.lastUpdated,
    this.autoUseExternal = true,
    this.notifyBeforeExternalUse = false,
  });

  /// Check if user has any external coverage active
  bool get hasAnyCoverage => activeCoverages.isNotEmpty;

  /// Get primary coverage (first in list)
  ExternalCoverageType? get primaryCoverage {
    return activeCoverages.isNotEmpty ? activeCoverages.first : null;
  }

  /// Check if specific coverage type is active
  bool hasCoverageType(ExternalCoverageType type) {
    return activeCoverages.contains(type);
  }

  ExternalCoverageProfile copyWith({
    bool? smartExternalCoverageEnabled,
    List<ExternalCoverageType>? activeCoverages,
    DateTime? lastUpdated,
    bool? autoUseExternal,
    bool? notifyBeforeExternalUse,
  }) {
    return ExternalCoverageProfile(
      userId: userId,
      smartExternalCoverageEnabled:
          smartExternalCoverageEnabled ?? this.smartExternalCoverageEnabled,
      activeCoverages: activeCoverages ?? this.activeCoverages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      autoUseExternal: autoUseExternal ?? this.autoUseExternal,
      notifyBeforeExternalUse:
          notifyBeforeExternalUse ?? this.notifyBeforeExternalUse,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'smartExternalCoverageEnabled': smartExternalCoverageEnabled,
    'activeCoverages': activeCoverages.map((e) => e.name).toList(),
    'lastUpdated': lastUpdated?.toIso8601String(),
    'autoUseExternal': autoUseExternal,
    'notifyBeforeExternalUse': notifyBeforeExternalUse,
  };

  factory ExternalCoverageProfile.fromJson(Map<String, dynamic> json) {
    return ExternalCoverageProfile(
      userId: json['userId'] as String,
      smartExternalCoverageEnabled:
          json['smartExternalCoverageEnabled'] as bool? ?? false,
      activeCoverages:
          (json['activeCoverages'] as List<dynamic>?)
              ?.map(
                (e) => ExternalCoverageType.values.firstWhere(
                  (type) => type.name == e,
                  orElse: () => ExternalCoverageType.privateHealth,
                ),
              )
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      autoUseExternal: json['autoUseExternal'] as bool? ?? true,
      notifyBeforeExternalUse:
          json['notifyBeforeExternalUse'] as bool? ?? false,
    );
  }

  /// Initial profile with no external coverage
  factory ExternalCoverageProfile.initial(String userId) {
    return ExternalCoverageProfile(
      userId: userId,
      smartExternalCoverageEnabled: false,
      activeCoverages: [],
      autoUseExternal: true,
      notifyBeforeExternalUse: false,
    );
  }
}

/// Coverage hierarchy calculation result.
/// Shows how a rescue cost is split across multiple coverage sources.
class CoverageHierarchyResult {
  final double externalCoverageAmount;
  final double safetyFundAmount;
  final double userAmount;
  final double totalCost;

  final List<String> coverageOrder; // Which coverages were used
  final bool externalCoverageFailed; // If external couldn't be used
  final String? failureReason;

  const CoverageHierarchyResult({
    required this.externalCoverageAmount,
    required this.safetyFundAmount,
    required this.userAmount,
    required this.totalCost,
    required this.coverageOrder,
    this.externalCoverageFailed = false,
    this.failureReason,
  });

  /// Check if external coverage covered everything
  bool get fullyCoveredByExternal {
    return externalCoverageAmount >= totalCost;
  }

  /// Check if Safety Fund was needed
  bool get safetyFundUsed {
    return safetyFundAmount > 0;
  }

  /// Get percentage covered by external
  double get externalCoveragePercent {
    return totalCost > 0 ? (externalCoverageAmount / totalCost) * 100 : 0;
  }

  /// Get percentage covered by Safety Fund
  double get safetyFundPercent {
    return totalCost > 0 ? (safetyFundAmount / totalCost) * 100 : 0;
  }

  /// Get percentage user must pay
  double get userPercent {
    return totalCost > 0 ? (userAmount / totalCost) * 100 : 0;
  }
}
