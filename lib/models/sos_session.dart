import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sos_session.g.dart';

/// SOS session model representing an emergency alert session
@JsonSerializable(explicitToJson: true)
class SOSSession extends Equatable {
  final String id;
  final String userId;
  final SOSType type;
  final SOSStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final LocationInfo location;
  final ImpactInfo? impactInfo;
  final List<String> contactedEmergencyContacts;
  final List<SOSMessage> messages;
  final List<MediaAttachment> mediaAttachments;
  final List<RescueTeamResponse> rescueTeamResponses;
  final List<EmergencyContactResponse> emergencyContactResponses;
  final RescueStatus? rescueStatus;
  final VoiceVerificationInfo? voiceVerification;
  final String? userMessage;
  final bool isTestMode;
  final Map<String, dynamic> metadata;

  const SOSSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.location,
    this.impactInfo,
    this.contactedEmergencyContacts = const [],
    this.messages = const [],
    this.mediaAttachments = const [],
    this.rescueTeamResponses = const [],
    this.emergencyContactResponses = const [],
    this.rescueStatus,
    this.voiceVerification,
    this.userMessage,
    this.isTestMode = false,
    this.metadata = const {},
  });

  factory SOSSession.fromJson(Map<String, dynamic> json) =>
      _$SOSSessionFromJson(json);

  Map<String, dynamic> toJson() => _$SOSSessionToJson(this);

  SOSSession copyWith({
    String? id,
    String? userId,
    SOSType? type,
    SOSStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    LocationInfo? location,
    ImpactInfo? impactInfo,
    List<String>? contactedEmergencyContacts,
    List<SOSMessage>? messages,
    List<MediaAttachment>? mediaAttachments,
    List<RescueTeamResponse>? rescueTeamResponses,
    List<EmergencyContactResponse>? emergencyContactResponses,
    RescueStatus? rescueStatus,
    VoiceVerificationInfo? voiceVerification,
    String? userMessage,
    bool? isTestMode,
    Map<String, dynamic>? metadata,
  }) {
    return SOSSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      impactInfo: impactInfo ?? this.impactInfo,
      contactedEmergencyContacts:
          contactedEmergencyContacts ?? this.contactedEmergencyContacts,
      messages: messages ?? this.messages,
      mediaAttachments: mediaAttachments ?? this.mediaAttachments,
      rescueTeamResponses: rescueTeamResponses ?? this.rescueTeamResponses,
      emergencyContactResponses:
          emergencyContactResponses ?? this.emergencyContactResponses,
      rescueStatus: rescueStatus ?? this.rescueStatus,
      voiceVerification: voiceVerification ?? this.voiceVerification,
      userMessage: userMessage ?? this.userMessage,
      isTestMode: isTestMode ?? this.isTestMode,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Duration of the SOS session
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if the session is currently active
  bool get isActive {
    return status == SOSStatus.active ||
        status == SOSStatus.countdown ||
        status == SOSStatus.acknowledged ||
        status == SOSStatus.assigned ||
        status == SOSStatus.enRoute ||
        status == SOSStatus.onScene ||
        status == SOSStatus.inProgress;
  }

  /// Check if the session was automatically triggered
  bool get isAutoTriggered {
    return type == SOSType.crashDetection || type == SOSType.fallDetection;
  }

  /// Get user name from metadata
  String? get userName => metadata['userName'] as String?;

  /// Get user phone from metadata
  String? get userPhone => metadata['userPhone'] as String?;

  /// Get battery level from metadata
  int? get batteryLevel => metadata['batteryLevel'] as int?;

  /// Get assigned SAR team name from metadata
  String? get assignedSARName => metadata['assignedSARName'] as String?;

  /// Get assigned SAR team phone from metadata
  String? get assignedSARPhone => metadata['assignedSARPhone'] as String?;

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    status,
    startTime,
    endTime,
    location,
    impactInfo,
    contactedEmergencyContacts,
    messages,
    mediaAttachments,
    rescueTeamResponses,
    emergencyContactResponses,
    rescueStatus,
    voiceVerification,
    userMessage,
    isTestMode,
    metadata,
  ];
}

/// Types of SOS triggers
enum SOSType {
  @JsonValue('manual')
  manual,
  @JsonValue('crash_detection')
  crashDetection,
  @JsonValue('fall_detection')
  fallDetection,
  @JsonValue('panic_button')
  panicButton,
  @JsonValue('voice_command')
  voiceCommand,
  @JsonValue('external_trigger')
  externalTrigger,
}

/// SOS session status
enum SOSStatus {
  @JsonValue('countdown')
  countdown,
  @JsonValue('active')
  active,
  @JsonValue('acknowledged')
  acknowledged,
  @JsonValue('assigned')
  assigned,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('on_scene')
  onScene,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('resolved')
  resolved,
  @JsonValue('false_alarm')
  falseAlarm,
}

