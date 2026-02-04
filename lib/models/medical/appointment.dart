import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class HealthAppointment extends Equatable {
  final String id;
  final String title; // e.g., "GP Checkup", "Cardiologist"
  final String? doctorName;
  final DateTime dateTime;
  final String? location; // address or clinic name
  final String? notes;
  final List<String> attachments; // file ids/urls
  final bool remindersEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthAppointment({
    required this.id,
    required this.title,
    this.doctorName,
    required this.dateTime,
    this.location,
    this.notes,
    this.attachments = const [],
    this.remindersEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthAppointment.fromJson(Map<String, dynamic> json) =>
      _$HealthAppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$HealthAppointmentToJson(this);

  HealthAppointment copyWith({
    String? id,
    String? title,
    String? doctorName,
    DateTime? dateTime,
    String? location,
    String? notes,
    List<String>? attachments,
    bool? remindersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthAppointment(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    doctorName,
    dateTime,
    location,
    notes,
    attachments,
    remindersEnabled,
    createdAt,
    updatedAt,
  ];
}
