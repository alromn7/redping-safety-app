// Example: How to use RedPing Adaptive Sound System

import 'package:redping_14v/services/adaptive_sound_service.dart';
import 'package:redping_14v/models/sos_session.dart';

void main() async {
  // Initialize the service (done automatically by NotificationScheduler)
  await AdaptiveSoundService.instance.initialize();

  // Example 1: Play sound for initial alert (Alert #1)
  // This will play Level 1 sound (gentle chime)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_123',
    alertNumber: 1,
    status: SOSStatus.active,
    emergencyType: SOSType.crashDetection,
  );

  // Wait 2 minutes...
  await Future.delayed(Duration(minutes: 2));

  // Example 2: Play sound for follow-up alert (Alert #2)
  // This will play Level 2 sound (moderate urgency)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_123',
    alertNumber: 2,
    status: SOSStatus.active,
    emergencyType: SOSType.crashDetection,
  );

  // Wait 2 minutes...
  await Future.delayed(Duration(minutes: 2));

  // Example 3: Play sound for escalation alert (Alert #5)
  // This will play Level 3 sound (high urgency)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_123',
    alertNumber: 5,
    status: SOSStatus.active,
    emergencyType: SOSType.crashDetection,
  );

  // Wait 2 minutes...
  await Future.delayed(Duration(minutes: 2));

  // Example 4: Play sound for critical alert (Alert #8)
  // This will play Level 4 sound (maximum urgency)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_123',
    alertNumber: 8,
    status: SOSStatus.active,
    emergencyType: SOSType.crashDetection,
  );

  // Wait 2 minutes...
  await Future.delayed(Duration(minutes: 2));

  // Example 5: Play sound for auto-escalation (Alert #10)
  // This will play Level 5 sound (continuous alarm)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_123',
    alertNumber: 10,
    status: SOSStatus.active,
    emergencyType: SOSType.crashDetection,
  );

  // Stop the continuous alarm after 30 seconds
  await Future.delayed(Duration(seconds: 30));
  await AdaptiveSoundService.instance.stopSound();

  // Example 6: Manual SOS starts at Level 3 (high urgency)
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_456',
    alertNumber: 1, // First alert
    status: SOSStatus.active,
    emergencyType: SOSType.manual, // Manual SOS
  );

  // Example 7: Acknowledged session has reduced intensity
  await AdaptiveSoundService.instance.playNotificationSound(
    sessionId: 'session_789',
    alertNumber: 5,
    status: SOSStatus.acknowledged, // SAR responding
    emergencyType: SOSType.crashDetection,
  );
  // This will play Level 3 (capped) instead of escalating higher

  // Example 8: Get sound filename for notification system
  final soundFilename = AdaptiveSoundService.instance.getSoundFilename(
    alertNumber: 3,
    status: SOSStatus.active,
    emergencyType: SOSType.fallDetection,
  );
  print('Sound file: $soundFilename'); // Output: "redping_level2"

  // Example 9: Check if sound is currently playing
  if (AdaptiveSoundService.instance.isPlaying) {
    print(
      'Sound is playing at level ${AdaptiveSoundService.instance.currentIntensityLevel}',
    );
  }

  // Example 10: Clean up when disposing
  await AdaptiveSoundService.instance.dispose();
}

// Escalation Logic Reference:
// ===========================
//
// Alert 1:        Level 1 (Initial - gentle)
// Alert 2-3:      Level 2 (Follow-up - moderate)
// Alert 4-6:      Level 3 (Escalation - high)
// Alert 7-9:      Level 4 (Critical - maximum)
// Alert 10+:      Level 5 (Auto-escalation - continuous)
//
// Special Cases:
// - Manual SOS: Starts at Level 3 (immediate high urgency)
// - Acknowledged: Capped at Level 3 (SAR responding, reduced intensity)
// - Auto-escalation (10+ alerts): Always Level 5 (continuous alarm)
//
// Sound Files Required:
// ====================
// assets/sounds/redping_level1.mp3 (gentle chime, 2-3s)
// assets/sounds/redping_level2.mp3 (two-tone, 3-4s)
// assets/sounds/redping_level3.mp3 (rising triplet, 4-5s)
// assets/sounds/redping_level4.mp3 (siren-like, 5-6s)
// assets/sounds/redping_level5.mp3 (continuous alarm, 8-10s, loops)
//
// Android raw resources (for system notifications):
// android/app/src/main/res/raw/redping_level1.mp3
// android/app/src/main/res/raw/redping_level2.mp3
// android/app/src/main/res/raw/redping_level3.mp3
// android/app/src/main/res/raw/redping_level4.mp3
// android/app/src/main/res/raw/redping_level5.mp3
//
// iOS resources (converted to AIFF):
// ios/Runner/Sounds/redping_level1.aiff
// ios/Runner/Sounds/redping_level2.aiff
// ios/Runner/Sounds/redping_level3.aiff
// ios/Runner/Sounds/redping_level4.aiff
// ios/Runner/Sounds/redping_level5.aiff
