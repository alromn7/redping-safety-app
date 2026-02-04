// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckInLocationSnapshot _$CheckInLocationSnapshotFromJson(
        Map<String, dynamic> json) =>
    CheckInLocationSnapshot(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$CheckInLocationSnapshotToJson(
        CheckInLocationSnapshot instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy': instance.accuracy,
      'capturedAt': instance.capturedAt.toIso8601String(),
    };

CheckInRequest _$CheckInRequestFromJson(Map<String, dynamic> json) =>
    CheckInRequest(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      requesterUserId: json['requesterUserId'] as String,
      targetUserId: json['targetUserId'] as String,
      status: $enumDecode(_$CheckInRequestStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      reason: json['reason'] as String?,
      autoApproved: json['autoApproved'] as bool? ?? false,
      locationSnapshot: json['locationSnapshot'] == null
          ? null
          : CheckInLocationSnapshot.fromJson(
              json['locationSnapshot'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CheckInRequestToJson(CheckInRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'requesterUserId': instance.requesterUserId,
      'targetUserId': instance.targetUserId,
      'status': _$CheckInRequestStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'reason': instance.reason,
      'autoApproved': instance.autoApproved,
      'locationSnapshot': instance.locationSnapshot?.toJson(),
    };

const _$CheckInRequestStatusEnumMap = {
  CheckInRequestStatus.pending: 'pending',
  CheckInRequestStatus.locationShared: 'locationShared',
  CheckInRequestStatus.denied: 'denied',
  CheckInRequestStatus.expired: 'expired',
};
