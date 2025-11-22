#!/usr/bin/env dart

import 'dart:io';

String _flutterCmd() {
  // On Windows, prefer flutter.bat to avoid PATH resolution issues
  if (Platform.isWindows) return 'flutter.bat';
  return 'flutter';
}

/// Test runner script for comprehensive E2E testing
void main(List<String> arguments) async {
  print('🚀 REDP!NG E2E Test Runner');
  print('========================\n');

  final testType = arguments.isNotEmpty ? arguments[0] : 'all';

  switch (testType.toLowerCase()) {
    case 'sos':
      await runSOSTests();
      break;
    case 'performance':
      await runPerformanceTests();
      break;
    case 'subscription':
      await runSubscriptionTests();
      break;
    case 'all':
      await runAllTests();
      break;
    default:
      print('❌ Unknown test type: $testType');
      print('Available options: sos, performance, subscription, all');
      exit(1);
  }
}

/// Run SOS flow tests
Future<void> runSOSTests() async {
  print('📱 Running SOS Flow Tests...');
  final result = await Process.run(_flutterCmd(), [
    'test',
    'test/e2e/sos_flow_test.dart',
    '--reporter=expanded',
  ]);

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ SOS Flow Tests Passed');
  } else {
    print('❌ SOS Flow Tests Failed');
    exit(result.exitCode);
  }
}

/// Run performance tests
Future<void> runPerformanceTests() async {
  print('⚡ Running Performance Tests...');
  final result = await Process.run(_flutterCmd(), [
    'test',
    'test/e2e/performance_test.dart',
    '--reporter=expanded',
  ]);

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Performance Tests Passed');
  } else {
    print('❌ Performance Tests Failed');
    exit(result.exitCode);
  }
}

/// Run subscription tests
Future<void> runSubscriptionTests() async {
  print('💳 Running Subscription Tests...');
  final result = await Process.run(_flutterCmd(), [
    'test',
    'test/e2e/subscription_flow_test.dart',
    '--reporter=expanded',
  ]);

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Subscription Tests Passed');
  } else {
    print('❌ Subscription Tests Failed');
    exit(result.exitCode);
  }
}

/// Run all tests
Future<void> runAllTests() async {
  print('🧪 Running All E2E Tests...\n');

  final tests = [
    ('SOS Flow', runSOSTests),
    ('Performance', runPerformanceTests),
    ('Subscription', runSubscriptionTests),
  ];

  int passed = 0;
  int failed = 0;

  for (final (name, testFunction) in tests) {
    try {
      await testFunction();
      passed++;
    } catch (e) {
      print('❌ $name Tests Failed: $e');
      failed++;
    }
    print(''); // Add spacing between test suites
  }

  print('📊 Test Summary:');
  print('   ✅ Passed: $passed');
  print('   ❌ Failed: $failed');
  print('   📈 Total: ${passed + failed}');

  if (failed > 0) {
    print('\n❌ Some tests failed. Please check the output above.');
    exit(1);
  } else {
    print('\n🎉 All tests passed!');
  }
}
