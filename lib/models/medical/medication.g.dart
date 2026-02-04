// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Medication _$MedicationFromJson(Map<String, dynamic> json) => Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      dosage: json['dosage'] as String,
      form: json['form'] as String,
      timesOfDay: (json['timesOfDay'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      frequencyPerDay: (json['frequencyPerDay'] as num?)?.toInt() ?? 0,
      refillCycleDays: (json['refillCycleDays'] as num?)?.toInt(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      instructions: json['instructions'] as String?,
      prescriber: json['prescriber'] as String?,
      prescriptionNumber: json['prescriptionNumber'] as String?,
      pharmacy: json['pharmacy'] as String?,
      lastTakenAt: json['lastTakenAt'] == null
          ? null
          : DateTime.parse(json['lastTakenAt'] as String),
      dosesTaken: (json['dosesTaken'] as num?)?.toInt() ?? 0,
      dosesMissed: (json['dosesMissed'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MedicationToJson(Medication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'dosage': instance.dosage,
      'form': instance.form,
      'timesOfDay': instance.timesOfDay,
      'frequencyPerDay': instance.frequencyPerDay,
      'refillCycleDays': instance.refillCycleDays,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'remindersEnabled': instance.remindersEnabled,
      'instructions': instance.instructions,
      'prescriber': instance.prescriber,
      'prescriptionNumber': instance.prescriptionNumber,
      'pharmacy': instance.pharmacy,
      'lastTakenAt': instance.lastTakenAt?.toIso8601String(),
      'dosesTaken': instance.dosesTaken,
      'dosesMissed': instance.dosesMissed,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
