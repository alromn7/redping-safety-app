import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../models/sos_session.dart';

/// Adaptive Sound Service for RedPing
/// Provides escalating sound intensity based on emergency severity and duration
///
/// Sound Intensity Levels:
/// Level 1 (Initial): Gentle alert - "something needs attention"
/// Level 2 (Follow-up): Moderate urgency - "this is important"
/// Level 3 (Escalation): High urgency - "respond now"
/// Level 4 (Critical): Maximum urgency - "emergency situation"
/// Level 5 (Auto-escalation): Continuous alarm - "immediate action required"
class AdaptiveSoundService {
  static final AdaptiveSoundService instance = AdaptiveSoundService._internal();
  factory AdaptiveSoundService() => instance;
  AdaptiveSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentIntensityLevel = 1;

  /// Sound intensity configurations
  static const Map<int, SoundConfig> _soundConfigs = {
    1: SoundConfig(
      filename: 'redping_level1.mp3',
      volume: 0.5,
      vibrationPattern: [0, 200, 100, 200], // Gentle double tap
      loops: 1,
      description: 'Initial Alert - Gentle notification',
    ),
    2: SoundConfig(
      filename: 'redping_level2.mp3',
      volume: 0.65,
      vibrationPattern: [0, 300, 150, 300, 150, 300], // Triple tap
      loops: 2,
      description: 'Follow-up - Moderate urgency',
    ),
    3: SoundConfig(
      filename: 'redping_level3.mp3',
      volume: 0.80,
      vibrationPattern: [0, 500, 200, 500, 200, 500, 200, 500], // Persistent
      loops: 3,
      description: 'Escalation - High urgency',
    ),
    4: SoundConfig(
      filename: 'redping_level4.mp3',
      volume: 0.95,
      vibrationPattern: [0, 800, 300, 800, 300, 800, 300, 800], // Intense
      loops: 4,
      description: 'Critical - Maximum urgency',
    ),
    5: SoundConfig(
      filename: 'redping_level5.mp3',
      volume: 1.0,
      vibrationPattern: [
        0,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        1000,
      ], // Continuous
      loops: -1, // Infinite loop until stopped
      description: 'Auto-escalation - Continuous alarm',
    ),
  };

