import 'package:hive/hive.dart';

part 'device_identity.g.dart';

/// Device identity with cryptographic keys
@HiveType(typeId: 2)
class DeviceIdentity {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String deviceId;

  @HiveField(2)
  final String publicKey; // X25519 public key for key exchange

  @HiveField(3)
  final String signingKey; // Ed25519 public key for signatures

  @HiveField(4)
  final int lastSeen; // Timestamp in milliseconds

  @HiveField(5)
  final List<String> availableTransports; // TransportType as strings

  @HiveField(6)
  final Map<String, dynamic> metadata;

  DeviceIdentity({
    required this.userId,
    required this.deviceId,
    required this.publicKey,
    required this.signingKey,
    required this.lastSeen,
    this.availableTransports = const [],
    this.metadata = const {},
  });

  /// Check if device is recently active (within 24 hours)
  bool get isActive {
    final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final difference = DateTime.now().difference(lastSeenDate);
    return difference.inHours < 24;
  }

  /// Update last seen timestamp
  DeviceIdentity updateLastSeen() {
    return copyWith(lastSeen: DateTime.now().millisecondsSinceEpoch);
  }

  /// Create a copy with updated fields
  DeviceIdentity copyWith({
    String? userId,
    String? deviceId,
    String? publicKey,
    String? signingKey,
    int? lastSeen,
    List<String>? availableTransports,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceIdentity(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      publicKey: publicKey ?? this.publicKey,
      signingKey: signingKey ?? this.signingKey,
      lastSeen: lastSeen ?? this.lastSeen,
      availableTransports: availableTransports ?? this.availableTransports,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'publicKey': publicKey,
      'signingKey': signingKey,
      'lastSeen': lastSeen,
      'availableTransports': availableTransports,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      publicKey: json['publicKey'] as String,
      signingKey: json['signingKey'] as String,
      lastSeen: json['lastSeen'] as int,
      availableTransports: List<String>.from(json['availableTransports'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'DeviceIdentity(userId: $userId, deviceId: $deviceId, active: $isActive)';
  }
}
