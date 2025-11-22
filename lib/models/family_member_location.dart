import 'package:equatable/equatable.dart';

/// Family member location data model
class FamilyMemberLocation extends Equatable {
  const FamilyMemberLocation({
    required this.memberId,
    required this.memberName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.batteryLevel,
    this.isOnline = true,
    this.lastSeen,
  });

  final String memberId;
  final String memberName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed; // m/s
  final double? heading; // degrees
  final double? altitude; // meters
  final int? batteryLevel; // percentage
  final bool isOnline;
  final DateTime? lastSeen;

  /// Create from JSON
  factory FamilyMemberLocation.fromJson(Map<String, dynamic> json) {
    return FamilyMemberLocation(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null
          ? (json['heading'] as num).toDouble()
          : null,
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
      batteryLevel: json['batteryLevel'] as int?,
      isOnline: json['isOnline'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'batteryLevel': batteryLevel,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  FamilyMemberLocation copyWith({
    String? memberId,
    String? memberName,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    int? batteryLevel,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return FamilyMemberLocation(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      altitude: altitude ?? this.altitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Get formatted speed in km/h
  String get speedKmh {
    if (speed == null) return 'N/A';
    return '${(speed! * 3.6).toStringAsFixed(1)} km/h';
  }

  /// Get formatted accuracy
  String get accuracyFormatted {
    if (accuracy == null) return 'N/A';
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  /// Get formatted battery level
  String get batteryFormatted {
    if (batteryLevel == null) return 'N/A';
    return '$batteryLevel%';
  }

  /// Get time since last update
  String get timeSinceUpdate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Check if location is stale (older than 10 minutes)
  bool get isStale {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    return diff.inMinutes > 10;
  }

  @override
  List<Object?> get props => [
    memberId,
    memberName,
    latitude,
    longitude,
    timestamp,
    accuracy,
    speed,
    heading,
    altitude,
    batteryLevel,
    isOnline,
    lastSeen,
  ];
}

/// Geofence zone data model
class GeofenceZone extends Equatable {
  const GeofenceZone({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLon,
    required this.radiusMeters,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.color,
    this.alertOnEntry = false,
    this.alertOnExit = true,
    this.isActive = true,
    this.allowedMembers = const [],
  });

  final String id;
  final String name;
  final double centerLat;
  final double centerLon;
  final double radiusMeters;
  final String createdBy;
  final DateTime createdAt;
  final String? description;
  final String? color; // Hex color
  final bool alertOnEntry;
  final bool alertOnExit;
  final bool isActive;
  final List<String> allowedMembers; // Member IDs

  /// Create from JSON
  factory GeofenceZone.fromJson(Map<String, dynamic> json) {
    return GeofenceZone(
      id: json['id'] as String,
      name: json['name'] as String,
      centerLat: (json['centerLat'] as num).toDouble(),
      centerLon: (json['centerLon'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      color: json['color'] as String?,
      alertOnEntry: json['alertOnEntry'] as bool? ?? false,
      alertOnExit: json['alertOnExit'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      allowedMembers:
          (json['allowedMembers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'centerLat': centerLat,
      'centerLon': centerLon,
      'radiusMeters': radiusMeters,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'color': color,
      'alertOnEntry': alertOnEntry,
      'alertOnExit': alertOnExit,
      'isActive': isActive,
      'allowedMembers': allowedMembers,
    };
  }

  /// Create a copy with updated fields
  GeofenceZone copyWith({
    String? id,
    String? name,
    double? centerLat,
    double? centerLon,
    double? radiusMeters,
    String? createdBy,
    DateTime? createdAt,
    String? description,
    String? color,
    bool? alertOnEntry,
    bool? alertOnExit,
    bool? isActive,
    List<String>? allowedMembers,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLon: centerLon ?? this.centerLon,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      color: color ?? this.color,
      alertOnEntry: alertOnEntry ?? this.alertOnEntry,
      alertOnExit: alertOnExit ?? this.alertOnExit,
      isActive: isActive ?? this.isActive,
      allowedMembers: allowedMembers ?? this.allowedMembers,
    );
  }

  /// Get formatted radius
  String get radiusFormatted {
    if (radiusMeters < 1000) {
      return '${radiusMeters.toStringAsFixed(0)}m';
    } else {
      return '${(radiusMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    centerLat,
    centerLon,
    radiusMeters,
    createdBy,
    createdAt,
    description,
    color,
    alertOnEntry,
    alertOnExit,
    isActive,
    allowedMembers,
  ];
}

/// Family member status model
class FamilyMemberStatus extends Equatable {
  const FamilyMemberStatus({
    required this.memberId,
    required this.memberName,
    required this.isOnline,
    this.location,
    this.batteryLevel,
    this.isInSafeZone = false,
    this.activeMode,
    this.lastCheckIn,
    this.speedKmh,
  });

  final String memberId;
  final String memberName;
  final bool isOnline;
  final FamilyMemberLocation? location;
  final int? batteryLevel;
  final bool isInSafeZone;
  final String? activeMode;
  final DateTime? lastCheckIn;
  final double? speedKmh;

  /// Create from JSON
  factory FamilyMemberStatus.fromJson(Map<String, dynamic> json) {
    return FamilyMemberStatus(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      isOnline: json['isOnline'] as bool,
      location: json['location'] != null
          ? FamilyMemberLocation.fromJson(json['location'])
          : null,
      batteryLevel: json['batteryLevel'] as int?,
      isInSafeZone: json['isInSafeZone'] as bool? ?? false,
      activeMode: json['activeMode'] as String?,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
      speedKmh: json['speedKmh'] != null
          ? (json['speedKmh'] as num).toDouble()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'isOnline': isOnline,
      'location': location?.toJson(),
      'batteryLevel': batteryLevel,
      'isInSafeZone': isInSafeZone,
      'activeMode': activeMode,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'speedKmh': speedKmh,
    };
  }

  /// Create a copy with updated fields
  FamilyMemberStatus copyWith({
    String? memberId,
    String? memberName,
    bool? isOnline,
    FamilyMemberLocation? location,
    int? batteryLevel,
    bool? isInSafeZone,
    String? activeMode,
    DateTime? lastCheckIn,
    double? speedKmh,
  }) {
    return FamilyMemberStatus(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      isOnline: isOnline ?? this.isOnline,
      location: location ?? this.location,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isInSafeZone: isInSafeZone ?? this.isInSafeZone,
      activeMode: activeMode ?? this.activeMode,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    memberName,
    isOnline,
    location,
    batteryLevel,
    isInSafeZone,
    activeMode,
    lastCheckIn,
    speedKmh,
  ];
}
