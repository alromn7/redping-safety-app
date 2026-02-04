/// Safety Fund subscription status
enum SafetyFundStatus { active, inactive, suspended }

/// Fund health indicators for transparency
enum FundHealthIndicator { stable, moderate, highUsage }

/// Safety Journey stages
enum SafetyStage {
  none,
  ambulanceSupport, // 6 months safe
  roadAssist, // 12 months safe
  fourWDAssist, // 24 months safe
  helicopterSupport, // 36 months safe
}

extension SafetyStageExtension on SafetyStage {
  String get displayName {
    switch (this) {
      case SafetyStage.none:
        return 'Getting Started';
      case SafetyStage.ambulanceSupport:
        return 'Ambulance Support';
      case SafetyStage.roadAssist:
        return 'Road Assist';
      case SafetyStage.fourWDAssist:
        return '4WD Assist';
      case SafetyStage.helicopterSupport:
        return 'Helicopter Support';
    }
  }

  String get badgeIcon {
    switch (this) {
      case SafetyStage.none:
        return '🛡️';
      case SafetyStage.ambulanceSupport:
        return '🚑';
      case SafetyStage.roadAssist:
        return '🚗';
      case SafetyStage.fourWDAssist:
        return '🚙';
      case SafetyStage.helicopterSupport:
        return '🚁';
    }
  }

  int get requiredMonths {
    switch (this) {
      case SafetyStage.none:
        return 0;
      case SafetyStage.ambulanceSupport:
        return 6;
      case SafetyStage.roadAssist:
        return 12;
      case SafetyStage.fourWDAssist:
        return 24;
      case SafetyStage.helicopterSupport:
        return 36;
    }
  }

  List<String> get rewards {
    switch (this) {
      case SafetyStage.none:
        return ['Basic safety tracking'];
      case SafetyStage.ambulanceSupport:
        return ['Safety badge', 'Safety summary', 'Enhanced check-ins'];
      case SafetyStage.roadAssist:
        return ['Driving risk report', 'Cloud history', 'Safety perks'];
      case SafetyStage.fourWDAssist:
        return ['Route analysis', 'Survival checklist', 'Hazard alerts'];
      case SafetyStage.helicopterSupport:
        return [
          'Deep risk report',
          'Priority support',
          'Lifetime fund discount',
        ];
    }
  }
}

/// User's Safety Fund subscription
class SafetyFundSubscription {
  final String userId;
  final SafetyFundStatus status;
  final double monthlyContribution;
  final DateTime enrollmentDate;
  final DateTime? lastContributionDate;
  final SafetyStage currentStage;
  final int streakMonths;
  final DateTime? lastClaimDate;
  final int totalClaims;
  final bool streakFreezeAvailable;
  final DateTime? streakFreezeUsedDate;
  final bool optedOut;

  SafetyFundSubscription({
    required this.userId,
    required this.status,
    required this.monthlyContribution,
    required this.enrollmentDate,
    this.lastContributionDate,
    this.currentStage = SafetyStage.none,
    this.streakMonths = 0,
    this.lastClaimDate,
    this.totalClaims = 0,
    this.streakFreezeAvailable = true,
    this.streakFreezeUsedDate,
    this.optedOut = false,
  });

  bool get isActive => status == SafetyFundStatus.active && !optedOut;

  /// Next stage after the current stage.
  ///
  /// Note: `currentStage` represents the user's already-earned stage.
  /// `streakMonths` is used to estimate time remaining until the next stage.
  SafetyStage get nextStage {
    switch (currentStage) {
      case SafetyStage.none:
        return SafetyStage.ambulanceSupport;
      case SafetyStage.ambulanceSupport:
        return SafetyStage.roadAssist;
      case SafetyStage.roadAssist:
        return SafetyStage.fourWDAssist;
      case SafetyStage.fourWDAssist:
        return SafetyStage.helicopterSupport;
      case SafetyStage.helicopterSupport:
        return SafetyStage.helicopterSupport;
    }
  }

