import 'package:equatable/equatable.dart';
import 'sos_session.dart'; // For LocationInfo

/// Types of activities users can engage in
enum ActivityType {
  hiking,
  fishing,
  kayaking,
  driving,
  fourWD,
  surfing,
  skydiving,
  remoteWork,
  exploring,
  scubaDiving,
  swimming,
  cycling,
  running,
  camping,
  climbing,
  skiing,
  snowboarding,
  sailing,
  hunting,
  photography,
  geocaching,
  backpacking,
  custom,
}

/// Risk level associated with activities
enum ActivityRiskLevel { low, moderate, high, extreme }

/// Activity status
enum ActivityStatus { planned, active, paused, completed, cancelled }

/// Environment where activity takes place
enum ActivityEnvironment {
  urban,
  suburban,
  rural,
  wilderness,
  water,
  mountain,
  desert,
  forest,
  coastal,
  indoor,
}

/// Safety equipment for activities
class ActivityEquipment extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isRequired;
  final bool isAvailable;
  final DateTime? lastChecked;

  const ActivityEquipment({
    required this.id,
    required this.name,
    this.description,
    required this.isRequired,
    required this.isAvailable,
    this.lastChecked,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'isAvailable': isAvailable,
      'lastChecked': lastChecked?.toIso8601String(),
    };
  }

  factory ActivityEquipment.fromJson(Map<String, dynamic> json) {
    return ActivityEquipment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isRequired: json['isRequired'] as bool,
      isAvailable: json['isAvailable'] as bool,
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    isRequired,
    isAvailable,
    lastChecked,
  ];
}

/// User activity session
class UserActivity extends Equatable {
  final String id;
  final String userId;
  final ActivityType type;
  final String title;
  final String? description;
  final String? customActivityName; // For custom activities
  final ActivityRiskLevel riskLevel;
  final ActivityEnvironment environment;
  final ActivityStatus status;

  // Timing
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? plannedStartTime;
  final DateTime? plannedEndTime;
  final Duration? estimatedDuration;

  // Location
  final LocationInfo? startLocation;
  final LocationInfo? currentLocation;
  final LocationInfo? plannedLocation;
  final List<LocationInfo> breadcrumbs;

  // Safety
  final List<ActivityEquipment> equipment;
  final List<String> safetyNotes;
  final bool hasCheckInSchedule;
  final Duration? checkInInterval;
  final DateTime? lastCheckIn;
  final DateTime? nextCheckInDue;

  // Activity specific data
  final Map<String, dynamic>
  activityData; // Weather conditions, group size, etc.
  final List<String> tags;

  // Safety monitoring
  final bool isHighRisk;
  final bool requiresSpecialMonitoring;
  final List<String> specialRequirements;

