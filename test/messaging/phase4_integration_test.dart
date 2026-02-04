import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/messaging_initializer.dart';
import 'package:redping_14v/models/messaging/message_packet.dart';

import '../test_utils/test_environment.dart';

/// Phase 4: Full System Integration Tests
/// Tests complete messaging system with all services
void main() {
  group('Phase 4: System Integration Tests', () {
    late MessagingInitializer messaging;

    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() async {
      await TestEnvironment.tearDown();
    });

    setUp(() async {
      messaging = MessagingInitializer();
      await messaging.initialize();
    });

    tearDown(() async {
      await messaging.dispose();
    });

    test('4.1 - MessagingInitializer initializes all components', () async {
      expect(messaging.isInitialized, isTrue);

      final stats = await messaging.getStatistics();
      expect(stats['engine'], isNotNull);
      expect(stats['transport'], isNotNull);
      expect(stats['sync'], isNotNull);

      print('✅ MessagingInitializer initialized');
    });

    test('4.2 - Get system statistics', () async {
      final stats = await messaging.getStatistics();

      expect(stats, isNotNull);
      expect(stats, containsPair('engine', anything));
      expect(stats, containsPair('transport', anything));
      expect(stats, containsPair('sync', anything));

      print('✅ System statistics retrieved');
      print('   Transport initialized: ${stats['transport']['initialized']}');
      print('   Outbox count: ${stats['transport']['outboxCount']}');
    });

    test(
      '4.3 - Emergency/SAR service integration (skipped in unit tests)',
      () async {},
      skip: 'Depends on platform plugins/Firebase; cover via integration tests.',
    );

    test('4.5 - Manual sync operation', () async {
      print('🔄 Starting manual sync...');

      await messaging.manualSync();

      print('✅ Manual sync completed');

      final stats = await messaging.getStatistics();
      print('   Queue after sync: ${stats['transport']['queuedMessages']}');
    });

    test('4.6 - Transport status monitoring', () async {
      final status = messaging.transportManager.currentStatus;
      expect(status, isNotNull);
      print('✅ Transport status retrieved');
      print('   Has outbox messages: ${status.hasOutboxMessages}');
      print('   Active transport: ${status.activeTransport?.name}');
    });

    test('4.7 - End-to-end message flow', () async {
      final conversationId =
          'e2e_test_${DateTime.now().millisecondsSinceEpoch}';

      // Send message through engine
      final packet = await messaging.engine.sendMessage(
        conversationId: conversationId,
        content: 'End-to-end test message',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: ['test_recipient'],
      );

      expect(packet, isNotNull);
      expect(packet.messageId, isNotEmpty);

      print('✅ End-to-end message sent');
      print('   Message ID: ${packet.messageId}');
      print('   Encrypted: ${packet.encryptedPayload.isNotEmpty}');
      print('   Signed: ${packet.signature.isNotEmpty}');

      // Verify conversation key exists
      final conversationKey = await messaging.crypto.getConversationKey(
        conversationId,
      );
      expect(conversationKey, isNotNull);

      print('✅ Conversation encrypted with key');
      print('   Key fingerprint: ${conversationKey!.substring(0, 16)}...');
    });

    test('4.8 - Offline queue handling', () async {
      // Send multiple messages
      for (int i = 0; i < 5; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'offline_conv',
          content: 'Offline test message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final queueCount = await messaging.transportManager.getOutboxCount();
      expect(queueCount, greaterThanOrEqualTo(5));

      print('✅ Messages queued for offline sending');
      print('   Queue count: $queueCount');
    });

    test('4.9 - Performance: Complete message flow', () async {
      final startTime = DateTime.now();

      for (int i = 0; i < 20; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'perf_conv',
          content: 'Performance test message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 20;

      print('✅ Performance test completed');
      print('   20 complete messages in ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per message');
      print('   (Includes encryption, signing, queueing)');

      expect(
        avgTime,
        lessThan(150),
        reason: 'Complete flow should be under 150ms',
      );
    });

    test('4.10 - System statistics after operations', () async {
      // Send some messages
      for (int i = 0; i < 3; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'stats_conv',
          content: 'Stats test message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final stats = await messaging.getStatistics();

      print('✅ Final system statistics:');
      print('   Engine stats keys: ${stats['engine'].keys}');
      print('   Transport outbox count: ${stats['transport']['outboxCount']}');
    });
  });
}
