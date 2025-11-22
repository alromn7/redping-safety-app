// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_ping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SOSPing _$SOSPingFromJson(Map<String, dynamic> json) => SOSPing(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userPhone: json['userPhone'] as String?,
      type: $enumDecode(_$SOSTypeEnumMap, json['type']),
      priority: $enumDecode(_$SOSPriorityEnumMap, json['priority']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      userMessage: json['userMessage'] as String?,
      medicalConditions: (json['medicalConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      bloodType: json['bloodType'] as String?,
      estimatedAge: (json['estimatedAge'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      impactInfo: json['impactInfo'] == null
          ? null
          : ImpactInfo.fromJson(json['impactInfo'] as Map<String, dynamic>),
      assignedSARMembers: (json['assignedSARMembers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sarResponses: (json['sarResponses'] as List<dynamic>?)
              ?.map((e) => SARResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: $enumDecode(_$SOSPingStatusEnumMap, json['status']),
      distanceFromSAR: (json['distanceFromSAR'] as num?)?.toDouble(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => EmergencyMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      weatherConditions: json['weatherConditions'] as String?,
      terrainType: json['terrainType'] as String?,
      accessibilityLevel:
          $enumDecode(_$AccessibilityLevelEnumMap, json['accessibilityLevel']),
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      estimatedRescueTime: (json['estimatedRescueTime'] as num).toInt(),
      riskLevel: $enumDecode(_$RiskLevelEnumMap, json['riskLevel']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$SOSPingToJson(SOSPing instance) => <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhone': instance.userPhone,
      'type': _$SOSTypeEnumMap[instance.type]!,
      'priority': _$SOSPriorityEnumMap[instance.priority]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location.toJson(),
      'userMessage': instance.userMessage,
      'medicalConditions': instance.medicalConditions,
      'allergies': instance.allergies,
      'bloodType': instance.bloodType,
      'estimatedAge': instance.estimatedAge,
      'gender': instance.gender,
      'impactInfo': instance.impactInfo?.toJson(),
      'assignedSARMembers': instance.assignedSARMembers,
      'sarResponses': instance.sarResponses.map((e) => e.toJson()).toList(),
      'status': _$SOSPingStatusEnumMap[instance.status]!,
      'distanceFromSAR': instance.distanceFromSAR,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'weatherConditions': instance.weatherConditions,
      'terrainType': instance.terrainType,
      'accessibilityLevel':
          _$AccessibilityLevelEnumMap[instance.accessibilityLevel]!,
      'requiredEquipment': instance.requiredEquipment,
      'estimatedRescueTime': instance.estimatedRescueTime,
      'riskLevel': _$RiskLevelEnumMap[instance.riskLevel]!,
      'metadata': instance.metadata,
    };

const _$SOSTypeEnumMap = {
  SOSType.manual: 'manual',
  SOSType.crashDetection: 'crash_detection',
  SOSType.fallDetection: 'fall_detection',
  SOSType.panicButton: 'panic_button',
  SOSType.voiceCommand: 'voice_command',
  SOSType.externalTrigger: 'external_trigger',
};

const _$SOSPriorityEnumMap = {
  SOSPriority.low: 'low',
  SOSPriority.medium: 'medium',
  SOSPriority.high: 'high',
  SOSPriority.critical: 'critical',
};

const _$SOSPingStatusEnumMap = {
  SOSPingStatus.active: 'active',
  SOSPingStatus.assigned: 'assigned',
  SOSPingStatus.inProgress: 'in_progress',
  SOSPingStatus.resolved: 'resolved',
  SOSPingStatus.cancelled: 'cancelled',
  SOSPingStatus.expired: 'expired',
};

const _$AccessibilityLevelEnumMap = {
  AccessibilityLevel.easy: 'easy',
  AccessibilityLevel.moderate: 'moderate',
  AccessibilityLevel.difficult: 'difficult',
  AccessibilityLevel.extreme: 'extreme',
};

const _$RiskLevelEnumMap = {
  RiskLevel.low: 'low',
  RiskLevel.medium: 'medium',
  RiskLevel.high: 'high',
  RiskLevel.critical: 'critical',
};

SARResponse _$SARResponseFromJson(Map<String, dynamic> json) => SARResponse(
      id: json['id'] as String,
      sarMemberId: json['sarMemberId'] as String,
      sarMemberName: json['sarMemberName'] as String,
      responseType: $enumDecode(_$SARResponseTypeEnumMap, json['responseType']),
      responseTime: DateTime.parse(json['responseTime'] as String),
      message: json['message'] as String?,
      estimatedArrivalTime: (json['estimatedArrivalTime'] as num?)?.toInt(),
      currentLocation: json['currentLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['currentLocation'] as Map<String, dynamic>),
      availableEquipment: (json['availableEquipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      teamMembers: (json['teamMembers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      vehicleType: json['vehicleType'] as String?,
      status: $enumDecode(_$SARResponseStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$SARResponseToJson(SARResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sarMemberId': instance.sarMemberId,
      'sarMemberName': instance.sarMemberName,
      'responseType': _$SARResponseTypeEnumMap[instance.responseType]!,
      'responseTime': instance.responseTime.toIso8601String(),
      'message': instance.message,
      'estimatedArrivalTime': instance.estimatedArrivalTime,
      'currentLocation': instance.currentLocation?.toJson(),
      'availableEquipment': instance.availableEquipment,
      'teamMembers': instance.teamMembers,
      'vehicleType': instance.vehicleType,
      'status': _$SARResponseStatusEnumMap[instance.status]!,
    };

const _$SARResponseTypeEnumMap = {
  SARResponseType.available: 'available',
  SARResponseType.enRoute: 'en_route',
  SARResponseType.unavailable: 'unavailable',
  SARResponseType.backupNeeded: 'backup_needed',
};

const _$SARResponseStatusEnumMap = {
  SARResponseStatus.pending: 'pending',
  SARResponseStatus.accepted: 'accepted',
  SARResponseStatus.declined: 'declined',
  SARResponseStatus.enRoute: 'en_route',
  SARResponseStatus.onScene: 'on_scene',
  SARResponseStatus.completed: 'completed',
};
