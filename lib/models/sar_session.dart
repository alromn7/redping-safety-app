import 'package:json_annotation/json_annotation.dart';
import 'sos_session.dart';

part 'sar_session.g.dart';

/// SAR (Search and Rescue) Session Model
@JsonSerializable()
class SARSession {
  final String id;
  final String userId;
  final SARType type;
  final SARStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final LocationInfo lastKnownLocation;
  final List<LocationInfo> locationHistory;
  final SARPriority priority;
  final String? description;
  final List<String> rescueTeamIds;
  final List<SARUpdate> updates;
  final SARWeatherInfo? weatherInfo;
  final SARTerrainInfo? terrainInfo;
  final List<String> equipmentList;
  final int? estimatedPersons;
  final bool isTestMode;
  final SARCompletion? completion;
  final List<SARMedia> mediaFiles;
  final Map<String, dynamic>? metadata;

  const SARSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.lastKnownLocation,
    this.locationHistory = const [],
    required this.priority,
    this.description,
    this.rescueTeamIds = const [],
    this.updates = const [],
    this.weatherInfo,
    this.terrainInfo,
    this.equipmentList = const [],
    this.estimatedPersons,
    this.isTestMode = false,
    this.completion,
    this.mediaFiles = const [],
    this.metadata,
  });

  factory SARSession.fromJson(Map<String, dynamic> json) =>
      _$SARSessionFromJson(json);
  Map<String, dynamic> toJson() => _$SARSessionToJson(this);

  SARSession copyWith({
    String? id,
    String? userId,
    SARType? type,
    SARStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    LocationInfo? lastKnownLocation,
    List<LocationInfo>? locationHistory,
    SARPriority? priority,
    String? description,
    List<String>? rescueTeamIds,
    List<SARUpdate>? updates,
    SARWeatherInfo? weatherInfo,
    SARTerrainInfo? terrainInfo,
    List<String>? equipmentList,
    int? estimatedPersons,
    bool? isTestMode,
    SARCompletion? completion,
    List<SARMedia>? mediaFiles,
    Map<String, dynamic>? metadata,
  }) {
    return SARSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      rescueTeamIds: rescueTeamIds ?? this.rescueTeamIds,
      updates: updates ?? this.updates,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      terrainInfo: terrainInfo ?? this.terrainInfo,
      equipmentList: equipmentList ?? this.equipmentList,
      estimatedPersons: estimatedPersons ?? this.estimatedPersons,
      isTestMode: isTestMode ?? this.isTestMode,
      completion: completion ?? this.completion,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isActive =>
      status == SARStatus.active || status == SARStatus.searching;
  bool get isResolved =>
      status == SARStatus.rescued || status == SARStatus.cancelled;
}

/// SAR Session Types
enum SARType {
  @JsonValue('missing_person')
  missingPerson,
  @JsonValue('medical_emergency')
  medicalEmergency,
  @JsonValue('vehicle_accident')
  vehicleAccident,
  @JsonValue('wilderness_rescue')
  wildernessRescue,
  @JsonValue('water_rescue')
  waterRescue,
  @JsonValue('mountain_rescue')
  mountainRescue,
  @JsonValue('urban_search')
  urbanSearch,
  @JsonValue('disaster_response')
  disasterResponse,
  @JsonValue('overdue_party')
  overdueParty,
  @JsonValue('equipment_failure')
  equipmentFailure,
}

/// SAR Session Status
enum SARStatus {
  @JsonValue('initiated')
  initiated,
  @JsonValue('dispatched')
  dispatched,
  @JsonValue('searching')
  searching,
  @JsonValue('located')
  located,
  @JsonValue('rescued')
  rescued,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('suspended')
  suspended,
  @JsonValue('active')
  active,
}

/// SAR Priority Levels
enum SARPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
  @JsonValue('urgent')
  urgent,
}

/// SAR Update/Log Entry
@JsonSerializable()
class SARUpdate {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String message;
  final LocationInfo? location;
  final SARUpdateType type;
  final Map<String, dynamic>? data;

  const SARUpdate({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.message,
    this.location,
    required this.type,
    this.data,
  });

  factory SARUpdate.fromJson(Map<String, dynamic> json) =>
      _$SARUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$SARUpdateToJson(this);
}

enum SARUpdateType {
  @JsonValue('status_update')
  statusUpdate,
  @JsonValue('location_update')
  locationUpdate,
  @JsonValue('team_dispatch')
  teamDispatch,
  @JsonValue('clue_found')
  clueFound,
  @JsonValue('contact_made')
  contactMade,
  @JsonValue('rescue_complete')
  rescueComplete,
  @JsonValue('weather_update')
  weatherUpdate,
  @JsonValue('resource_request')
  resourceRequest,
  @JsonValue('sos_alert')
  sosAlert,
}

/// SAR Weather Information
@JsonSerializable()
class SARWeatherInfo {
  final double temperature;
  final double windSpeed;
  final String windDirection;
  final double visibility;
  final String conditions;
  final double precipitation;
  final DateTime timestamp;

  const SARWeatherInfo({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.conditions,
    required this.precipitation,
    required this.timestamp,
  });

