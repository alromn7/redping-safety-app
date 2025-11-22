import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'communication_log.g.dart';

/// Communication log model for tracking SAR team communications
/// Aligned with website's messaging structure
@JsonSerializable()
class CommunicationLog extends Equatable {
  /// Unique message ID
  final String id;

  /// Communication type (call, sms, email, etc.)
  final String type;

  /// Message type aligned with EmergencyMessage enum (sarResponse, userResponse, etc.)
  final String messageType;

  /// Associated SOS session ID (if applicable)
  final String? sosId;

  /// Associated help request ID (if applicable)
  final String? helpRequestId;

  /// Sender ID (SAR team member)
  final String senderId;

  /// Sender name
  final String senderName;

  /// Recipient user ID
  final String? recipientId;

  /// Recipient phone number
  final String recipientPhone;

  /// Recipient name
  final String recipientName;

  /// Communication content/description
  final String content;

  /// Priority level (low, medium, high, critical)
  final String priority;

  /// Communication status (initiated, sent, delivered, read, failed)
  final String status;

  /// Timestamp of communication
  final DateTime timestamp;

  /// Whether message has been read
  final bool isRead;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  const CommunicationLog({
    required this.id,
    required this.type,
    required this.messageType,
    this.sosId,
    this.helpRequestId,
    required this.senderId,
    required this.senderName,
    this.recipientId,
    required this.recipientPhone,
    required this.recipientName,
    required this.content,
    this.priority = 'high',
    this.status = 'initiated',
    required this.timestamp,
    this.isRead = false,
    this.metadata = const {},
  });

  factory CommunicationLog.fromJson(Map<String, dynamic> json) =>
      _$CommunicationLogFromJson(json);

  Map<String, dynamic> toJson() => _$CommunicationLogToJson(this);

  /// Create a call communication log
  factory CommunicationLog.call({
    required String recipientPhone,
    required String recipientName,
    String? sosId,
    String? helpRequestId,
    String? recipientId,
    required String senderId,
    required String senderName,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final messageId =
        'msg_${now.millisecondsSinceEpoch}_${_generateRandomId()}';

    return CommunicationLog(
      id: messageId,
      type: 'call',
      messageType: 'sarResponse',
      sosId: sosId,
      helpRequestId: helpRequestId,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientPhone: recipientPhone,
      recipientName: recipientName,
      content: 'Phone call initiated to $recipientName',
      priority: 'high',
      status: 'initiated',
      timestamp: now,
      isRead: false,
      metadata: {
        'messageSource': 'sar_mobile_app',
        'communicationType': 'voice_call',
        'initiatedBy': 'SAR Team',
        'platform': 'mobile',
        ...?metadata,
      },
    );
  }

  /// Create an SMS communication log
  factory CommunicationLog.sms({
    required String recipientPhone,
    required String recipientName,
    String? sosId,
    String? helpRequestId,
    String? recipientId,
    required String senderId,
    required String senderName,
    String? messageContent,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final messageId =
        'msg_${now.millisecondsSinceEpoch}_${_generateRandomId()}';

    return CommunicationLog(
      id: messageId,
      type: 'sms',
      messageType: 'sarResponse',
      sosId: sosId,
      helpRequestId: helpRequestId,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientPhone: recipientPhone,
      recipientName: recipientName,
      content: messageContent ?? 'SMS message initiated to $recipientName',
      priority: 'high',
      status: 'initiated',
      timestamp: now,
      isRead: false,
      metadata: {
        'messageSource': 'sar_mobile_app',
        'communicationType': 'sms',
        'initiatedBy': 'SAR Team',
        'platform': 'mobile',
        ...?metadata,
      },
    );
  }

  /// Generate random ID component
  static String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
      9,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  /// Copy with method
  CommunicationLog copyWith({
    String? id,
    String? type,
    String? messageType,
    String? sosId,
    String? helpRequestId,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientPhone,
    String? recipientName,
    String? content,
    String? priority,
    String? status,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return CommunicationLog(
      id: id ?? this.id,
      type: type ?? this.type,
      messageType: messageType ?? this.messageType,
      sosId: sosId ?? this.sosId,
      helpRequestId: helpRequestId ?? this.helpRequestId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    messageType,
    sosId,
    helpRequestId,
    senderId,
    senderName,
    recipientId,
    recipientPhone,
    recipientName,
    content,
    priority,
    status,
    timestamp,
    isRead,
    metadata,
  ];
}

/// Communication priority levels
enum CommunicationPriority { low, medium, high, critical }

/// Communication status
enum CommunicationStatus { initiated, sent, delivered, read, failed }

/// Communication types
enum CommunicationType { call, sms, email, inAppMessage }