  /// Days until next stage
  int get daysToNextStage {
    final currentRequired = currentStage.requiredMonths;
    final nextRequired = nextStage.requiredMonths;
    if (nextRequired <= currentRequired) return 0;
    if (streakMonths >= nextRequired) return 0;
    final monthsRemaining = nextRequired - streakMonths;
    return monthsRemaining * 30; // Approximate
  }

  /// Contribution amount based on stage (Orange/Red adjustments)
  static double getContributionAmount(
    SafetyStage stage, {
    bool isOrange = false,
    bool isRed = false,
  }) {
    if (isRed) return 10.0;
    if (isOrange) return 7.5;
    return 5.0; // Standard (Green stage)
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'status': status.name,
    'monthlyContribution': monthlyContribution,
    'enrollmentDate': enrollmentDate.toIso8601String(),
    'lastContributionDate': lastContributionDate?.toIso8601String(),
    'currentStage': currentStage.name,
    'streakMonths': streakMonths,
    'lastClaimDate': lastClaimDate?.toIso8601String(),
    'totalClaims': totalClaims,
    'streakFreezeAvailable': streakFreezeAvailable,
    'streakFreezeUsedDate': streakFreezeUsedDate?.toIso8601String(),
    'optedOut': optedOut,
  };

  factory SafetyFundSubscription.fromJson(Map<String, dynamic> json) =>
      SafetyFundSubscription(
        userId: json['userId'] as String,
        status: SafetyFundStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SafetyFundStatus.inactive,
        ),
        monthlyContribution: (json['monthlyContribution'] as num).toDouble(),
        enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
        lastContributionDate: json['lastContributionDate'] != null
            ? DateTime.parse(json['lastContributionDate'] as String)
            : null,
        currentStage: SafetyStage.values.firstWhere(
          (e) => e.name == json['currentStage'],
          orElse: () => SafetyStage.none,
        ),
        streakMonths: json['streakMonths'] as int? ?? 0,
        lastClaimDate: json['lastClaimDate'] != null
            ? DateTime.parse(json['lastClaimDate'] as String)
            : null,
        totalClaims: json['totalClaims'] as int? ?? 0,
        streakFreezeAvailable: json['streakFreezeAvailable'] as bool? ?? true,
        streakFreezeUsedDate: json['streakFreezeUsedDate'] != null
            ? DateTime.parse(json['streakFreezeUsedDate'] as String)
            : null,
        optedOut: json['optedOut'] as bool? ?? false,
      );

  SafetyFundSubscription copyWith({
    String? userId,
    SafetyFundStatus? status,
    double? monthlyContribution,
    DateTime? enrollmentDate,
    DateTime? lastContributionDate,
    SafetyStage? currentStage,
    int? streakMonths,
    DateTime? lastClaimDate,
    int? totalClaims,
    bool? streakFreezeAvailable,
    DateTime? streakFreezeUsedDate,
    bool? optedOut,
  }) => SafetyFundSubscription(
    userId: userId ?? this.userId,
    status: status ?? this.status,
    monthlyContribution: monthlyContribution ?? this.monthlyContribution,
    enrollmentDate: enrollmentDate ?? this.enrollmentDate,
    lastContributionDate: lastContributionDate ?? this.lastContributionDate,
    currentStage: currentStage ?? this.currentStage,
    streakMonths: streakMonths ?? this.streakMonths,
    lastClaimDate: lastClaimDate ?? this.lastClaimDate,
    totalClaims: totalClaims ?? this.totalClaims,
    streakFreezeAvailable: streakFreezeAvailable ?? this.streakFreezeAvailable,
    streakFreezeUsedDate: streakFreezeUsedDate ?? this.streakFreezeUsedDate,
    optedOut: optedOut ?? this.optedOut,
  );
}
