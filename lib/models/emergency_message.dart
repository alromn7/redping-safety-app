import 'package:equatable/equatable.dart';

/// Emergency message priority levels
enum MessagePriority { low, medium, high, critical }

/// Emergency message types
enum MessageType {
  emergency,
  alert,
  status,
  response,
  general,
  sarResponse,
  userResponse,
}

/// Emergency message status
enum MessageStatus { pending, sent, delivered, read, failed }

/// Emergency message model
class EmergencyMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final List<String> recipients;
  final DateTime timestamp;
  final MessagePriority priority;
  final MessageType type;
  final MessageStatus status;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const EmergencyMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.recipients,
    required this.timestamp,
    required this.priority,
    required this.type,
    required this.status,
    required this.isRead,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'recipients': recipients,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.name,
      'type': type.name,
      'status': status.name,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory EmergencyMessage.fromJson(Map<String, dynamic> json) {
    return EmergencyMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      recipients: List<String>.from(json['recipients'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: MessagePriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => MessagePriority.medium,
      ),
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.general,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      isRead: json['isRead'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  EmergencyMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    List<String>? recipients,
    DateTime? timestamp,
    MessagePriority? priority,
    MessageType? type,
    MessageStatus? status,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return EmergencyMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      recipients: recipients ?? this.recipients,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    content,
    recipients,
    timestamp,
    priority,
    type,
    status,
    isRead,
    metadata,
  ];

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case MessagePriority.low:
        return 'blue';
      case MessagePriority.medium:
        return 'orange';
      case MessagePriority.high:
        return 'red';
      case MessagePriority.critical:
        return 'dark_red';
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case MessageType.emergency:
        return 'emergency';
      case MessageType.alert:
        return 'warning';
      case MessageType.status:
        return 'info';
      case MessageType.response:
        return 'reply';
      case MessageType.general:
        return 'message';
      case MessageType.sarResponse:
        return 'sar_response';
      case MessageType.userResponse:
        return 'user_response';
    }
  }

  /// Get status text
  String get statusText {
    switch (status) {
      case MessageStatus.pending:
        return 'Pending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  /// Check if message is urgent
  bool get isUrgent =>
      priority == MessagePriority.high || priority == MessagePriority.critical;

  /// Check if message is emergency type
  bool get isEmergency => type == MessageType.emergency;

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
