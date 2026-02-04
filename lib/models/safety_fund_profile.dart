/// Safety Journey stages based on time without Safety Fund claims.
/// Aligned with RedPing Safety Fund Blueprint.
enum SafetyJourneyStage {
  stage1_0to6Months,
  stage2_6to12Months,
  stage3_1to2Years,
  stage4_2to5Years,
  stage5_5plusYears, // 100% coverage tier
}

extension SafetyJourneyStageExtension on SafetyJourneyStage {
  String get displayName {
    switch (this) {
      case SafetyJourneyStage.stage1_0to6Months:
        return 'Ambulance Support';
      case SafetyJourneyStage.stage2_6to12Months:
        return 'Road Assist';
      case SafetyJourneyStage.stage3_1to2Years:
        return '4WD Assist';
      case SafetyJourneyStage.stage4_2to5Years:
        return 'Helicopter Support';
      case SafetyJourneyStage.stage5_5plusYears:
        return 'Community Hero';
    }
  }

  String get badgeIcon {
    switch (this) {
      case SafetyJourneyStage.stage1_0to6Months:
        return '🚑';
      case SafetyJourneyStage.stage2_6to12Months:
        return '🚗';
      case SafetyJourneyStage.stage3_1to2Years:
        return '🚙';
      case SafetyJourneyStage.stage4_2to5Years:
        return '🚁';
      case SafetyJourneyStage.stage5_5plusYears:
        return '🏆';
    }
  }

  int get requiredMonths {
    switch (this) {
      case SafetyJourneyStage.stage1_0to6Months:
        return 6;
      case SafetyJourneyStage.stage2_6to12Months:
        return 12;
      case SafetyJourneyStage.stage3_1to2Years:
        return 24;
      case SafetyJourneyStage.stage4_2to5Years:
        return 60;
      case SafetyJourneyStage.stage5_5plusYears:
        return 60; // 5+ years
    }
  }

  List<String> get rewards {
    switch (this) {
      case SafetyJourneyStage.stage1_0to6Months:
        return ['Safety badge', 'Safety summary', 'Enhanced check-ins'];
      case SafetyJourneyStage.stage2_6to12Months:
        return ['Driving risk report', 'Cloud history', 'Safety perks'];
      case SafetyJourneyStage.stage3_1to2Years:
        return ['Route analysis', 'Survival checklist', 'Hazard alerts'];
      case SafetyJourneyStage.stage4_2to5Years:
        return [
          'Deep risk report',
          'Priority support',
          'Lifetime fund discount',
        ];
      case SafetyJourneyStage.stage5_5plusYears:
        return [
          '100% coverage',
          'Community Hero status',
          'Lifetime recognition',
        ];
    }
  }
}

/// High-level fund usage state for a user.
/// Determines billing split after rescue events.
enum SafetyFundUsageState {
  normal, // default, no recent claim (Fund 80%, User 20%)
  rebalancing, // after claim: user pays 80%, fund 20%
  heroEligible, // 10+ years, can help non-members (Fund 100%)
}

extension SafetyFundUsageStateExtension on SafetyFundUsageState {
  String get displayName {
    switch (this) {
      case SafetyFundUsageState.normal:
        return 'Active Coverage';
      case SafetyFundUsageState.rebalancing:
        return 'Rebalancing Period';
      case SafetyFundUsageState.heroEligible:
        return 'Community Hero';
    }
  }

  String get description {
    switch (this) {
      case SafetyFundUsageState.normal:
        return 'Safety Fund covers 80% of rescue costs';
      case SafetyFundUsageState.rebalancing:
        return 'Temporary period after claim - You pay 80%, Fund pays 20%';
      case SafetyFundUsageState.heroEligible:
        return '10+ years without claims - Fund covers 100% + Can help non-members';
    }
  }

  BillingSplit get billingSplit {
    switch (this) {
      case SafetyFundUsageState.normal:
        return const BillingSplit.fund80User20();
      case SafetyFundUsageState.rebalancing:
        return const BillingSplit.fund20User80();
      case SafetyFundUsageState.heroEligible:
        return const BillingSplit.fund100User0();
    }
  }
}

/// Billing split between user and fund.
/// Represents the shared responsibility model.
class BillingSplit {
  final double fundShare; // 0.0–1.0
  final double userShare; // 0.0–1.0

  const BillingSplit._(this.fundShare, this.userShare)
    : assert(fundShare >= 0 && fundShare <= 1),
      assert(userShare >= 0 && userShare <= 1);

