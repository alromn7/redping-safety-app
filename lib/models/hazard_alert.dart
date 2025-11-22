import 'package:json_annotation/json_annotation.dart';
import 'sos_session.dart';

part 'hazard_alert.g.dart';

/// Hazard Alert Model for weather and emergency alerts
@JsonSerializable()
class HazardAlert {
  final String id;
  final HazardType type;
  final HazardSeverity severity;
  final String title;
  final String description;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final LocationInfo? affectedArea;
  final double? radius; // kilometers
  final List<String> affectedRegions;
  final HazardSource source;
  final Map<String, dynamic>? weatherData;
  final List<String> instructions;
  final List<String> safetyTips;
  final bool isActive;
  final String? imageUrl;
  final String? audioUrl;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const HazardAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.issuedAt,
    this.expiresAt,
    this.affectedArea,
    this.radius,
    this.affectedRegions = const [],
    required this.source,
    this.weatherData,
    this.instructions = const [],
    this.safetyTips = const [],
    this.isActive = true,
    this.imageUrl,
    this.audioUrl,
    this.tags = const [],
    this.metadata,
  });

  factory HazardAlert.fromJson(Map<String, dynamic> json) =>
      _$HazardAlertFromJson(json);
  Map<String, dynamic> toJson() => _$HazardAlertToJson(this);

  HazardAlert copyWith({
    String? id,
    HazardType? type,
    HazardSeverity? severity,
    String? title,
    String? description,
    DateTime? issuedAt,
    DateTime? expiresAt,
    LocationInfo? affectedArea,
    double? radius,
    List<String>? affectedRegions,
    HazardSource? source,
    Map<String, dynamic>? weatherData,
    List<String>? instructions,
    List<String>? safetyTips,
    bool? isActive,
    String? imageUrl,
    String? audioUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return HazardAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      affectedArea: affectedArea ?? this.affectedArea,
      radius: radius ?? this.radius,
      affectedRegions: affectedRegions ?? this.affectedRegions,
      source: source ?? this.source,
      weatherData: weatherData ?? this.weatherData,
      instructions: instructions ?? this.instructions,
      safetyTips: safetyTips ?? this.safetyTips,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isNearUser =>
      affectedArea != null; // Would calculate distance in production
  Duration get timeRemaining =>
      expiresAt != null ? expiresAt!.difference(DateTime.now()) : Duration.zero;
}

/// Types of hazard alerts
enum HazardType {
  @JsonValue('weather')
  weather,
  @JsonValue('earthquake')
  earthquake,
  @JsonValue('flood')
  flood,
  @JsonValue('fire')
  fire,
  @JsonValue('tornado')
  tornado,
  @JsonValue('hurricane')
  hurricane,
  @JsonValue('tsunami')
  tsunami,
  @JsonValue('landslide')
  landslide,
  @JsonValue('avalanche')
  avalanche,
  @JsonValue('severe_storm')
  severeStorm,
  @JsonValue('heat_wave')
  heatWave,
  @JsonValue('cold_wave')
  coldWave,
  @JsonValue('air_quality')
  airQuality,
  @JsonValue('radiation')
  radiation,
  @JsonValue('chemical_spill')
  chemicalSpill,
  @JsonValue('gas_leak')
  gasLeak,
  @JsonValue('power_outage')
  powerOutage,
  @JsonValue('water_contamination')
  waterContamination,
  @JsonValue('road_closure')
  roadClosure,
  @JsonValue('civil_emergency')
  civilEmergency,
  @JsonValue('amber_alert')
  amberAlert,
  @JsonValue('security_threat')
  securityThreat,
  @JsonValue('evacuation')
  evacuation,
  @JsonValue('shelter_in_place')
  shelterInPlace,
  @JsonValue('community_hazard')
  communityHazard,
}

/// Severity levels for hazard alerts
enum HazardSeverity {
  @JsonValue('info')
  info,
  @JsonValue('minor')
  minor,
  @JsonValue('moderate')
  moderate,
  @JsonValue('severe')
  severe,
  @JsonValue('extreme')
  extreme,
  @JsonValue('critical')
  critical,
}

/// Source of hazard alert
enum HazardSource {
  @JsonValue('national_weather_service')
  nationalWeatherService,
  @JsonValue('emergency_management')
  emergencyManagement,
  @JsonValue('local_authorities')
  localAuthorities,
  @JsonValue('community_report')
  communityReport,
  @JsonValue('automated_system')
  automatedSystem,
  @JsonValue('user_report')
  userReport,
  @JsonValue('sensor_network')
  sensorNetwork,
  @JsonValue('satellite_data')
  satelliteData,
}

/// Community-reported hazard
@JsonSerializable()
class CommunityHazardReport {
  final String id;
  final String reporterId;
  final HazardType type;
  final String title;
  final String description;
  final LocationInfo location;
  final DateTime reportedAt;
  final HazardSeverity reportedSeverity;
  final List<String> mediaFiles;
  final List<String> tags;
  final int verificationCount;
  final List<String> verifiedByUsers;
  final bool isVerified;
  final bool isActive;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const CommunityHazardReport({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.reportedAt,
    required this.reportedSeverity,
    this.mediaFiles = const [],
    this.tags = const [],
    this.verificationCount = 0,
    this.verifiedByUsers = const [],
    this.isVerified = false,
    this.isActive = true,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory CommunityHazardReport.fromJson(Map<String, dynamic> json) =>
      _$CommunityHazardReportFromJson(json);
  Map<String, dynamic> toJson() => _$CommunityHazardReportToJson(this);

  CommunityHazardReport copyWith({
    String? id,
    String? reporterId,
    HazardType? type,
    String? title,
    String? description,
    LocationInfo? location,
    DateTime? reportedAt,
    HazardSeverity? reportedSeverity,
    List<String>? mediaFiles,
    List<String>? tags,
    int? verificationCount,
    List<String>? verifiedByUsers,
    bool? isVerified,
    bool? isActive,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) {
    return CommunityHazardReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      reportedAt: reportedAt ?? this.reportedAt,
      reportedSeverity: reportedSeverity ?? this.reportedSeverity,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      tags: tags ?? this.tags,
      verificationCount: verificationCount ?? this.verificationCount,
      verifiedByUsers: verifiedByUsers ?? this.verifiedByUsers,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  Duration get age => DateTime.now().difference(reportedAt);
  bool get needsVerification => !isVerified && verificationCount < 3;
}

/// Weather alert data
@JsonSerializable()
class WeatherAlert {
  final String id;
  final String event;
  final HazardSeverity severity;
  final DateTime effective;
  final DateTime? expires;
  final String headline;
  final String description;
  final String instruction;
  final List<String> areas;
  final Map<String, dynamic> parameters;

  const WeatherAlert({
    required this.id,
    required this.event,
    required this.severity,
    required this.effective,
    this.expires,
    required this.headline,
    required this.description,
    required this.instruction,
    this.areas = const [],
    this.parameters = const {},
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherAlertToJson(this);
}

/// Emergency broadcast alert
@JsonSerializable()
class EmergencyBroadcast {
  final String id;
  final String title;
  final String message;
  final HazardSeverity urgency;
  final DateTime broadcastAt;
  final DateTime? expiresAt;
  final String source;
  final List<String> targetAreas;
  final Map<String, dynamic>? actionRequired;
  final bool requiresAcknowledgment;
  final List<String> acknowledgedByUsers;

  const EmergencyBroadcast({
    required this.id,
    required this.title,
    required this.message,
    required this.urgency,
    required this.broadcastAt,
    this.expiresAt,
    required this.source,
    this.targetAreas = const [],
    this.actionRequired,
    this.requiresAcknowledgment = false,
    this.acknowledgedByUsers = const [],
  });

  factory EmergencyBroadcast.fromJson(Map<String, dynamic> json) =>
      _$EmergencyBroadcastFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyBroadcastToJson(this);

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get needsAcknowledgment =>
      requiresAcknowledgment &&
      !acknowledgedByUsers.contains('current_user'); // Would use actual user ID
}
