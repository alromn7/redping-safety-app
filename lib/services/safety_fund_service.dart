import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/safety_fund_profile.dart';
import '../models/safety_fund_metrics.dart';
import '../models/safety_fund_subscription.dart';
import '../domain/safety/safety_fund_policy.dart';
import '../core/config/feature_flags.dart';

/// Service for managing Safety Fund subscriptions
class SafetyFundService {
  static final SafetyFundService _instance = SafetyFundService._internal();
  static SafetyFundService get instance => _instance;

  SafetyFundService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for reducing redundant Firestore reads
  final Map<String, SafetyFundProfile> _profileCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(minutes: 5);

  // Policy for business rules
  final SafetyFundPolicy _policy = const SafetyFundPolicy();

  /// Get user's Safety Fund profile (with caching)
  Future<SafetyFundProfile?> getProfile(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return null;
    try {
      // Check cache first
      final cachedTimestamp = _cacheTimestamps[userId];
      if (cachedTimestamp != null &&
          DateTime.now().difference(cachedTimestamp) < _cacheDuration) {
        debugPrint('✅ Using cached Safety Fund profile for $userId');
        return _profileCache[userId];
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .get();

      if (!doc.exists) {
        _profileCache.remove(userId);
        _cacheTimestamps.remove(userId);
        return null;
      }

      final profile = SafetyFundProfile.fromJson(doc.data()!);

      // Update cache
      _profileCache[userId] = profile;
      _cacheTimestamps[userId] = DateTime.now();

      return profile;
    } catch (e) {
      debugPrint('Error getting Safety Fund profile: $e');
      return null;
    }
  }

  /// Legacy method for backward compatibility - returns subscription view
  @Deprecated('Use getProfile instead')
  Future<SafetyFundSubscription?> getSubscription(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return null;
    final profile = await getProfile(userId);
    if (profile == null) return null;
    return _toSubscription(profile);
  }

  /// Clear cache for a specific user (call after updates)
  void clearCache(String userId) {
    _profileCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Stream of user's Safety Fund profile
  Stream<SafetyFundProfile?> profileStream(String userId) {
    if (!FeatureFlags.enableSafetyFund) {
      return Stream.value(null);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('safetyFund')
        .doc('profile')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return SafetyFundProfile.fromJson(doc.data()!);
        });
  }

  /// Legacy method for backward compatibility - maps profile to subscription
  @Deprecated('Use profileStream instead')
  Stream<SafetyFundSubscription?> subscriptionStream(String userId) {
    if (!FeatureFlags.enableSafetyFund) {
      return Stream.value(null);
    }
    return profileStream(userId).map((profile) {
      if (profile == null) return null;
      return _toSubscription(profile);
    });
  }

  /// Enroll user in Safety Fund
  Future<void> enrollInSafetyFund(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return;
    try {
      final profile = SafetyFundProfile.initial(userId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .set(profile.toJson());

      clearCache(userId); // Invalidate cache
      debugPrint('✅ User enrolled in Safety Fund: $userId');
    } catch (e) {
      debugPrint('❌ Error enrolling in Safety Fund: $e');
      rethrow;
    }
  }

  /// Opt out of Safety Fund
  Future<void> optOutOfSafetyFund(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .update({'isActive': false});

      clearCache(userId); // Invalidate cache
      debugPrint('User opted out of Safety Fund: $userId');
    } catch (e) {
      debugPrint('Error opting out of Safety Fund: $e');
      rethrow;
    }
  }

  /// Calculate billing split for a rescue cost
  BillingSplit calculateBillingSplit(SafetyFundProfile profile) {
    return _policy.resolveBillingSplit(profile);
  }

  /// Calculate fund's share of rescue cost
  double calculateFundShare(SafetyFundProfile profile, double totalCost) {
    return profile.calculateFundShare(totalCost);
  }

  /// Calculate user's share of rescue cost
  double calculateUserShare(SafetyFundProfile profile, double totalCost) {
    return profile.calculateUserShare(totalCost);
  }

  /// Check if streak freeze is available
  Future<bool> checkStreakFreezeAvailability(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile == null) return false;

      return _policy.canRenewStreakFreeze(profile);
    } catch (e) {
      debugPrint('Error checking streak freeze: $e');
      return false;
    }
  }

  /// Use streak freeze to protect progress
  Future<void> useStreakFreeze(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .update({'streakFreezeAvailable': false});

      clearCache(userId);
      debugPrint('✅ Streak freeze used for user: $userId');
    } catch (e) {
      debugPrint('❌ Error using streak freeze: $e');
      rethrow;
    }
  }

  /// Apply claim and update profile using SafetyFundPolicy
  Future<void> applyClaim(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return;
    try {
      final profile = await getProfile(userId);
      if (profile == null) return;

      // Use policy to calculate new profile state
      final updatedProfile = _policy.applyClaim(profile);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .set(updatedProfile.toJson());

      clearCache(userId);
      debugPrint('⚠️ Claim applied, profile updated for user: $userId');
    } catch (e) {
      debugPrint('❌ Error applying claim: $e');
      rethrow;
    }
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use applyClaim instead')
  Future<void> resetStageAfterClaim(String userId) => applyClaim(userId);

  /// Get current fund metrics
  Future<SafetyFundMetrics?> getCurrentMetrics() async {
    if (!FeatureFlags.enableSafetyFund) {
      final now = DateTime.now();
      return SafetyFundMetrics(
        month: now,
        totalRescues: 0,
        rescuesByType: const {},
        healthIndicator: FundHealthIndicator.stable,
        utilizationPercentage: 0.0,
        activeSubscribers: 0,
        successStories: const [],
      );
    }
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('safetyFund')
          .doc('metrics')
          .collection('monthly')
          .doc(monthKey)
          .get();

      if (!doc.exists) {
        // Return default metrics if not available
        return SafetyFundMetrics(
          month: now,
          totalRescues: 0,
          rescuesByType: {},
          healthIndicator: FundHealthIndicator.stable,
          utilizationPercentage: 0.0,
          activeSubscribers: 0,
          successStories: [],
        );
      }

      return SafetyFundMetrics.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting fund metrics: $e');
      return null;
    }
  }

  /// Stream of current metrics
  Stream<SafetyFundMetrics?> currentMetricsStream() {
    if (!FeatureFlags.enableSafetyFund) {
      final now = DateTime.now();
      return Stream<SafetyFundMetrics?>.value(
        SafetyFundMetrics(
          month: now,
          totalRescues: 0,
          rescuesByType: const {},
          healthIndicator: FundHealthIndicator.stable,
          utilizationPercentage: 0.0,
          activeSubscribers: 0,
          successStories: const [],
        ),
      );
    }
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return _firestore
        .collection('safetyFund')
        .doc('metrics')
        .collection('monthly')
        .doc(monthKey)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return SafetyFundMetrics(
              month: now,
              totalRescues: 0,
              rescuesByType: {},
              healthIndicator: FundHealthIndicator.stable,
              utilizationPercentage: 0.0,
              activeSubscribers: 0,
            );
          }
          return SafetyFundMetrics.fromJson(doc.data()!);
        });
  }

  /// Check if user has Safety Fund active
  Future<bool> hasActiveFund(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return false;
    try {
      final profile = await getProfile(userId);
      return profile?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking fund status: $e');
      return false;
    }
  }

  /// Recalculate and update journey stage based on time
  Future<void> updateJourneyStage(String userId) async {
    if (!FeatureFlags.enableSafetyFund) return;
    try {
      final profile = await getProfile(userId);
      if (profile == null) return;

      // Calculate current months without claim
      final months = _policy.calculateMonthsWithoutClaim(
        profile.joinedAt,
        profile.lastClaimAt,
      );

      // Create updated profile with recalculated stage
      final updatedProfile = profile.copyWith(monthsWithoutClaim: months);

      // Apply policy calculations
      final finalProfile = _policy.recalculateJourneyStage(updatedProfile);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('profile')
          .set(finalProfile.toJson());

      clearCache(userId);
      debugPrint('✅ Journey stage updated for user: $userId');
    } catch (e) {
      debugPrint('❌ Error updating journey stage: $e');
      rethrow;
    }
  }
}

