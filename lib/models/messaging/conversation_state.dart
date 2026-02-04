import 'package:hive/hive.dart';

part 'conversation_state.g.dart';

/// Conversation state for synchronization and encryption
@HiveType(typeId: 3)
class ConversationState {
  @HiveField(0)
  final String conversationId;

  @HiveField(1)
  final List<String> participants; // User IDs

  @HiveField(2)
  final String? sharedSecret; // Encrypted conversation key

  @HiveField(3)
  final int lastSyncTimestamp;

  @HiveField(4)
  final Map<String, int> participantSyncMarkers; // userId -> timestamp

  @HiveField(5)
  final bool isEncrypted;

  @HiveField(6)
  final Map<String, dynamic> metadata;

  @HiveField(7)
  final String? lastMessageId;

  @HiveField(8)
  final int? keyRotationTimestamp; // When conversation key was last rotated

  ConversationState({
    required this.conversationId,
    required this.participants,
    this.sharedSecret,
    required this.lastSyncTimestamp,
    this.participantSyncMarkers = const {},
    this.isEncrypted = true,
    this.metadata = const {},
    this.lastMessageId,
    this.keyRotationTimestamp,
  });

  /// Check if conversation key needs rotation (every 30 days)
  bool get needsKeyRotation {
    if (keyRotationTimestamp == null) return true;
    final rotatedAt = DateTime.fromMillisecondsSinceEpoch(
      keyRotationTimestamp!,
    );
    final daysSinceRotation = DateTime.now().difference(rotatedAt).inDays;
    return daysSinceRotation >= 30;
  }

  /// Get sync marker for specific participant
  int? getSyncMarkerForParticipant(String userId) {
    return participantSyncMarkers[userId];
  }

  /// Update sync marker for participant
  ConversationState updateParticipantSync(String userId, int timestamp) {
    final updatedMarkers = Map<String, int>.from(participantSyncMarkers);
    updatedMarkers[userId] = timestamp;
    return copyWith(
      participantSyncMarkers: updatedMarkers,
      lastSyncTimestamp: timestamp,
    );
  }

  /// Rotate conversation key
  ConversationState rotateKey(String newSharedSecret) {
    return copyWith(
      sharedSecret: newSharedSecret,
      keyRotationTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Create a copy with updated fields
  ConversationState copyWith({
    String? conversationId,
    List<String>? participants,
    String? sharedSecret,
    int? lastSyncTimestamp,
    Map<String, int>? participantSyncMarkers,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
    String? lastMessageId,
    int? keyRotationTimestamp,
  }) {
    return ConversationState(
      conversationId: conversationId ?? this.conversationId,
      participants: participants ?? this.participants,
      sharedSecret: sharedSecret ?? this.sharedSecret,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      participantSyncMarkers:
          participantSyncMarkers ?? this.participantSyncMarkers,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      keyRotationTimestamp: keyRotationTimestamp ?? this.keyRotationTimestamp,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'participants': participants,
      'sharedSecret': sharedSecret,
      'lastSyncTimestamp': lastSyncTimestamp,
      'participantSyncMarkers': participantSyncMarkers,
      'isEncrypted': isEncrypted,
      'metadata': metadata,
      'lastMessageId': lastMessageId,
      'keyRotationTimestamp': keyRotationTimestamp,
    };
  }

  /// Create from JSON
  factory ConversationState.fromJson(Map<String, dynamic> json) {
    return ConversationState(
      conversationId: json['conversationId'] as String,
      participants: List<String>.from(json['participants'] ?? []),
      sharedSecret: json['sharedSecret'] as String?,
      lastSyncTimestamp: json['lastSyncTimestamp'] as int,
      participantSyncMarkers: Map<String, int>.from(
        json['participantSyncMarkers'] ?? {},
      ),
      isEncrypted: json['isEncrypted'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      lastMessageId: json['lastMessageId'] as String?,
      keyRotationTimestamp: json['keyRotationTimestamp'] as int?,
    );
  }

  @override
  String toString() {
    return 'ConversationState(id: $conversationId, participants: ${participants.length}, encrypted: $isEncrypted)';
  }
}
