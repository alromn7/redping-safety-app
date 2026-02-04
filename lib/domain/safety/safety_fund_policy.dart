// lib/domain/safety/safety_fund_policy.dart

import '../../models/safety_fund_profile.dart';

/// Encapsulates Safety Fund rules: billing split, journey progression, hero logic.
///
/// This policy class implements the Safety Fund Blueprint principles:
/// - Equality of Rescue: All users receive assistance regardless of status
/// - Journey-Based Progression: Stage advancement based on time, not risk
/// - Flexible Billing: Dynamic splits based on stage and usage state
/// - Hero Tier: 10+ years without claim = community hero status
/// - Streak Freeze: Once-per-year protection for unavoidable events
class SafetyFundPolicy {
  const SafetyFundPolicy();

  /// Decide how to split a rescue bill between fund and user.
  ///
  /// Billing Split Logic (per blueprint):
  /// - External Coverage Enabled: 0/100 (fund/user) - external pays first
  /// - Stage 5 (5+ years): 100/0 - Full coverage
  /// - Rebalancing State: 20/80 - User pays more after recent claim
  /// - Stage 3-4 (1-5 years): 90/10 - Enhanced coverage
  /// - Default (Stage 1-2): 80/20 - Standard coverage
  BillingSplit resolveBillingSplit(SafetyFundProfile profile) {
    // If user explicitly wants to use external coverage first, Safety Fund is not used.
    // External coverage (insurance, workcover, roadside assist) pays first.
    if (profile.externalCoverageEnabled) {
      // Note: In practice, we'd track external vs Safety Fund separately.
      // For billing split purposes, this means Safety Fund contributes 0%.
      // The SafetyFundProfile.billingSplit getter handles this logic.
      return profile.billingSplit;
    }

    // 10+ years without claim → hero-eligible user still follows normal rules
    // for their own rescue, but can help others via a separate flow.
    // For the user's own rescue, we rely mainly on stage + usageState.

    // 5+ years claim-free → 100% coverage tier (journey Stage 5)
    if (profile.journeyStage == SafetyJourneyStage.stage5_5plusYears) {
      return const BillingSplit.fund100User0();
    }

    // Rebalancing phase after a claim → user pays 80%, fund 20%.
    if (profile.usageState == SafetyFundUsageState.rebalancing) {
      return const BillingSplit.fund20User80();
    }

    // Optionally reward middle tiers (Stage 3/4) with 90/10 split:
    if (profile.journeyStage == SafetyJourneyStage.stage3_1to2Years ||
        profile.journeyStage == SafetyJourneyStage.stage4_2to5Years) {
      return const BillingSplit.fund90User10();
    }

    // Default: 80/20 split (fund 80%, user 20%)
    return const BillingSplit.fund80User20();
  }

  /// Should this user be considered hero-eligible (10+ years, no claim)?
  ///
  /// Community Hero Status Requirements:
  /// 🟢 Step 1: Reach 10-year safety streak
  ///   - No Safety Fund claims for 10+ years
  ///   - Only limited by one Streak Freeze per year
  ///   - Ultra loyalty level reached
  ///   - Status updated to Community Hero Level
  ///
  /// 🟦 Step 2: Unlock "Emergency Support for Non-Members"
  ///   - Applies only in real emergencies
  ///   - Must be triggered by verified RedPing SOS or SAR confirmation
  ///   - Can only cover 80% of the cost (never 100%)
  ///   - Maximum one activation per year
  ///   - Maximum usage cap per incident: $3,000
  ///
  /// 🟣 Step 3: Partial Journey Reset (NOT full reset)
  ///   - Journey resets to 5-year stage (Stage 4), NOT Stage 1
  ///   - Still enjoy 90-95% RedPing coverage
  ///   - Only need 5 more years to regain Community Hero status
  ///   - Prevents discouragement from using this generous privilege
  ///
  /// This is a special privilege to recognize long-term contributors who have
  /// maintained excellent safety records and can extend the community benefit
  /// beyond RedPing members.
  bool isCommunityHeroEligible(SafetyFundProfile profile) {
    return profile.monthsWithoutClaim >= 120 &&
        profile.usageState == SafetyFundUsageState.heroEligible;
  }

