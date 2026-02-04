// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthAppointment _$HealthAppointmentFromJson(Map<String, dynamic> json) =>
    HealthAppointment(
      id: json['id'] as String,
      title: json['title'] as String,
      doctorName: json['doctorName'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$HealthAppointmentToJson(HealthAppointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'doctorName': instance.doctorName,
      'dateTime': instance.dateTime.toIso8601String(),
      'location': instance.location,
      'notes': instance.notes,
      'attachments': instance.attachments,
      'remindersEnabled': instance.remindersEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