  const UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    this.customActivityName,
    required this.riskLevel,
    required this.environment,
    required this.status,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.plannedStartTime,
    this.plannedEndTime,
    this.estimatedDuration,
    this.startLocation,
    this.currentLocation,
    this.plannedLocation,
    this.breadcrumbs = const [],
    this.equipment = const [],
    this.safetyNotes = const [],
    this.hasCheckInSchedule = false,
    this.checkInInterval,
    this.lastCheckIn,
    this.nextCheckInDue,
    this.activityData = const {},
    this.tags = const [],
    this.isHighRisk = false,
    this.requiresSpecialMonitoring = false,
    this.specialRequirements = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'customActivityName': customActivityName,
      'riskLevel': riskLevel.name,
      'environment': environment.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'plannedStartTime': plannedStartTime?.toIso8601String(),
      'plannedEndTime': plannedEndTime?.toIso8601String(),
      'estimatedDuration': estimatedDuration?.inMinutes,
      'startLocation': startLocation?.toJson(),
      'currentLocation': currentLocation?.toJson(),
      'plannedLocation': plannedLocation?.toJson(),
      'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'safetyNotes': safetyNotes,
      'hasCheckInSchedule': hasCheckInSchedule,
      'checkInInterval': checkInInterval?.inMinutes,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'nextCheckInDue': nextCheckInDue?.toIso8601String(),
      'activityData': activityData,
      'tags': tags,
      'isHighRisk': isHighRisk,
      'requiresSpecialMonitoring': requiresSpecialMonitoring,
      'specialRequirements': specialRequirements,
    };
  }

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: ActivityType.values.firstWhere((t) => t.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      customActivityName: json['customActivityName'] as String?,
      riskLevel: ActivityRiskLevel.values.firstWhere(
        (r) => r.name == json['riskLevel'],
      ),
      environment: ActivityEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
      ),
      status: ActivityStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      plannedStartTime: json['plannedStartTime'] != null
          ? DateTime.parse(json['plannedStartTime'] as String)
          : null,
      plannedEndTime: json['plannedEndTime'] != null
          ? DateTime.parse(json['plannedEndTime'] as String)
          : null,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'] as int)
          : null,
      startLocation: json['startLocation'] != null
          ? LocationInfo.fromJson(json['startLocation'])
          : null,
      currentLocation: json['currentLocation'] != null
          ? LocationInfo.fromJson(json['currentLocation'])
          : null,
      plannedLocation: json['plannedLocation'] != null
          ? LocationInfo.fromJson(json['plannedLocation'])
          : null,
      breadcrumbs: (json['breadcrumbs'] as List? ?? [])
          .map((b) => LocationInfo.fromJson(b))
          .toList(),
      equipment: (json['equipment'] as List? ?? [])
          .map((e) => ActivityEquipment.fromJson(e))
          .toList(),
      safetyNotes: List<String>.from(json['safetyNotes'] ?? []),
      hasCheckInSchedule: json['hasCheckInSchedule'] as bool? ?? false,
      checkInInterval: json['checkInInterval'] != null
          ? Duration(minutes: json['checkInInterval'] as int)
          : null,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
      nextCheckInDue: json['nextCheckInDue'] != null
          ? DateTime.parse(json['nextCheckInDue'] as String)
          : null,
      activityData: Map<String, dynamic>.from(json['activityData'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      isHighRisk: json['isHighRisk'] as bool? ?? false,
      requiresSpecialMonitoring:
          json['requiresSpecialMonitoring'] as bool? ?? false,
      specialRequirements: List<String>.from(json['specialRequirements'] ?? []),
    );
  }

  UserActivity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? title,
    String? description,
    String? customActivityName,
    ActivityRiskLevel? riskLevel,
    ActivityEnvironment? environment,
    ActivityStatus? status,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? plannedStartTime,
    DateTime? plannedEndTime,
    Duration? estimatedDuration,
    LocationInfo? startLocation,
    LocationInfo? currentLocation,
    LocationInfo? plannedLocation,
    List<LocationInfo>? breadcrumbs,
    List<ActivityEquipment>? equipment,
    List<String>? safetyNotes,
    bool? hasCheckInSchedule,
    Duration? checkInInterval,
    DateTime? lastCheckIn,
    DateTime? nextCheckInDue,
    Map<String, dynamic>? activityData,
    List<String>? tags,
    bool? isHighRisk,
    bool? requiresSpecialMonitoring,
    List<String>? specialRequirements,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      customActivityName: customActivityName ?? this.customActivityName,
      riskLevel: riskLevel ?? this.riskLevel,
      environment: environment ?? this.environment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      plannedEndTime: plannedEndTime ?? this.plannedEndTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startLocation: startLocation ?? this.startLocation,
      currentLocation: currentLocation ?? this.currentLocation,
      plannedLocation: plannedLocation ?? this.plannedLocation,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      equipment: equipment ?? this.equipment,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      hasCheckInSchedule: hasCheckInSchedule ?? this.hasCheckInSchedule,
      checkInInterval: checkInInterval ?? this.checkInInterval,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      nextCheckInDue: nextCheckInDue ?? this.nextCheckInDue,
      activityData: activityData ?? this.activityData,
      tags: tags ?? this.tags,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      requiresSpecialMonitoring:
          requiresSpecialMonitoring ?? this.requiresSpecialMonitoring,
      specialRequirements: specialRequirements ?? this.specialRequirements,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    description,
    customActivityName,
    riskLevel,
    environment,
    status,
    createdAt,
    startTime,
    endTime,
    plannedStartTime,
    plannedEndTime,
    estimatedDuration,
    startLocation,
    currentLocation,
    plannedLocation,
    breadcrumbs,
    equipment,
    safetyNotes,
    hasCheckInSchedule,
    checkInInterval,
    lastCheckIn,
    nextCheckInDue,
    activityData,
    tags,
    isHighRisk,
    requiresSpecialMonitoring,
    specialRequirements,
  ];
}

/// Activity template for quick setup
class ActivityTemplate extends Equatable {
  final String id;
  final ActivityType type;
  final String name;
  final String description;
  final ActivityRiskLevel defaultRiskLevel;
  final ActivityEnvironment defaultEnvironment;
  final List<ActivityEquipment> recommendedEquipment;
  final List<String> safetyTips;
  final Duration? typicalDuration;
  final bool requiresCheckIn;
  final Duration? recommendedCheckInInterval;
  final List<String> specialRequirements;

