import 'package:hive/hive.dart';

part 'message_packet.g.dart';

/// Message type classification
enum MessageType {
  text,        // Standard communication
  location,    // Coordinates, accuracy, timestamp
  sos,         // High priority emergency ping
  system,      // Delivery receipts, server notices
  key,         // Key-exchange packets for encryption
}

/// Message priority levels
enum MessagePriority {
  normal,
  high,
  emergency,   // SOS priority - attempt all transports
}

/// Message delivery status
enum MessageStatus {
  composing,      // Being typed
  queued,         // In outbox
  sending,        // Transmission in progress
  sentInternet,   // Delivered via internet
  sentMesh,       // Delivered via mesh
  sentSatellite,  // Delivered via satellite
  delivered,      // Received by recipient
  read,           // Read by recipient
  failed,         // All transports failed
  expired,        // TTL exceeded
}

/// Core message packet for multi-transport delivery
@HiveType(typeId: 1)
class MessagePacket {
  @HiveField(0)
  final String messageId;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String deviceId;

  @HiveField(4)
  final String type; // MessageType as string

  @HiveField(5)
  final String encryptedPayload; // AES-GCM encrypted

  @HiveField(6)
  final String signature; // Ed25519 signature

  @HiveField(7)
  final int timestamp;

  @HiveField(8)
  final String priority; // MessagePriority as string

  @HiveField(9)
  final String preferredTransport; // TransportHint as string

  @HiveField(10)
  final int ttl; // Time to live in seconds

  @HiveField(11)
  final int hopCount; // For mesh routing

  @HiveField(12)
  final Map<String, dynamic> metadata;

  @HiveField(13)
  final List<String> recipients;

  @HiveField(14)
  final String? status; // MessageStatus as string

  @HiveField(15)
  final String? transportUsed; // TransportType as string

  MessagePacket({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.deviceId,
    required this.type,
    required this.encryptedPayload,
    required this.signature,
    required this.timestamp,
    required this.priority,
    required this.preferredTransport,
    this.ttl = 86400, // 24 hours default
    this.hopCount = 0,
    this.metadata = const {},
    this.recipients = const [],
    this.status,
    this.transportUsed,
  });

  /// Check if message has expired
  bool get isExpired {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expiresAt = createdAt.add(Duration(seconds: ttl));
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if message can be forwarded in mesh
  bool get canForward {
    // Emergency messages have higher hop limits
    final maxHops = priority == 'emergency' ? 10 : 5;
    return hopCount < maxHops && !isExpired;
  }

  /// Create a copy with updated fields
  MessagePacket copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? deviceId,
    String? type,
    String? encryptedPayload,
    String? signature,
    int? timestamp,
    String? priority,
    String? preferredTransport,
    int? ttl,
    int? hopCount,
    Map<String, dynamic>? metadata,
    List<String>? recipients,
    String? status,
    String? transportUsed,
  }) {
    return MessagePacket(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      signature: signature ?? this.signature,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      preferredTransport: preferredTransport ?? this.preferredTransport,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      metadata: metadata ?? this.metadata,
      recipients: recipients ?? this.recipients,
      status: status ?? this.status,
      transportUsed: transportUsed ?? this.transportUsed,
    );
  }

  /// Convert to JSON for network transmission
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'deviceId': deviceId,
      'type': type,
      'encryptedPayload': encryptedPayload,
      'signature': signature,
      'timestamp': timestamp,
      'priority': priority,
      'preferredTransport': preferredTransport,
      'ttl': ttl,
      'hopCount': hopCount,
      'metadata': metadata,
      'recipients': recipients,
      'status': status,
      'transportUsed': transportUsed,
    };
  }

  /// Create from JSON
  factory MessagePacket.fromJson(Map<String, dynamic> json) {
    return MessagePacket(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      encryptedPayload: json['encryptedPayload'] as String,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      priority: json['priority'] as String,
      preferredTransport: json['preferredTransport'] as String,
      ttl: json['ttl'] as int? ?? 86400,
      hopCount: json['hopCount'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      recipients: List<String>.from(json['recipients'] ?? []),
      status: json['status'] as String?,
      transportUsed: json['transportUsed'] as String?,
    );
  }

  @override
  String toString() {
    return 'MessagePacket(id: $messageId, type: $type, priority: $priority, hops: $hopCount)';
  }
}