  factory SARWeatherInfo.fromJson(Map<String, dynamic> json) =>
      _$SARWeatherInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SARWeatherInfoToJson(this);
}

/// SAR Terrain Information
@JsonSerializable()
class SARTerrainInfo {
  final String terrainType;
  final double elevation;
  final String difficulty;
  final List<String> hazards;
  final double searchRadius;
  final String accessMethod;

  const SARTerrainInfo({
    required this.terrainType,
    required this.elevation,
    required this.difficulty,
    this.hazards = const [],
    required this.searchRadius,
    required this.accessMethod,
  });

  factory SARTerrainInfo.fromJson(Map<String, dynamic> json) =>
      _$SARTerrainInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SARTerrainInfoToJson(this);
}

/// SAR Rescue Team
@JsonSerializable()
class SARTeam {
  final String id;
  final String name;
  final SARTeamType type;
  final SARTeamStatus status;
  final LocationInfo? currentLocation;
  final List<String> memberIds;
  final List<String> capabilities;
  final String? contactInfo;
  final DateTime? lastUpdate;

  const SARTeam({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.currentLocation,
    this.memberIds = const [],
    this.capabilities = const [],
    this.contactInfo,
    this.lastUpdate,
  });

  factory SARTeam.fromJson(Map<String, dynamic> json) =>
      _$SARTeamFromJson(json);
  Map<String, dynamic> toJson() => _$SARTeamToJson(this);
}

enum SARTeamType {
  @JsonValue('ground_team')
  groundTeam,
  @JsonValue('air_support')
  airSupport,
  @JsonValue('water_rescue')
  waterRescue,
  @JsonValue('medical_team')
  medicalTeam,
  @JsonValue('k9_unit')
  k9Unit,
  @JsonValue('technical_rescue')
  technicalRescue,
  @JsonValue('command_post')
  commandPost,
}

enum SARTeamStatus {
  @JsonValue('available')
  available,
  @JsonValue('dispatched')
  dispatched,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('on_scene')
  onScene,
  @JsonValue('searching')
  searching,
  @JsonValue('returning')
  returning,
  @JsonValue('unavailable')
  unavailable,
}

/// SAR Mission Completion Report
@JsonSerializable()
class SARCompletion {
  final DateTime completionTime;
  final SAROutcome outcome;
  final String summary;
  final String? detailedReport;
  final List<String> personsFound;
  final List<String> personsNotFound;
  final List<String> resourcesUsed;
  final Duration totalDuration;
  final Map<String, String> teamPerformance;
  final List<String> lessonsLearned;
  final int? survivorsCount;
  final int? casualtiesCount;
  final String? hospitalDestination;
  final SARDifficulty difficulty;
  final double successRating;
  final String completedBy;

  const SARCompletion({
    required this.completionTime,
    required this.outcome,
    required this.summary,
    this.detailedReport,
    this.personsFound = const [],
    this.personsNotFound = const [],
    this.resourcesUsed = const [],
    required this.totalDuration,
    this.teamPerformance = const {},
    this.lessonsLearned = const [],
    this.survivorsCount,
    this.casualtiesCount,
    this.hospitalDestination,
    required this.difficulty,
    required this.successRating,
    required this.completedBy,
  });

  factory SARCompletion.fromJson(Map<String, dynamic> json) =>
      _$SARCompletionFromJson(json);
  Map<String, dynamic> toJson() => _$SARCompletionToJson(this);
}

enum SAROutcome {
  @JsonValue('successful_rescue')
  successfulRescue,
  @JsonValue('persons_found_safe')
  personsFoundSafe,
  @JsonValue('persons_found_injured')
  personsFoundInjured,
  @JsonValue('persons_found_deceased')
  personsFoundDeceased,
  @JsonValue('persons_not_found')
  personsNotFound,
  @JsonValue('false_alarm')
  falseAlarm,
  @JsonValue('operation_suspended')
  operationSuspended,
  @JsonValue('operation_cancelled')
  operationCancelled,
  @JsonValue('transferred_to_authorities')
  transferredToAuthorities,
}

enum SARDifficulty {
  @JsonValue('routine')
  routine,
  @JsonValue('moderate')
  moderate,
  @JsonValue('challenging')
  challenging,
  @JsonValue('extreme')
  extreme,
  @JsonValue('unprecedented')
  unprecedented,
}

/// SAR Media Documentation
@JsonSerializable()
class SARMedia {
  final String id;
  final SARMediaType type;
  final String filePath;
  final String? description;
  final LocationInfo? location;
  final DateTime timestamp;
  final String uploadedBy;
  final List<String> tags;
  final bool isEvidence;
  final Map<String, dynamic>? metadata;

  const SARMedia({
    required this.id,
    required this.type,
    required this.filePath,
    this.description,
    this.location,
    required this.timestamp,
    required this.uploadedBy,
    this.tags = const [],
    this.isEvidence = false,
    this.metadata,
  });

  factory SARMedia.fromJson(Map<String, dynamic> json) =>
      _$SARMediaFromJson(json);
  Map<String, dynamic> toJson() => _$SARMediaToJson(this);
}

enum SARMediaType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('document')
  document,
  @JsonValue('map')
  map,
  @JsonValue('evidence')
  evidence,
}
