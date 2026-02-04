import 'package:cloud_firestore/cloud_firestore.dart';

/// Badge types in the safety journey
enum BadgeType {
  // Streak milestones
  firstMonth,
  threeMonths,
  sixMonths,
  oneYear,
  twoYears,
  threeYears,

  // Stage completions
  ambulanceSupport,
  roadAssist,
  fourWDAssist,
  helicopterSupport,

  // Special achievements
  streakFreeze,
  perfectYear,
  communityHero,
  earlyAdopter,

  // Activity badges
  safeDriver,
  mountainExplorer,
  desertSurvivor,
  coastalGuardian,
}

extension BadgeTypeExtension on BadgeType {
  String get displayName {
    switch (this) {
      case BadgeType.firstMonth:
        return 'First Steps';
      case BadgeType.threeMonths:
        return 'Safety Warrior';
      case BadgeType.sixMonths:
        return 'Ambulance Hero';
      case BadgeType.oneYear:
        return 'Road Master';
      case BadgeType.twoYears:
        return '4WD Champion';
      case BadgeType.threeYears:
        return 'Helicopter Legend';
      case BadgeType.ambulanceSupport:
        return 'Life Saver';
      case BadgeType.roadAssist:
        return 'Road Guardian';
      case BadgeType.fourWDAssist:
        return 'Off-Road Expert';
      case BadgeType.helicopterSupport:
        return 'Sky Rescuer';
      case BadgeType.streakFreeze:
        return 'Streak Protector';
      case BadgeType.perfectYear:
        return 'Perfect Year';
      case BadgeType.communityHero:
        return 'Community Hero';
      case BadgeType.earlyAdopter:
        return 'Early Adopter';
      case BadgeType.safeDriver:
        return 'Safe Driver';
      case BadgeType.mountainExplorer:
        return 'Mountain Explorer';
      case BadgeType.desertSurvivor:
        return 'Desert Survivor';
      case BadgeType.coastalGuardian:
        return 'Coastal Guardian';
    }
  }

  String get icon {
    switch (this) {
      case BadgeType.firstMonth:
        return '🎖️';
      case BadgeType.threeMonths:
        return '⭐';
      case BadgeType.sixMonths:
        return '🚑';
      case BadgeType.oneYear:
        return '🚗';
      case BadgeType.twoYears:
        return '🚙';
      case BadgeType.threeYears:
        return '🚁';
      case BadgeType.ambulanceSupport:
        return '💊';
      case BadgeType.roadAssist:
        return '🛣️';
      case BadgeType.fourWDAssist:
        return '⛰️';
      case BadgeType.helicopterSupport:
        return '🌟';
      case BadgeType.streakFreeze:
        return '❄️';
      case BadgeType.perfectYear:
        return '🏆';
      case BadgeType.communityHero:
        return '🦸';
      case BadgeType.earlyAdopter:
        return '🚀';
      case BadgeType.safeDriver:
        return '🚦';
      case BadgeType.mountainExplorer:
        return '🏔️';
      case BadgeType.desertSurvivor:
        return '🏜️';
      case BadgeType.coastalGuardian:
        return '🌊';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.firstMonth:
        return 'Completed your first month in the Safety Fund';
      case BadgeType.threeMonths:
        return '3 consecutive safe months';
      case BadgeType.sixMonths:
        return 'Reached Ambulance Support stage';
      case BadgeType.oneYear:
        return '12 months of continuous safety';
      case BadgeType.twoYears:
        return '24 months without incidents';
      case BadgeType.threeYears:
        return 'Elite 36-month achievement';
      case BadgeType.ambulanceSupport:
        return 'Unlocked Ambulance Support coverage';
      case BadgeType.roadAssist:
        return 'Unlocked Road Assist benefits';
      case BadgeType.fourWDAssist:
        return 'Unlocked 4WD Assist coverage';
      case BadgeType.helicopterSupport:
        return 'Unlocked Helicopter Support (highest tier)';
      case BadgeType.streakFreeze:
        return 'Used streak freeze to protect progress';
      case BadgeType.perfectYear:
        return 'Maintained perfect 365-day streak';
      case BadgeType.communityHero:
        return 'Contributed to 10+ successful rescues';
      case BadgeType.earlyAdopter:
        return 'Joined Safety Fund in first month of launch';
      case BadgeType.safeDriver:
        return 'Completed 100+ safe driving sessions';
      case BadgeType.mountainExplorer:
        return 'Safely explored mountain regions';
      case BadgeType.desertSurvivor:
        return 'Completed desert expeditions safely';
      case BadgeType.coastalGuardian:
        return 'Safe coastal adventures';
    }
  }

