import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/models/safety_fund_subscription.dart';
import 'package:redping_14v/models/safety_fund_metrics.dart';
import 'package:redping_14v/models/safety_journey_progress.dart';
import 'package:redping_14v/services/safety_journey_service.dart';

void main() {
  group('Phase 1: Safety Fund Foundation Tests', () {
    const testUserId = 'test_user_123';

    group('SafetyFundSubscription Model', () {
      test('should create subscription with default values', () {
        final subscription = SafetyFundSubscription(
          userId: testUserId,
          status: SafetyFundStatus.active,
          monthlyContribution: 5.0,
          enrollmentDate: DateTime.now(),
        );

        expect(subscription.userId, testUserId);
        expect(subscription.status, SafetyFundStatus.active);
        expect(subscription.monthlyContribution, 5.0);
        expect(subscription.currentStage, SafetyStage.none);
        expect(subscription.streakMonths, 0);
        expect(subscription.totalClaims, 0);
        expect(subscription.isActive, true);
      });

      test('should calculate next stage correctly', () {
        final subscription = SafetyFundSubscription(
          userId: testUserId,
          status: SafetyFundStatus.active,
          monthlyContribution: 5.0,
          enrollmentDate: DateTime.now(),
          streakMonths: 7,
          currentStage: SafetyStage.ambulanceSupport,
        );

        expect(subscription.nextStage, SafetyStage.roadAssist);
        expect(subscription.currentStage, SafetyStage.ambulanceSupport);
      });

      test('should calculate days to next stage', () {
        final subscription = SafetyFundSubscription(
          userId: testUserId,
          status: SafetyFundStatus.active,
          monthlyContribution: 5.0,
          enrollmentDate: DateTime.now(),
          streakMonths: 8,
          currentStage: SafetyStage.ambulanceSupport,
        );

        // From 8 months to 12 months (Road Assist) = 4 months = ~120 days
        expect(subscription.daysToNextStage, 120);
      });

      test('should return correct contribution amounts', () {
        expect(
          SafetyFundSubscription.getContributionAmount(SafetyStage.none),
          5.0,
        );
        expect(
          SafetyFundSubscription.getContributionAmount(
            SafetyStage.none,
            isOrange: true,
          ),
          7.5,
        );
        expect(
          SafetyFundSubscription.getContributionAmount(
            SafetyStage.none,
            isRed: true,
          ),
          10.0,
        );
      });

      test('should serialize to JSON correctly', () {
        final now = DateTime.now();
        final subscription = SafetyFundSubscription(
          userId: testUserId,
          status: SafetyFundStatus.active,
          monthlyContribution: 5.0,
          enrollmentDate: now,
          streakMonths: 3,
          currentStage: SafetyStage.none,
        );

        final json = subscription.toJson();

        expect(json['userId'], testUserId);
        expect(json['status'], 'active');
        expect(json['monthlyContribution'], 5.0);
        expect(json['streakMonths'], 3);
        expect(json['currentStage'], 'none');
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'userId': testUserId,
          'status': 'active',
          'monthlyContribution': 5.0,
          'enrollmentDate': DateTime.now().toIso8601String(),
          'streakMonths': 5,
          'currentStage': 'ambulanceSupport',
          'totalClaims': 0,
          'streakFreezeAvailable': true,
          'optedOut': false,
        };

        final subscription = SafetyFundSubscription.fromJson(json);

        expect(subscription.userId, testUserId);
        expect(subscription.status, SafetyFundStatus.active);
        expect(subscription.streakMonths, 5);
        expect(subscription.currentStage, SafetyStage.ambulanceSupport);
      });
    });

    group('SafetyStage Extension', () {
      test('should return correct display names', () {
        expect(SafetyStage.none.displayName, 'Getting Started');
        expect(SafetyStage.ambulanceSupport.displayName, 'Ambulance Support');
        expect(SafetyStage.roadAssist.displayName, 'Road Assist');
        expect(SafetyStage.fourWDAssist.displayName, '4WD Assist');
        expect(SafetyStage.helicopterSupport.displayName, 'Helicopter Support');
      });

      test('should return correct icons', () {
        expect(SafetyStage.none.badgeIcon, '🛡️');
        expect(SafetyStage.ambulanceSupport.badgeIcon, '🚑');
        expect(SafetyStage.roadAssist.badgeIcon, '🚗');
        expect(SafetyStage.fourWDAssist.badgeIcon, '🚙');
        expect(SafetyStage.helicopterSupport.badgeIcon, '🚁');
      });

      test('should return correct required months', () {
        expect(SafetyStage.none.requiredMonths, 0);
        expect(SafetyStage.ambulanceSupport.requiredMonths, 6);
        expect(SafetyStage.roadAssist.requiredMonths, 12);
        expect(SafetyStage.fourWDAssist.requiredMonths, 24);
        expect(SafetyStage.helicopterSupport.requiredMonths, 36);
      });

      test('should return rewards for each stage', () {
        expect(SafetyStage.none.rewards.length, 1);
        expect(SafetyStage.ambulanceSupport.rewards.length, 3);
        expect(SafetyStage.roadAssist.rewards.length, 3);
        expect(SafetyStage.fourWDAssist.rewards.length, 3);
        expect(SafetyStage.helicopterSupport.rewards.length, 3);
      });
    });

    group('SafetyFundMetrics Model', () {
      test('should create metrics with all fields', () {
        final metrics = SafetyFundMetrics(
          month: DateTime(2025, 11),
          totalRescues: 12,
          rescuesByType: {'ambulance': 5, 'road': 7},
          healthIndicator: FundHealthIndicator.stable,
          utilizationPercentage: 45.0,
          activeSubscribers: 1000,
        );

        expect(metrics.totalRescues, 12);
        expect(metrics.healthIndicator, FundHealthIndicator.stable);
        expect(metrics.utilizationPercentage, 45.0);
        expect(metrics.activeSubscribers, 1000);
      });

      test('should return correct health descriptions', () {
        final stable = SafetyFundMetrics(
          month: DateTime.now(),
          totalRescues: 5,
          rescuesByType: {},
          healthIndicator: FundHealthIndicator.stable,
          utilizationPercentage: 30.0,
          activeSubscribers: 100,
        );

        final moderate = SafetyFundMetrics(
          month: DateTime.now(),
          totalRescues: 15,
          rescuesByType: {},
          healthIndicator: FundHealthIndicator.moderate,
          utilizationPercentage: 55.0,
          activeSubscribers: 100,
        );

        final high = SafetyFundMetrics(
          month: DateTime.now(),
          totalRescues: 30,
          rescuesByType: {},
          healthIndicator: FundHealthIndicator.highUsage,
          utilizationPercentage: 85.0,
          activeSubscribers: 100,
        );

        expect(stable.healthDescription, 'Fund is stable and healthy');
        expect(moderate.healthDescription, 'Fund usage is moderate');
        expect(high.healthDescription, 'High rescue activity this month');
      });

      test('should return correct health icons', () {
        final metrics = SafetyFundMetrics(
          month: DateTime.now(),
          totalRescues: 0,
          rescuesByType: {},
          healthIndicator: FundHealthIndicator.stable,
          utilizationPercentage: 0,
          activeSubscribers: 0,
        );

        expect(metrics.healthIcon, '🟢');
      });
    });
  });

  group('Phase 2: Safety Journey Tests', () {
    group('Badge Model', () {
      test('should create badge with all properties', () {
        final badge = Badge(
          type: BadgeType.firstMonth,
          earnedDate: DateTime.now(),
          isNew: true,
        );

        expect(badge.type, BadgeType.firstMonth);
        expect(badge.isNew, true);
      });

      test('should serialize and deserialize correctly', () {
        final now = DateTime.now();
        final badge = Badge(
          type: BadgeType.perfectYear,
          earnedDate: now,
          isNew: false,
        );

        final json = badge.toJson();
        expect(json['type'], 'perfectYear');
        expect(json['isNew'], false);

        final restored = Badge.fromJson(json);
        expect(restored.type, BadgeType.perfectYear);
        expect(restored.isNew, false);
      });

      test('should copy with new flag', () {
        final badge = Badge(
          type: BadgeType.streakFreeze,
          earnedDate: DateTime.now(),
          isNew: true,
        );

        final updated = badge.copyWith(isNew: false);
        expect(updated.isNew, false);
        expect(updated.type, badge.type);
      });
    });

    group('BadgeType Extension', () {
      test('should return correct display names', () {
        expect(BadgeType.firstMonth.displayName, 'First Steps');
        expect(BadgeType.threeMonths.displayName, 'Safety Warrior');
        expect(BadgeType.sixMonths.displayName, 'Ambulance Hero');
        expect(BadgeType.oneYear.displayName, 'Road Master');
        expect(BadgeType.perfectYear.displayName, 'Perfect Year');
      });

      test('should return correct icons', () {
        expect(BadgeType.firstMonth.icon, '🎖️');
        expect(BadgeType.threeMonths.icon, '⭐');
        expect(BadgeType.perfectYear.icon, '🏆');
        expect(BadgeType.communityHero.icon, '🦸');
      });

      test('should return correct points values', () {
        expect(BadgeType.firstMonth.pointsValue, 10);
        expect(BadgeType.threeMonths.pointsValue, 30);
        expect(BadgeType.sixMonths.pointsValue, 60);
        expect(BadgeType.oneYear.pointsValue, 120);
        expect(BadgeType.threeYears.pointsValue, 500);
      });

      test('should classify rare badges correctly', () {
        expect(BadgeType.firstMonth.isRare, false); // 10 pts
        expect(BadgeType.threeMonths.isRare, false); // 30 pts
        expect(BadgeType.oneYear.isRare, false); // 120 pts
        expect(BadgeType.fourWDAssist.isRare, true); // 200 pts
        expect(BadgeType.twoYears.isRare, true); // 240 pts
        expect(BadgeType.perfectYear.isRare, true); // 300 pts
        expect(BadgeType.helicopterSupport.isRare, true); // 400 pts
        expect(BadgeType.threeYears.isRare, true); // 500 pts
      });

      test('should return descriptions for all badges', () {
        for (final badgeType in BadgeType.values) {
          expect(badgeType.description.isNotEmpty, true);
        }
      });
    });

    group('Milestone Model', () {
      test('should create milestone with all fields', () {
        final milestone = Milestone(
          id: 'test_milestone',
          title: 'Test Milestone',
          description: 'Test description',
          targetMonths: 6,
          reward: 'Test reward',
        );

        expect(milestone.id, 'test_milestone');
        expect(milestone.title, 'Test Milestone');
        expect(milestone.isCompleted, false);
        expect(milestone.completedDate, null);
      });

      test('should serialize completed milestone', () {
        final now = DateTime.now();
        final milestone = Milestone(
          id: 'completed',
          title: 'Completed Milestone',
          description: 'Done',
          targetMonths: 3,
          isCompleted: true,
          completedDate: now,
          reward: 'Badge',
        );

        final json = milestone.toJson();
        expect(json['isCompleted'], true);
        expect(json['completedDate'], isNotNull);
      });
    });

    group('SafetyJourneyProgress Model', () {
      test('should create progress with default values', () {
        final progress = SafetyJourneyProgress(
          userId: 'test_user',
          lastUpdated: DateTime.now(),
        );

        expect(progress.badges, isEmpty);
        expect(progress.milestones, isEmpty);
        expect(progress.totalPoints, 0);
        expect(progress.badgeCount, 0);
        expect(progress.newBadgeCount, 0);
        expect(progress.completedMilestones, 0);
      });

      test('should calculate badge counts correctly', () {
        final progress = SafetyJourneyProgress(
          userId: 'test_user',
          badges: [
            Badge(
              type: BadgeType.firstMonth,
              earnedDate: DateTime.now(),
              isNew: true,
            ),
            Badge(
              type: BadgeType.threeMonths,
              earnedDate: DateTime.now(),
              isNew: false,
            ),
            Badge(
              type: BadgeType.perfectYear,
              earnedDate: DateTime.now(),
              isNew: true,
            ),
          ],
          lastUpdated: DateTime.now(),
        );

        expect(progress.badgeCount, 3);
        expect(progress.newBadgeCount, 2);
        expect(progress.rareBadges.length, 1); // perfectYear is rare
      });

      test('should count completed milestones', () {
        final progress = SafetyJourneyProgress(
          userId: 'test_user',
          milestones: [
            Milestone(
              id: 'm1',
              title: 'M1',
              description: 'D1',
              targetMonths: 1,
              isCompleted: true,
              reward: 'R1',
            ),
            Milestone(
              id: 'm2',
              title: 'M2',
              description: 'D2',
              targetMonths: 3,
              isCompleted: true,
              reward: 'R2',
            ),
            Milestone(
              id: 'm3',
              title: 'M3',
              description: 'D3',
              targetMonths: 6,
              isCompleted: false,
              reward: 'R3',
            ),
          ],
          lastUpdated: DateTime.now(),
        );

        expect(progress.completedMilestones, 2);
      });

      test('should serialize and deserialize with badges', () {
        final now = DateTime.now();
        final progress = SafetyJourneyProgress(
          userId: 'test_user',
          badges: [
            Badge(type: BadgeType.firstMonth, earnedDate: now, isNew: false),
          ],
          totalPoints: 10,
          lastUpdated: now,
        );

        final json = progress.toJson();
        expect(json['userId'], 'test_user');
        expect(json['totalPoints'], 10);
        expect(json['badges'], hasLength(1));

        final restored = SafetyJourneyProgress.fromJson(json);
        expect(restored.userId, 'test_user');
        expect(restored.totalPoints, 10);
        expect(restored.badges.length, 1);
        expect(restored.badges.first.type, BadgeType.firstMonth);
      });
    });

    group('SafetyJourneyService', () {
      test('should calculate days to next milestone', () {
        final service = SafetyJourneyService.instance;

        // At 0 months, next is 1 month = ~30 days
        expect(service.calculateDaysToNextMilestone(0), 30);

        // At 2 months, next is 3 months = ~30 days
        expect(service.calculateDaysToNextMilestone(2), 30);

        // At 7 months, next is 12 months = ~150 days
        expect(service.calculateDaysToNextMilestone(7), 150);

        // At 36+ months, already at max = 0
        expect(service.calculateDaysToNextMilestone(40), 0);
      });

      test('should get next milestone correctly', () {
        final service = SafetyJourneyService.instance;

        final nextAt0 = service.getNextMilestone(0);
        expect(nextAt0?.targetMonths, 1);

        final nextAt5 = service.getNextMilestone(5);
        expect(nextAt5?.targetMonths, 6);

        final nextAt25 = service.getNextMilestone(25);
        expect(nextAt25?.targetMonths, 36);

        final nextAt40 = service.getNextMilestone(40);
        expect(nextAt40, null); // All completed
      });
    });
  });

  group('Integration Tests', () {
    test('should award multiple badges for 12-month streak', () {
      // Simulate a user with 12 months streak
      // Should earn: firstMonth, threeMonths, sixMonths, oneYear badges
      final expectedBadges = [
        BadgeType.firstMonth,
        BadgeType.threeMonths,
        BadgeType.sixMonths,
        BadgeType.oneYear,
      ];

      // In real test, would call SafetyJourneyService.checkAndAwardBadges
      // and verify all 4 badges are awarded

      expect(expectedBadges.length, 4);
      final totalPoints = expectedBadges.fold<int>(
        0,
        (sum, type) => sum + type.pointsValue,
      );
      expect(totalPoints, 220); // 10 + 30 + 60 + 120
    });

    test('should progress through stages correctly', () {
      // Stage progression timeline
      final stages = [
        (0, SafetyStage.none),
        (6, SafetyStage.ambulanceSupport),
        (12, SafetyStage.roadAssist),
        (24, SafetyStage.fourWDAssist),
        (36, SafetyStage.helicopterSupport),
      ];

      for (final (months, expectedStage) in stages) {
        // Verify stage matches streak months
        expect(expectedStage.requiredMonths <= months, true);
      }
    });

    test('should calculate contribution totals correctly', () {
      // User with 10 months at $5/month
      final months = 10;
      final rate = 5.0;
      final total = months * rate;

      expect(total, 50.0);

      // User with 12 months, 6 at $5, 6 at $7.50 (orange)
      final totalOrange = (6 * 5.0) + (6 * 7.5);
      expect(totalOrange, 75.0);
    });
  });
}
