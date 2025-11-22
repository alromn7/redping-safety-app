import 'package:equatable/equatable.dart';

/// Group activity type enum
enum GroupActivityType {
  hiking,
  cycling,
  waterSports,
  skiing,
  climbing,
  teamSports,
  camping,
}

/// Group member data model
class GroupMember extends Equatable {
  const GroupMember({
    required this.memberId,
    required this.memberName,
    required this.role,
    required this.joinedAt,
    this.email,
    this.phone,
    this.buddyId,
    this.isOnline = true,
    this.lastCheckIn,
    this.latitude,
    this.longitude,
    this.batteryLevel,
    this.speed,
  });

  final String memberId;
  final String memberName;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final String? email;
  final String? phone;
  final String? buddyId; // Buddy system pairing
  final bool isOnline;
  final DateTime? lastCheckIn;
  final double? latitude;
  final double? longitude;
  final int? batteryLevel;
  final double? speed; // m/s

  /// Create from JSON
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      role: GroupMemberRole.values.byName(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      buddyId: json['buddyId'] as String?,
      isOnline: json['isOnline'] as bool? ?? true,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      batteryLevel: json['batteryLevel'] as int?,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'email': email,
      'phone': phone,
      'buddyId': buddyId,
      'isOnline': isOnline,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'batteryLevel': batteryLevel,
      'speed': speed,
    };
  }

  /// Create a copy with updated fields
  GroupMember copyWith({
    String? memberId,
    String? memberName,
    GroupMemberRole? role,
    DateTime? joinedAt,
    String? email,
    String? phone,
    String? buddyId,
    bool? isOnline,
    DateTime? lastCheckIn,
    double? latitude,
    double? longitude,
    int? batteryLevel,
    double? speed,
  }) {
    return GroupMember(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      buddyId: buddyId ?? this.buddyId,
      isOnline: isOnline ?? this.isOnline,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      speed: speed ?? this.speed,
    );
  }

  /// Check if member has checked in recently (within 30 min)
  bool get hasRecentCheckIn {
    if (lastCheckIn == null) return false;
    final now = DateTime.now();
    return now.difference(lastCheckIn!).inMinutes < 30;
  }

  /// Get time since last check-in
  String get checkInStatus {
    if (lastCheckIn == null) return 'Never';
    final diff = DateTime.now().difference(lastCheckIn!);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  @override
  List<Object?> get props => [
    memberId,
    memberName,
    role,
    joinedAt,
    email,
    phone,
    buddyId,
    isOnline,
    lastCheckIn,
    latitude,
    longitude,
    batteryLevel,
    speed,
  ];
}

/// Group member role
enum GroupMemberRole { leader, coLeader, member }

/// Rally point data model
class RallyPoint extends Equatable {
  const RallyPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.type,
    this.checkInRequired = false,
    this.checkedInMembers = const [],
    this.scheduledTime,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String createdBy;
  final DateTime createdAt;
  final String? description;
  final RallyPointType? type;
  final bool checkInRequired;
  final List<String> checkedInMembers; // Member IDs
  final DateTime? scheduledTime;
  final bool isActive;