/// Location information for SOS session
@JsonSerializable(explicitToJson: true)
class LocationInfo extends Equatable {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? address;
  final List<BreadcrumbPoint> breadcrumbTrail;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    this.address,
    this.breadcrumbTrail = const [],
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationInfoToJson(this);

  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? address,
    List<BreadcrumbPoint>? breadcrumbTrail,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      breadcrumbTrail: breadcrumbTrail ?? this.breadcrumbTrail,
    );
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    altitude,
    accuracy,
    speed,
    heading,
    timestamp,
    address,
    breadcrumbTrail,
  ];
}

/// Breadcrumb point for location trail
@JsonSerializable(explicitToJson: true)
class BreadcrumbPoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;

  const BreadcrumbPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
  });

  factory BreadcrumbPoint.fromJson(Map<String, dynamic> json) =>
      _$BreadcrumbPointFromJson(json);

  Map<String, dynamic> toJson() => _$BreadcrumbPointToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, timestamp, speed];
}

/// Impact information for crash/fall detection
@JsonSerializable(explicitToJson: true)
class ImpactInfo extends Equatable {
  final double accelerationMagnitude;
  final double maxAcceleration;
  final DateTime detectionTime;
  final List<SensorReading> sensorReadings;
  final ImpactSeverity severity;
  final String? detectionAlgorithm;

  // AI Verification fields
  final bool isVerified;
  final double? verificationConfidence;
  final String? verificationReason;

  const ImpactInfo({
    required this.accelerationMagnitude,
    required this.maxAcceleration,
    required this.detectionTime,
    this.sensorReadings = const [],
    required this.severity,
    this.detectionAlgorithm,
    this.isVerified = false,
    this.verificationConfidence,
    this.verificationReason,
  });

  /// Named constructor for AI verification results
  const ImpactInfo.fromVerification({
    required DateTime timestamp,
    required double magnitude,
    required LocationInfo? location,
    required this.isVerified,
    required this.verificationConfidence,
    required this.verificationReason,
    this.severity = ImpactSeverity.medium,
    this.detectionAlgorithm = 'AI Verification',
  }) : accelerationMagnitude = magnitude,
       maxAcceleration = magnitude,
       detectionTime = timestamp,
       sensorReadings = const [];

  factory ImpactInfo.fromJson(Map<String, dynamic> json) =>
      _$ImpactInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ImpactInfoToJson(this);

  @override
  List<Object?> get props => [
    accelerationMagnitude,
    maxAcceleration,
    detectionTime,
    sensorReadings,
    severity,
    detectionAlgorithm,
    isVerified,
    verificationConfidence,
    verificationReason,
  ];
}

/// Impact severity levels
enum ImpactSeverity {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// Sensor reading data
@JsonSerializable(explicitToJson: true)
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final String sensorType;

  const SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.sensorType,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingFromJson(json);

  Map<String, dynamic> toJson() => _$SensorReadingToJson(this);

  double get magnitude => (x * x + y * y + z * z).abs();

  @override
  List<Object?> get props => [timestamp, x, y, z, sensorType];
}

/// SOS message within a session
@JsonSerializable(explicitToJson: true)
class SOSMessage extends Equatable {
  final String id;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? senderId;
  final bool isDelivered;
  final bool isRead;

  const SOSMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
    this.senderId,
    this.isDelivered = false,
    this.isRead = false,
  });

  factory SOSMessage.fromJson(Map<String, dynamic> json) =>
      _$SOSMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SOSMessageToJson(this);

  @override
  List<Object?> get props => [
    id,
    content,
    timestamp,
    type,
    senderId,
    isDelivered,
    isRead,
  ];
}

/// Message types
enum MessageType {
  @JsonValue('user_message')
  userMessage,
  @JsonValue('system_message')
  systemMessage,
  @JsonValue('emergency_contact_response')
  emergencyContactResponse,
  @JsonValue('responder_message')
  responderMessage,
}

/// Media attachment for SOS session
@JsonSerializable(explicitToJson: true)
class MediaAttachment extends Equatable {
  final String id;
  final String fileName;
  final String filePath;
  final MediaType type;
  final int fileSizeBytes;
  final DateTime timestamp;
  final String? description;
  final bool isUploaded;

  const MediaAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSizeBytes,
    required this.timestamp,
    this.description,
    this.isUploaded = false,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) =>
      _$MediaAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$MediaAttachmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    fileName,
    filePath,
    type,
    fileSizeBytes,
    timestamp,
    description,
    isUploaded,
  ];
}

/// Media types
enum MediaType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('document')
  document,
}

/// Rescue team response to SOS
@JsonSerializable()
class RescueTeamResponse extends Equatable {
  final String id;
  final String teamId;
  final String teamName;
  final RescueTeamType teamType;
  final ResponseStatus status;
  final DateTime responseTime;
  final DateTime? estimatedArrival;
  final LocationInfo? currentLocation;
  final String? message;
  final List<RescueTeamMember> assignedMembers;
  final Map<String, dynamic> equipment;

