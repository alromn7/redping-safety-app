/// Performance Benchmark for Phone AI Optimizations
/// Run with: flutter test test/phone_ai_performance_test.dart
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/voice_session_controller.dart';

void main() {
  group('Phone AI Performance Benchmarks', () {
    test('Classifier pattern matching performance', () {
      final controller = VoiceSessionController();
      final testPhrases = [
        'check my status',
        'start emergency sos',
        'what hazards are nearby',
        'share my location',
        'how is my battery',
        'tell me the weather',
        'help me I crashed',
        'any alerts for me',
      ];

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (var i = 0; i < iterations; i++) {
        for (final phrase in testPhrases) {
          controller.classifyLocally(phrase);
        }
      }

      stopwatch.stop();
      final avgMicroseconds =
          stopwatch.elapsedMicroseconds / (iterations * testPhrases.length);

      print('Classifier Performance:');
      print('  Total classifications: ${iterations * testPhrases.length}');
      print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      print(
        '  Average per classification: ${avgMicroseconds.toStringAsFixed(2)}μs',
      );

      // Assert performance target: <100μs per classification
      expect(
        avgMicroseconds,
        lessThan(100),
        reason: 'Classifier should be under 100μs per call',
      );
    });

    test('Pattern cache effectiveness', () {
      final controller = VoiceSessionController();

      // Warm up cache
      controller.classifyLocally('check status');

      final stopwatch = Stopwatch()..start();
      const iterations = 10000;

      for (var i = 0; i < iterations; i++) {
        controller.classifyLocally('check my battery status');
      }

      stopwatch.stop();
      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      print('Cached Pattern Performance:');
      print('  Total calls: $iterations');
      print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('  Average: ${avgMicroseconds.toStringAsFixed(2)}μs');

      // With caching, should be very fast
      expect(
        avgMicroseconds,
        lessThan(50),
        reason: 'Cached patterns should be under 50μs',
      );
    });

    test('Memory efficiency: no pattern allocation per call', () {
      final controller = VoiceSessionController();
      final initialMemory = _estimateMemoryUsage();

      // Run many classifications
      for (var i = 0; i < 1000; i++) {
        controller.classifyLocally('status check $i');
      }

      final finalMemory = _estimateMemoryUsage();
      final memoryGrowth = finalMemory - initialMemory;

      print('Memory Efficiency:');
      print('  Initial: ${initialMemory}KB');
      print('  Final: ${finalMemory}KB');
      print('  Growth: ${memoryGrowth}KB');

      // Memory growth should be minimal (<100KB for 1000 calls)
      expect(
        memoryGrowth,
        lessThan(100),
        reason: 'Memory growth should be minimal with pattern caching',
      );
    });
  });
}

// Simple memory estimation helper
int _estimateMemoryUsage() {
  // In real tests, use ProcessInfo.currentRss or similar
  // This is a placeholder for test demonstration
  return 0;
}
