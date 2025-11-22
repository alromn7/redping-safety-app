import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/voice_session_controller.dart';

void main() {
  group('VoiceSessionController.classifyLocally', () {
    final c = VoiceSessionController();

    test('detects emergency keywords', () {
      final result = c.classifyLocally('Help, I had a crash');
      expect(result.type, 'emergency');
      expect(result.confidence, greaterThan(0.8));
    });

    test('detects drowsiness keywords', () {
      final result = c.classifyLocally("I'm feeling very sleepy");
      expect(result.type, 'drowsiness_report');
      expect(result.confidence, greaterThan(0.7));
    });

    test('detects hazard keywords', () {
      final result = c.classifyLocally('any hazard or alert near me?');
      expect(result.type, 'hazard_report');
      expect(result.confidence, greaterThan(0.7));
    });

    test('defaults to generic query', () {
      final result = c.classifyLocally('what is the weather');
      expect(result.type, 'generic_query');
      expect(result.confidence, greaterThan(0.5));
    });
  });
}
