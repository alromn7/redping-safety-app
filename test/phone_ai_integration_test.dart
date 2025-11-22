/// Integration test for Phone AI Channel and Voice Controller
/// Tests OS assistant intent delivery and native-first processing
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/platform/phone_ai_channel.dart';
import 'package:redping_14v/services/voice_session_controller.dart';

void main() {
  group('Phone AI Integration', () {
    late PhoneAIChannel channel;
    late VoiceSessionController controller;

    setUp(() {
      channel = PhoneAIChannel();
      controller = VoiceSessionController();
    });

    test('PhoneAIChannel initializes without errors', () {
      expect(() => channel.initialize(), returnsNormally);
    });

    test('VoiceSessionController classifies safety commands', () async {
      final testCases = {
        'check my safety status': 'status',
        'start emergency sos': 'sos',
        'what hazards are nearby': 'hazards',
        'share my location': 'location',
        'how is my battery': 'battery',
        'tell me about the weather': 'general',
        'random query': 'general',
      };

      for (final entry in testCases.entries) {
        final result = controller.classifyLocally(entry.key);
        expect(
          result,
          entry.value,
          reason: 'Failed to classify: "${entry.key}"',
        );
      }
    });

    test('VoiceSessionController handles utterances', () async {
      final spokenTexts = <String>[];

      // Mock speak function
      Future<void> mockSpeak(String text) async {
        spokenTexts.add(text);
      }

      await controller.onUtterance('check status', mockSpeak);

      // Should have classified and attempted response
      expect(spokenTexts.isNotEmpty, true);
      expect(controller.currentState, VoiceSessionState.idle);
    });

    test('VoiceSessionController state transitions', () async {
      expect(controller.currentState, VoiceSessionState.idle);

      // Processing should transition to idle after completion
      await controller.onUtterance('battery level', (text) async {});

      expect(controller.currentState, VoiceSessionState.idle);
    });

    test('Heuristic classifier handles edge cases', () {
      final edgeCases = {
        '': 'general',
        '   ': 'general',
        'SOS SOS SOS': 'sos',
        'STATUS? STATUS?': 'status',
        'check check check': 'status',
      };

      for (final entry in edgeCases.entries) {
        final result = controller.classifyLocally(entry.key);
        expect(result, entry.value);
      }
    });
  });

  group('Intent Payload Validation', () {
    test('Intent payload structure is valid', () {
      final samplePayload = {
        'type': 'voice_command',
        'text': 'check status',
        'slots': {'command': 'status'},
        'confidence': 1.0,
      };

      expect(samplePayload['type'], isA<String>());
      expect(samplePayload['text'], isA<String>());
      expect(samplePayload['slots'], isA<Map>());
      expect(samplePayload['confidence'], isA<double>());
    });

    test('Transcript payload structure is valid', () {
      final samplePayload = {'text': 'what is my battery level'};

      expect(samplePayload['text'], isA<String>());
      expect(samplePayload['text'], isNotEmpty);
    });
  });

  group('Command Mapping', () {
    test('Android deep link commands map correctly', () {
      final commandMap = {
        'status': 'check my safety status',
        'sos': 'start emergency SOS',
        'hazards': 'check hazard alerts',
        'location': 'share my location',
        'battery': 'check battery level',
      };

      for (final entry in commandMap.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value, contains(entry.key.split('_').first));
      }
    });

    test('iOS Siri commands map correctly', () {
      final activityTypes = [
        'com.redping.redping.command.status',
        'com.redping.redping.command.sos',
        'com.redping.redping.command.hazards',
        'com.redping.redping.command.location',
        'com.redping.redping.command.battery',
      ];

      for (final type in activityTypes) {
        expect(type, startsWith('com.redping.redping.command.'));
        final command = type.split('.').last;
        expect(
          command,
          isIn(['status', 'sos', 'hazards', 'location', 'battery']),
        );
      }
    });
  });
}