  const RescueTeamResponse({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.teamType,
    required this.status,
    required this.responseTime,
    this.estimatedArrival,
    this.currentLocation,
    this.message,
    this.assignedMembers = const [],
    this.equipment = const {},
  });

  factory RescueTeamResponse.fromJson(Map<String, dynamic> json) =>
      _$RescueTeamResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RescueTeamResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    teamId,
    teamName,
    teamType,
    status,
    responseTime,
    estimatedArrival,
    currentLocation,
    message,
    assignedMembers,
    equipment,
  ];
}

/// Emergency contact response to SOS
@JsonSerializable(explicitToJson: true)
class EmergencyContactResponse extends Equatable {
  final String id;
  final String contactId;
  final String contactName;
  final ResponseStatus status;
  final DateTime responseTime;
  final String? message;
  final bool isOnWay;
  final DateTime? estimatedArrival;

  const EmergencyContactResponse({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.status,
    required this.responseTime,
    this.message,
    this.isOnWay = false,
    this.estimatedArrival,
  });

  factory EmergencyContactResponse.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    contactId,
    contactName,
    status,
    responseTime,
    message,
    isOnWay,
    estimatedArrival,
  ];
}

/// Rescue team member
@JsonSerializable(explicitToJson: true)
class RescueTeamMember extends Equatable {
  final String id;
  final String name;
  final String role;
  final String? specialization;

  const RescueTeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.specialization,
  });

  factory RescueTeamMember.fromJson(Map<String, dynamic> json) =>
      _$RescueTeamMemberFromJson(json);

  Map<String, dynamic> toJson() => _$RescueTeamMemberToJson(this);

  @override
  List<Object?> get props => [id, name, role, specialization];
}

/// Rescue status information
@JsonSerializable(explicitToJson: true)
class RescueStatus extends Equatable {
  final String id;
  final RescuePhase phase;
  final DateTime lastUpdate;
  final String? currentAction;
  final int respondersEnRoute;
  final int respondersOnScene;
  final DateTime? estimatedCompletion;

  const RescueStatus({
    required this.id,
    required this.phase,
    required this.lastUpdate,
    this.currentAction,
    this.respondersEnRoute = 0,
    this.respondersOnScene = 0,
    this.estimatedCompletion,
  });

  factory RescueStatus.fromJson(Map<String, dynamic> json) =>
      _$RescueStatusFromJson(json);

  Map<String, dynamic> toJson() => _$RescueStatusToJson(this);

  @override
  List<Object?> get props => [
    id,
    phase,
    lastUpdate,
    currentAction,
    respondersEnRoute,
    respondersOnScene,
    estimatedCompletion,
  ];
}

/// Response status
enum ResponseStatus {
  @JsonValue('acknowledged')
  acknowledged,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('on_scene')
  onScene,
  @JsonValue('unable_to_respond')
  unableToRespond,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Rescue team types
enum RescueTeamType {
  @JsonValue('paramedic')
  paramedic,
  @JsonValue('fire_department')
  fireDepartment,
  @JsonValue('police')
  police,
  @JsonValue('sar_team')
  sarTeam,
  @JsonValue('helicopter')
  helicopter,
  @JsonValue('coast_guard')
  coastGuard,
}

/// Rescue phases
enum RescuePhase {
  @JsonValue('alert_sent')
  alertSent,
  @JsonValue('response_dispatched')
  responseDispatched,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('on_scene')
  onScene,
  @JsonValue('treatment_in_progress')
  treatmentInProgress,
  @JsonValue('transport_to_hospital')
  transportToHospital,
  @JsonValue('completed')
  completed,
}

/// Voice verification information
@JsonSerializable(explicitToJson: true)
class VoiceVerificationInfo extends Equatable {
  final DateTime requestTime;
  final DateTime? responseTime;
  final VoiceVerificationResult result;
  final String? transcription;
  final double? confidenceScore;
  final int attemptCount;

  const VoiceVerificationInfo({
    required this.requestTime,
    this.responseTime,
    required this.result,
    this.transcription,
    this.confidenceScore,
    this.attemptCount = 1,
  });

  factory VoiceVerificationInfo.fromJson(Map<String, dynamic> json) =>
      _$VoiceVerificationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceVerificationInfoToJson(this);

  VoiceVerificationInfo copyWith({
    DateTime? requestTime,
    DateTime? responseTime,
    VoiceVerificationResult? result,
    String? transcription,
    double? confidenceScore,
    int? attemptCount,
  }) {
    return VoiceVerificationInfo(
      requestTime: requestTime ?? this.requestTime,
      responseTime: responseTime ?? this.responseTime,
      result: result ?? this.result,
      transcription: transcription ?? this.transcription,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  @override
  List<Object?> get props => [
    requestTime,
    responseTime,
    result,
    transcription,
    confidenceScore,
    attemptCount,
  ];
}

/// Voice verification results
enum VoiceVerificationResult {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('no_response')
  noResponse,
  @JsonValue('unclear_response')
  unclearResponse,
}
