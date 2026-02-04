import '../../../models/messaging/message_packet.dart';
import '../../../models/messaging/transport_type.dart';

/// Abstract interface for all transport implementations
abstract class ITransport {
  /// Transport type identifier
  TransportType get type;

  /// Check if transport is currently available
  Future<bool> isAvailable();

  /// Initialize transport (setup connections, start scanning, etc.)
  Future<void> initialize();

  /// Send a message packet via this transport
  Future<void> sendPacket(MessagePacket packet);

  /// Stream of received packets from this transport
  Stream<MessagePacket> get receivedPackets;

  /// Get current transport health/status
  Future<Map<String, dynamic>> getStatus();

  /// Cleanup and dispose resources
  Future<void> dispose();

  /// Transport priority (higher = preferred)
  int get priority;

  /// Estimated latency in milliseconds
  int get estimatedLatency;

  /// Can handle emergency messages
  bool get supportsEmergencyPriority;
}

/// Transport capabilities and metadata
class TransportCapabilities {
  final bool supportsEncryption;
  final bool supportsMultiHop;
  final bool requiresInternet;
  final int maxPacketSize; // bytes
  final int maxHopCount;
  final bool supportsGroupMessaging;

  const TransportCapabilities({
    this.supportsEncryption = true,
    this.supportsMultiHop = false,
    this.requiresInternet = true,
    this.maxPacketSize = 65536, // 64KB default
    this.maxHopCount = 1,
    this.supportsGroupMessaging = true,
  });
}

/// Transport metrics for monitoring
class TransportMetrics {
  final int messagesSent;
  final int messagesReceived;
  final int messagesFailed;
  final double averageLatency;
  final DateTime? lastUsed;
  final int bytesTransferred;

  const TransportMetrics({
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.messagesFailed = 0,
    this.averageLatency = 0.0,
    this.lastUsed,
    this.bytesTransferred = 0,
  });

  TransportMetrics copyWith({
    int? messagesSent,
    int? messagesReceived,
    int? messagesFailed,
    double? averageLatency,
    DateTime? lastUsed,
    int? bytesTransferred,
  }) {
    return TransportMetrics(
      messagesSent: messagesSent ?? this.messagesSent,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      messagesFailed: messagesFailed ?? this.messagesFailed,
      averageLatency: averageLatency ?? this.averageLatency,
      lastUsed: lastUsed ?? this.lastUsed,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
    );
  }
}