  /// Standard coverage: Fund pays 80%, User pays 20%
  const BillingSplit.fund80User20() : this._(0.8, 0.2);

  /// Rebalancing period: Fund pays 20%, User pays 80%
  const BillingSplit.fund20User80() : this._(0.2, 0.8);

  /// Hero tier (5+ years): Fund pays 100%, User pays 0%
  const BillingSplit.fund100User0() : this._(1.0, 0.0);

  /// Optional enhanced coverage: Fund pays 90%, User pays 10%
  const BillingSplit.fund90User10() : this._(0.9, 0.1);

  /// Community Hero non-member assistance: Fund pays 50%, Hero pays 50%
  const BillingSplit.fund50User50() : this._(0.5, 0.5);

  /// Community Hero model (safe design): Fund 40%, Hero 40%, Non-member 20%
  /// Represented as: Fund 40%, User (Hero+Non-member) 60%
  const BillingSplit.fund40User60() : this._(0.4, 0.6);

  /// Non-member pays all (when hero not eligible): Fund pays 0%, Non-member pays 100%
  const BillingSplit.fund0User100() : this._(0.0, 1.0);

  double calculateFundAmount(double totalCost) => totalCost * fundShare;
  double calculateUserAmount(double totalCost) => totalCost * userShare;

  String get displayText =>
      '${(fundShare * 100).toInt()}/${(userShare * 100).toInt()} Split';
}

/// Snapshot of a user's relationship with the Safety Fund.
/// Core model aligned with RedPing Safety Fund Blueprint.
class SafetyFundProfile {
  // Community Hero Non-Member Assistance Limits
  static const int heroMinMonths = 120; // 10 years
  static const double heroMaxCoveragePercent = 0.80; // 80% max
  static const double heroMaxIncidentCost = 3000.0; // $3,000 cap
  static const int heroResetToMonths = 60; // Reset to 5 years (Stage 4)
  final String userId;
  final SafetyJourneyStage journeyStage;
  final SafetyFundUsageState usageState;

  /// External Coverage Flag - ENCOURAGES USING OWN COVERAGE
  ///
  /// LEGAL COMPLIANCE: Safety Fund is NOT insurance!
  /// RedPing = Safety communication platform (coordinates rescue)
  /// Safety Fund = Community pooling for coordination costs ONLY
  ///
  /// User Choice:
  /// - Users CAN use Safety Fund anytime (always available)
  /// - BUT journey penalties apply if they have external coverage
  /// - Encourages using their OWN insurance/WorkCover first
  ///
  /// Journey Logic:
  /// - Has external + uses it: Journey continues normally ✅
  /// - Has external + uses Safety Fund: Penalty applied (higher user share)
  /// - No external: Normal journey progression
  ///
  /// Goal: Push users to use external coverage first, but never block rescue
  final bool externalCoverageEnabled;
  final DateTime? lastClaimAt;
  final DateTime joinedAt;
  final int monthsWithoutClaim; // computed from joinedAt + lastClaimAt
  final bool streakFreezeAvailable;
  final bool isActive; // enrolled in Safety Fund
  final double monthlyContribution; // $5, $7.50, or $10 based on fund health

  const SafetyFundProfile({
    required this.userId,
    required this.journeyStage,
    required this.usageState,
    required this.externalCoverageEnabled,
    this.lastClaimAt,
    required this.joinedAt,
    required this.monthsWithoutClaim,
    required this.streakFreezeAvailable,
    required this.isActive,
    this.monthlyContribution = 5.0,
  });

  /// Calculate journey stage from months without claim
  static SafetyJourneyStage calculateStage(int monthsWithoutClaim) {
    if (monthsWithoutClaim >= 60) {
      return SafetyJourneyStage.stage5_5plusYears;
    } else if (monthsWithoutClaim >= 24) {
      return SafetyJourneyStage.stage4_2to5Years;
    } else if (monthsWithoutClaim >= 12) {
      return SafetyJourneyStage.stage3_1to2Years;
    } else if (monthsWithoutClaim >= 6) {
      return SafetyJourneyStage.stage2_6to12Months;
    } else {
      return SafetyJourneyStage.stage1_0to6Months;
    }
  }

