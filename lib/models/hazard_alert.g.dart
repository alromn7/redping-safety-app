// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hazard_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HazardAlert _$HazardAlertFromJson(Map<String, dynamic> json) => HazardAlert(
      id: json['id'] as String,
      type: $enumDecode(_$HazardTypeEnumMap, json['type']),
      severity: $enumDecode(_$HazardSeverityEnumMap, json['severity']),
      title: json['title'] as String,
      description: json['description'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      affectedArea: json['affectedArea'] == null
          ? null
          : LocationInfo.fromJson(json['affectedArea'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble(),
      affectedRegions: (json['affectedRegions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      source: $enumDecode(_$HazardSourceEnumMap, json['source']),
      weatherData: json['weatherData'] as Map<String, dynamic>?,
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      safetyTips: (json['safetyTips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$HazardAlertToJson(HazardAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$HazardTypeEnumMap[instance.type]!,
      'severity': _$HazardSeverityEnumMap[instance.severity]!,
      'title': instance.title,
      'description': instance.description,
      'issuedAt': instance.issuedAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'affectedArea': instance.affectedArea,
      'radius': instance.radius,
      'affectedRegions': instance.affectedRegions,
      'source': _$HazardSourceEnumMap[instance.source]!,
      'weatherData': instance.weatherData,
      'instructions': instance.instructions,
      'safetyTips': instance.safetyTips,
      'isActive': instance.isActive,
      'imageUrl': instance.imageUrl,
      'audioUrl': instance.audioUrl,
      'tags': instance.tags,
      'metadata': instance.metadata,
    };

const _$HazardTypeEnumMap = {
  HazardType.weather: 'weather',
  HazardType.earthquake: 'earthquake',
  HazardType.flood: 'flood',
  HazardType.fire: 'fire',
  HazardType.tornado: 'tornado',
  HazardType.hurricane: 'hurricane',
  HazardType.tsunami: 'tsunami',
  HazardType.landslide: 'landslide',
  HazardType.avalanche: 'avalanche',
  HazardType.severeStorm: 'severe_storm',
  HazardType.heatWave: 'heat_wave',
  HazardType.coldWave: 'cold_wave',
  HazardType.airQuality: 'air_quality',
  HazardType.radiation: 'radiation',
  HazardType.chemicalSpill: 'chemical_spill',
  HazardType.gasLeak: 'gas_leak',
  HazardType.powerOutage: 'power_outage',
  HazardType.waterContamination: 'water_contamination',
  HazardType.roadClosure: 'road_closure',
  HazardType.civilEmergency: 'civil_emergency',
  HazardType.amberAlert: 'amber_alert',
  HazardType.securityThreat: 'security_threat',
  HazardType.evacuation: 'evacuation',
  HazardType.shelterInPlace: 'shelter_in_place',
  HazardType.communityHazard: 'community_hazard',
};

const _$HazardSeverityEnumMap = {
  HazardSeverity.info: 'info',
  HazardSeverity.minor: 'minor',
  HazardSeverity.moderate: 'moderate',
  HazardSeverity.severe: 'severe',
  HazardSeverity.extreme: 'extreme',
  HazardSeverity.critical: 'critical',
};

const _$HazardSourceEnumMap = {
  HazardSource.nationalWeatherService: 'national_weather_service',
  HazardSource.emergencyManagement: 'emergency_management',
  HazardSource.localAuthorities: 'local_authorities',
  HazardSource.communityReport: 'community_report',
  HazardSource.automatedSystem: 'automated_system',
  HazardSource.userReport: 'user_report',
  HazardSource.sensorNetwork: 'sensor_network',
  HazardSource.satelliteData: 'satellite_data',
};

CommunityHazardReport _$CommunityHazardReportFromJson(
        Map<String, dynamic> json) =>
    CommunityHazardReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      type: $enumDecode(_$HazardTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      location: LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      reportedSeverity:
          $enumDecode(_$HazardSeverityEnumMap, json['reportedSeverity']),
      mediaFiles: (json['mediaFiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      verificationCount: (json['verificationCount'] as num?)?.toInt() ?? 0,
      verifiedByUsers: (json['verifiedByUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      resolutionNotes: json['resolutionNotes'] as String?,
    );

Map<String, dynamic> _$CommunityHazardReportToJson(
        CommunityHazardReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'type': _$HazardTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'reportedAt': instance.reportedAt.toIso8601String(),
      'reportedSeverity': _$HazardSeverityEnumMap[instance.reportedSeverity]!,
      'mediaFiles': instance.mediaFiles,
      'tags': instance.tags,
      'verificationCount': instance.verificationCount,
      'verifiedByUsers': instance.verifiedByUsers,
      'isVerified': instance.isVerified,
      'isActive': instance.isActive,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'resolutionNotes': instance.resolutionNotes,
    };

WeatherAlert _$WeatherAlertFromJson(Map<String, dynamic> json) => WeatherAlert(
      id: json['id'] as String,
      event: json['event'] as String,
      severity: $enumDecode(_$HazardSeverityEnumMap, json['severity']),
      effective: DateTime.parse(json['effective'] as String),
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      headline: json['headline'] as String,
      description: json['description'] as String,
      instruction: json['instruction'] as String,
      areas:
          (json['areas'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$WeatherAlertToJson(WeatherAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event': instance.event,
      'severity': _$HazardSeverityEnumMap[instance.severity]!,
      'effective': instance.effective.toIso8601String(),
      'expires': instance.expires?.toIso8601String(),
      'headline': instance.headline,
      'description': instance.description,
      'instruction': instance.instruction,
      'areas': instance.areas,
      'parameters': instance.parameters,
    };

EmergencyBroadcast _$EmergencyBroadcastFromJson(Map<String, dynamic> json) =>
    EmergencyBroadcast(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      urgency: $enumDecode(_$HazardSeverityEnumMap, json['urgency']),
      broadcastAt: DateTime.parse(json['broadcastAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      source: json['source'] as String,
      targetAreas: (json['targetAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      actionRequired: json['actionRequired'] as Map<String, dynamic>?,
      requiresAcknowledgment: json['requiresAcknowledgment'] as bool? ?? false,
      acknowledgedByUsers: (json['acknowledgedByUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EmergencyBroadcastToJson(EmergencyBroadcast instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'urgency': _$HazardSeverityEnumMap[instance.urgency]!,
      'broadcastAt': instance.broadcastAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'source': instance.source,
      'targetAreas': instance.targetAreas,
      'actionRequired': instance.actionRequired,
      'requiresAcknowledgment': instance.requiresAcknowledgment,
      'acknowledgedByUsers': instance.acknowledgedByUsers,
    };
