class ExternalCoverageProfile {
  final String userId;
  final bool smartExternalCoverageEnabled;
  final List<ExternalCoverageType> activeCoverages;
  final DateTime? lastUpdated;

  const ExternalCoverageProfile({
    required this.userId,
    this.smartExternalCoverageEnabled = false,
    this.activeCoverages = const [],
    this.lastUpdated,
  });

  factory ExternalCoverageProfile.initial(String userId) {
    return ExternalCoverageProfile(
      userId: userId,
      smartExternalCoverageEnabled: false,
      activeCoverages: const [],
      lastUpdated: DateTime.now(),
    );
  }

  factory ExternalCoverageProfile.fromJson(Map<String, dynamic> json) {
    final rawCoverages = (json['activeCoverages'] as List?) ?? const [];
    return ExternalCoverageProfile(
      userId: (json['userId'] ?? '').toString(),
      smartExternalCoverageEnabled:
          json['smartExternalCoverageEnabled'] == true,
      activeCoverages: rawCoverages
          .map((e) => ExternalCoverageTypeX.fromStorage(e.toString()))
          .toList(growable: false),
      lastUpdated: _toDateTime(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'smartExternalCoverageEnabled': smartExternalCoverageEnabled,
    'activeCoverages': activeCoverages
        .map((e) => e.storageValue)
        .toList(growable: false),
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  ExternalCoverageProfile copyWith({
    String? userId,
    bool? smartExternalCoverageEnabled,
    List<ExternalCoverageType>? activeCoverages,
    DateTime? lastUpdated,
  }) {
    return ExternalCoverageProfile(
      userId: userId ?? this.userId,
      smartExternalCoverageEnabled:
          smartExternalCoverageEnabled ?? this.smartExternalCoverageEnabled,
      activeCoverages: activeCoverages ?? this.activeCoverages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    final asString = value.toString();
    return DateTime.tryParse(asString);
  }
}

enum ExternalCoverageType {
  privateInsurance,
  medicare,
  medicaid,
  veteransAffairs,
  travelInsurance,
  other,
}

extension ExternalCoverageTypeX on ExternalCoverageType {
  String get storageValue {
    switch (this) {
      case ExternalCoverageType.privateInsurance:
        return 'privateInsurance';
      case ExternalCoverageType.medicare:
        return 'medicare';
      case ExternalCoverageType.medicaid:
        return 'medicaid';
      case ExternalCoverageType.veteransAffairs:
        return 'veteransAffairs';
      case ExternalCoverageType.travelInsurance:
        return 'travelInsurance';
      case ExternalCoverageType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ExternalCoverageType.privateInsurance:
        return 'Private Insurance';
      case ExternalCoverageType.medicare:
        return 'Medicare';
      case ExternalCoverageType.medicaid:
        return 'Medicaid';
      case ExternalCoverageType.veteransAffairs:
        return 'Veterans Affairs';
      case ExternalCoverageType.travelInsurance:
        return 'Travel Insurance';
      case ExternalCoverageType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExternalCoverageType.privateInsurance:
        return '🛡️';
      case ExternalCoverageType.medicare:
        return '🏥';
      case ExternalCoverageType.medicaid:
        return '🧾';
      case ExternalCoverageType.veteransAffairs:
        return '🎖️';
      case ExternalCoverageType.travelInsurance:
        return '✈️';
      case ExternalCoverageType.other:
        return '📄';
    }
  }

  static ExternalCoverageType fromStorage(String raw) {
    switch (raw) {
      case 'privateInsurance':
        return ExternalCoverageType.privateInsurance;
      case 'medicare':
        return ExternalCoverageType.medicare;
      case 'medicaid':
        return ExternalCoverageType.medicaid;
      case 'veteransAffairs':
        return ExternalCoverageType.veteransAffairs;
      case 'travelInsurance':
        return ExternalCoverageType.travelInsurance;
      default:
        return ExternalCoverageType.other;
    }
  }
}