  /// Calculate usage state based on claim history and time
  static SafetyFundUsageState calculateUsageState({
    required int monthsWithoutClaim,
    DateTime? lastClaimAt,
  }) {
    // Hero eligible: 10+ years (120+ months) without claims
    if (monthsWithoutClaim >= 120) {
      return SafetyFundUsageState.heroEligible;
    }

    // Rebalancing: within 12 months of a claim
    if (lastClaimAt != null) {
      final monthsSinceClaim =
          DateTime.now().difference(lastClaimAt).inDays ~/ 30;
      if (monthsSinceClaim < 12) {
        return SafetyFundUsageState.rebalancing;
      }
    }

    return SafetyFundUsageState.normal;
  }

  /// Get billing split for this profile
  BillingSplit get billingSplit => usageState.billingSplit;

  /// Check if user is Community Hero eligible (10+ years without claims)
  /// Community Heroes can use Safety Fund to help non-members in emergencies
  ///
  /// Rules:
  /// - Must have 10+ years (120+ months) without Safety Fund claims
  /// - Limited to one Streak Freeze per year
  /// - Can activate once per year
  /// - Covers max 80% of rescue cost (never 100%)
  /// - Maximum $3,000 per incident
  /// - Resets journey to 5-year stage (not Stage 1)
  bool get canHelpNonMembers {
    return monthsWithoutClaim >= 120 && // 10+ years
        usageState == SafetyFundUsageState.heroEligible;
  }

  /// Calculate fund share for a given cost
  double calculateFundShare(double totalCost) {
    return billingSplit.calculateFundAmount(totalCost);
  }

  /// Calculate user share for a given cost
  double calculateUserShare(double totalCost) {
    return billingSplit.calculateUserAmount(totalCost);
  }

  SafetyFundProfile copyWith({
    SafetyJourneyStage? journeyStage,
    SafetyFundUsageState? usageState,
    bool? externalCoverageEnabled,
    DateTime? lastClaimAt,
    DateTime? joinedAt,
    int? monthsWithoutClaim,
    bool? streakFreezeAvailable,
    bool? isActive,
    double? monthlyContribution,
  }) {
    return SafetyFundProfile(
      userId: userId,
      journeyStage: journeyStage ?? this.journeyStage,
      usageState: usageState ?? this.usageState,
      externalCoverageEnabled:
          externalCoverageEnabled ?? this.externalCoverageEnabled,
      lastClaimAt: lastClaimAt ?? this.lastClaimAt,
      joinedAt: joinedAt ?? this.joinedAt,
      monthsWithoutClaim: monthsWithoutClaim ?? this.monthsWithoutClaim,
      streakFreezeAvailable:
          streakFreezeAvailable ?? this.streakFreezeAvailable,
      isActive: isActive ?? this.isActive,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'journeyStage': journeyStage.name,
    'usageState': usageState.name,
    'externalCoverageEnabled': externalCoverageEnabled,
    'lastClaimAt': lastClaimAt?.toIso8601String(),
    'joinedAt': joinedAt.toIso8601String(),
    'monthsWithoutClaim': monthsWithoutClaim,
    'streakFreezeAvailable': streakFreezeAvailable,
    'isActive': isActive,
    'monthlyContribution': monthlyContribution,
  };

  factory SafetyFundProfile.fromJson(Map<String, dynamic> json) {
    return SafetyFundProfile(
      userId: json['userId'] as String,
      journeyStage: SafetyJourneyStage.values.firstWhere(
        (e) => e.name == json['journeyStage'],
        orElse: () => SafetyJourneyStage.stage1_0to6Months,
      ),
      usageState: SafetyFundUsageState.values.firstWhere(
        (e) => e.name == json['usageState'],
        orElse: () => SafetyFundUsageState.normal,
      ),
      externalCoverageEnabled:
          json['externalCoverageEnabled'] as bool? ?? false,
      lastClaimAt: json['lastClaimAt'] != null
          ? DateTime.parse(json['lastClaimAt'] as String)
          : null,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      monthsWithoutClaim: json['monthsWithoutClaim'] as int? ?? 0,
      streakFreezeAvailable: json['streakFreezeAvailable'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      monthlyContribution:
          (json['monthlyContribution'] as num?)?.toDouble() ?? 5.0,
    );
  }

  /// Initial profile for new Safety Fund member
  factory SafetyFundProfile.initial(String userId) {
    return SafetyFundProfile(
      userId: userId,
      journeyStage: SafetyJourneyStage.stage1_0to6Months,
      usageState: SafetyFundUsageState.normal,
      externalCoverageEnabled: false,
      joinedAt: DateTime.now(),
      monthsWithoutClaim: 0,
      streakFreezeAvailable: true,
      isActive: true,
      monthlyContribution: 5.0,
    );
  }
}
