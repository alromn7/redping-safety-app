import 'package:flutter/material.dart';

/// RedPing Mode - Activity-based safety configuration
class RedPingMode {
  final String id;
  final String name;
  final String description;
  final ModeCategory category;
  final IconData icon;
  final Color themeColor;

  // Sensor Configuration
  final SensorConfig sensorConfig;
  final LocationConfig locationConfig;
  final HazardConfig hazardConfig;
  final EmergencyConfig emergencyConfig;

  // Auto-Trigger Rules
  final List<AutoTriggerRule> autoTriggers;
  final List<String> activeHazardTypes;
  final List<String> priorityContactIds;

  // UI Customization
  final List<String> dashboardMetrics;
  final bool showPerformanceStats;
  final String statusMessage;

  const RedPingMode({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.themeColor,
    required this.sensorConfig,
    required this.locationConfig,
    required this.hazardConfig,
    required this.emergencyConfig,
    this.autoTriggers = const [],
    this.activeHazardTypes = const [],
    this.priorityContactIds = const [],
    this.dashboardMetrics = const [],
    this.showPerformanceStats = false,
    this.statusMessage = '',
  });

  /// Create a copy with modified fields
  RedPingMode copyWith({
    String? id,
    String? name,
    String? description,
    ModeCategory? category,
    IconData? icon,
    Color? themeColor,
    SensorConfig? sensorConfig,
    LocationConfig? locationConfig,
    HazardConfig? hazardConfig,
    EmergencyConfig? emergencyConfig,
    List<AutoTriggerRule>? autoTriggers,
    List<String>? activeHazardTypes,
    List<String>? priorityContactIds,
    List<String>? dashboardMetrics,
    bool? showPerformanceStats,
    String? statusMessage,
  }) {
    return RedPingMode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      themeColor: themeColor ?? this.themeColor,
      sensorConfig: sensorConfig ?? this.sensorConfig,
      locationConfig: locationConfig ?? this.locationConfig,
      hazardConfig: hazardConfig ?? this.hazardConfig,
      emergencyConfig: emergencyConfig ?? this.emergencyConfig,
      autoTriggers: autoTriggers ?? this.autoTriggers,
      activeHazardTypes: activeHazardTypes ?? this.activeHazardTypes,
      priorityContactIds: priorityContactIds ?? this.priorityContactIds,
      dashboardMetrics: dashboardMetrics ?? this.dashboardMetrics,
      showPerformanceStats: showPerformanceStats ?? this.showPerformanceStats,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.toString(),
    'sensorConfig': sensorConfig.toJson(),
    'locationConfig': locationConfig.toJson(),
    'hazardConfig': hazardConfig.toJson(),
    'emergencyConfig': emergencyConfig.toJson(),
    'activeHazardTypes': activeHazardTypes,
    'priorityContactIds': priorityContactIds,
    'dashboardMetrics': dashboardMetrics,
    'showPerformanceStats': showPerformanceStats,
    'statusMessage': statusMessage,
  };

  /// Create from JSON
  factory RedPingMode.fromJson(Map<String, dynamic> json) {
    return RedPingMode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: ModeCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => ModeCategory.work,
      ),
      icon: Icons.work, // Default icon, will be set by predefined modes
      themeColor: Colors.blue,
      sensorConfig: SensorConfig.fromJson(
        json['sensorConfig'] as Map<String, dynamic>,
      ),
      locationConfig: LocationConfig.fromJson(
        json['locationConfig'] as Map<String, dynamic>,
      ),
      hazardConfig: HazardConfig.fromJson(
        json['hazardConfig'] as Map<String, dynamic>,
      ),
      emergencyConfig: EmergencyConfig.fromJson(
        json['emergencyConfig'] as Map<String, dynamic>,
      ),
      activeHazardTypes: List<String>.from(json['activeHazardTypes'] ?? []),
      priorityContactIds: List<String>.from(json['priorityContactIds'] ?? []),
      dashboardMetrics: List<String>.from(json['dashboardMetrics'] ?? []),
      showPerformanceStats: json['showPerformanceStats'] as bool? ?? false,
      statusMessage: json['statusMessage'] as String? ?? '',
    );
  }
}

/// Mode Categories
enum ModeCategory {
  work, // Remote Area, Working at Height, High Risk
  travel, // Journey Mode
  family, // Family Mode
  group, // Group Mode
  extreme, // Extreme Activities
}

