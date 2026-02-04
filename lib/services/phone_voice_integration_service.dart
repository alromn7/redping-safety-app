// Phone Voice Integration Service - STUB VERSION (Phase 1 optimization)
// Original service disabled to remove speech_to_text and flutter_tts dependencies.
// Full service backed up in test_scripts/

import 'dart:async';
import 'package:flutter/foundation.dart';

class PhoneVoiceIntegrationService {
  static final PhoneVoiceIntegrationService _instance =
      PhoneVoiceIntegrationService._internal();
  factory PhoneVoiceIntegrationService() => _instance;
  PhoneVoiceIntegrationService._internal();

  bool _isInitialized = false;
  final bool _voiceCommandsEnabled = false;
  final bool _isListening = false;

  // Properties
  bool get isInitialized => _isInitialized;
  bool get voiceCommandsEnabled => _voiceCommandsEnabled;
  bool get isListening => _isListening;
  bool get speechEnabled => false; // Disabled
  bool get ttsEnabled => false; // Disabled
  bool get micGranted => false; // Disabled
  String get lastRecognizedWords => '';

  Future<void> initialize({dynamic serviceManager}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint(
      'PhoneVoiceIntegrationService: Speech/TTS features disabled (Phase 1 optimization)',
    );
  }

  Future<void> shutdown() async {
    _isInitialized = false;
    debugPrint('PhoneVoiceIntegrationService: Shutdown');
  }

  void enableVoiceCommands() {
    debugPrint('Voice commands disabled in Phase 1');
  }

  void disableVoiceCommands() {
    // Already disabled
  }

  void startVoiceListening() {
    debugPrint('Voice listening disabled in Phase 1');
  }

  void stopVoiceListening() {
    // Already stopped
  }

  Future<void> speak(String text) async {
    debugPrint('TTS disabled: $text');
  }

  void wake() {
    debugPrint('PhoneVoiceIntegrationService: wake (no-op)');
  }

  void hibernate() {
    debugPrint('PhoneVoiceIntegrationService: hibernate (no-op)');
  }

  // Callback setters (no-op)
  void setListeningStateCallback(void Function(bool)? callback) {}
  void setVoiceRecognizedCallback(void Function(String)? callback) {}
  void setVoiceCommandCallback(void Function(String)? callback) {}
  void setOnListeningStateChanged(void Function(bool)? callback) {}
  void setOnVoiceRecognized(void Function(String)? callback) {}
  void setOnVoiceCommand(void Function(String)? callback) {}

  // Additional stub methods for voice commands
  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    debugPrint('Voice commands disabled in Phase 1');
  }

  Map<String, List<String>> getAvailableCommands() {
    return {}; // No commands available
  }

  void dispose() {
    _isInitialized = false;
  }
}
