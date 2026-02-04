import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Medication notifications (dry-run)', () {
    setUp(() async {
      // Enable dry-run mode to avoid platform/plugin calls
      NotificationService.debugDryRun = true;
    });

    test(
      'schedules daily notifications and cancels by payload prefix',
      () async {
        final ns = NotificationService();

        await ns.scheduleDailyNotification(
          id: 1001,
          hour: 8,
          minute: 0,
          title: 'Medication Reminder',
          body: 'Med A 500 mg',
          payload: 'med:abc:08:00',
        );

        await ns.scheduleDailyNotification(
          id: 1002,
          hour: 20,
          minute: 0,
          title: 'Medication Reminder',
          body: 'Med A 500 mg',
          payload: 'med:abc:20:00',
        );

        final scheduled = ns.debugGetScheduled();
        expect(scheduled.length, 2);
        expect(
          scheduled.map((e) => e['payload']).toSet(),
          containsAll(<String>{'med:abc:08:00', 'med:abc:20:00'}),
        );

        // Cancel all schedules for this medication id
        await ns.cancelScheduledByPayloadPrefix('med:abc');
        final afterCancel = ns.debugGetScheduled();
        expect(
          afterCancel
              .where((e) => (e['payload'] as String).startsWith('med:abc'))
              .isEmpty,
          isTrue,
        );
      },
    );
  });
}
