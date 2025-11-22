import 'package:shared_preferences/shared_preferences.dart';
import '../services/group_activity_service.dart';
import '../models/group_activity.dart';

/// Test data generator for Group Activity features
/// Use this class to quickly populate the app with sample group activity data for testing
class GroupActivityTestData {
  GroupActivityTestData._();

  /// Initialize complete test group activity with members, rally points, and buddy pairs
  /// Returns the created session
  static Future<GroupActivitySession> initializeAllTestData() async {
    final service = GroupActivityService.instance;
    await service.initialize();

    // Create test session
    final session = await createTestSession();

    // Add test members
    await addTestMembers();

    // Create test rally points
    await createTestRallyPoints();

    // Create test buddy pairs
    await createTestBuddyPairs();

    // Add test location updates
    await addTestLocationUpdates();

    return session;
  }

  /// Create a test hiking session
  static Future<GroupActivitySession> createTestSession() async {
    final service = GroupActivityService.instance;

    return await service.createSession(
      groupName: 'Weekend Hike - Mt. Tamalpais',
      activityType: GroupActivityType.hiking,
      leaderId: 'leader_001',
      leaderName: 'Sarah Johnson',
      description: 'Scenic hike through Mt. Tamalpais with multiple viewpoints',
      maxMembers: 50,
    );
  }

  /// Add test members to the group
  static Future<void> addTestMembers() async {
    final service = GroupActivityService.instance;

    // Co-Leader
    await service.addMember(
      memberId: 'member_002',
      memberName: 'Mike Chen',
      role: GroupMemberRole.coLeader,
      email: 'mike.chen@email.com',
      phone: '+1-555-0102',
    );

    // Regular members
    final members = [
      {
        'id': 'member_003',
        'name': 'Emma Davis',
        'email': 'emma.d@email.com',
        'phone': '+1-555-0103',
      },
      {
        'id': 'member_004',
        'name': 'James Wilson',
        'email': 'james.w@email.com',
        'phone': '+1-555-0104',
      },
      {
        'id': 'member_005',
        'name': 'Olivia Martinez',
        'email': 'olivia.m@email.com',
        'phone': '+1-555-0105',
      },
      {
        'id': 'member_006',
        'name': 'Liam Anderson',
        'email': 'liam.a@email.com',
        'phone': '+1-555-0106',
      },
      {
        'id': 'member_007',
        'name': 'Sophia Taylor',
        'email': 'sophia.t@email.com',
        'phone': '+1-555-0107',
      },
      {
        'id': 'member_008',
        'name': 'Noah Brown',
        'email': 'noah.b@email.com',
        'phone': '+1-555-0108',
      },
    ];

    for (final member in members) {
      await service.addMember(
        memberId: member['id'] as String,
        memberName: member['name'] as String,
        role: GroupMemberRole.member,
        email: member['email'] as String,
        phone: member['phone'] as String,
      );
    }
  }

  /// Create test rally points along Mt. Tamalpais trail
  static Future<void> createTestRallyPoints() async {
    final service = GroupActivityService.instance;

    // Start Point - Parking lot
    await service.createRallyPoint(
      name: 'Trailhead Parking',
      latitude: 37.9235,
      longitude: -122.5965,
      radiusMeters: 50,
      createdBy: 'leader_001',
      description: 'Meet at the main parking lot',
      type: RallyPointType.start,
      checkInRequired: true,
      scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
    );

    // Checkpoint 1 - Vista Point
    await service.createRallyPoint(
      name: 'Mountain Vista',
      latitude: 37.9245,
      longitude: -122.5955,
      radiusMeters: 30,
      createdBy: 'leader_001',
      description: 'First viewpoint with panoramic views',
      type: RallyPointType.checkpoint,
      checkInRequired: true,
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
    );

    // Rest Stop
    await service.createRallyPoint(
      name: 'Oak Grove Rest Area',
      latitude: 37.9265,
      longitude: -122.5935,
      radiusMeters: 40,
      createdBy: 'leader_001',
      description: 'Shaded rest area with benches',
      type: RallyPointType.rest,
      checkInRequired: false,
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    );

    // Lunch Point - Summit
    await service.createRallyPoint(
      name: 'Summit Lunch Break',
      latitude: 37.9285,
      longitude: -122.5915,
      radiusMeters: 50,
      createdBy: 'leader_001',
      description: 'Summit area - 30 minute lunch break',
      type: RallyPointType.lunch,
      checkInRequired: true,
      scheduledTime: DateTime.now().add(const Duration(hours: 3)),
    );

    // Checkpoint 2 - Waterfall
    await service.createRallyPoint(
      name: 'Cascade Falls',
      latitude: 37.9265,
      longitude: -122.5895,
      radiusMeters: 35,
      createdBy: 'leader_001',
      description: 'Scenic waterfall viewpoint',
      type: RallyPointType.checkpoint,
      checkInRequired: true,
      scheduledTime: DateTime.now().add(const Duration(hours: 4, minutes: 30)),
    );

    // Finish Point
    await service.createRallyPoint(
      name: 'Trail Completion',
      latitude: 37.9235,
      longitude: -122.5965,
      radiusMeters: 50,
      createdBy: 'leader_001',
      description: 'Back at parking lot - trail complete!',
      type: RallyPointType.finish,
      checkInRequired: true,
      scheduledTime: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
    );
  }

