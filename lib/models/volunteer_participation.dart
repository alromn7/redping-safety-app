import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'sos_session.dart';

part 'volunteer_participation.g.dart';

/// Volunteer participation in rescue missions
@JsonSerializable()
class VolunteerParticipation extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final String missionId;
  final VolunteerRole role;
  final VolunteerStatus status;
  final DateTime joinedAt;
  final DateTime? acknowledgedRiskAt;
  final LocationInfo? currentLocation;
  final List<String> skills;
  final List<String> equipment;
  final String? notes;
  final bool hasFirstAid;
  final bool hasTransportation;
  final bool isLocalResident;
  final EmergencyContact? emergencyContact;

  const VolunteerParticipation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.missionId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.acknowledgedRiskAt,
    this.currentLocation,
    required this.skills,
    required this.equipment,
    this.notes,
    this.hasFirstAid = false,
    this.hasTransportation = false,
    this.isLocalResident = false,
    this.emergencyContact,
  });

  factory VolunteerParticipation.fromJson(Map<String, dynamic> json) =>
      _$VolunteerParticipationFromJson(json);

  Map<String, dynamic> toJson() => _$VolunteerParticipationToJson(this);

  VolunteerParticipation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? missionId,
    VolunteerRole? role,
    VolunteerStatus? status,
    DateTime? joinedAt,
    DateTime? acknowledgedRiskAt,
    LocationInfo? currentLocation,
    List<String>? skills,
    List<String>? equipment,
    String? notes,
    bool? hasFirstAid,
    bool? hasTransportation,
    bool? isLocalResident,
    EmergencyContact? emergencyContact,
  }) {
    return VolunteerParticipation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      missionId: missionId ?? this.missionId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      acknowledgedRiskAt: acknowledgedRiskAt ?? this.acknowledgedRiskAt,
      currentLocation: currentLocation ?? this.currentLocation,
      skills: skills ?? this.skills,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      hasFirstAid: hasFirstAid ?? this.hasFirstAid,
      hasTransportation: hasTransportation ?? this.hasTransportation,
      isLocalResident: isLocalResident ?? this.isLocalResident,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  bool get hasAcknowledgedRisk => acknowledgedRiskAt != null;
  bool get isActive => status == VolunteerStatus.active;

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userPhone,
    missionId,
    role,
    status,
    joinedAt,
    acknowledgedRiskAt,
    currentLocation,
    skills,
    equipment,
    notes,
    hasFirstAid,
    hasTransportation,
    isLocalResident,
    emergencyContact,
  ];
}

/// Risk acknowledgment for volunteer participation
@JsonSerializable()
class RiskAcknowledgment extends Equatable {
  final String id;
  final String userId;
  final String missionId;
  final DateTime acknowledgedAt;
  final String ipAddress;
  final String deviceInfo;
  final List<String> acknowledgedRisks;
  final bool confirmedAdult;
  final bool confirmedPhysicalCapability;
  final bool confirmedInsurance;
  final bool confirmedEmergencyContact;
  final String digitalSignature;

  const RiskAcknowledgment({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.acknowledgedAt,
    required this.ipAddress,
    required this.deviceInfo,
    required this.acknowledgedRisks,
    required this.confirmedAdult,
    required this.confirmedPhysicalCapability,
    required this.confirmedInsurance,
    required this.confirmedEmergencyContact,
    required this.digitalSignature,
  });

  factory RiskAcknowledgment.fromJson(Map<String, dynamic> json) =>
      _$RiskAcknowledgmentFromJson(json);

  Map<String, dynamic> toJson() => _$RiskAcknowledgmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    missionId,
    acknowledgedAt,
    ipAddress,
    deviceInfo,
    acknowledgedRisks,
    confirmedAdult,
    confirmedPhysicalCapability,
    confirmedInsurance,
    confirmedEmergencyContact,
    digitalSignature,
  ];
}

/// Emergency contact for volunteers
@JsonSerializable()
class EmergencyContact extends Equatable {
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactToJson(this);

  @override
  List<Object?> get props => [name, phone, relationship];
}

/// Volunteer role in rescue mission
enum VolunteerRole {
  @JsonValue('general_support')
  generalSupport,
  @JsonValue('search_assistant')
  searchAssistant,
  @JsonValue('logistics_support')
  logisticsSupport,
  @JsonValue('communication_relay')
  communicationRelay,
  @JsonValue('crowd_control')
  crowdControl,
  @JsonValue('supply_runner')
  supplyRunner,
  @JsonValue('local_guide')
  localGuide,
  @JsonValue('witness')
  witness,
  @JsonValue('family_liaison')
  familyLiaison,
}

/// Volunteer participation status
enum VolunteerStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('standby')
  standby,
  @JsonValue('completed')
  completed,
  @JsonValue('withdrawn')
  withdrawn,
  @JsonValue('dismissed')
  dismissed,
}