extension on SafetyFundService {
  /// Map the canonical SafetyFundProfile to the legacy SafetyFundSubscription
  SafetyFundSubscription _toSubscription(SafetyFundProfile profile) {
    // Map journey stages to legacy stages
    SafetyStage stage;
    switch (profile.journeyStage) {
      case SafetyJourneyStage.stage1_0to6Months:
        stage = SafetyStage.ambulanceSupport;
        break;
      case SafetyJourneyStage.stage2_6to12Months:
        stage = SafetyStage.roadAssist;
        break;
      case SafetyJourneyStage.stage3_1to2Years:
        stage = SafetyStage.fourWDAssist;
        break;
      case SafetyJourneyStage.stage4_2to5Years:
        stage = SafetyStage.helicopterSupport;
        break;
      case SafetyJourneyStage.stage5_5plusYears:
        // Legacy model tops out at Helicopter Support
        stage = SafetyStage.helicopterSupport;
        break;
    }

    return SafetyFundSubscription(
      userId: profile.userId,
      status: profile.isActive
          ? SafetyFundStatus.active
          : SafetyFundStatus.inactive,
      monthlyContribution: profile.monthlyContribution,
      enrollmentDate: profile.joinedAt,
      lastContributionDate: null,
      currentStage: stage,
      streakMonths: profile.monthsWithoutClaim,
      lastClaimDate: profile.lastClaimAt,
      totalClaims: 0, // Not tracked in profile; default to 0
      streakFreezeAvailable: profile.streakFreezeAvailable,
      streakFreezeUsedDate: null,
      optedOut: !profile.isActive,
    );
  }
}