  /// Create from JSON
  factory RallyPoint.fromJson(Map<String, dynamic> json) {
    return RallyPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      type: json['type'] != null
          ? RallyPointType.values.byName(json['type'] as String)
          : null,
      checkInRequired: json['checkInRequired'] as bool? ?? false,
      checkedInMembers:
          (json['checkedInMembers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'type': type?.name,
      'checkInRequired': checkInRequired,
      'checkedInMembers': checkedInMembers,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  RallyPoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? createdBy,
    DateTime? createdAt,
    String? description,
    RallyPointType? type,
    bool? checkInRequired,
    List<String>? checkedInMembers,
    DateTime? scheduledTime,
    bool? isActive,
  }) {
    return RallyPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      type: type ?? this.type,
      checkInRequired: checkInRequired ?? this.checkInRequired,
      checkedInMembers: checkedInMembers ?? this.checkedInMembers,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get check-in percentage
  double getCheckInPercentage(int totalMembers) {
    if (totalMembers == 0) return 0.0;
    return (checkedInMembers.length / totalMembers) * 100;
  }

  /// Get formatted radius
  String get radiusFormatted {
    if (radiusMeters < 1000) {
      return '${radiusMeters.toStringAsFixed(0)}m';
    } else {
      return '${(radiusMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Check if rally point is overdue
  bool get isOverdue {
    if (scheduledTime == null) return false;
    return DateTime.now().isAfter(scheduledTime!);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    createdBy,
    createdAt,
    description,
    type,
    checkInRequired,
    checkedInMembers,
    scheduledTime,
    isActive,
  ];
}

/// Rally point type
enum RallyPointType { start, checkpoint, rest, lunch, emergency, finish }

/// Buddy pair data model
class BuddyPair extends Equatable {
  const BuddyPair({
    required this.id,
    required this.member1Id,
    required this.member2Id,
    required this.createdAt,
    this.maxSeparationMeters = 100.0,
    this.isActive = true,
  });

  final String id;
  final String member1Id;
  final String member2Id;
  final DateTime createdAt;
  final double maxSeparationMeters;
  final bool isActive;

  /// Create from JSON
  factory BuddyPair.fromJson(Map<String, dynamic> json) {
    return BuddyPair(
      id: json['id'] as String,
      member1Id: json['member1Id'] as String,
      member2Id: json['member2Id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      maxSeparationMeters: json['maxSeparationMeters'] != null
          ? (json['maxSeparationMeters'] as num).toDouble()
          : 100.0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member1Id': member1Id,
      'member2Id': member2Id,
      'createdAt': createdAt.toIso8601String(),
      'maxSeparationMeters': maxSeparationMeters,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  BuddyPair copyWith({
    String? id,
    String? member1Id,
    String? member2Id,
    DateTime? createdAt,
    double? maxSeparationMeters,
    bool? isActive,
  }) {
    return BuddyPair(
      id: id ?? this.id,
      member1Id: member1Id ?? this.member1Id,
      member2Id: member2Id ?? this.member2Id,
      createdAt: createdAt ?? this.createdAt,
      maxSeparationMeters: maxSeparationMeters ?? this.maxSeparationMeters,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if member is part of this pair
  bool hasMember(String memberId) {
    return member1Id == memberId || member2Id == memberId;
  }

  /// Get buddy of a member
  String? getBuddyOf(String memberId) {
    if (member1Id == memberId) return member2Id;
    if (member2Id == memberId) return member1Id;
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    member1Id,
    member2Id,
    createdAt,
    maxSeparationMeters,
    isActive,
  ];
}

/// Group activity session data model
class GroupActivitySession extends Equatable {
  const GroupActivitySession({
    required this.id,
    required this.groupName,
    required this.activityType,
    required this.leaderId,
    required this.startTime,
    this.endTime,
    this.description,
    this.maxMembers = 50,
    this.currentMembers = const [],
    this.rallyPoints = const [],
    this.buddyPairs = const [],
    this.isActive = true,
  });

  final String id;
  final String groupName;
  final GroupActivityType activityType;
  final String leaderId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;
  final int maxMembers;
  final List<GroupMember> currentMembers;
  final List<RallyPoint> rallyPoints;
  final List<BuddyPair> buddyPairs;
  final bool isActive;

  /// Create from JSON
  factory GroupActivitySession.fromJson(Map<String, dynamic> json) {
    return GroupActivitySession(
      id: json['id'] as String,
      groupName: json['groupName'] as String,
      activityType: GroupActivityType.values.byName(
        json['activityType'] as String,
      ),
      leaderId: json['leaderId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      description: json['description'] as String?,
      maxMembers: json['maxMembers'] as int? ?? 50,
      currentMembers:
          (json['currentMembers'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rallyPoints:
          (json['rallyPoints'] as List<dynamic>?)
              ?.map((e) => RallyPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      buddyPairs:
          (json['buddyPairs'] as List<dynamic>?)
              ?.map((e) => BuddyPair.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'activityType': activityType.name,
      'leaderId': leaderId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'description': description,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers.map((m) => m.toJson()).toList(),
      'rallyPoints': rallyPoints.map((r) => r.toJson()).toList(),
      'buddyPairs': buddyPairs.map((b) => b.toJson()).toList(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  GroupActivitySession copyWith({
    String? id,
    String? groupName,
    GroupActivityType? activityType,
    String? leaderId,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    int? maxMembers,
    List<GroupMember>? currentMembers,
    List<RallyPoint>? rallyPoints,
    List<BuddyPair>? buddyPairs,
    bool? isActive,
  }) {
    return GroupActivitySession(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      activityType: activityType ?? this.activityType,
      leaderId: leaderId ?? this.leaderId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      rallyPoints: rallyPoints ?? this.rallyPoints,
      buddyPairs: buddyPairs ?? this.buddyPairs,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Get online members count
  int get onlineMembersCount {
    return currentMembers.where((m) => m.isOnline).length;
  }

  /// Get checked-in members count
  int get checkedInMembersCount {
    return currentMembers.where((m) => m.hasRecentCheckIn).length;
  }

  /// Check if session has available slots
  bool get hasAvailableSlots {
    return currentMembers.length < maxMembers;
  }

  @override
  List<Object?> get props => [
    id,
    groupName,
    activityType,
    leaderId,
    startTime,
    endTime,
    description,
    maxMembers,
    currentMembers,
    rallyPoints,
    buddyPairs,
    isActive,
  ];
}
