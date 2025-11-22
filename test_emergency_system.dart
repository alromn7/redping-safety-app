/// Test script for RedPing Emergency System
/// Tests: Event Bus, WebRTC Token, SMS Service, Complete SOS Flow
///
/// Run: dart run test_emergency_system.dart
library;

import 'dart:async';

// Import services (adjust paths as needed)
// import 'lib/services/emergency_event_bus.dart';
// import 'lib/services/agora_token_service.dart';
// import 'lib/services/platform_sms_sender_service.dart';
// import 'lib/services/sms_service.dart';
// import 'lib/services/webrtc_emergency_call_service.dart';
// import 'lib/models/sos_session.dart';
// import 'lib/models/emergency_contact.dart';

void main() async {
  print('🧪 RedPing Emergency System Tests\n');
  print('═' * 50);

  await testEventBusSystem();
  await testWebRTCTokenGeneration();
  await testNativeSMSSending();
  await testCompleteSOS();

  print('\n${'═' * 50}');
  print('✅ All tests completed!');
}

/// Test 1: Event Bus System
Future<void> testEventBusSystem() async {
  print('\n📡 TEST 1: Event Bus System');
  print('─' * 50);

  try {
    // Note: Uncomment when running in Flutter environment
    /*
    final eventBus = EmergencyEventBus();
    final events = <EmergencyEvent>[];
    
    // Subscribe to all events
    final subscription = eventBus.stream.listen((event) {
      events.add(event);
      print('  📨 Event received: ${event.type}');
      print('     Session: ${event.sessionId}');
      print('     Message: ${event.message}');
    });
    
    // Fire test events
    print('\n  🔥 Firing test events...');
    
    eventBus.fireSOSActivated('test_session_1', 'manual', {
      'latitude': 40.7128,
      'longitude': -74.0060,
    });
    
    eventBus.fireWebRTCCallStarted('test_session_1', 'test_channel', 'contact_1');
    
    eventBus.fireSMSSent(
      'test_session_1',
      EmergencyEventType.smsInitialSent,
      3,
      message: 'Test SMS sent to 3 contacts',
    );
    
    eventBus.fireAIMonitoringStarted('test_session_1', 'Fall detected');
    
    // Wait for events to process
    await Future.delayed(Duration(milliseconds: 500));
    
    // Verify events
    print('\n  📊 Event Summary:');
    print('     Total events fired: ${events.length}');
    print('     Event types: ${events.map((e) => e.type).toSet().length}');
    
    // Get statistics
    final stats = eventBus.getStatistics();
    print('     Statistics: $stats');
    
    // Get session events
    final sessionEvents = eventBus.getSessionEvents('test_session_1');
    print('     Session events: ${sessionEvents.length}');
    
    subscription.cancel();
    eventBus.clearAllHistory();
    
    print('\n  ✅ Event Bus test PASSED');
    */

    print('  ⚠️  Manual verification needed in Flutter app');
    print('     1. Import emergency_event_bus.dart');
    print('     2. Subscribe to eventBus.stream');
    print('     3. Trigger SOS and watch events flow');
  } catch (e) {
    print('  ❌ Event Bus test FAILED: $e');
  }
}

/// Test 2: WebRTC Token Generation
Future<void> testWebRTCTokenGeneration() async {
  print('\n🎥 TEST 2: WebRTC Token Generation');
  print('─' * 50);

  try {
    // Note: Uncomment when running in Flutter environment
    /*
    final tokenService = AgoraTokenService();
    
    print('  🔑 Generating Agora token...');
    
    final token = await tokenService.generateToken(
      channelName: 'test_emergency_channel',
      uid: 12345,
    );
    
    if (token.isNotEmpty) {
      print('  ✅ Token generated successfully');
      print('     Length: ${token.length} chars');
      print('     Preview: ${token.substring(0, 20)}...');
    } else {
      print('  ⚠️  Empty token (development mode)');
    }
    */

    print('  📝 Manual test steps:');
    print(
      '     1. Deploy Firebase functions: cd functions && firebase deploy --only functions',
    );
    print('     2. Set Agora credentials:');
    print(
      '        firebase functions:config:set agora.app_id="a4d1ae536fb44710aa2c19d825f79ddb"',
    );
    print(
      '        firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE"',
    );
    print('     3. Test with curl:');
    print(
      '        curl -X POST https://YOUR_PROJECT.cloudfunctions.net/generateAgoraToken \\',
    );
    print('             -H "Content-Type: application/json" \\');
    print('             -d \'{"channelName":"test","uid":12345}\'');
    print('     4. Verify response contains valid token');
  } catch (e) {
    print('  ❌ Token generation test FAILED: $e');
  }
}

/// Test 3: Native SMS Sending
Future<void> testNativeSMSSending() async {
  print('\n📱 TEST 3: Native SMS Sending');
  print('─' * 50);

  try {
    // Note: Uncomment when running on Android device
    /*
    final smsSender = PlatformSMSSenderService();
    
    print('  📤 Testing SMS sending...');
    
    // Test with a safe number (use your own test number)
    const testNumber = '+1234567890'; // REPLACE WITH YOUR TEST NUMBER
    const testMessage = 'RedPing Emergency System Test - Please ignore this message';
    
    final success = await smsSender.sendSMSWithFallback(
      phoneNumber: testNumber,
      message: testMessage,
    );
    
    if (success) {
      print('  ✅ SMS sent successfully via native Android');
    } else {
      print('  ⚠️  Native SMS failed, fell back to SMS app');
    }
    */

    print('  📝 Manual test steps:');
    print('     1. Build and install app on Android device');
    print('     2. Grant SMS permission when prompted');
    print('     3. Trigger SOS (use TESTING mode to avoid real emergency)');
    print('     4. Check if SMS is sent automatically without opening SMS app');
    print('     5. Verify emergency contacts receive messages');
    print('     6. Check logs for SMS delivery status');

    print('\n  🔍 Debug commands:');
    print('     adb logcat | grep -i "sms"');
    print('     adb logcat | grep -i "emergency"');
  } catch (e) {
    print('  ❌ SMS test FAILED: $e');
  }
}

