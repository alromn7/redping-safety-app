import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'medication.g.dart';

/// Represents a prescribed or over-the-counter medication the user takes.
@JsonSerializable()
class Medication extends Equatable {
  final String id;
  final String name; // e.g., "Metformin"
  final String? brand; // e.g., "Glucophage"
  final String dosage; // e.g., "500 mg"
  final String form; // e.g., tablet, capsule, liquid
  final List<String> timesOfDay; // e.g., ["08:00", "20:00"] in HH:mm
  final int frequencyPerDay; // derived from timesOfDay length typically
  final int? refillCycleDays; // e.g., 30
  final DateTime? startDate;
  final DateTime? endDate;
  final bool remindersEnabled;
  final String? instructions; // e.g., "Take with food"
  final String? prescriber; // doctor name
  final String? prescriptionNumber;
  final String? pharmacy;

  // Adherence tracking
  final DateTime? lastTakenAt;
  final int dosesTaken;
  final int dosesMissed;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.name,
    this.brand,
    required this.dosage,
    required this.form,
    this.timesOfDay = const [],
    this.frequencyPerDay = 0,
    this.refillCycleDays,
    this.startDate,
    this.endDate,
    this.remindersEnabled = true,
    this.instructions,
    this.prescriber,
    this.prescriptionNumber,
    this.pharmacy,
    this.lastTakenAt,
    this.dosesTaken = 0,
    this.dosesMissed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationToJson(this);

  Medication copyWith({
    String? id,
    String? name,
    String? brand,
    String? dosage,
    String? form,
    List<String>? timesOfDay,
    int? frequencyPerDay,
    int? refillCycleDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? remindersEnabled,
    String? instructions,
    String? prescriber,
    String? prescriptionNumber,
    String? pharmacy,
    DateTime? lastTakenAt,
    int? dosesTaken,
    int? dosesMissed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
      refillCycleDays: refillCycleDays ?? this.refillCycleDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      instructions: instructions ?? this.instructions,
      prescriber: prescriber ?? this.prescriber,
      prescriptionNumber: prescriptionNumber ?? this.prescriptionNumber,
      pharmacy: pharmacy ?? this.pharmacy,
      lastTakenAt: lastTakenAt ?? this.lastTakenAt,
      dosesTaken: dosesTaken ?? this.dosesTaken,
      dosesMissed: dosesMissed ?? this.dosesMissed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    dosage,
    form,
    timesOfDay,
    frequencyPerDay,
    refillCycleDays,
    startDate,
    endDate,
    remindersEnabled,
    instructions,
    prescriber,
    prescriptionNumber,
    pharmacy,
    lastTakenAt,
    dosesTaken,
    dosesMissed,
    createdAt,
    updatedAt,
  ];
}
