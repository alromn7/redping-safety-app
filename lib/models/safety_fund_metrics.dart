import 'package:cloud_firestore/cloud_firestore.dart';
import 'safety_fund_subscription.dart';

/// Transparent metrics shown to users (no actual balances)
class SafetyFundMetrics {
  final DateTime month;
  final int totalRescues;
  final Map<String, int> rescuesByType;
  final FundHealthIndicator healthIndicator;
  final double utilizationPercentage;
  final int activeSubscribers;
  final List<AnonymousRescueStory> successStories;

  SafetyFundMetrics({
    required this.month,
    required this.totalRescues,
    required this.rescuesByType,
    required this.healthIndicator,
    required this.utilizationPercentage,
    required this.activeSubscribers,
    this.successStories = const [],
  });

  String get healthDescription {
    switch (healthIndicator) {
      case FundHealthIndicator.stable:
        return 'Fund is stable and healthy';
      case FundHealthIndicator.moderate:
        return 'Fund usage is moderate';
      case FundHealthIndicator.highUsage:
        return 'High rescue activity this month';
    }
  }

  String get healthIcon {
    switch (healthIndicator) {
      case FundHealthIndicator.stable:
        return '🟢';
      case FundHealthIndicator.moderate:
        return '🟡';
      case FundHealthIndicator.highUsage:
        return '🔴';
    }
  }

  Map<String, dynamic> toJson() => {
    'month': Timestamp.fromDate(month),
    'totalRescues': totalRescues,
    'rescuesByType': rescuesByType,
    'healthIndicator': healthIndicator.name,
    'utilizationPercentage': utilizationPercentage,
    'activeSubscribers': activeSubscribers,
    'successStories': successStories.map((s) => s.toJson()).toList(),
  };

  factory SafetyFundMetrics.fromJson(Map<String, dynamic> json) =>
      SafetyFundMetrics(
        month: (json['month'] as Timestamp).toDate(),
        totalRescues: json['totalRescues'] as int,
        rescuesByType: Map<String, int>.from(json['rescuesByType'] as Map),
        healthIndicator: FundHealthIndicator.values.firstWhere(
          (e) => e.name == json['healthIndicator'],
          orElse: () => FundHealthIndicator.stable,
        ),
        utilizationPercentage: (json['utilizationPercentage'] as num)
            .toDouble(),
        activeSubscribers: json['activeSubscribers'] as int,
        successStories:
            (json['successStories'] as List?)
                ?.map(
                  (s) =>
                      AnonymousRescueStory.fromJson(s as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

/// Anonymous rescue story for community inspiration
class AnonymousRescueStory {
  final String id;
  final String title;
  final String rescueType;
  final String region;
  final DateTime date;
  final String description;
  final List<String> tags;

  AnonymousRescueStory({
    required this.id,
    required this.title,
    required this.rescueType,
    required this.region,
    required this.date,
    required this.description,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'rescueType': rescueType,
    'region': region,
    'date': Timestamp.fromDate(date),
    'description': description,
    'tags': tags,
  };

  factory AnonymousRescueStory.fromJson(Map<String, dynamic> json) =>
      AnonymousRescueStory(
        id: json['id'] as String,
        title: json['title'] as String,
        rescueType: json['rescueType'] as String,
        region: json['region'] as String,
        date: (json['date'] as Timestamp).toDate(),
        description: json['description'] as String,
        tags: (json['tags'] as List?)?.map((t) => t as String).toList() ?? [],
      );
}
