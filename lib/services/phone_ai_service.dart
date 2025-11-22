import 'package:flutter/material.dart';

/// Phone AI Service - DISABLED
/// AI emergency calls have been removed
/// SMS notifications handle all emergency alerts
/// This is a stub to allow compilation while we clean up references

class PhoneAIService {
  static final PhoneAIService _instance = PhoneAIService._internal();
  factory PhoneAIService() => _instance;
  PhoneAIService._internal();

  bool get isInitialized => false;
  bool get isListening => false;
  bool get isSpeaking => false;
  bool get voiceCommandsEnabled => false;
  Map<String, dynamic> get permissions => {};

  Future<void> initialize({dynamic serviceManager}) async {
    // AI emergency calls disabled
  }

  void dispose() {
    // AI emergency calls disabled
  }

  Future<void> speak(String text) async {
    // AI emergency calls disabled
  }

  void startVoiceListening() {
    // AI emergency calls disabled
  }

  void stopVoiceListening() {
    // AI emergency calls disabled
  }

  Future<void> stopSpeaking() async {
    // AI emergency calls disabled
  }

  Future<bool> requestAIPermission(BuildContext context) async {
    // AI emergency calls disabled
    return false;
  }

  Future<void> listenForCommand({
    required Function(String) onResult,
    required VoidCallback onError,
  }) async {
    // AI emergency calls disabled
  }
}
