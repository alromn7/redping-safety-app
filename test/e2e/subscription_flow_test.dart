import 'package:flutter_test/flutter_test.dart';

/// End-to-end tests for subscription and family management flows
///
/// NOTE: Subscriptions/tiered access have been removed from the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription Flow E2E Tests', () {
    testWidgets(
      'Subscriptions removed',
      (WidgetTester tester) async {},
      skip: true,
    );
  });
}