/// Test 4: Complete SOS Flow
Future<void> testCompleteSOS() async {
  print('\n🚨 TEST 4: Complete SOS Flow Integration');
  print('─' * 50);

  print('  📋 Complete emergency flow test checklist:\n');

  print('  PHASE 1: Preparation');
  print('  ─────────────────────');
  print('  [ ] Firebase functions deployed');
  print('  [ ] Agora credentials configured');
  print('  [ ] App built and installed on test device');
  print('  [ ] SMS permission granted');
  print('  [ ] Emergency contacts configured (use test numbers)');
  print('  [ ] Test mode enabled to avoid real emergency alerts\n');

  print('  PHASE 2: SOS Activation');
  print('  ───────────────────────');
  print('  [ ] Trigger SOS (manual button or test fall detection)');
  print('  [ ] Verify SOS session created in Firestore');
  print('  [ ] Check event bus fires: sosActivated');
  print('  [ ] Verify UI shows active SOS status\n');

  print('  PHASE 3: SMS Notifications');
  print('  ──────────────────────────');
  print('  [ ] Initial alert SMS sent automatically (no SMS app opened)');
  print('  [ ] Verify contacts receive Initial Alert message');
  print('  [ ] Check digital emergency card link works');
  print('  [ ] Wait 2 minutes → Follow-up SMS sent');
  print('  [ ] Wait 4 minutes → Escalation SMS sent');
  print('  [ ] Verify event bus fires: smsInitialSent, smsFollowUpSent\n');

  print('  PHASE 4: WebRTC Call (Optional)');
  print('  ────────────────────────────────');
  print('  [ ] SAR accepts emergency → WebRTC call initiated');
  print('  [ ] Token generated from Firebase function');
  print('  [ ] Agora channel joined successfully');
  print('  [ ] Audio/video streams working');
  print('  [ ] AI voice injection functional');
  print('  [ ] Event bus fires: webrtcCallStarted, webrtcCallConnected\n');

  print('  PHASE 5: AI Monitoring (Optional)');
  print('  ─────────────────────────────────');
  print('  [ ] AI monitoring starts for fall/crash victim');
  print('  [ ] Verification prompts sent');
  print('  [ ] Responsiveness detected correctly');
  print('  [ ] Event bus fires: aiMonitoringStarted, aiVerificationAttempt\n');

  print('  PHASE 6: Event Coordination');
  print('  ───────────────────────────');
  print('  [ ] All services firing events correctly');
  print('  [ ] Event history preserved per session');
  print('  [ ] Statistics tracking working');
  print('  [ ] No duplicate or missed events\n');

  print('  PHASE 7: Resolution');
  print('  ───────────────────');
  print('  [ ] Cancel SOS → Final SMS sent');
  print('  [ ] Or mark resolved → Resolved SMS sent');
  print('  [ ] All timers stopped');
  print('  [ ] Event bus fires: sosResolved or sosCancelled');
  print('  [ ] Session marked complete in Firestore\n');

  print('  📊 Expected Log Output:');
  print('  ─────────────────────────');
  print('  ✅ SMS sent automatically to +123...');
  print('  📡 Event: sosActivated | session_xyz');
  print('  📡 Event: smsInitialSent | 3 contacts');
  print('  🔑 Token generated: 00674...xyz');
  print('  📡 Event: webrtcCallStarted | channel_abc');
  print('  📡 Event: aiMonitoringStarted | Fall detected');
  print('  ✅ SOS resolved after 8 minutes\n');
}

/// Helper: Create test SOS session
/*
SOSSession createTestSession() {
  return SOSSession(
    id: 'test_session_${DateTime.now().millisecondsSinceEpoch}',
    userId: 'test_user_123',
    type: SOSType.manual,
    status: SOSStatus.active,
    startTime: DateTime.now(),
    location: LocationInfo(
      latitude: 40.7128,
      longitude: -74.0060,
      accuracy: 10.0,
      timestamp: DateTime.now(),
      address: 'Test Location, NY',
    ),
    userMessage: 'Test emergency',
    metadata: {
      'userName': 'Test User',
      'userPhone': '+1234567890',
      'batteryLevel': 85,
    },
  );
}

/// Helper: Create test emergency contacts
List<EmergencyContact> createTestContacts() {
  return [
    EmergencyContact(
      id: 'contact_1',
      name: 'Emergency Contact 1',
      phoneNumber: '+1234567891',
      type: ContactType.primary,
      priority: 1,
      relationship: 'Test Contact',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    EmergencyContact(
      id: 'contact_2',
      name: 'Emergency Contact 2',
      phoneNumber: '+1234567892',
      type: ContactType.secondary,
      priority: 2,
      relationship: 'Test Contact',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
*/
