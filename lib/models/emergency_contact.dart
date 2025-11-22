import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'emergency_contact.g.dart';

/// Emergency contact model for SOS alerts
@JsonSerializable()
class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final ContactType type;
  final bool isEnabled;
  final int priority; // 1 = highest priority
  final String? relationship;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ENHANCEMENT 5: Contact availability tracking
  final ContactAvailability availability;
  final double?
  distanceKm; // Distance from user's location (for smart selection)
  final DateTime? lastResponseTime; // Track response history

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.type,
    this.isEnabled = true,
    required this.priority,
    this.relationship,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.availability = ContactAvailability.available,
    this.distanceKm,
    this.lastResponseTime,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactToJson(this);

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    ContactType? type,
    bool? isEnabled,
    int? priority,
    String? relationship,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ContactAvailability? availability,
    double? distanceKm,
    DateTime? lastResponseTime,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      priority: priority ?? this.priority,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availability: availability ?? this.availability,
      distanceKm: distanceKm ?? this.distanceKm,
      lastResponseTime: lastResponseTime ?? this.lastResponseTime,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    email,
    type,
    isEnabled,
    priority,
    relationship,
    notes,
    createdAt,
    updatedAt,
    availability,
    distanceKm,
    lastResponseTime,
  ];
}

/// Types of emergency contacts
enum ContactType {
  @JsonValue('family')
  family,
  @JsonValue('friend')
  friend,
  @JsonValue('medical')
  medical,
  @JsonValue('work')
  work,
  @JsonValue('emergency_services')
  emergencyServices,
  @JsonValue('other')
  other,
}

/// Emergency contact alert log
@JsonSerializable()
class ContactAlertLog extends Equatable {
  final String id;
  final String contactId;
  final String sosSessionId;
  final AlertMethod method;
  final AlertStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? acknowledgedAt;
  final String? errorMessage;
  final int retryCount;

  const ContactAlertLog({
    required this.id,
    required this.contactId,
    required this.sosSessionId,
    required this.method,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.acknowledgedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  factory ContactAlertLog.fromJson(Map<String, dynamic> json) =>
      _$ContactAlertLogFromJson(json);

  Map<String, dynamic> toJson() => _$ContactAlertLogToJson(this);

  ContactAlertLog copyWith({
    String? id,
    String? contactId,
    String? sosSessionId,
    AlertMethod? method,
    AlertStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? acknowledgedAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return ContactAlertLog(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      sosSessionId: sosSessionId ?? this.sosSessionId,
      method: method ?? this.method,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    contactId,
    sosSessionId,
    method,
    status,
    sentAt,
    deliveredAt,
    acknowledgedAt,
    errorMessage,
    retryCount,
  ];
}

/// Alert delivery methods
enum AlertMethod {
  @JsonValue('sms')
  sms,
  @JsonValue('call')
  call,
  @JsonValue('email')
  email,
  @JsonValue('push_notification')
  pushNotification,
  @JsonValue('app_notification')
  appNotification,
}

/// Alert delivery status
enum AlertStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('acknowledged')
  acknowledged,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// ENHANCEMENT 5: Contact availability status
enum ContactAvailability {
  @JsonValue('available')
  available, // Contact is available and will respond to emergencies

  @JsonValue('busy')
  busy, // Contact is busy but will try to respond

  @JsonValue('emergency_only')
  emergencyOnly, // Contact only for critical emergencies

  @JsonValue('unavailable')
  unavailable, // Contact temporarily unavailable (e.g., traveling, sleeping)

  @JsonValue('unknown')
  unknown, // Availability status not set
}
