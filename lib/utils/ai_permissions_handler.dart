import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Handler for AI-related system permissions
class AIPermissionsHandler {
  /// Request all AI-related permissions
  static Future<AIPermissionStatus> requestAIPermissions() async {
    final results = AIPermissionStatus();

    try {
      // Microphone permission for voice commands
      final microphoneStatus = await Permission.microphone.request();
      results.microphoneGranted = microphoneStatus.isGranted;

      // Speech recognition (Android only)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final speechStatus = await Permission.speech.request();
        results.speechRecognitionGranted = speechStatus.isGranted;
      } else {
        // iOS handles speech recognition through microphone permission
        results.speechRecognitionGranted = microphoneStatus.isGranted;
      }

      // Notification permission for AI alerts (includes high-priority channels)
      final notificationStatus = await Permission.notification.request();
      results.notificationsGranted = notificationStatus.isGranted;

      // Critical alerts use high-priority notification channels
      // instead of system overlay - more privacy-friendly

      // Background audio for continuous AI monitoring
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS handles this through Info.plist UIBackgroundModes
        results.backgroundAudioGranted = true;
      } else {
        results.backgroundAudioGranted = true; // Android handles via manifest
      }

      debugPrint('AIPermissionsHandler: Permission results - $results');
    } catch (e) {
      debugPrint('AIPermissionsHandler: Error requesting permissions - $e');
    }

    return results;
  }

  /// Check if all AI permissions are granted
  static Future<bool> checkAIPermissions() async {
    try {
      final microphone = await Permission.microphone.status;
      final notification = await Permission.notification.status;

      bool speechGranted = true;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final speech = await Permission.speech.status;
        speechGranted = speech.isGranted;
      }

      return microphone.isGranted && notification.isGranted && speechGranted;
    } catch (e) {
      debugPrint('AIPermissionsHandler: Error checking permissions - $e');
      return false;
    }
  }

  /// Request specific permission
  static Future<bool> requestPermission(AIPermissionType type) async {
    try {
      Permission permission;

      switch (type) {
        case AIPermissionType.microphone:
          permission = Permission.microphone;
          break;
        case AIPermissionType.speechRecognition:
          if (defaultTargetPlatform == TargetPlatform.android) {
            permission = Permission.speech;
          } else {
            permission = Permission.microphone;
          }
          break;
        case AIPermissionType.notifications:
          permission = Permission.notification;
          break;
        default:
          return false;
      }

      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('AIPermissionsHandler: Error requesting $type - $e');
      return false;
    }
  }

  /// Open app settings for permission management
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Get user-friendly description for permission
  static String getPermissionDescription(AIPermissionType type) {
    switch (type) {
      case AIPermissionType.microphone:
        return 'Microphone access allows AI to respond to voice commands for hands-free safety assistance.';
      case AIPermissionType.speechRecognition:
        return 'Speech recognition enables the AI to understand your voice commands and respond intelligently.';
      case AIPermissionType.notifications:
        return 'Notifications allow AI to send you proactive safety alerts and emergency warnings.';
      case AIPermissionType.backgroundAudio:
        return 'Background audio enables AI to monitor for voice commands even when the screen is off.';
    }
  }
}

/// AI Permission types
enum AIPermissionType {
  microphone,
  speechRecognition,
  notifications,
  backgroundAudio,
}

/// Status of AI permissions
class AIPermissionStatus {
  bool microphoneGranted = false;
  bool speechRecognitionGranted = false;
  bool notificationsGranted = false;
  bool backgroundAudioGranted = false;

  bool get allGranted =>
      microphoneGranted && speechRecognitionGranted && notificationsGranted;

  bool get criticalGranted => microphoneGranted && notificationsGranted;

  @override
  String toString() {
    return 'AIPermissionStatus(mic: $microphoneGranted, speech: $speechRecognitionGranted, '
        'notifications: $notificationsGranted, backgroundAudio: $backgroundAudioGranted)';
  }
}
