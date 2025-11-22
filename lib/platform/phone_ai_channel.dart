import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// PhoneAIChannel bridges native OS assistant intents into Dart.
/// Android/iOS should call into this channel with:
/// - method: 'incoming_intent', args: { type, text, slots, confidence }
/// - method: 'transcript_final', args: { text }
class PhoneAIChannel {
  static final PhoneAIChannel _instance = PhoneAIChannel._internal();
  factory PhoneAIChannel() => _instance;
  PhoneAIChannel._internal();

  static const MethodChannel _channel = MethodChannel('phone_ai');

  bool _initialized = false;

  // Streams
  final StreamController<Map<String, dynamic>> _intentController =
      StreamController.broadcast();
  final StreamController<String> _transcriptController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get onIntent => _intentController.stream;
  Stream<String> get onTranscriptFinal => _transcriptController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'incoming_intent') {
          final Map<dynamic, dynamic> raw = call.arguments as Map;
          _intentController.add(raw.cast<String, dynamic>());
        } else if (call.method == 'transcript_final') {
          final String text = (call.arguments as Map)['text'] as String;
          _transcriptController.add(text);
        } else {
          debugPrint('PhoneAIChannel: Unknown method ${call.method}');
        }
      } catch (e) {
        debugPrint('PhoneAIChannel handler error: $e');
      }
      return null;
    });
    _initialized = true;
  }

  void dispose() {
    _intentController.close();
    _transcriptController.close();
  }
}
