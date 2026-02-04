import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/utils/activity_classifier.dart';

void main() {
  group('ActivityClassifier', () {
    test('Flying by speed >= 250 km/h', () {
      final status = ActivityClassifier.classify(300, 500);
      expect(status.mode.startsWith('Flying'), isTrue);
      expect(status.summary, 'Airplane mode detected');
    });

    test('Flying by altitude >= 2500 m when speed low/null', () {
      final status1 = ActivityClassifier.classify(null, 9000);
      expect(status1.mode.startsWith('Flying'), isTrue);
      expect(status1.summary, 'Airplane mode detected');

      final status2 = ActivityClassifier.classify(0.0, 3000);
      expect(status2.mode.startsWith('Flying'), isTrue);
      expect(status2.summary, 'Airplane mode detected');
    });

    test('Driving classification', () {
      final status = ActivityClassifier.classify(80, 200);
      expect(status.mode.contains('Driving'), isTrue);
      expect(status.summary, 'Vehicle movement');
    });

    test('Walking classification', () {
      final status = ActivityClassifier.classify(4, 50);
      expect(status.mode.contains('Walking'), isTrue);
      expect(status.summary, 'Walking detected');
    });

    test('Idle when speed < 2', () {
      final status = ActivityClassifier.classify(1.5, 100);
      expect(status.mode, 'Idle');
      expect(status.summary, isEmpty);
    });
  });
}
