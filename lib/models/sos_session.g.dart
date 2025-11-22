// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SOSSession _$SOSSessionFromJson(Map<String, dynamic> json) => SOSSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$SOSTypeEnumMap, json['type']),
      status: $enumDecode(_$SOSStatusEnumMap, json['status']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      location: LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      impactInfo: json['impactInfo'] == null
          ? null
          : ImpactInfo.fromJson(json['impactInfo'] as Map<String, dynamic>),
      contactedEmergencyContacts:
          (json['contactedEmergencyContacts'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => SOSMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mediaAttachments: (json['mediaAttachments'] as List<dynamic>?)
              ?.map((e) => MediaAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rescueTeamResponses: (json['rescueTeamResponses'] as List<dynamic>?)
              ?.map(
                  (e) => RescueTeamResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      emergencyContactResponses: (json['emergencyContactResponses']
                  as List<dynamic>?)
              ?.map((e) =>
                  EmergencyContactResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rescueStatus: json['rescueStatus'] == null
          ? null
          : RescueStatus.fromJson(json['rescueStatus'] as Map<String, dynamic>),
      voiceVerification: json['voiceVerification'] == null
          ? null
          : VoiceVerificationInfo.fromJson(
              json['voiceVerification'] as Map<String, dynamic>),
      userMessage: json['userMessage'] as String?,
      isTestMode: json['isTestMode'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$SOSSessionToJson(SOSSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$SOSTypeEnumMap[instance.type]!,
      'status': _$SOSStatusEnumMap[instance.status]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'location': instance.location.toJson(),
      'impactInfo': instance.impactInfo?.toJson(),
      'contactedEmergencyContacts': instance.contactedEmergencyContacts,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'mediaAttachments':
          instance.mediaAttachments.map((e) => e.toJson()).toList(),
      'rescueTeamResponses':
          instance.rescueTeamResponses.map((e) => e.toJson()).toList(),
      'emergencyContactResponses':
          instance.emergencyContactResponses.map((e) => e.toJson()).toList(),
      'rescueStatus': instance.rescueStatus?.toJson(),
      'voiceVerification': instance.voiceVerification?.toJson(),
      'userMessage': instance.userMessage,
      'isTestMode': instance.isTestMode,
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

const _$SOSStatusEnumMap = {
  SOSStatus.countdown: 'countdown',
  SOSStatus.active: 'active',
  SOSStatus.acknowledged: 'acknowledged',
  SOSStatus.assigned: 'assigned',
  SOSStatus.enRoute: 'en_route',
  SOSStatus.onScene: 'on_scene',
  SOSStatus.inProgress: 'in_progress',
  SOSStatus.cancelled: 'cancelled',
  SOSStatus.resolved: 'resolved',
  SOSStatus.falseAlarm: 'false_alarm',
};

LocationInfo _$LocationInfoFromJson(Map<String, dynamic> json) => LocationInfo(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
      breadcrumbTrail: (json['breadcrumbTrail'] as List<dynamic>?)
              ?.map((e) => BreadcrumbPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LocationInfoToJson(LocationInfo instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'heading': instance.heading,
      'timestamp': instance.timestamp.toIso8601String(),
      'address': instance.address,
      'breadcrumbTrail':
          instance.breadcrumbTrail.map((e) => e.toJson()).toList(),
    };

BreadcrumbPoint _$BreadcrumbPointFromJson(Map<String, dynamic> json) =>
    BreadcrumbPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BreadcrumbPointToJson(BreadcrumbPoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'speed': instance.speed,
    };

ImpactInfo _$ImpactInfoFromJson(Map<String, dynamic> json) => ImpactInfo(
      accelerationMagnitude: (json['accelerationMagnitude'] as num).toDouble(),
      maxAcceleration: (json['maxAcceleration'] as num).toDouble(),
      detectionTime: DateTime.parse(json['detectionTime'] as String),
      sensorReadings: (json['sensorReadings'] as List<dynamic>?)
              ?.map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      severity: $enumDecode(_$ImpactSeverityEnumMap, json['severity']),
      detectionAlgorithm: json['detectionAlgorithm'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationConfidence:
          (json['verificationConfidence'] as num?)?.toDouble(),
      verificationReason: json['verificationReason'] as String?,
    );

Map<String, dynamic> _$ImpactInfoToJson(ImpactInfo instance) =>
    <String, dynamic>{
      'accelerationMagnitude': instance.accelerationMagnitude,
      'maxAcceleration': instance.maxAcceleration,
      'detectionTime': instance.detectionTime.toIso8601String(),
      'sensorReadings': instance.sensorReadings.map((e) => e.toJson()).toList(),
      'severity': _$ImpactSeverityEnumMap[instance.severity]!,
      'detectionAlgorithm': instance.detectionAlgorithm,
      'isVerified': instance.isVerified,
      'verificationConfidence': instance.verificationConfidence,
      'verificationReason': instance.verificationReason,
    };

const _$ImpactSeverityEnumMap = {
  ImpactSeverity.low: 'low',
  ImpactSeverity.medium: 'medium',
  ImpactSeverity.high: 'high',
  ImpactSeverity.critical: 'critical',
};

SensorReading _$SensorReadingFromJson(Map<String, dynamic> json) =>
    SensorReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      sensorType: json['sensorType'] as String,
    );

Map<String, dynamic> _$SensorReadingToJson(SensorReading instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
      'sensorType': instance.sensorType,
    };

SOSMessage _$SOSMessageFromJson(Map<String, dynamic> json) => SOSMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      senderId: json['senderId'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$SOSMessageToJson(SOSMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
      'senderId': instance.senderId,
      'isDelivered': instance.isDelivered,
      'isRead': instance.isRead,
    };

const _$MessageTypeEnumMap = {
  MessageType.userMessage: 'user_message',
  MessageType.systemMessage: 'system_message',
  MessageType.emergencyContactResponse: 'emergency_contact_response',
  MessageType.responderMessage: 'responder_message',
};

MediaAttachment _$MediaAttachmentFromJson(Map<String, dynamic> json) =>
    MediaAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      type: $enumDecode(_$MediaTypeEnumMap, json['type']),
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      isUploaded: json['isUploaded'] as bool? ?? false,
    );

Map<String, dynamic> _$MediaAttachmentToJson(MediaAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'type': _$MediaTypeEnumMap[instance.type]!,
      'fileSizeBytes': instance.fileSizeBytes,
      'timestamp': instance.timestamp.toIso8601String(),
      'description': instance.description,
      'isUploaded': instance.isUploaded,
    };

const _$MediaTypeEnumMap = {
  MediaType.photo: 'photo',
  MediaType.video: 'video',
  MediaType.audio: 'audio',
  MediaType.document: 'document',
};

RescueTeamResponse _$RescueTeamResponseFromJson(Map<String, dynamic> json) =>
    RescueTeamResponse(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamType: $enumDecode(_$RescueTeamTypeEnumMap, json['teamType']),
      status: $enumDecode(_$ResponseStatusEnumMap, json['status']),
      responseTime: DateTime.parse(json['responseTime'] as String),
      estimatedArrival: json['estimatedArrival'] == null
          ? null
          : DateTime.parse(json['estimatedArrival'] as String),
      currentLocation: json['currentLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['currentLocation'] as Map<String, dynamic>),
      message: json['message'] as String?,
      assignedMembers: (json['assignedMembers'] as List<dynamic>?)
              ?.map((e) => RescueTeamMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      equipment: json['equipment'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$RescueTeamResponseToJson(RescueTeamResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'teamType': _$RescueTeamTypeEnumMap[instance.teamType]!,
      'status': _$ResponseStatusEnumMap[instance.status]!,
      'responseTime': instance.responseTime.toIso8601String(),
      'estimatedArrival': instance.estimatedArrival?.toIso8601String(),
      'currentLocation': instance.currentLocation,
      'message': instance.message,
      'assignedMembers': instance.assignedMembers,
      'equipment': instance.equipment,
    };

const _$RescueTeamTypeEnumMap = {
  RescueTeamType.paramedic: 'paramedic',
  RescueTeamType.fireDepartment: 'fire_department',
  RescueTeamType.police: 'police',
  RescueTeamType.sarTeam: 'sar_team',
  RescueTeamType.helicopter: 'helicopter',
  RescueTeamType.coastGuard: 'coast_guard',
};

const _$ResponseStatusEnumMap = {
  ResponseStatus.acknowledged: 'acknowledged',
  ResponseStatus.enRoute: 'en_route',
  ResponseStatus.onScene: 'on_scene',
  ResponseStatus.unableToRespond: 'unable_to_respond',
  ResponseStatus.completed: 'completed',
  ResponseStatus.cancelled: 'cancelled',
};

EmergencyContactResponse _$EmergencyContactResponseFromJson(
        Map<String, dynamic> json) =>
    EmergencyContactResponse(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      contactName: json['contactName'] as String,
      status: $enumDecode(_$ResponseStatusEnumMap, json['status']),
      responseTime: DateTime.parse(json['responseTime'] as String),
      message: json['message'] as String?,
      isOnWay: json['isOnWay'] as bool? ?? false,
      estimatedArrival: json['estimatedArrival'] == null
          ? null
          : DateTime.parse(json['estimatedArrival'] as String),
    );

Map<String, dynamic> _$EmergencyContactResponseToJson(
        EmergencyContactResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contactId': instance.contactId,
      'contactName': instance.contactName,
      'status': _$ResponseStatusEnumMap[instance.status]!,
      'responseTime': instance.responseTime.toIso8601String(),
      'message': instance.message,
      'isOnWay': instance.isOnWay,
      'estimatedArrival': instance.estimatedArrival?.toIso8601String(),
    };

RescueTeamMember _$RescueTeamMemberFromJson(Map<String, dynamic> json) =>
    RescueTeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      specialization: json['specialization'] as String?,
    );

Map<String, dynamic> _$RescueTeamMemberToJson(RescueTeamMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'specialization': instance.specialization,
    };

RescueStatus _$RescueStatusFromJson(Map<String, dynamic> json) => RescueStatus(
      id: json['id'] as String,
      phase: $enumDecode(_$RescuePhaseEnumMap, json['phase']),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      currentAction: json['currentAction'] as String?,
      respondersEnRoute: (json['respondersEnRoute'] as num?)?.toInt() ?? 0,
      respondersOnScene: (json['respondersOnScene'] as num?)?.toInt() ?? 0,
      estimatedCompletion: json['estimatedCompletion'] == null
          ? null
          : DateTime.parse(json['estimatedCompletion'] as String),
    );

Map<String, dynamic> _$RescueStatusToJson(RescueStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phase': _$RescuePhaseEnumMap[instance.phase]!,
      'lastUpdate': instance.lastUpdate.toIso8601String(),
      'currentAction': instance.currentAction,
      'respondersEnRoute': instance.respondersEnRoute,
      'respondersOnScene': instance.respondersOnScene,
      'estimatedCompletion': instance.estimatedCompletion?.toIso8601String(),
    };

const _$RescuePhaseEnumMap = {
  RescuePhase.alertSent: 'alert_sent',
  RescuePhase.responseDispatched: 'response_dispatched',
  RescuePhase.enRoute: 'en_route',
  RescuePhase.onScene: 'on_scene',
  RescuePhase.treatmentInProgress: 'treatment_in_progress',
  RescuePhase.transportToHospital: 'transport_to_hospital',
  RescuePhase.completed: 'completed',
};

VoiceVerificationInfo _$VoiceVerificationInfoFromJson(
        Map<String, dynamic> json) =>
    VoiceVerificationInfo(
      requestTime: DateTime.parse(json['requestTime'] as String),
      responseTime: json['responseTime'] == null
          ? null
          : DateTime.parse(json['responseTime'] as String),
      result: $enumDecode(_$VoiceVerificationResultEnumMap, json['result']),
      transcription: json['transcription'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$VoiceVerificationInfoToJson(
        VoiceVerificationInfo instance) =>
    <String, dynamic>{
      'requestTime': instance.requestTime.toIso8601String(),
      'responseTime': instance.responseTime?.toIso8601String(),
      'result': _$VoiceVerificationResultEnumMap[instance.result]!,
      'transcription': instance.transcription,
      'confidenceScore': instance.confidenceScore,
      'attemptCount': instance.attemptCount,
    };

const _$VoiceVerificationResultEnumMap = {
  VoiceVerificationResult.pending: 'pending',
  VoiceVerificationResult.confirmed: 'confirmed',
  VoiceVerificationResult.cancelled: 'cancelled',
  VoiceVerificationResult.noResponse: 'no_response',
  VoiceVerificationResult.unclearResponse: 'unclear_response',
};
