import 'package:equatable/equatable.dart';

/// Model representing a response to a help request
class HelpResponse extends Equatable {
  final String id;
  final String requestId;
  final String responderId;
  final String responderName;
  final String message;
  final HelpResponseType type;
  final String? contactInfo;
  final List<String> attachments;
  final DateTime createdAt;
  final bool isAccepted;

  const HelpResponse({
    required this.id,
    required this.requestId,
    required this.responderId,
    required this.responderName,
    required this.message,
    required this.type,
    this.contactInfo,
    this.attachments = const [],
    required this.createdAt,
    this.isAccepted = false,
  });

  /// Create a copy of this response with updated fields
  HelpResponse copyWith({
    String? id,
    String? requestId,
    String? responderId,
    String? responderName,
    String? message,
    HelpResponseType? type,
    String? contactInfo,
    List<String>? attachments,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return HelpResponse(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      responderId: responderId ?? this.responderId,
      responderName: responderName ?? this.responderName,
      message: message ?? this.message,
      type: type ?? this.type,
      contactInfo: contactInfo ?? this.contactInfo,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'responderId': responderId,
      'responderName': responderName,
      'message': message,
      'type': type.name,
      'contactInfo': contactInfo,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'isAccepted': isAccepted,
    };
  }

  /// Create from JSON
  factory HelpResponse.fromJson(Map<String, dynamic> json) {
    return HelpResponse(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      responderId: json['responderId'] as String,
      responderName: json['responderName'] as String,
      message: json['message'] as String,
      type: HelpResponseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HelpResponseType.offer,
      ),
      contactInfo: json['contactInfo'] as String?,
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    requestId,
    responderId,
    responderName,
    message,
    type,
    contactInfo,
    attachments,
    createdAt,
    isAccepted,
  ];
}

/// Type of help response
enum HelpResponseType {
  offer, // Community helper offering assistance
  service, // Local service provider offering service
  information, // Providing information or guidance
  referral, // Referring to another service
  emergency, // Escalating to emergency services
}