/// Sensor Configuration
class SensorConfig {
  final double crashThreshold; // m/s²
  final double fallThreshold; // m/s²
  final double violentHandlingMin; // m/s²
  final double violentHandlingMax; // m/s²
  final Duration monitoringInterval;
  final bool enableFreefallDetection;
  final bool enableMotionTracking;
  final bool enableAltitudeTracking;
  final PowerMode powerMode;

  const SensorConfig({
    this.crashThreshold = 180.0,
    this.fallThreshold = 150.0,
    this.violentHandlingMin = 100.0,
    this.violentHandlingMax = 180.0,
    this.monitoringInterval = const Duration(seconds: 1),
    this.enableFreefallDetection = true,
    this.enableMotionTracking = true,
    this.enableAltitudeTracking = false,
    this.powerMode = PowerMode.balanced,
  });

  Map<String, dynamic> toJson() => {
    'crashThreshold': crashThreshold,
    'fallThreshold': fallThreshold,
    'violentHandlingMin': violentHandlingMin,
    'violentHandlingMax': violentHandlingMax,
    'monitoringIntervalMs': monitoringInterval.inMilliseconds,
    'enableFreefallDetection': enableFreefallDetection,
    'enableMotionTracking': enableMotionTracking,
    'enableAltitudeTracking': enableAltitudeTracking,
    'powerMode': powerMode.toString(),
  };

  factory SensorConfig.fromJson(Map<String, dynamic> json) {
    return SensorConfig(
      crashThreshold: json['crashThreshold'] as double? ?? 180.0,
      fallThreshold: json['fallThreshold'] as double? ?? 150.0,
      violentHandlingMin: json['violentHandlingMin'] as double? ?? 100.0,
      violentHandlingMax: json['violentHandlingMax'] as double? ?? 180.0,
      monitoringInterval: Duration(
        milliseconds: json['monitoringIntervalMs'] as int? ?? 1000,
      ),
      enableFreefallDetection: json['enableFreefallDetection'] as bool? ?? true,
      enableMotionTracking: json['enableMotionTracking'] as bool? ?? true,
      enableAltitudeTracking: json['enableAltitudeTracking'] as bool? ?? false,
      powerMode: PowerMode.values.firstWhere(
        (e) => e.toString() == json['powerMode'],
        orElse: () => PowerMode.balanced,
      ),
    );
  }
}

/// Power Modes
enum PowerMode {
  low, // 3-5 day battery, reduced monitoring
  balanced, // 1-2 day battery, standard monitoring
  high, // <1 day battery, maximum sensitivity
}

/// Location Configuration
class LocationConfig {
  final Duration breadcrumbInterval; // 30 sec - 5 min
  final int accuracyTargetMeters; // Target accuracy in meters
  final bool enableOfflineMaps;
  final bool enableRouteTracking;
  final bool enableGeofencing;
  final int mapCacheRadiusKm;

  const LocationConfig({
    this.breadcrumbInterval = const Duration(seconds: 30),
    this.accuracyTargetMeters = 50,
    this.enableOfflineMaps = false,
    this.enableRouteTracking = false,
    this.enableGeofencing = false,
    this.mapCacheRadiusKm = 5,
  });

  Map<String, dynamic> toJson() => {
    'breadcrumbIntervalSec': breadcrumbInterval.inSeconds,
    'accuracyTargetMeters': accuracyTargetMeters,
    'enableOfflineMaps': enableOfflineMaps,
    'enableRouteTracking': enableRouteTracking,
    'enableGeofencing': enableGeofencing,
    'mapCacheRadiusKm': mapCacheRadiusKm,
  };

  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    return LocationConfig(
      breadcrumbInterval: Duration(
        seconds: json['breadcrumbIntervalSec'] as int? ?? 30,
      ),
      accuracyTargetMeters: json['accuracyTargetMeters'] as int? ?? 50,
      enableOfflineMaps: json['enableOfflineMaps'] as bool? ?? false,
      enableRouteTracking: json['enableRouteTracking'] as bool? ?? false,
      enableGeofencing: json['enableGeofencing'] as bool? ?? false,
      mapCacheRadiusKm: json['mapCacheRadiusKm'] as int? ?? 5,
    );
  }
}

/// Hazard Configuration
class HazardConfig {
  final bool enableWeatherAlerts;
  final bool enableEnvironmentalAlerts;
  final bool enableProximityAlerts;
  final bool enableTrafficAlerts;

  const HazardConfig({
    this.enableWeatherAlerts = true,
    this.enableEnvironmentalAlerts = true,
    this.enableProximityAlerts = false,
    this.enableTrafficAlerts = false,
  });

