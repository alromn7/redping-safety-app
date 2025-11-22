import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'sos_session.dart';
import 'emergency_message.dart';

part 'sos_ping.g.dart';

/// SOS ping model for SAR member dashboard
@JsonSerializable(explicitToJson: true)
class SOSPing extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final String? userName;
  final String? userPhone;
  final SOSType type;
  final SOSPriority priority;
  final DateTime timestamp;
  final LocationInfo location;
  final String? userMessage;
  final List<String> medicalConditions;
  final List<String> allergies;
  final String? bloodType;
  final int? estimatedAge;
  final String? gender;
  final ImpactInfo? impactInfo;
  final List<String> assignedSARMembers;
  final List<SARResponse> sarResponses;
  final SOSPingStatus status;
  final double? distanceFromSAR;
  final List<EmergencyMessage> messages;
  final String? weatherConditions;
  final String? terrainType;
  final AccessibilityLevel accessibilityLevel;
  final List<String> requiredEquipment;
  final int estimatedRescueTime; // minutes
  final RiskLevel riskLevel;
  final Map<String, dynamic> metadata;

  const SOSPing({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.location,
    this.userMessage,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.bloodType,
    this.estimatedAge,
    this.gender,
    this.impactInfo,
    this.assignedSARMembers = const [],
    this.sarResponses = const [],
    required this.status,
    this.distanceFromSAR,
    this.messages = const [],
    this.weatherConditions,
    this.terrainType,
    required this.accessibilityLevel,
    this.requiredEquipment = const [],
    required this.estimatedRescueTime,
    required this.riskLevel,
    this.metadata = const {},
  });

  factory SOSPing.fromJson(Map<String, dynamic> json) =>
      _$SOSPingFromJson(json);

  Map<String, dynamic> toJson() => _$SOSPingToJson(this);

  SOSPing copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    String? userPhone,
    SOSType? type,
    SOSPriority? priority,
    DateTime? timestamp,
    LocationInfo? location,
    String? userMessage,
    List<String>? medicalConditions,
    List<String>? allergies,
    String? bloodType,
    int? estimatedAge,
    String? gender,
    ImpactInfo? impactInfo,
    List<String>? assignedSARMembers,
    List<SARResponse>? sarResponses,
    SOSPingStatus? status,
    double? distanceFromSAR,
    List<EmergencyMessage>? messages,
    String? weatherConditions,
    String? terrainType,
    AccessibilityLevel? accessibilityLevel,
    List<String>? requiredEquipment,
    int? estimatedRescueTime,
    RiskLevel? riskLevel,
    Map<String, dynamic>? metadata,
  }) {
    return SOSPing(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      userMessage: userMessage ?? this.userMessage,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      bloodType: bloodType ?? this.bloodType,
      estimatedAge: estimatedAge ?? this.estimatedAge,
      gender: gender ?? this.gender,
      impactInfo: impactInfo ?? this.impactInfo,
      assignedSARMembers: assignedSARMembers ?? this.assignedSARMembers,
      sarResponses: sarResponses ?? this.sarResponses,
      status: status ?? this.status,
      distanceFromSAR: distanceFromSAR ?? this.distanceFromSAR,
      messages: messages ?? this.messages,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      terrainType: terrainType ?? this.terrainType,
      accessibilityLevel: accessibilityLevel ?? this.accessibilityLevel,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      estimatedRescueTime: estimatedRescueTime ?? this.estimatedRescueTime,
      riskLevel: riskLevel ?? this.riskLevel,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this ping is urgent (requires immediate attention)
  bool get isUrgent =>
      priority == SOSPriority.critical ||
      riskLevel == RiskLevel.critical ||
      (impactInfo?.severity == ImpactSeverity.critical);

  /// Get time elapsed since SOS was triggered
  Duration get timeElapsed => DateTime.now().difference(timestamp);

  /// Check if SAR member is assigned to this ping
  bool isAssignedTo(String sarMemberId) {
    return assignedSARMembers.contains(sarMemberId);
  }

  /// Get SAR response from specific member
  SARResponse? getResponseFrom(String sarMemberId) {
    try {
      return sarResponses.firstWhere((r) => r.sarMemberId == sarMemberId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    id,
    sessionId,
    userId,
    type,
    priority,
    timestamp,
    location,
    status,
    assignedSARMembers,
    riskLevel,
  ];
}

/// SAR member response to SOS ping
@JsonSerializable(explicitToJson: true)
class SARResponse extends Equatable {
  final String id;
  final String sarMemberId;
  final String sarMemberName;
  final SARResponseType responseType;
  final DateTime responseTime;
  final String? message;
  final int? estimatedArrivalTime; // minutes
  final LocationInfo? currentLocation;
  final List<String> availableEquipment;
  final List<String> teamMembers;
  final String? vehicleType;
  final SARResponseStatus status;

  const SARResponse({
    required this.id,
    required this.sarMemberId,
    required this.sarMemberName,
    required this.responseType,
    required this.responseTime,
    this.message,
    this.estimatedArrivalTime,
    this.currentLocation,
    this.availableEquipment = const [],
    this.teamMembers = const [],
    this.vehicleType,
    required this.status,
  });

  factory SARResponse.fromJson(Map<String, dynamic> json) =>
      _$SARResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SARResponseToJson(this);

  SARResponse copyWith({
    String? id,
    String? sarMemberId,
    String? sarMemberName,
    SARResponseType? responseType,
    DateTime? responseTime,
    String? message,
    int? estimatedArrivalTime,
    LocationInfo? currentLocation,
    List<String>? availableEquipment,
    List<String>? teamMembers,
    String? vehicleType,
    SARResponseStatus? status,
  }) {
    return SARResponse(
      id: id ?? this.id,
      sarMemberId: sarMemberId ?? this.sarMemberId,
      sarMemberName: sarMemberName ?? this.sarMemberName,
      responseType: responseType ?? this.responseType,
      responseTime: responseTime ?? this.responseTime,
      message: message ?? this.message,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      currentLocation: currentLocation ?? this.currentLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      teamMembers: teamMembers ?? this.teamMembers,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sarMemberId,
    responseType,
    responseTime,
    status,
  ];
}

/// SOS priority levels for SAR operations
enum SOSPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// SOS ping status
enum SOSPingStatus {
  @JsonValue('active')
  active,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
}

/// Accessibility level for rescue location
enum AccessibilityLevel {
  @JsonValue('easy')
  easy,
  @JsonValue('moderate')
  moderate,
  @JsonValue('difficult')
  difficult,
  @JsonValue('extreme')
  extreme,
}

/// Risk level assessment
enum RiskLevel {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// SAR response types
enum SARResponseType {
  @JsonValue('available')
  available,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('unavailable')
  unavailable,
  @JsonValue('backup_needed')
  backupNeeded,
}

/// SAR response status
enum SARResponseStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('declined')
  declined,
  @JsonValue('en_route')
  enRoute,
  @JsonValue('on_scene')
  onScene,
  @JsonValue('completed')
  completed,
}