  int get pointsValue {
    switch (this) {
      case BadgeType.firstMonth:
        return 10;
      case BadgeType.threeMonths:
        return 30;
      case BadgeType.sixMonths:
        return 60;
      case BadgeType.oneYear:
        return 120;
      case BadgeType.twoYears:
        return 240;
      case BadgeType.threeYears:
        return 500;
      case BadgeType.ambulanceSupport:
        return 50;
      case BadgeType.roadAssist:
        return 100;
      case BadgeType.fourWDAssist:
        return 200;
      case BadgeType.helicopterSupport:
        return 400;
      case BadgeType.streakFreeze:
        return 25;
      case BadgeType.perfectYear:
        return 300;
      case BadgeType.communityHero:
        return 150;
      case BadgeType.earlyAdopter:
        return 100;
      case BadgeType.safeDriver:
        return 75;
      case BadgeType.mountainExplorer:
        return 80;
      case BadgeType.desertSurvivor:
        return 90;
      case BadgeType.coastalGuardian:
        return 70;
    }
  }

  bool get isRare => pointsValue >= 200;
}

/// Earned badge record
class Badge {
  final BadgeType type;
  final DateTime earnedDate;
  final bool isNew;

  Badge({required this.type, required this.earnedDate, this.isNew = false});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'earnedDate': Timestamp.fromDate(earnedDate),
    'isNew': isNew,
  };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    type: BadgeType.values.firstWhere((e) => e.name == json['type']),
    earnedDate: (json['earnedDate'] as Timestamp).toDate(),
    isNew: json['isNew'] as bool? ?? false,
  );

  Badge copyWith({bool? isNew}) =>
      Badge(type: type, earnedDate: earnedDate, isNew: isNew ?? this.isNew);
}

/// Journey milestone
class Milestone {
  final String id;
  final String title;
  final String description;
  final int targetMonths;
  final bool isCompleted;
  final DateTime? completedDate;
  final String reward;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMonths,
    this.isCompleted = false,
    this.completedDate,
    required this.reward,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetMonths': targetMonths,
    'isCompleted': isCompleted,
    'completedDate': completedDate != null
        ? Timestamp.fromDate(completedDate!)
        : null,
    'reward': reward,
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    targetMonths: json['targetMonths'] as int,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedDate: json['completedDate'] != null
        ? (json['completedDate'] as Timestamp).toDate()
        : null,
    reward: json['reward'] as String,
  );
}

/// User's safety journey progress
class SafetyJourneyProgress {
  final String userId;
  final List<Badge> badges;
  final List<Milestone> milestones;
  final int totalPoints;
  final DateTime lastUpdated;
  final Map<String, dynamic> insights;

  SafetyJourneyProgress({
    required this.userId,
    this.badges = const [],
    this.milestones = const [],
    this.totalPoints = 0,
    required this.lastUpdated,
    this.insights = const {},
  });

  int get badgeCount => badges.length;
  int get newBadgeCount => badges.where((b) => b.isNew).length;
  int get completedMilestones => milestones.where((m) => m.isCompleted).length;

  List<Badge> get rareBadges => badges.where((b) => b.type.isRare).toList();

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'badges': badges.map((b) => b.toJson()).toList(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'totalPoints': totalPoints,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'insights': insights,
  };

  factory SafetyJourneyProgress.fromJson(Map<String, dynamic> json) =>
      SafetyJourneyProgress(
        userId: json['userId'] as String,
        badges:
            (json['badges'] as List?)
                ?.map((b) => Badge.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        milestones:
            (json['milestones'] as List?)
                ?.map((m) => Milestone.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        totalPoints: json['totalPoints'] as int? ?? 0,
        lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
        insights: json['insights'] as Map<String, dynamic>? ?? {},
      );
}