  Map<String, dynamic> toJson() => {
    'enableWeatherAlerts': enableWeatherAlerts,
    'enableEnvironmentalAlerts': enableEnvironmentalAlerts,
    'enableProximityAlerts': enableProximityAlerts,
    'enableTrafficAlerts': enableTrafficAlerts,
  };

  factory HazardConfig.fromJson(Map<String, dynamic> json) {
    return HazardConfig(
      enableWeatherAlerts: json['enableWeatherAlerts'] as bool? ?? true,
      enableEnvironmentalAlerts:
          json['enableEnvironmentalAlerts'] as bool? ?? true,
      enableProximityAlerts: json['enableProximityAlerts'] as bool? ?? false,
      enableTrafficAlerts: json['enableTrafficAlerts'] as bool? ?? false,
    );
  }
}

/// Emergency Configuration
class EmergencyConfig {
  final Duration sosCountdown; // 0-90 sec
  final bool autoCallEmergency;
  final String emergencyMessage;
  final bool enableVideoEvidence;
  final bool enableVoiceMessage;
  final RescueType preferredRescue;

  const EmergencyConfig({
    this.sosCountdown = const Duration(seconds: 10),
    this.autoCallEmergency = false,
    this.emergencyMessage = '',
    this.enableVideoEvidence = false,
    this.enableVoiceMessage = false,
    this.preferredRescue = RescueType.ground,
  });

  Map<String, dynamic> toJson() => {
    'sosCountdownSec': sosCountdown.inSeconds,
    'autoCallEmergency': autoCallEmergency,
    'emergencyMessage': emergencyMessage,
    'enableVideoEvidence': enableVideoEvidence,
    'enableVoiceMessage': enableVoiceMessage,
    'preferredRescue': preferredRescue.toString(),
  };

  factory EmergencyConfig.fromJson(Map<String, dynamic> json) {
    return EmergencyConfig(
      sosCountdown: Duration(seconds: json['sosCountdownSec'] as int? ?? 10),
      autoCallEmergency: json['autoCallEmergency'] as bool? ?? false,
      emergencyMessage: json['emergencyMessage'] as String? ?? '',
      enableVideoEvidence: json['enableVideoEvidence'] as bool? ?? false,
      enableVoiceMessage: json['enableVoiceMessage'] as bool? ?? false,
      preferredRescue: RescueType.values.firstWhere(
        (e) => e.toString() == json['preferredRescue'],
        orElse: () => RescueType.ground,
      ),
    );
  }
}

/// Rescue Types
enum RescueType {
  ground, // Ambulance, SAR team
  aerial, // Helicopter
  marine, // Coast guard, boat
}

/// Auto-Trigger Rule
class AutoTriggerRule {
  final String id;
  final String condition; // e.g., "stationary > 30 min"
  final TriggerAction action;
  final Duration delay;
  final String message;
  final bool requiresConfirmation;

  const AutoTriggerRule({
    required this.id,
    required this.condition,
    required this.action,
    required this.delay,
    required this.message,
    this.requiresConfirmation = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'condition': condition,
    'action': action.toString(),
    'delaySec': delay.inSeconds,
    'message': message,
    'requiresConfirmation': requiresConfirmation,
  };

  factory AutoTriggerRule.fromJson(Map<String, dynamic> json) {
    return AutoTriggerRule(
      id: json['id'] as String,
      condition: json['condition'] as String,
      action: TriggerAction.values.firstWhere(
        (e) => e.toString() == json['action'],
        orElse: () => TriggerAction.alert,
      ),
      delay: Duration(seconds: json['delaySec'] as int? ?? 0),
      message: json['message'] as String,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );
  }
}

/// Trigger Actions
enum TriggerAction {
  alert, // Show notification
  checkIn, // Request check-in
  sos, // Activate SOS
  notify, // Notify contacts
}

/// Active Mode Session
class ActiveModeSession {
  final String sessionId;
  final RedPingMode mode;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> stats;

  ActiveModeSession({
    required this.sessionId,
    required this.mode,
    required this.startTime,
    this.endTime,
    this.stats = const {},
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  bool get isActive => endTime == null;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'mode': mode.toJson(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'stats': stats,
  };

  factory ActiveModeSession.fromJson(Map<String, dynamic> json) {
    return ActiveModeSession(
      sessionId: json['sessionId'] as String,
      mode: RedPingMode.fromJson(json['mode'] as Map<String, dynamic>),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      stats: json['stats'] as Map<String, dynamic>? ?? {},
    );
  }
}
