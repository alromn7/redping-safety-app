// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sar_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SARSession _$SARSessionFromJson(Map<String, dynamic> json) => SARSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$SARTypeEnumMap, json['type']),
      status: $enumDecode(_$SARStatusEnumMap, json['status']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      lastKnownLocation: LocationInfo.fromJson(
          json['lastKnownLocation'] as Map<String, dynamic>),
      locationHistory: (json['locationHistory'] as List<dynamic>?)
              ?.map((e) => LocationInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      priority: $enumDecode(_$SARPriorityEnumMap, json['priority']),
      description: json['description'] as String?,
      rescueTeamIds: (json['rescueTeamIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updates: (json['updates'] as List<dynamic>?)
              ?.map((e) => SARUpdate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      weatherInfo: json['weatherInfo'] == null
          ? null
          : SARWeatherInfo.fromJson(
              json['weatherInfo'] as Map<String, dynamic>),
      terrainInfo: json['terrainInfo'] == null
          ? null
          : SARTerrainInfo.fromJson(
              json['terrainInfo'] as Map<String, dynamic>),
      equipmentList: (json['equipmentList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      estimatedPersons: (json['estimatedPersons'] as num?)?.toInt(),
      isTestMode: json['isTestMode'] as bool? ?? false,
      completion: json['completion'] == null
          ? null
          : SARCompletion.fromJson(json['completion'] as Map<String, dynamic>),
      mediaFiles: (json['mediaFiles'] as List<dynamic>?)
              ?.map((e) => SARMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SARSessionToJson(SARSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$SARTypeEnumMap[instance.type]!,
      'status': _$SARStatusEnumMap[instance.status]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'lastKnownLocation': instance.lastKnownLocation,
      'locationHistory': instance.locationHistory,
      'priority': _$SARPriorityEnumMap[instance.priority]!,
      'description': instance.description,
      'rescueTeamIds': instance.rescueTeamIds,
      'updates': instance.updates,
      'weatherInfo': instance.weatherInfo,
      'terrainInfo': instance.terrainInfo,
      'equipmentList': instance.equipmentList,
      'estimatedPersons': instance.estimatedPersons,
      'isTestMode': instance.isTestMode,
      'completion': instance.completion,
      'mediaFiles': instance.mediaFiles,
      'metadata': instance.metadata,
    };

const _$SARTypeEnumMap = {
  SARType.missingPerson: 'missing_person',
  SARType.medicalEmergency: 'medical_emergency',
  SARType.vehicleAccident: 'vehicle_accident',
  SARType.wildernessRescue: 'wilderness_rescue',
  SARType.waterRescue: 'water_rescue',
  SARType.mountainRescue: 'mountain_rescue',
  SARType.urbanSearch: 'urban_search',
  SARType.disasterResponse: 'disaster_response',
  SARType.overdueParty: 'overdue_party',
  SARType.equipmentFailure: 'equipment_failure',
};

const _$SARStatusEnumMap = {
  SARStatus.initiated: 'initiated',
  SARStatus.dispatched: 'dispatched',
  SARStatus.searching: 'searching',
  SARStatus.located: 'located',
  SARStatus.rescued: 'rescued',
  SARStatus.cancelled: 'cancelled',
  SARStatus.suspended: 'suspended',
  SARStatus.active: 'active',
};

const _$SARPriorityEnumMap = {
  SARPriority.low: 'low',
  SARPriority.medium: 'medium',
  SARPriority.high: 'high',
  SARPriority.critical: 'critical',
  SARPriority.urgent: 'urgent',
};

SARUpdate _$SARUpdateFromJson(Map<String, dynamic> json) => SARUpdate(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      message: json['message'] as String,
      location: json['location'] == null
          ? null
          : LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      type: $enumDecode(_$SARUpdateTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SARUpdateToJson(SARUpdate instance) => <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'userId': instance.userId,
      'message': instance.message,
      'location': instance.location,
      'type': _$SARUpdateTypeEnumMap[instance.type]!,
      'data': instance.data,
    };

const _$SARUpdateTypeEnumMap = {
  SARUpdateType.statusUpdate: 'status_update',
  SARUpdateType.locationUpdate: 'location_update',
  SARUpdateType.teamDispatch: 'team_dispatch',
  SARUpdateType.clueFound: 'clue_found',
  SARUpdateType.contactMade: 'contact_made',
  SARUpdateType.rescueComplete: 'rescue_complete',
  SARUpdateType.weatherUpdate: 'weather_update',
  SARUpdateType.resourceRequest: 'resource_request',
  SARUpdateType.sosAlert: 'sos_alert',
};

SARWeatherInfo _$SARWeatherInfoFromJson(Map<String, dynamic> json) =>
    SARWeatherInfo(
      temperature: (json['temperature'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDirection: json['windDirection'] as String,
      visibility: (json['visibility'] as num).toDouble(),
      conditions: json['conditions'] as String,
      precipitation: (json['precipitation'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SARWeatherInfoToJson(SARWeatherInfo instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'visibility': instance.visibility,
      'conditions': instance.conditions,
      'precipitation': instance.precipitation,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SARTerrainInfo _$SARTerrainInfoFromJson(Map<String, dynamic> json) =>
    SARTerrainInfo(
      terrainType: json['terrainType'] as String,
      elevation: (json['elevation'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      hazards: (json['hazards'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      searchRadius: (json['searchRadius'] as num).toDouble(),
      accessMethod: json['accessMethod'] as String,
    );

Map<String, dynamic> _$SARTerrainInfoToJson(SARTerrainInfo instance) =>
    <String, dynamic>{
      'terrainType': instance.terrainType,
      'elevation': instance.elevation,
      'difficulty': instance.difficulty,
      'hazards': instance.hazards,
      'searchRadius': instance.searchRadius,
      'accessMethod': instance.accessMethod,
    };

SARTeam _$SARTeamFromJson(Map<String, dynamic> json) => SARTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$SARTeamTypeEnumMap, json['type']),
      status: $enumDecode(_$SARTeamStatusEnumMap, json['status']),
      currentLocation: json['currentLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['currentLocation'] as Map<String, dynamic>),
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contactInfo: json['contactInfo'] as String?,
      lastUpdate: json['lastUpdate'] == null
          ? null
          : DateTime.parse(json['lastUpdate'] as String),
    );

Map<String, dynamic> _$SARTeamToJson(SARTeam instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$SARTeamTypeEnumMap[instance.type]!,
      'status': _$SARTeamStatusEnumMap[instance.status]!,
      'currentLocation': instance.currentLocation,
      'memberIds': instance.memberIds,
      'capabilities': instance.capabilities,
      'contactInfo': instance.contactInfo,
      'lastUpdate': instance.lastUpdate?.toIso8601String(),
    };

const _$SARTeamTypeEnumMap = {
  SARTeamType.groundTeam: 'ground_team',
  SARTeamType.airSupport: 'air_support',
  SARTeamType.waterRescue: 'water_rescue',
  SARTeamType.medicalTeam: 'medical_team',
  SARTeamType.k9Unit: 'k9_unit',
  SARTeamType.technicalRescue: 'technical_rescue',
  SARTeamType.commandPost: 'command_post',
};

const _$SARTeamStatusEnumMap = {
  SARTeamStatus.available: 'available',
  SARTeamStatus.dispatched: 'dispatched',
  SARTeamStatus.enRoute: 'en_route',
  SARTeamStatus.onScene: 'on_scene',
  SARTeamStatus.searching: 'searching',
  SARTeamStatus.returning: 'returning',
  SARTeamStatus.unavailable: 'unavailable',
};

SARCompletion _$SARCompletionFromJson(Map<String, dynamic> json) =>
    SARCompletion(
      completionTime: DateTime.parse(json['completionTime'] as String),
      outcome: $enumDecode(_$SAROutcomeEnumMap, json['outcome']),
      summary: json['summary'] as String,
      detailedReport: json['detailedReport'] as String?,
      personsFound: (json['personsFound'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      personsNotFound: (json['personsNotFound'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      resourcesUsed: (json['resourcesUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      totalDuration:
          Duration(microseconds: (json['totalDuration'] as num).toInt()),
      teamPerformance: (json['teamPerformance'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      lessonsLearned: (json['lessonsLearned'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      survivorsCount: (json['survivorsCount'] as num?)?.toInt(),
      casualtiesCount: (json['casualtiesCount'] as num?)?.toInt(),
      hospitalDestination: json['hospitalDestination'] as String?,
      difficulty: $enumDecode(_$SARDifficultyEnumMap, json['difficulty']),
      successRating: (json['successRating'] as num).toDouble(),
      completedBy: json['completedBy'] as String,
    );

Map<String, dynamic> _$SARCompletionToJson(SARCompletion instance) =>
    <String, dynamic>{
      'completionTime': instance.completionTime.toIso8601String(),
      'outcome': _$SAROutcomeEnumMap[instance.outcome]!,
      'summary': instance.summary,
      'detailedReport': instance.detailedReport,
      'personsFound': instance.personsFound,
      'personsNotFound': instance.personsNotFound,
      'resourcesUsed': instance.resourcesUsed,
      'totalDuration': instance.totalDuration.inMicroseconds,
      'teamPerformance': instance.teamPerformance,
      'lessonsLearned': instance.lessonsLearned,
      'survivorsCount': instance.survivorsCount,
      'casualtiesCount': instance.casualtiesCount,
      'hospitalDestination': instance.hospitalDestination,
      'difficulty': _$SARDifficultyEnumMap[instance.difficulty]!,
      'successRating': instance.successRating,
      'completedBy': instance.completedBy,
    };

const _$SAROutcomeEnumMap = {
  SAROutcome.successfulRescue: 'successful_rescue',
  SAROutcome.personsFoundSafe: 'persons_found_safe',
  SAROutcome.personsFoundInjured: 'persons_found_injured',
  SAROutcome.personsFoundDeceased: 'persons_found_deceased',
  SAROutcome.personsNotFound: 'persons_not_found',
  SAROutcome.falseAlarm: 'false_alarm',
  SAROutcome.operationSuspended: 'operation_suspended',
  SAROutcome.operationCancelled: 'operation_cancelled',
  SAROutcome.transferredToAuthorities: 'transferred_to_authorities',
};

const _$SARDifficultyEnumMap = {
  SARDifficulty.routine: 'routine',
  SARDifficulty.moderate: 'moderate',
  SARDifficulty.challenging: 'challenging',
  SARDifficulty.extreme: 'extreme',
  SARDifficulty.unprecedented: 'unprecedented',
};

SARMedia _$SARMediaFromJson(Map<String, dynamic> json) => SARMedia(
      id: json['id'] as String,
      type: $enumDecode(_$SARMediaTypeEnumMap, json['type']),
      filePath: json['filePath'] as String,
      description: json['description'] as String?,
      location: json['location'] == null
          ? null
          : LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      uploadedBy: json['uploadedBy'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isEvidence: json['isEvidence'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SARMediaToJson(SARMedia instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$SARMediaTypeEnumMap[instance.type]!,
      'filePath': instance.filePath,
      'description': instance.description,
      'location': instance.location,
      'timestamp': instance.timestamp.toIso8601String(),
      'uploadedBy': instance.uploadedBy,
      'tags': instance.tags,
      'isEvidence': instance.isEvidence,
      'metadata': instance.metadata,
    };

const _$SARMediaTypeEnumMap = {
  SARMediaType.photo: 'photo',
  SARMediaType.video: 'video',
  SARMediaType.audio: 'audio',
  SARMediaType.document: 'document',
  SARMediaType.map: 'map',
  SARMediaType.evidence: 'evidence',
};
