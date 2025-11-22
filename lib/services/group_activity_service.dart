import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_activity.dart';

/// Service for managing group activities, members, rally points, and buddy system
class GroupActivityService {
  GroupActivityService._();
  static final GroupActivityService _instance = GroupActivityService._();
  static GroupActivityService get instance => _instance;

  // Stream controllers
  final StreamController<GroupActivitySession?> _sessionController =
      StreamController<GroupActivitySession?>.broadcast();
  final StreamController<List<GroupMember>> _membersController =
      StreamController<List<GroupMember>>.broadcast();
  final StreamController<GroupAlert> _alertController =
      StreamController<GroupAlert>.broadcast();

  // Current state
  GroupActivitySession? _activeSession;
  bool _isInitialized = false;

  // Storage keys
  static const String _sessionKey = 'group_activity_session';

  // Getters
  Stream<GroupActivitySession?> get sessionStream => _sessionController.stream;
  Stream<List<GroupMember>> get membersStream => _membersController.stream;
  Stream<GroupAlert> get alertStream => _alertController.stream;
  GroupActivitySession? get activeSession => _activeSession;
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!.isActive;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('GroupActivityService: Already initialized');
      return;
    }

    try {
      await _loadSession();
      _isInitialized = true;
      debugPrint('GroupActivityService: Initialized successfully');
    } catch (e) {
      debugPrint('GroupActivityService: Initialization error - $e');
      rethrow;
    }
  }

  /// Load session from storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson != null) {
        final data = jsonDecode(sessionJson);
        _activeSession = GroupActivitySession.fromJson(data);
        _sessionController.add(_activeSession);
        _membersController.add(_activeSession!.currentMembers);
      }

      debugPrint(
        'GroupActivityService: Loaded session - ${_activeSession?.groupName ?? "None"}',
      );
    } catch (e) {
      debugPrint('GroupActivityService: Error loading session - $e');
    }
  }

  /// Save session to storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeSession != null) {
        final sessionJson = jsonEncode(_activeSession!.toJson());
        await prefs.setString(_sessionKey, sessionJson);
      } else {
        await prefs.remove(_sessionKey);
      }
    } catch (e) {
      debugPrint('GroupActivityService: Error saving session - $e');
    }
  }

  /// Create a new group activity session
  Future<GroupActivitySession> createSession({
    required String groupName,
    required GroupActivityType activityType,
    required String leaderId,
    required String leaderName,
    String? description,
    int maxMembers = 50,
  }) async {
    try {
      final leader = GroupMember(
        memberId: leaderId,
        memberName: leaderName,
        role: GroupMemberRole.leader,
        joinedAt: DateTime.now(),
      );

      final session = GroupActivitySession(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        groupName: groupName,
        activityType: activityType,
        leaderId: leaderId,
        startTime: DateTime.now(),
        description: description,
        maxMembers: maxMembers,
        currentMembers: [leader],
      );

      _activeSession = session;
      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      debugPrint('GroupActivityService: Created session "$groupName"');
      return session;
    } catch (e) {
      debugPrint('GroupActivityService: Error creating session - $e');
      rethrow;
    }
  }

  /// Add member to group
  Future<void> addMember({
    required String memberId,
    required String memberName,
    GroupMemberRole role = GroupMemberRole.member,
    String? email,
    String? phone,
  }) async {
    try {
      if (_activeSession == null) {
        throw Exception('No active session');
      }

      if (_activeSession!.currentMembers.length >= _activeSession!.maxMembers) {
        throw Exception('Group is full (max ${_activeSession!.maxMembers})');
      }

      // Check if member already exists
      final exists = _activeSession!.currentMembers.any(
        (m) => m.memberId == memberId,
      );
      if (exists) {
        throw Exception('Member already in group');
      }

      final member = GroupMember(
        memberId: memberId,
        memberName: memberName,
        role: role,
        joinedAt: DateTime.now(),
        email: email,
        phone: phone,
      );

      final updatedMembers = [..._activeSession!.currentMembers, member];
      _activeSession = _activeSession!.copyWith(currentMembers: updatedMembers);

      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      debugPrint('GroupActivityService: Added member "$memberName"');
    } catch (e) {
      debugPrint('GroupActivityService: Error adding member - $e');
      rethrow;
    }
  }

  /// Remove member from group
  Future<void> removeMember(String memberId) async {
    try {
      if (_activeSession == null) return;

      final updatedMembers = _activeSession!.currentMembers
          .where((m) => m.memberId != memberId)
          .toList();

      _activeSession = _activeSession!.copyWith(currentMembers: updatedMembers);
      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      debugPrint('GroupActivityService: Removed member $memberId');
    } catch (e) {
      debugPrint('GroupActivityService: Error removing member - $e');
    }
  }

  /// Update member location
  Future<void> updateMemberLocation({
    required String memberId,
    required double latitude,
    required double longitude,
    double? speed,
    int? batteryLevel,
  }) async {
    try {
      if (_activeSession == null) return;

      final updatedMembers = _activeSession!.currentMembers.map((m) {
        if (m.memberId == memberId) {
          return m.copyWith(
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            batteryLevel: batteryLevel,
            isOnline: true,
          );
        }
        return m;
      }).toList();

      _activeSession = _activeSession!.copyWith(currentMembers: updatedMembers);
      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      // Check rally points
      await _checkRallyPoints(memberId, latitude, longitude);

      // Check buddy separation
      await _checkBuddySeparation(memberId);
    } catch (e) {
      debugPrint('GroupActivityService: Error updating location - $e');
    }
  }

  /// Member check-in
  Future<void> memberCheckIn(String memberId) async {
    try {
      if (_activeSession == null) return;

      final updatedMembers = _activeSession!.currentMembers.map((m) {
        if (m.memberId == memberId) {
          return m.copyWith(lastCheckIn: DateTime.now());
        }
        return m;
      }).toList();

      _activeSession = _activeSession!.copyWith(currentMembers: updatedMembers);
      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      debugPrint('GroupActivityService: Member $memberId checked in');
    } catch (e) {
      debugPrint('GroupActivityService: Error checking in - $e');
    }
  }

  /// Create rally point
  Future<RallyPoint> createRallyPoint({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String createdBy,
    String? description,
    RallyPointType? type,
    bool checkInRequired = false,
    DateTime? scheduledTime,
  }) async {
    try {
      if (_activeSession == null) {
        throw Exception('No active session');
      }

      final rallyPoint = RallyPoint(
        id: 'rally_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        description: description,
        type: type,
        checkInRequired: checkInRequired,
        scheduledTime: scheduledTime,
      );

      final updatedRallyPoints = [..._activeSession!.rallyPoints, rallyPoint];
      _activeSession = _activeSession!.copyWith(
        rallyPoints: updatedRallyPoints,
      );

      _sessionController.add(_activeSession);
      await _saveSession();

      debugPrint('GroupActivityService: Created rally point "$name"');
      return rallyPoint;
    } catch (e) {
      debugPrint('GroupActivityService: Error creating rally point - $e');
      rethrow;
    }
  }

  /// Check into rally point
  Future<void> checkIntoRallyPoint({
    required String rallyPointId,
    required String memberId,
  }) async {
    try {
      if (_activeSession == null) return;

      final updatedRallyPoints = _activeSession!.rallyPoints.map((r) {
        if (r.id == rallyPointId) {
          final checkedIn = [...r.checkedInMembers];
          if (!checkedIn.contains(memberId)) {
            checkedIn.add(memberId);
          }
          return r.copyWith(checkedInMembers: checkedIn);
        }
        return r;
      }).toList();

      _activeSession = _activeSession!.copyWith(
        rallyPoints: updatedRallyPoints,
      );
      _sessionController.add(_activeSession);
      await _saveSession();

      final rallyPoint = updatedRallyPoints.firstWhere(
        (r) => r.id == rallyPointId,
      );
      _triggerAlert(
        type: GroupAlertType.rallyPointCheckIn,
        message: 'Member checked into ${rallyPoint.name}',
        memberId: memberId,
      );

      debugPrint(
        'GroupActivityService: Member $memberId checked into rally point',
      );
    } catch (e) {
      debugPrint('GroupActivityService: Error checking into rally point - $e');
    }
  }

  /// Create buddy pair
  Future<BuddyPair> createBuddyPair({
    required String member1Id,
    required String member2Id,
    double maxSeparationMeters = 100.0,
  }) async {
    try {
      if (_activeSession == null) {
        throw Exception('No active session');
      }

      // Check if either member already has a buddy
      final existingPair = _activeSession!.buddyPairs.firstWhere(
        (p) => p.hasMember(member1Id) || p.hasMember(member2Id),
        orElse: () => BuddyPair(
          id: '',
          member1Id: '',
          member2Id: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingPair.id.isNotEmpty) {
        throw Exception('One or both members already have a buddy');
      }

      final pair = BuddyPair(
        id: 'buddy_${DateTime.now().millisecondsSinceEpoch}',
        member1Id: member1Id,
        member2Id: member2Id,
        createdAt: DateTime.now(),
        maxSeparationMeters: maxSeparationMeters,
      );

      final updatedPairs = [..._activeSession!.buddyPairs, pair];

      // Update members with buddy IDs
      final updatedMembers = _activeSession!.currentMembers.map((m) {
        if (m.memberId == member1Id) {
          return m.copyWith(buddyId: member2Id);
        } else if (m.memberId == member2Id) {
          return m.copyWith(buddyId: member1Id);
        }
        return m;
      }).toList();

      _activeSession = _activeSession!.copyWith(
        buddyPairs: updatedPairs,
        currentMembers: updatedMembers,
      );

      _sessionController.add(_activeSession);
      _membersController.add(_activeSession!.currentMembers);
      await _saveSession();

      debugPrint('GroupActivityService: Created buddy pair');
      return pair;
    } catch (e) {
      debugPrint('GroupActivityService: Error creating buddy pair - $e');
      rethrow;
    }
  }

  /// Check rally points for member
  Future<void> _checkRallyPoints(
    String memberId,
    double lat,
    double lon,
  ) async {
    if (_activeSession == null) return;

    for (final rallyPoint in _activeSession!.rallyPoints) {
      if (!rallyPoint.isActive) continue;

      final distance = _calculateDistance(
        lat,
        lon,
        rallyPoint.latitude,
        rallyPoint.longitude,
      );

      if (distance <= rallyPoint.radiusMeters) {
        // Auto check-in if not already checked in
        if (!rallyPoint.checkedInMembers.contains(memberId)) {
          await checkIntoRallyPoint(
            rallyPointId: rallyPoint.id,
            memberId: memberId,
          );
        }
      }
    }
  }

  /// Check buddy separation
  Future<void> _checkBuddySeparation(String memberId) async {
    if (_activeSession == null) return;

    final member = _activeSession!.currentMembers.firstWhere(
      (m) => m.memberId == memberId,
      orElse: () => GroupMember(
        memberId: '',
        memberName: '',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
      ),
    );

    if (member.buddyId == null || member.latitude == null) return;

    final buddy = _activeSession!.currentMembers.firstWhere(
      (m) => m.memberId == member.buddyId,
      orElse: () => GroupMember(
        memberId: '',
        memberName: '',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
      ),
    );

    if (buddy.latitude == null) return;

    final pair = _activeSession!.buddyPairs.firstWhere(
      (p) => p.hasMember(memberId),
      orElse: () => BuddyPair(
        id: '',
        member1Id: '',
        member2Id: '',
        createdAt: DateTime.now(),
      ),
    );

    if (pair.id.isEmpty) return;

    final distance = _calculateDistance(
      member.latitude!,
      member.longitude!,
      buddy.latitude!,
      buddy.longitude!,
    );

    if (distance > pair.maxSeparationMeters) {
      _triggerAlert(
        type: GroupAlertType.buddySeparation,
        message:
            '${member.memberName} and ${buddy.memberName} separated by ${distance.toStringAsFixed(0)}m',
        memberId: memberId,
        data: {'distance': distance, 'maxSeparation': pair.maxSeparationMeters},
      );
    }
  }

  /// Trigger alert
  void _triggerAlert({
    required GroupAlertType type,
    required String message,
    String? memberId,
    Map<String, dynamic>? data,
  }) {
    final alert = GroupAlert(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      memberId: memberId,
      data: data,
    );

    _alertController.add(alert);
    debugPrint('GroupActivityService: ${type.name.toUpperCase()} - $message');
  }

  /// Calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// End session
  Future<void> endSession() async {
    try {
      if (_activeSession == null) return;

      _activeSession = _activeSession!.copyWith(
        endTime: DateTime.now(),
        isActive: false,
      );

      _sessionController.add(_activeSession);
      await _saveSession();

      debugPrint('GroupActivityService: Session ended');
    } catch (e) {
      debugPrint('GroupActivityService: Error ending session - $e');
    }
  }

  /// Clear session
  Future<void> clearSession() async {
    try {
      _activeSession = null;
      _sessionController.add(null);
      _membersController.add([]);
      await _saveSession();

      debugPrint('GroupActivityService: Session cleared');
    } catch (e) {
      debugPrint('GroupActivityService: Error clearing session - $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _sessionController.close();
    _membersController.close();
    _alertController.close();
  }
}

/// Group alert type
enum GroupAlertType {
  memberJoined,
  memberLeft,
  rallyPointCheckIn,
  buddySeparation,
  lowBattery,
  memberOffline,
  emergencyAlert,
}

/// Group alert model
class GroupAlert {
  const GroupAlert({
    required this.type,
    required this.message,
    required this.timestamp,
    this.memberId,
    this.data,
  });

  final GroupAlertType type;
  final String message;
  final DateTime timestamp;
  final String? memberId;
  final Map<String, dynamic>? data;
}