  const ActivityTemplate({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.defaultRiskLevel,
    required this.defaultEnvironment,
    this.recommendedEquipment = const [],
    this.safetyTips = const [],
    this.typicalDuration,
    this.requiresCheckIn = false,
    this.recommendedCheckInInterval,
    this.specialRequirements = const [],
  });

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    description,
    defaultRiskLevel,
    defaultEnvironment,
    recommendedEquipment,
    safetyTips,
    typicalDuration,
    requiresCheckIn,
    recommendedCheckInInterval,
    specialRequirements,
  ];
}

/// Activity check-in record
class ActivityCheckIn extends Equatable {
  final String id;
  final String activityId;
  final DateTime timestamp;
  final LocationInfo? location;
  final String status; // 'safe', 'need_help', 'emergency'
  final String? message;
  final bool isAutomatic; // Generated by system vs manual user check-in

  const ActivityCheckIn({
    required this.id,
    required this.activityId,
    required this.timestamp,
    this.location,
    required this.status,
    this.message,
    required this.isAutomatic,
  });

  @override
  List<Object?> get props => [
    id,
    activityId,
    timestamp,
    location,
    status,
    message,
    isAutomatic,
  ];
}

/// User's activity preferences and settings
class ActivityPreferences extends Equatable {
  final List<ActivityType> favoriteActivities;
  final bool enableActivityTracking;
  final bool enableAutoCheckIn;
  final bool enableLocationTracking;
  final bool enableSensorMonitoring;
  final bool shareActivityWithContacts;
  final Duration defaultCheckInInterval;
  final bool requireConfirmationForHighRisk;
  final DateTime lastUpdated;

  const ActivityPreferences({
    this.favoriteActivities = const [],
    this.enableActivityTracking = true,
    this.enableAutoCheckIn = false,
    this.enableLocationTracking = true,
    this.enableSensorMonitoring = true,
    this.shareActivityWithContacts = false,
    this.defaultCheckInInterval = const Duration(hours: 2),
    this.requireConfirmationForHighRisk = true,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'favoriteActivities': favoriteActivities.map((a) => a.name).toList(),
      'enableActivityTracking': enableActivityTracking,
      'enableAutoCheckIn': enableAutoCheckIn,
      'enableLocationTracking': enableLocationTracking,
      'enableSensorMonitoring': enableSensorMonitoring,
      'shareActivityWithContacts': shareActivityWithContacts,
      'defaultCheckInInterval': defaultCheckInInterval.inMinutes,
      'requireConfirmationForHighRisk': requireConfirmationForHighRisk,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ActivityPreferences.fromJson(Map<String, dynamic> json) {
    return ActivityPreferences(
      favoriteActivities: (json['favoriteActivities'] as List? ?? [])
          .map((name) => ActivityType.values.firstWhere((t) => t.name == name))
          .toList(),
      enableActivityTracking: json['enableActivityTracking'] as bool? ?? true,
      enableAutoCheckIn: json['enableAutoCheckIn'] as bool? ?? false,
      enableLocationTracking: json['enableLocationTracking'] as bool? ?? true,
      enableSensorMonitoring: json['enableSensorMonitoring'] as bool? ?? true,
      shareActivityWithContacts:
          json['shareActivityWithContacts'] as bool? ?? false,
      defaultCheckInInterval: Duration(
        minutes: json['defaultCheckInInterval'] as int? ?? 120,
      ),
      requireConfirmationForHighRisk:
          json['requireConfirmationForHighRisk'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  ActivityPreferences copyWith({
    List<ActivityType>? favoriteActivities,
    bool? enableActivityTracking,
    bool? enableAutoCheckIn,
    bool? enableLocationTracking,
    bool? enableSensorMonitoring,
    bool? shareActivityWithContacts,
    Duration? defaultCheckInInterval,
    bool? requireConfirmationForHighRisk,
    DateTime? lastUpdated,
  }) {
    return ActivityPreferences(
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      enableActivityTracking:
          enableActivityTracking ?? this.enableActivityTracking,
      enableAutoCheckIn: enableAutoCheckIn ?? this.enableAutoCheckIn,
      enableLocationTracking:
          enableLocationTracking ?? this.enableLocationTracking,
      enableSensorMonitoring:
          enableSensorMonitoring ?? this.enableSensorMonitoring,
      shareActivityWithContacts:
          shareActivityWithContacts ?? this.shareActivityWithContacts,
      defaultCheckInInterval:
          defaultCheckInInterval ?? this.defaultCheckInInterval,
      requireConfirmationForHighRisk:
          requireConfirmationForHighRisk ?? this.requireConfirmationForHighRisk,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    favoriteActivities,
    enableActivityTracking,
    enableAutoCheckIn,
    enableLocationTracking,
    enableSensorMonitoring,
    shareActivityWithContacts,
    defaultCheckInInterval,
    requireConfirmationForHighRisk,
    lastUpdated,
  ];
}