  /// Create test buddy pairs
  static Future<void> createTestBuddyPairs() async {
    final service = GroupActivityService.instance;

    // Pair 1: Emma and James
    await service.createBuddyPair(
      member1Id: 'member_003',
      member2Id: 'member_004',
      maxSeparationMeters: 100,
    );

    // Pair 2: Olivia and Liam
    await service.createBuddyPair(
      member1Id: 'member_005',
      member2Id: 'member_006',
      maxSeparationMeters: 150,
    );

    // Pair 3: Sophia and Noah
    await service.createBuddyPair(
      member1Id: 'member_007',
      member2Id: 'member_008',
      maxSeparationMeters: 100,
    );
  }

  /// Add test location updates for members (around Mt. Tamalpais area)
  static Future<void> addTestLocationUpdates() async {
    final service = GroupActivityService.instance;

    // Leader - at trailhead
    await service.updateMemberLocation(
      memberId: 'leader_001',
      latitude: 37.9235,
      longitude: -122.5965,
      speed: 0.8, // m/s (walking)
      batteryLevel: 85,
    );
    await service.memberCheckIn('leader_001');

    // Co-Leader - nearby
    await service.updateMemberLocation(
      memberId: 'member_002',
      latitude: 37.9236,
      longitude: -122.5964,
      speed: 0.7,
      batteryLevel: 78,
    );
    await service.memberCheckIn('member_002');

    // Emma - ahead on trail
    await service.updateMemberLocation(
      memberId: 'member_003',
      latitude: 37.9240,
      longitude: -122.5960,
      speed: 1.2,
      batteryLevel: 92,
    );
    await service.memberCheckIn('member_003');

    // James - with Emma (buddy)
    await service.updateMemberLocation(
      memberId: 'member_004',
      latitude: 37.9241,
      longitude: -122.5959,
      speed: 1.3,
      batteryLevel: 65,
    );
    await service.memberCheckIn('member_004');

    // Olivia - middle of group
    await service.updateMemberLocation(
      memberId: 'member_005',
      latitude: 37.9238,
      longitude: -122.5962,
      speed: 0.9,
      batteryLevel: 45, // Low battery warning
    );
    await service.memberCheckIn('member_005');

    // Liam - with Olivia (buddy)
    await service.updateMemberLocation(
      memberId: 'member_006',
      latitude: 37.9237,
      longitude: -122.5963,
      speed: 0.8,
      batteryLevel: 88,
    );
    await service.memberCheckIn('member_006');

    // Sophia - at back of group
    await service.updateMemberLocation(
      memberId: 'member_007',
      latitude: 37.9234,
      longitude: -122.5966,
      speed: 0.6,
      batteryLevel: 55,
    );
    await service.memberCheckIn('member_007');

    // Noah - with Sophia (buddy) - no recent check-in
    await service.updateMemberLocation(
      memberId: 'member_008',
      latitude: 37.9233,
      longitude: -122.5967,
      speed: 0.5,
      batteryLevel: 42,
    );
    // Noah hasn't checked in recently - will show warning
  }

  /// Create a cycling group session
  static Future<GroupActivitySession> createCyclingSession() async {
    final service = GroupActivityService.instance;

    return await service.createSession(
      groupName: 'Bay Trail Cycling Tour',
      activityType: GroupActivityType.cycling,
      leaderId: 'cyclist_001',
      leaderName: 'Alex Rivera',
      description: 'Scenic coastal cycling route along the bay',
      maxMembers: 30,
    );
  }

  /// Create a water sports session
  static Future<GroupActivitySession> createWaterSportsSession() async {
    final service = GroupActivityService.instance;

    return await service.createSession(
      groupName: 'Kayaking Adventure',
      activityType: GroupActivityType.waterSports,
      leaderId: 'kayak_001',
      leaderName: 'Marina Costa',
      description: 'Guided kayaking tour with safety checkpoints',
      maxMembers: 20,
    );
  }

  /// Create a skiing session
  static Future<GroupActivitySession> createSkiingSession() async {
    final service = GroupActivityService.instance;

    return await service.createSession(
      groupName: 'Alpine Ski Group',
      activityType: GroupActivityType.skiing,
      leaderId: 'ski_001',
      leaderName: 'Chris Schneider',
      description: 'Intermediate slope runs with buddy system',
      maxMembers: 25,
    );
  }

  /// Clear all test data
  static Future<void> clearAllTestData() async {
    final service = GroupActivityService.instance;
    await service.clearSession();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('group_activity_session');

    print('✅ All group activity test data cleared');
  }

  /// Print current session status
  static void printSessionStatus() {
    final service = GroupActivityService.instance;
    final session = service.activeSession;

    if (session == null) {
      print('❌ No active group session');
      return;
    }

    print('\n📊 Group Activity Session Status:');
    print('   Group: ${session.groupName}');
    print('   Activity: ${session.activityType.name}');
    print('   Leader: ${session.leaderId}');
    print('   Members: ${session.currentMembers.length}/${session.maxMembers}');
    print('   Online: ${session.onlineMembersCount}');
    print('   Checked In: ${session.checkedInMembersCount}');
    print('   Rally Points: ${session.rallyPoints.length}');
    print('   Buddy Pairs: ${session.buddyPairs.length}');
    print('   Duration: ${session.duration.inMinutes} minutes');
    print('   Status: ${session.isActive ? "Active" : "Ended"}');
    print('');
  }
}