  /// Initialize audio player
  Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      debugPrint('✅ AdaptiveSoundService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AdaptiveSoundService: $e');
    }
  }

  /// Play sound with adaptive intensity based on alert number and session status
  ///
  /// Intensity escalation rules:
  /// - Alert 1: Level 1 (Initial)
  /// - Alerts 2-3: Level 2 (Follow-up)
  /// - Alerts 4-6: Level 3 (Escalation)
  /// - Alerts 7-9: Level 4 (Critical)
  /// - Alert 10+: Level 5 (Auto-escalation)
  Future<void> playNotificationSound({
    required String sessionId,
    required int alertNumber,
    required SOSStatus status,
    SOSType? emergencyType,
  }) async {
    try {
      // Determine intensity level
      final intensityLevel = _determineIntensityLevel(
        alertNumber: alertNumber,
        status: status,
        emergencyType: emergencyType,
      );

      // Update tracking
      _currentIntensityLevel = intensityLevel;

      // Get sound configuration
      final config = _soundConfigs[intensityLevel]!;

      debugPrint(
        '🔊 Playing RedPing sound - Level $intensityLevel (${config.description})',
      );
      debugPrint(
        '   Alert #$alertNumber | Status: ${status.name} | Type: ${emergencyType?.name ?? "N/A"}',
      );

      // Play sound
      await _playSound(config);

      // Trigger vibration
      await _playVibration(config.vibrationPattern);
    } catch (e) {
      debugPrint('❌ Error playing adaptive sound: $e');
    }
  }

  /// Determine intensity level based on alert context
  int _determineIntensityLevel({
    required int alertNumber,
    required SOSStatus status,
    SOSType? emergencyType,
  }) {
    // Auto-escalation always gets max intensity (no specific auto-escalated status in enum)
    // Use high alert numbers (10+) as proxy for auto-escalation
    if (alertNumber >= 10) {
      return 5;
    }

    // Manual SOS always starts at level 3 (high urgency)
    if (emergencyType == SOSType.manual && alertNumber == 1) {
      return 3;
    }

    // Acknowledged sessions get reduced intensity
    if (status == SOSStatus.acknowledged) {
      return alertNumber <= 2 ? 2 : 3; // Max level 3 for acknowledged
    }

    // Standard escalation based on alert number
    if (alertNumber == 1) return 1; // Initial
    if (alertNumber <= 3) return 2; // Follow-up
    if (alertNumber <= 6) return 3; // Escalation
    if (alertNumber <= 9) return 4; // Critical
    return 5; // Auto-escalation threshold
  }

  /// Play sound file with configuration
  Future<void> _playSound(SoundConfig config) async {
    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Set volume
      await _audioPlayer.setVolume(config.volume);

      // Set loop mode
      if (config.loops == -1) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      }

      // Play from assets
      await _audioPlayer.play(AssetSource('sounds/${config.filename}'));

      _isPlaying = true;

      // Handle finite loops
      if (config.loops > 1) {
        for (int i = 1; i < config.loops; i++) {
          await Future.delayed(
            const Duration(milliseconds: 100),
          ); // Brief pause between loops
          if (_isPlaying) {
            await _audioPlayer.play(AssetSource('sounds/${config.filename}'));
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing sound file: $e');
      // Fallback to system notification sound
    }
  }

  /// Play vibration pattern
  Future<void> _playVibration(List<int> pattern) async {
    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      debugPrint('⚠️ Vibration not available: $e');
    }
  }

  /// Stop currently playing sound
  Future<void> stopSound() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
        debugPrint('🔇 Stopped RedPing sound');
      }
    } catch (e) {
      debugPrint('❌ Error stopping sound: $e');
    }
  }

  /// Get sound filename for notification system integration
  String getSoundFilename({
    required int alertNumber,
    required SOSStatus status,
    SOSType? emergencyType,
  }) {
    final level = _determineIntensityLevel(
      alertNumber: alertNumber,
      status: status,
      emergencyType: emergencyType,
    );
    return _soundConfigs[level]!.filename.replaceAll('.mp3', '');
  }

  /// Get current intensity level
  int get currentIntensityLevel => _currentIntensityLevel;

  /// Check if sound is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

/// Sound configuration for each intensity level
class SoundConfig {
  final String filename;
  final double volume; // 0.0 to 1.0
  final List<int> vibrationPattern; // Milliseconds pattern
  final int loops; // -1 for infinite
  final String description;

  const SoundConfig({
    required this.filename,
    required this.volume,
    required this.vibrationPattern,
    required this.loops,
    required this.description,
  });
}

/// Sound intensity level descriptions
enum SoundIntensity {
  level1, // Initial: Gentle alert
  level2, // Follow-up: Moderate urgency
  level3, // Escalation: High urgency
  level4, // Critical: Maximum urgency
  level5, // Auto-escalation: Continuous alarm
}

extension SoundIntensityExtension on SoundIntensity {
  String get description {
    switch (this) {
      case SoundIntensity.level1:
        return 'Initial Alert - Gentle notification';
      case SoundIntensity.level2:
        return 'Follow-up - Moderate urgency';
      case SoundIntensity.level3:
        return 'Escalation - High urgency';
      case SoundIntensity.level4:
        return 'Critical - Maximum urgency';
      case SoundIntensity.level5:
        return 'Auto-escalation - Continuous alarm';
    }
  }

  int get level {
    switch (this) {
      case SoundIntensity.level1:
        return 1;
      case SoundIntensity.level2:
        return 2;
      case SoundIntensity.level3:
        return 3;
      case SoundIntensity.level4:
        return 4;
      case SoundIntensity.level5:
        return 5;
    }
  }
}
