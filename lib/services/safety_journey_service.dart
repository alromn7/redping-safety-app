import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/safety_journey_progress.dart';
import '../models/safety_fund_subscription.dart';
import 'safety_fund_service.dart';

/// Service for managing safety journey progress, badges, and milestones
class SafetyJourneyService {
  static final SafetyJourneyService _instance =
      SafetyJourneyService._internal();
  static SafetyJourneyService get instance => _instance;

  SafetyJourneyService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _firestoreOrNull {
    if (_firestore != null) return _firestore;
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('⚠️ SafetyJourneyService: Firestore unavailable: $e');
      _firestore = null;
    }
    return _firestore;
  }

  /// Get user's journey progress
  Future<SafetyJourneyProgress?> getProgress(String userId) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('journey')
          .get();

      if (!doc.exists) {
        // Initialize new journey progress
        return await _initializeProgress(userId);
      }

      return SafetyJourneyProgress.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting journey progress: $e');
      return null;
    }
  }

  /// Stream of journey progress
  Stream<SafetyJourneyProgress?> progressStream(String userId) {
    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return const Stream<SafetyJourneyProgress?>.empty();
    }

    return firestore
        .collection('users')
        .doc(userId)
        .collection('safetyFund')
        .doc('journey')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return SafetyJourneyProgress.fromJson(doc.data()!);
        });
  }

  /// Create recovery milestone after rescue
  Future<void> createRecoveryMilestone(String incidentId) async {
    // Recovery milestone implementation
    debugPrint('🏥 Recovery milestone created for incident: $incidentId');
  }

  /// Initialize journey progress for new user
  Future<SafetyJourneyProgress> _initializeProgress(String userId) async {
    final progress = SafetyJourneyProgress(
      userId: userId,
      badges: [],
      milestones: _createDefaultMilestones(),
      totalPoints: 0,
      lastUpdated: DateTime.now(),
      insights: {},
    );

    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return progress;
    }

    await firestore
        .collection('users')
        .doc(userId)
        .collection('safetyFund')
        .doc('journey')
        .set(progress.toJson());

    return progress;
  }

  /// Create default milestones for journey
  List<Milestone> _createDefaultMilestones() {
    return [
      Milestone(
        id: 'first_month',
        title: 'First Month Safe',
        description: 'Complete your first month without incidents',
        targetMonths: 1,
        reward: 'First Steps badge',
      ),
      Milestone(
        id: 'three_months',
        title: '3 Months Safe',
        description: 'Maintain safety for 3 consecutive months',
        targetMonths: 3,
        reward: 'Safety Warrior badge',
      ),
      Milestone(
        id: 'ambulance_stage',
        title: 'Ambulance Support',
        description: 'Reach Ambulance Support stage (6 months)',
        targetMonths: 6,
        reward: 'Life Saver badge + safety summary',
      ),
      Milestone(
        id: 'one_year',
        title: 'One Year Safe',
        description: '12 months of continuous safety',
        targetMonths: 12,
        reward: 'Road Master badge + Driving risk report',
      ),
      Milestone(
        id: 'road_assist_stage',
        title: 'Road Assist',
        description: 'Reach Road Assist stage (12 months)',
        targetMonths: 12,
        reward: 'Road Guardian badge + Cloud history',
      ),
      Milestone(
        id: 'two_years',
        title: 'Two Years Safe',
        description: '24 months without incidents',
        targetMonths: 24,
        reward: '4WD Champion badge + Route analysis',
      ),
      Milestone(
        id: 'fourwd_stage',
        title: '4WD Assist',
        description: 'Reach 4WD Assist stage (24 months)',
        targetMonths: 24,
        reward: 'Off-Road Expert badge + Hazard alerts',
      ),
      Milestone(
        id: 'three_years',
        title: 'Three Years Safe',
        description: 'Elite 36-month achievement',
        targetMonths: 36,
        reward: 'Helicopter Legend badge + Priority support',
      ),
      Milestone(
        id: 'helicopter_stage',
        title: 'Helicopter Support',
        description: 'Reach highest stage (36 months)',
        targetMonths: 36,
        reward: 'Sky Rescuer badge + Lifetime discount',
      ),
    ];
  }

  /// Check and award badges based on progress
  Future<List<Badge>> checkAndAwardBadges(String userId) async {
    try {
      final subscription = await SafetyFundService.instance.getSubscription(
        userId,
      );
      if (subscription == null || !subscription.isActive) return [];

      final progress = await getProgress(userId);
      if (progress == null) return [];

      final newBadges = <Badge>[];
      final streakMonths = subscription.streakMonths;

      // Check streak milestones
      if (streakMonths >= 1 && !_hasBadge(progress, BadgeType.firstMonth)) {
        newBadges.add(_createBadge(BadgeType.firstMonth));
      }
      if (streakMonths >= 3 && !_hasBadge(progress, BadgeType.threeMonths)) {
        newBadges.add(_createBadge(BadgeType.threeMonths));
      }
      if (streakMonths >= 6 && !_hasBadge(progress, BadgeType.sixMonths)) {
        newBadges.add(_createBadge(BadgeType.sixMonths));
      }
      if (streakMonths >= 12 && !_hasBadge(progress, BadgeType.oneYear)) {
        newBadges.add(_createBadge(BadgeType.oneYear));
      }
      if (streakMonths >= 24 && !_hasBadge(progress, BadgeType.twoYears)) {
        newBadges.add(_createBadge(BadgeType.twoYears));
      }
      if (streakMonths >= 36 && !_hasBadge(progress, BadgeType.threeYears)) {
        newBadges.add(_createBadge(BadgeType.threeYears));
      }

      // Check stage completion badges
      switch (subscription.currentStage) {
        case SafetyStage.ambulanceSupport:
          if (!_hasBadge(progress, BadgeType.ambulanceSupport)) {
            newBadges.add(_createBadge(BadgeType.ambulanceSupport));
          }
          break;
        case SafetyStage.roadAssist:
          if (!_hasBadge(progress, BadgeType.roadAssist)) {
            newBadges.add(_createBadge(BadgeType.roadAssist));
          }
          break;
        case SafetyStage.fourWDAssist:
          if (!_hasBadge(progress, BadgeType.fourWDAssist)) {
            newBadges.add(_createBadge(BadgeType.fourWDAssist));
          }
          break;
        case SafetyStage.helicopterSupport:
          if (!_hasBadge(progress, BadgeType.helicopterSupport)) {
            newBadges.add(_createBadge(BadgeType.helicopterSupport));
          }
          break;
        case SafetyStage.none:
          break;
      }

      // Check perfect year (365 consecutive days)
      if (streakMonths >= 12 && !_hasBadge(progress, BadgeType.perfectYear)) {
        final daysSinceEnrollment = DateTime.now()
            .difference(subscription.enrollmentDate)
            .inDays;
        if (daysSinceEnrollment >= 365 && subscription.totalClaims == 0) {
          newBadges.add(_createBadge(BadgeType.perfectYear));
        }
      }

      // Check streak freeze usage
      if (subscription.streakFreezeUsedDate != null &&
          !_hasBadge(progress, BadgeType.streakFreeze)) {
        newBadges.add(_createBadge(BadgeType.streakFreeze));
      }

      // Award new badges
      if (newBadges.isNotEmpty) {
        await _awardBadges(userId, newBadges);
        await _updateMilestones(userId, streakMonths);
      }

      return newBadges;
    } catch (e) {
      debugPrint('Error checking badges: $e');
      return [];
    }
  }

  /// Check if user has specific badge
  bool _hasBadge(SafetyJourneyProgress progress, BadgeType type) {
    return progress.badges.any((b) => b.type == type);
  }

  /// Create new badge
  Badge _createBadge(BadgeType type) {
    return Badge(type: type, earnedDate: DateTime.now(), isNew: true);
  }

  /// Award badges to user
  Future<void> _awardBadges(String userId, List<Badge> badges) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return;

      final progress = await getProgress(userId);
      if (progress == null) return;

      final updatedBadges = [...progress.badges, ...badges];
      final newPoints = badges.fold<int>(
        0,
        (sum, badge) => sum + badge.type.pointsValue,
      );

      await firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('journey')
          .update({
            'badges': updatedBadges.map((b) => b.toJson()).toList(),
            'totalPoints': FieldValue.increment(newPoints),
            'lastUpdated': Timestamp.now(),
          });

      debugPrint('✅ Awarded ${badges.length} badges to user: $userId');
    } catch (e) {
      debugPrint('❌ Error awarding badges: $e');
      rethrow;
    }
  }

  /// Update milestones based on streak months
  Future<void> _updateMilestones(String userId, int streakMonths) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return;

      final progress = await getProgress(userId);
      if (progress == null) return;

      bool hasUpdates = false;
      final updatedMilestones = progress.milestones.map((milestone) {
        if (!milestone.isCompleted && streakMonths >= milestone.targetMonths) {
          hasUpdates = true;
          return Milestone(
            id: milestone.id,
            title: milestone.title,
            description: milestone.description,
            targetMonths: milestone.targetMonths,
            isCompleted: true,
            completedDate: DateTime.now(),
            reward: milestone.reward,
          );
        }
        return milestone;
      }).toList();

      if (hasUpdates) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('safetyFund')
            .doc('journey')
            .update({
              'milestones': updatedMilestones.map((m) => m.toJson()).toList(),
              'lastUpdated': Timestamp.now(),
            });

        debugPrint('✅ Updated milestones for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error updating milestones: $e');
    }
  }

  /// Mark badges as seen (remove "new" flag)
  Future<void> markBadgesAsSeen(String userId) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return;

      final progress = await getProgress(userId);
      if (progress == null) return;

      final updatedBadges = progress.badges
          .map((b) => b.copyWith(isNew: false))
          .toList();

      await firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('journey')
          .update({
            'badges': updatedBadges.map((b) => b.toJson()).toList(),
            'lastUpdated': Timestamp.now(),
          });

      debugPrint('Badges marked as seen for user: $userId');
    } catch (e) {
      debugPrint('Error marking badges as seen: $e');
    }
  }

  /// Calculate days to next milestone
  int calculateDaysToNextMilestone(int currentMonths) {
    final milestones = _createDefaultMilestones();
    final nextMilestone = milestones.firstWhere(
      (m) => m.targetMonths > currentMonths,
      orElse: () => milestones.last,
    );

    if (nextMilestone.targetMonths <= currentMonths) {
      return 0; // Already at max
    }

    final monthsRemaining = nextMilestone.targetMonths - currentMonths;
    return monthsRemaining * 30; // Approximate days
  }

  /// Get next milestone
  Milestone? getNextMilestone(int currentMonths) {
    final milestones = _createDefaultMilestones();
    try {
      return milestones.firstWhere((m) => m.targetMonths > currentMonths);
    } catch (e) {
      return null; // All milestones completed
    }
  }

  /// Generate insights for journey
  Future<void> generateInsights(String userId) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return;

      final subscription = await SafetyFundService.instance.getSubscription(
        userId,
      );
      if (subscription == null) return;

      final progress = await getProgress(userId);
      if (progress == null) return;

      final insights = <String, dynamic>{
        'streakDays': subscription.streakMonths * 30,
        'totalBadges': progress.badgeCount,
        'rareBadges': progress.rareBadges.length,
        'completedMilestones': progress.completedMilestones,
        'totalMilestones': progress.milestones.length,
        'currentStage': subscription.currentStage.displayName,
        'nextStage': subscription.nextStage.displayName,
        'daysToNextStage': subscription.daysToNextStage,
        'contributionAmount': subscription.monthlyContribution,
        'totalContributed':
            subscription.monthlyContribution * subscription.streakMonths,
        'safetySince': subscription.enrollmentDate.toIso8601String(),
      };

        await firestore
          .collection('users')
          .doc(userId)
          .collection('safetyFund')
          .doc('journey')
          .update({'insights': insights, 'lastUpdated': Timestamp.now()});

      debugPrint('✅ Generated insights for user: $userId');
    } catch (e) {
      debugPrint('❌ Error generating insights: $e');
    }
  }

  /// Get leaderboard position (placeholder for future)
  Future<int?> getLeaderboardPosition(String userId) async {
    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) return null;

      final progress = await getProgress(userId);
      if (progress == null) return null;

      // Query users with higher points
        final querySnapshot = await firestore
          .collectionGroup('journey')
          .where('totalPoints', isGreaterThan: progress.totalPoints)
          .get();

      return querySnapshot.docs.length + 1;
    } catch (e) {
      debugPrint('Error getting leaderboard position: $e');
      return null;
    }
  }
}
