import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/messaging_initializer.dart';
import 'package:redping_14v/models/messaging/message_packet.dart';
import '../test_utils/test_environment.dart';

/// Comprehensive Messaging System Test (All Phases)
/// Tests the complete messaging stack through MessagingInitializer
void main() {
  group('Complete Messaging System Tests', () {
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

    test('✅ Phase 1: System initializes all components', () async {
      expect(messaging.isInitialized, isTrue);

      final stats = await messaging.getStatistics();

      print('\n📊 Phase 1: Initialization Status');
      print('   Engine initialized: ${stats['engine']['currentDeviceId'] != null}');
      print('   Transport initialized: ${stats['transport']['initialized']}');
      print('   Sync status: ${stats['sync']}');

      expect(stats['engine'], isNotNull);
      expect(stats['transport'], isNotNull);
      expect(stats['sync'], isNotNull);
    });

    test('✅ Phase 2: Send encrypted message', () async {
      final conversationId =
          'test_conv_${DateTime.now().millisecondsSinceEpoch}';

      final packet = await messaging.engine.sendMessage(
        conversationId: conversationId,
        content: 'Test message for Phase 2',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: ['recipient_001'],
      );

      print('\n📊 Phase 2: Message Encryption');
      print('   Message ID: ${packet.messageId}');
      print('   Encrypted: ${packet.encryptedPayload.isNotEmpty}');
      print('   Signed: ${packet.signature.isNotEmpty}');
      print('   Status: ${packet.status}');

      expect(packet, isNotNull);
      expect(packet.messageId, isNotEmpty);
      expect(packet.encryptedPayload, isNotEmpty);
      expect(packet.signature, isNotEmpty);
    });

    test('✅ Phase 3: Message deduplication prevents duplicates', () async {
      final messageId = 'dedup_test_${DateTime.now().millisecondsSinceEpoch}';

      // First check
      final firstCheck = await messaging.engine.isMessageProcessed(messageId);
      expect(
        firstCheck,
        isFalse,
        reason: 'Message should not be processed yet',
      );

      // Mark as processed
      await messaging.engine.markMessageProcessed(messageId);

      // Second check
      final secondCheck = await messaging.engine.isMessageProcessed(messageId);
      expect(
        secondCheck,
        isTrue,
        reason: 'Message should be marked as processed',
      );

      print('\n📊 Phase 3: Deduplication');
        final preview = messageId.length > 30
          ? '${messageId.substring(0, 30)}...'
          : messageId;
        print('   Message ID: $preview');
      print('   First check (new): $firstCheck');
      print('   Second check (processed): $secondCheck');
      print('   ✅ Infinite loop prevention working');
    });

    test('✅ Phase 4: Transport and queue operations', () async {
      // Send multiple messages
      for (int i = 0; i < 5; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'queue_conv',
          content: 'Queue test message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final queueCount = await messaging.transportManager.getOutboxCount();

      print('\n📊 Phase 4: Transport & Queue');
      print('   Messages queued: $queueCount');
      print('   ✅ Offline queue operational');

      expect(queueCount, greaterThanOrEqualTo(5));
    });

    test('✅ Phase 5: Manual sync operation', () async {
      print('\n📊 Phase 5: Manual Sync');
      print('   Starting manual sync...');

      await messaging.manualSync();

      print('   ✅ Sync completed successfully');
    });

    test('✅ Phase 6: Emergency priority message', () async {
      final packet = await messaging.engine.sendMessage(
        conversationId: 'emergency_conv',
        content: 'EMERGENCY! Need immediate help!',
        type: MessageType.sos,
        priority: MessagePriority.emergency,
        recipients: ['emergency_responder'],
      );

      print('\n📊 Phase 6: Emergency Messaging');
      print('   Priority: ${packet.priority}');
      print('   Type: ${packet.type}');
      print('   ✅ High-priority message handling working');

      expect(packet.priority, equals(MessagePriority.emergency.name));
      expect(packet.type, equals(MessageType.sos.name));
    });

    test('✅ Phase 7: Multiple recipients', () async {
      final recipients = ['user1', 'user2', 'user3', 'user4', 'user5'];

      final packet = await messaging.engine.sendMessage(
        conversationId: 'multi_conv',
        content: 'Message to multiple recipients',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: recipients,
      );

      print('\n📊 Phase 7: Multiple Recipients');
      print('   Recipients: ${packet.recipients.length}');
      print('   Names: ${packet.recipients.take(3).join(', ')}...');
      print('   ✅ Multi-recipient messaging working');

      expect(packet.recipients, hasLength(5));
      expect(packet.recipients, containsAll(recipients));
    });

    test('✅ Phase 8: Performance - Send 50 messages', () async {
      print('\n📊 Phase 8: Performance Test');
      print('   Sending 50 encrypted messages...');

      final startTime = DateTime.now();

      for (int i = 0; i < 50; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'perf_conv',
          content: 'Performance test message $i with some content to encrypt',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 50;

      print('   Total time: ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per message');

      if (avgTime < 100) {
        print('   ✅ EXCELLENT: Under 100ms per message');
      } else if (avgTime < 200) {
        print('   ✅ GOOD: Under 200ms per message');
      } else {
        print('   ⚠️  SLOW: Over 200ms per message');
      }

      expect(
        avgTime,
        lessThan(300),
        reason: 'Performance should be reasonable',
      );
    });

    test('✅ Phase 9: Performance - Deduplication checks', () async {
      print('\n📊 Phase 9: Deduplication Performance');
      print('   Checking 500 message IDs...');

      final startTime = DateTime.now();

      for (int i = 0; i < 500; i++) {
        await messaging.engine.isMessageProcessed('perf_dedup_$i');
      }

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 500;

      print('   Total time: ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per check');

      if (avgTime < 5) {
        print('   ✅ EXCELLENT: Under 5ms per check');
      } else if (avgTime < 10) {
        print('   ✅ GOOD: Under 10ms per check');
      } else {
        print('   ⚠️  SLOW: Over 10ms per check');
      }

      expect(avgTime, lessThan(20), reason: 'Deduplication should be fast');
    });

    test('✅ Phase 10: System statistics and health check', () async {
      // Send some messages first
      for (int i = 0; i < 3; i++) {
        await messaging.engine.sendMessage(
          conversationId: 'health_conv',
          content: 'Health check message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }

      final stats = await messaging.getStatistics();

      print('\n📊 Phase 10: Final System Health Check');
      print('   Transport initialized: ${stats['transport']['initialized']}');
      print('   Outbox count: ${stats['transport']['outboxCount']}');
      print('   Pending messages: ${stats['engine']['pendingMessages']}');

      expect(stats['engine'], isNotNull);
      expect(stats['transport'], isNotNull);
    });
  });
}
