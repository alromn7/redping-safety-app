// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      type: $enumDecode(_$ContactTypeEnumMap, json['type']),
      isEnabled: json['isEnabled'] as bool? ?? true,
      priority: (json['priority'] as num).toInt(),
      relationship: json['relationship'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      availability: $enumDecodeNullable(
              _$ContactAvailabilityEnumMap, json['availability']) ??
          ContactAvailability.available,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      lastResponseTime: json['lastResponseTime'] == null
          ? null
          : DateTime.parse(json['lastResponseTime'] as String),
    );

Map<String, dynamic> _$EmergencyContactToJson(EmergencyContact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'type': _$ContactTypeEnumMap[instance.type]!,
      'isEnabled': instance.isEnabled,
      'priority': instance.priority,
      'relationship': instance.relationship,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'availability': _$ContactAvailabilityEnumMap[instance.availability]!,
      'distanceKm': instance.distanceKm,
      'lastResponseTime': instance.lastResponseTime?.toIso8601String(),
    };

const _$ContactTypeEnumMap = {
  ContactType.family: 'family',
  ContactType.friend: 'friend',
  ContactType.medical: 'medical',
  ContactType.work: 'work',
  ContactType.emergencyServices: 'emergency_services',
  ContactType.other: 'other',
};

const _$ContactAvailabilityEnumMap = {
  ContactAvailability.available: 'available',
  ContactAvailability.busy: 'busy',
  ContactAvailability.emergencyOnly: 'emergency_only',
  ContactAvailability.unavailable: 'unavailable',
  ContactAvailability.unknown: 'unknown',
};

ContactAlertLog _$ContactAlertLogFromJson(Map<String, dynamic> json) =>
    ContactAlertLog(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      sosSessionId: json['sosSessionId'] as String,
      method: $enumDecode(_$AlertMethodEnumMap, json['method']),
      status: $enumDecode(_$AlertStatusEnumMap, json['status']),
      sentAt: DateTime.parse(json['sentAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ContactAlertLogToJson(ContactAlertLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contactId': instance.contactId,
      'sosSessionId': instance.sosSessionId,
      'method': _$AlertMethodEnumMap[instance.method]!,
      'status': _$AlertStatusEnumMap[instance.status]!,
      'sentAt': instance.sentAt.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'retryCount': instance.retryCount,
    };

const _$AlertMethodEnumMap = {
  AlertMethod.sms: 'sms',
  AlertMethod.call: 'call',
  AlertMethod.email: 'email',
  AlertMethod.pushNotification: 'push_notification',
  AlertMethod.appNotification: 'app_notification',
};

const _$AlertStatusEnumMap = {
  AlertStatus.pending: 'pending',
  AlertStatus.sent: 'sent',
  AlertStatus.delivered: 'delivered',
  AlertStatus.acknowledged: 'acknowledged',
  AlertStatus.failed: 'failed',
  AlertStatus.cancelled: 'cancelled',
};
