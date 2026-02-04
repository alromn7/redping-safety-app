// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalProfile _$MedicalProfileFromJson(Map<String, dynamic> json) =>
    MedicalProfile(
      userId: json['userId'] as String,
      bloodType: $enumDecodeNullable(_$BloodTypeEnumMap, json['bloodType']),
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      medicationsActiveIds: (json['medicationsActiveIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      emergencyNotes: json['emergencyNotes'] as String?,
      shareCoverageWithFamily: json['shareCoverageWithFamily'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MedicalProfileToJson(MedicalProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'bloodType': _$BloodTypeEnumMap[instance.bloodType],
      'allergies': instance.allergies,
      'conditions': instance.conditions,
      'medicationsActiveIds': instance.medicationsActiveIds,
      'emergencyNotes': instance.emergencyNotes,
      'shareCoverageWithFamily': instance.shareCoverageWithFamily,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$BloodTypeEnumMap = {
  BloodType.aPos: 'A+',
  BloodType.aNeg: 'A-',
  BloodType.bPos: 'B+',
  BloodType.bNeg: 'B-',
  BloodType.abPos: 'AB+',
  BloodType.abNeg: 'AB-',
  BloodType.oPos: 'O+',
  BloodType.oNeg: 'O-',
};