  /// When a claim is successfully paid by the Safety Fund, update profile.
  ///
  /// Claim Application Logic:
  /// 1. Check if Streak Freeze is available and applicable
  /// 2. If freeze used: Enter rebalancing but keep journey stage
  /// 3. If no freeze: Reset to Stage 1 and enter rebalancing
  /// 4. Record claim timestamp
  ///
  /// Per Blueprint: "Claims reset journey progress but users can always request rescue"
  SafetyFundProfile applyClaim(SafetyFundProfile profile) {
    final now = DateTime.now();

    // Optionally: if streakFreeze was available and this is a legitimate unavoidable event,
    // you could choose not to reset the journey stage here.
    final bool useFreeze =
        profile.streakFreezeAvailable &&
        _shouldUseStreakFreezeForThisClaim(profile);

    if (useFreeze) {
      return profile.copyWith(
        lastClaimAt: now,
        streakFreezeAvailable: false,
        // Journey stage not reset.
        usageState:
            SafetyFundUsageState.rebalancing, // still go into rebalancing
      );
    }

    // Normal claim: reset to Stage 1 and enter rebalancing phase.
    return profile.copyWith(
      lastClaimAt: now,
      journeyStage: SafetyJourneyStage.stage1_0to6Months,
      usageState: SafetyFundUsageState.rebalancing,
      monthsWithoutClaim: 0,
    );
  }

  /// After enough time has passed and user stays claim-free,
  /// we can upgrade their journey stage.
  ///
  /// Journey Stage Progression (per blueprint):
  /// - 0-6 months: Stage 1 (🚑 Ambulance Support)
  /// - 6-12 months: Stage 2 (🚗 Road Assist)
  /// - 1-2 years: Stage 3 (🚙 4WD Assist)
  /// - 2-5 years: Stage 4 (🚁 Helicopter Support)
  /// - 5+ years: Stage 5 (🏆 Community Hero - 100% coverage)
  ///
  /// Rebalancing Exit: After 1 year claim-free, exit rebalancing state
  SafetyFundProfile recalculateJourneyStage(SafetyFundProfile profile) {
    final months = profile.monthsWithoutClaim;

    // Use the static method from SafetyFundProfile for consistency
    final stage = SafetyFundProfile.calculateStage(months);

    // Calculate usage state using the static method
    final usageState = SafetyFundProfile.calculateUsageState(
      monthsWithoutClaim: months,
      lastClaimAt: profile.lastClaimAt,
    );

    return profile.copyWith(journeyStage: stage, usageState: usageState);
  }

  /// Determine if a user should be granted a streak freeze for this claim.
  ///
  /// Streak Freeze Criteria (per blueprint):
  /// - Available once per year
  /// - Applied to unavoidable emergencies:
  ///   * Severe vehicle crash (airbag deployment)
  ///   * Natural disaster (flood, bushfire, earthquake)
  ///   * Medical emergency (stroke, heart attack, severe injury)
  ///   * External factor (hit by another vehicle, fallen tree, etc.)
  /// - Requires manual approval or high-confidence detection
  /// - NOT applicable to: breakdowns, flat tires, minor incidents
  ///
  /// Note: This is a placeholder - actual implementation requires:
  /// 1. Incident severity analysis (sensor data, photos)
  /// 2. Manual review dashboard for edge cases
  /// 3. Clear user communication about freeze usage
  bool _shouldUseStreakFreezeForThisClaim(SafetyFundProfile profile) {
    // Placeholder: here you'd implement logic to decide if we auto-apply freeze,
    // or require manual approval (e.g. severe crash, natural disaster).
    return false;
  }

