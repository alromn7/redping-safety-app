import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

/// Local classification result with type & confidence for downstream logic/tests
class LocalClassificationResult {
  final String type; // e.g. emergency, drowsiness_report, hazard_report
  final double confidence; // heuristic 0.0 - 1.0
  const LocalClassificationResult(this.type, this.confidence);

  @override
  String toString() =>
      'LocalClassificationResult(type: $type, confidence: ${confidence.toStringAsFixed(2)})';
}

enum VoiceSessionState { idle, listening, processing, speaking }

class VoiceSessionController {
  VoiceSessionState _state = VoiceSessionState.idle;
  VoiceSessionState get currentState => _state;

  // Cached regex patterns for performance
  static final _statusPattern = RegExp(
    r'\b(status|check|system status)\b',
    caseSensitive: false,
  );
  static final _sosPattern = RegExp(
    r'\b(sos|emergency|help|help me|danger|crash|accident)\b',
    caseSensitive: false,
  );
  static final _hazardPattern = RegExp(
    r'\b(hazard|alert|warning|threat)\b',
    caseSensitive: false,
  );
  static final _drowsinessPattern = RegExp(
    r'\b(drowsy|sleepy|tired|fatigued|sleep)\b',
    caseSensitive: false,
  );
  static final _locationPattern = RegExp(
    r'\b(location|where|position|gps)\b',
    caseSensitive: false,
  );
  static final _batteryPattern = RegExp(
    r'\b(battery|power|charge)\b',
    caseSensitive: false,
  );

  // Debounce rapid utterances
  Timer? _debounceTimer;
  DateTime _lastProcessed = DateTime.now();
  static const _minProcessInterval = Duration(milliseconds: 800);

  void _transition(VoiceSessionState next) {
    if (_state == next) return;
    _state = next;
    debugPrint('[VOICE_SESSION] state=$_state');
  }

  Future<void> onUtterance(
    String rawText,
    Future<void> Function(String text) speak,
  ) async {
    // Debounce rapid utterances
    final now = DateTime.now();
    if (now.difference(_lastProcessed) < _minProcessInterval) {
      debugPrint('[VOICE_SESSION] Debounced (too rapid)');
      return;
    }
    _lastProcessed = now;

    _transition(VoiceSessionState.processing);

    try {
      // Cloud/LLM assistant removed: local-only classification remains.
      final allowVoice = Env.flag<bool>('enableInAppVoice', false);
      if (!allowVoice) return;

      final classification = classifyLocally(rawText);
      _transition(VoiceSessionState.speaking);
      await speak('Voice command detected: ${classification.type}.');
    } catch (e) {
      debugPrint('[VOICE_SESSION] Error: $e');
    } finally {
      _transition(VoiceSessionState.idle);
    }
  }

  LocalClassificationResult classifyLocally(String raw) {
    if (raw.trim().isEmpty) {
      return const LocalClassificationResult('generic_query', 0.0);
    }

    final text = raw.toLowerCase();

    // Priority order (critical first). Confidence heuristic based on keyword type.
    if (_sosPattern.hasMatch(text)) {
      return const LocalClassificationResult('emergency', 0.92);
    }
    if (_drowsinessPattern.hasMatch(text)) {
      return const LocalClassificationResult('drowsiness_report', 0.88);
    }
    if (_hazardPattern.hasMatch(text)) {
      return const LocalClassificationResult('hazard_report', 0.85);
    }
    if (_batteryPattern.hasMatch(text)) {
      return const LocalClassificationResult('battery_status', 0.80);
    }
    if (_locationPattern.hasMatch(text)) {
      return const LocalClassificationResult('location_query', 0.78);
    }
    if (_statusPattern.hasMatch(text)) {
      return const LocalClassificationResult('status_query', 0.75);
    }

    return const LocalClassificationResult('generic_query', 0.60);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
