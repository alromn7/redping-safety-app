import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'medical_profile.g.dart';

@JsonSerializable()
class MedicalProfile extends Equatable {
  final String userId;
  final BloodType? bloodType;
  final List<String> allergies; // e.g., Penicillin, Nuts
  final List<String> conditions; // e.g., Diabetes, Hypertension
  final List<String> medicationsActiveIds; // references to Medication docs
  final String? emergencyNotes; // free text visible during SOS

  // Insurance / coverage info (operational only)
  final bool shareCoverageWithFamily; // privacy control

  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalProfile({
    required this.userId,
    this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    this.medicationsActiveIds = const [],
    this.emergencyNotes,
    this.shareCoverageWithFamily = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) =>
      _$MedicalProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MedicalProfileToJson(this);

  MedicalProfile copyWith({
    String? userId,
    BloodType? bloodType,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medicationsActiveIds,
    String? emergencyNotes,
    bool? shareCoverageWithFamily,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalProfile(
      userId: userId ?? this.userId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medicationsActiveIds: medicationsActiveIds ?? this.medicationsActiveIds,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      shareCoverageWithFamily:
          shareCoverageWithFamily ?? this.shareCoverageWithFamily,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    bloodType,
    allergies,
    conditions,
    medicationsActiveIds,
    emergencyNotes,
    shareCoverageWithFamily,
    createdAt,
    updatedAt,
  ];
}

enum BloodType {
  @JsonValue('A+')
  aPos,
  @JsonValue('A-')
  aNeg,
  @JsonValue('B+')
  bPos,
  @JsonValue('B-')
  bNeg,
  @JsonValue('AB+')
  abPos,
  @JsonValue('AB-')
  abNeg,
  @JsonValue('O+')
  oPos,
  @JsonValue('O-')
  oNeg,
}