  /// Calculate the number of months without a claim for a user.
  ///
  /// This is used for:
  /// - Journey stage progression
  /// - Hero eligibility (10+ years = 120+ months)
  /// - Rebalancing exit timing (12+ months)
  int calculateMonthsWithoutClaim(DateTime joinedAt, DateTime? lastClaimAt) {
    final referenceDate = lastClaimAt ?? joinedAt;
    final now = DateTime.now();
    final daysSinceReference = now.difference(referenceDate).inDays;
    return daysSinceReference ~/ 30; // Approximate months
  }

  /// Check if a user qualifies for streak freeze renewal.
  ///
  /// Renewal Rules:
  /// - Once per calendar year
  /// - Automatically renewed on January 1st if not used
  /// - Can accumulate if not used (optional - check blueprint)
  bool canRenewStreakFreeze(SafetyFundProfile profile) {
    // If freeze is already available, no renewal needed
    if (profile.streakFreezeAvailable) return false;

    // Check if enough time has passed since last freeze usage
    // This requires tracking when freeze was last used (not in current model)
    // Placeholder: assume can renew after 1 year
    return true;
  }

  /// Validate if a billing split is correctly applied based on profile.
  ///
  /// This is useful for:
  /// - Testing billing logic
  /// - Audit trail verification
  /// - Debugging split calculations
  bool validateBillingSplit(SafetyFundProfile profile, BillingSplit split) {
    final expectedSplit = resolveBillingSplit(profile);
    return split.fundShare == expectedSplit.fundShare &&
        split.userShare == expectedSplit.userShare;
  }

  /// Calculate billing split for non-member assistance by Community Hero.
  ///
  /// Community Hero Assistance Rules (SAFE DESIGN):
  /// - Only available to users with 10+ years (120+ months) without claims
  /// - Can be used for verified emergency rescues of non-RedPing members
  /// - Maximum coverage: 80% (Fund 40%, Hero 40%, Non-member 20%)
  /// - Maximum incident cost: $3,000
  /// - Maximum one activation per year
  /// - Requires verified RedPing SOS or SAR confirmation
  /// - Hero member pays their 40% as a generous contribution
  /// - Non-member must pay at least 20% (prevents abuse)
  ///
  /// After using this privilege:
  /// - Journey resets to 5-year stage (60 months), NOT Stage 1
  /// - Hero retains 90%+ coverage for their own rescues
  /// - Only needs 5 more years to regain full Community Hero status
  ///
  /// This feature recognizes exceptional long-term safety records and allows
  /// the community's most dedicated members to extend the safety net beyond
  /// the RedPing community while maintaining fund sustainability.
  BillingSplit resolveNonMemberAssistanceSplit(SafetyFundProfile heroProfile) {
    if (!isCommunityHeroEligible(heroProfile)) {
      // Not eligible - return 0/100 (hero pays nothing, non-member pays all)
      return const BillingSplit.fund0User100();
    }

    // Community Hero assists non-member: 40/40/20 split
    // Fund pays 40%, Hero pays 40%, Non-member pays 20%
    // Represented as 80/20 split (combined Fund+Hero vs Non-member)
    return const BillingSplit.fund80User20();
  }

  /// Check if a Community Hero can initiate non-member assistance.
  ///
  /// Validation checks:
  /// - Must be Community Hero eligible (10+ years)
  /// - Must be in heroEligible usage state (not rebalancing)
  /// - Requires manual approval for non-member rescue verification
  /// - Subject to fund health and availability
  bool canInitiateNonMemberAssistance(SafetyFundProfile profile) {
    return profile.canHelpNonMembers;
  }

