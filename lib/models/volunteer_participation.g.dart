// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volunteer_participation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolunteerParticipation _$VolunteerParticipationFromJson(
        Map<String, dynamic> json) =>
    VolunteerParticipation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String?,
      missionId: json['missionId'] as String,
      role: $enumDecode(_$VolunteerRoleEnumMap, json['role']),
      status: $enumDecode(_$VolunteerStatusEnumMap, json['status']),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      acknowledgedRiskAt: json['acknowledgedRiskAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedRiskAt'] as String),
      currentLocation: json['currentLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['currentLocation'] as Map<String, dynamic>),
      skills:
          (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
      equipment:
          (json['equipment'] as List<dynamic>).map((e) => e as String).toList(),
      notes: json['notes'] as String?,
      hasFirstAid: json['hasFirstAid'] as bool? ?? false,
      hasTransportation: json['hasTransportation'] as bool? ?? false,
      isLocalResident: json['isLocalResident'] as bool? ?? false,
      emergencyContact: json['emergencyContact'] == null
          ? null
          : EmergencyContact.fromJson(
              json['emergencyContact'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VolunteerParticipationToJson(
        VolunteerParticipation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhone': instance.userPhone,
      'missionId': instance.missionId,
      'role': _$VolunteerRoleEnumMap[instance.role]!,
      'status': _$VolunteerStatusEnumMap[instance.status]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'acknowledgedRiskAt': instance.acknowledgedRiskAt?.toIso8601String(),
      'currentLocation': instance.currentLocation,
      'skills': instance.skills,
      'equipment': instance.equipment,
      'notes': instance.notes,
      'hasFirstAid': instance.hasFirstAid,
      'hasTransportation': instance.hasTransportation,
      'isLocalResident': instance.isLocalResident,
      'emergencyContact': instance.emergencyContact,
    };

const _$VolunteerRoleEnumMap = {
  VolunteerRole.generalSupport: 'general_support',
  VolunteerRole.searchAssistant: 'search_assistant',
  VolunteerRole.logisticsSupport: 'logistics_support',
  VolunteerRole.communicationRelay: 'communication_relay',
  VolunteerRole.crowdControl: 'crowd_control',
  VolunteerRole.supplyRunner: 'supply_runner',
  VolunteerRole.localGuide: 'local_guide',
  VolunteerRole.witness: 'witness',
  VolunteerRole.familyLiaison: 'family_liaison',
};

const _$VolunteerStatusEnumMap = {
  VolunteerStatus.pending: 'pending',
  VolunteerStatus.active: 'active',
  VolunteerStatus.standby: 'standby',
  VolunteerStatus.completed: 'completed',
  VolunteerStatus.withdrawn: 'withdrawn',
  VolunteerStatus.dismissed: 'dismissed',
};

RiskAcknowledgment _$RiskAcknowledgmentFromJson(Map<String, dynamic> json) =>
    RiskAcknowledgment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      missionId: json['missionId'] as String,
      acknowledgedAt: DateTime.parse(json['acknowledgedAt'] as String),
      ipAddress: json['ipAddress'] as String,
      deviceInfo: json['deviceInfo'] as String,
      acknowledgedRisks: (json['acknowledgedRisks'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      confirmedAdult: json['confirmedAdult'] as bool,
      confirmedPhysicalCapability: json['confirmedPhysicalCapability'] as bool,
      confirmedInsurance: json['confirmedInsurance'] as bool,
      confirmedEmergencyContact: json['confirmedEmergencyContact'] as bool,
      digitalSignature: json['digitalSignature'] as String,
    );

Map<String, dynamic> _$RiskAcknowledgmentToJson(RiskAcknowledgment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'missionId': instance.missionId,
      'acknowledgedAt': instance.acknowledgedAt.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'deviceInfo': instance.deviceInfo,
      'acknowledgedRisks': instance.acknowledgedRisks,
      'confirmedAdult': instance.confirmedAdult,
      'confirmedPhysicalCapability': instance.confirmedPhysicalCapability,
      'confirmedInsurance': instance.confirmedInsurance,
      'confirmedEmergencyContact': instance.confirmedEmergencyContact,
      'digitalSignature': instance.digitalSignature,
    };

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
    );

Map<String, dynamic> _$EmergencyContactToJson(EmergencyContact instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'relationship': instance.relationship,
    };