  /// Calculate the maximum fund contribution for non-member assistance.
  ///
  /// Rules:
  /// - Never exceeds 80% of rescue cost
  /// - Never exceeds $3,000 total
  /// - Split: Fund 40% + Hero 40% = 80% coverage
  /// - Non-member pays remaining 20%
  double calculateNonMemberFundShare(double rescueCost) {
    // Cap at 80% of cost or $3,000, whichever is lower
    final maxCoverage = rescueCost * SafetyFundProfile.heroMaxCoveragePercent;
    final cappedCoverage = maxCoverage > SafetyFundProfile.heroMaxIncidentCost
        ? SafetyFundProfile.heroMaxIncidentCost
        : maxCoverage;

    // Fund pays 40% (half of the 80% coverage)
    return cappedCoverage * 0.5;
  }

  /// Calculate the Hero member's contribution for non-member assistance.
  ///
  /// Hero pays 40% of covered amount (half of 80% total coverage)
  double calculateNonMemberHeroShare(double rescueCost) {
    // Same calculation as fund share - Hero matches the fund contribution
    return calculateNonMemberFundShare(rescueCost);
  }

  /// Calculate billing split with penalty for not using external coverage.
  ///
  /// LEGAL COMPLIANCE: NOT insurance - community pooling for coordination!
  ///
  /// User Choice System:
  /// - Users CAN use Safety Fund anytime (rescue never blocked)
  /// - Journey penalties encourage using external coverage first
  /// - Higher user share if they skip their own coverage
  ///
  /// Penalty Logic:
  /// - Has external + uses it: Normal journey benefits (80-100% fund share)
  /// - Has external + uses Safety Fund: PENALTY (40% fund / 60% user)
  /// - No external: Normal journey progression
  ///
  /// Example scenarios:
  /// - Scenario 1: User has WorkCover, uses it
  ///   → WorkCover handles rescue
  ///   → Safety Fund: $0
  ///   → Journey: Continues normally ✅
  ///
  /// - Scenario 2: User has WorkCover, uses Safety Fund instead
  ///   → Safety Fund: 40% ($1200 on $3000)
  ///   → User pays: 60% ($1800)
  ///   → Journey: Penalty applied (higher cost discourages this)
  ///
  /// - Scenario 3: User has NO coverage
  ///   → Safety Fund: 80-100% (based on journey stage)
  ///   → User pays: 0-20%
  ///   → Journey: Normal progression
  double calculateSafetyFundShareWithExternal(
    SafetyFundProfile profile,
    double totalCost,
    double externalCoverageAmount,
  ) {
    // Calculate remaining gap after external coverage
    final gapAmount = totalCost - externalCoverageAmount;

    if (gapAmount <= 0) {
      // External covered everything - Safety Fund pays nothing!
      // Journey progress unaffected!
      return 0.0;
    }

    // Safety Fund covers 80-100% of the GAP (not total cost)
    return profile.calculateFundShare(gapAmount);
  }

  /// Apply non-member assistance and update Community Hero profile.
  ///
  /// 🟣 SAFE DESIGN - Partial Reset:
  /// - Resets journey to 5-year stage (Stage 4: Helicopter Support)
  /// - Hero retains 90% coverage for their own rescues
  /// - Needs only 5 more years to regain Community Hero status
  /// - Does NOT go back to Stage 1 (prevents discouragement)
  ///
  /// This encourages Heroes to use this privilege without fear of
  /// losing all their progress. They remain highly protected members.
  SafetyFundProfile applyNonMemberAssistance(SafetyFundProfile profile) {
    final now = DateTime.now();

    // Reset to 5-year stage (60 months = Stage 4)
    // This is the key feature: NOT back to Stage 1!
    return profile.copyWith(
      lastClaimAt: now,
      monthsWithoutClaim: SafetyFundProfile.heroResetToMonths, // 60 months
      journeyStage: SafetyJourneyStage.stage4_2to5Years, // Stage 4
      usageState: SafetyFundUsageState.normal, // NOT rebalancing
      // Note: Hero maintains normal usage state, not rebalancing
      // This is generous recognition of their contribution
    );
  }
}
