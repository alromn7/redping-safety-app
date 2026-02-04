import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/messaging/message_engine.dart';
import 'package:redping_14v/models/messaging/message_packet.dart';
import 'package:redping_14v/services/messaging/dtn_storage_service.dart';

import '../test_utils/test_environment.dart';

/// Phase 3: Message Engine & Deduplication Tests
/// Tests MessageEngine, global deduplication, service integration
void main() {
  group('Phase 3: Message Engine Tests', () {
    late MessageEngine engine;

    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() async {
      await TestEnvironment.tearDown();
    });

    setUp(() async {
      engine = MessageEngine();
      // Reset singleton state for clean expectations per test.
      await engine.dispose();
      await engine.initialize(deviceId: 'test_device', userId: 'test_user');
      await DTNStorageService().deleteAllData();
    });

    tearDown(() async {
      await DTNStorageService().deleteAllData();
    });

    test('3.1 - MessageEngine initializes successfully', () {
      expect(engine, isNotNull);
      print('✅ MessageEngine initialized');
    });

    test('3.2 - Send encrypted message', () async {
      final packet = await engine.sendMessage(
        conversationId: 'test_conv_001',
        content: 'Test message content',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: ['recipient_001'],
      );
      
      expect(packet, isNotNull);
      expect(packet.messageId, isNotEmpty);
      expect(packet.encryptedPayload, isNotEmpty);
      expect(packet.signature, isNotEmpty);
      expect(packet.status, equals(MessageStatus.queued.name));
      
      print('✅ Message sent through engine');
      print('   Message ID: ${packet.messageId}');
      print('   Encrypted payload length: ${packet.encryptedPayload.length}');
      print('   Signature length: ${packet.signature.length}');
    });

    test('3.3 - Message deduplication prevents duplicates', () async {
      final messageId = 'dedup_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // First check - should be false (not processed)
      final firstCheck = await engine.isMessageProcessed(messageId);
      expect(firstCheck, isFalse);
      
      print('✅ First check: message not processed');
      
      // Mark as processed
      await engine.markMessageProcessed(messageId);
      
      // Second check - should be true (already processed)
      final secondCheck = await engine.isMessageProcessed(messageId);
      expect(secondCheck, isTrue);
      
      print('✅ Deduplication working correctly');
      print('   Message ID: $messageId');
      print('   First check: $firstCheck');
      print('   Second check: $secondCheck');
    });

    test('3.4 - Prevent infinite message loop', () async {
      final conversationId = 'loop_test_conv';
      
      // Send first message
      final packet1 = await engine.sendMessage(
        conversationId: conversationId,
        content: 'First message',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: ['recipient'],
      );
      
      print('✅ First message sent: ${packet1.messageId}');
      
      // Mark as processed to simulate the app handling it.
      await engine.markMessageProcessed(packet1.messageId);
      final wouldLoop = await engine.isMessageProcessed(packet1.messageId);
      expect(
        wouldLoop,
        isTrue,
        reason: 'Should detect duplicate and prevent loop',
      );
      
      print('✅ Infinite loop prevention verified');
    });

    test('3.5 - Multiple recipients', () async {
      final recipients = ['user1', 'user2', 'user3', 'user4', 'user5'];
      
      final packet = await engine.sendMessage(
        conversationId: 'multi_recipient_conv',
        content: 'Message to multiple recipients',
        type: MessageType.text,
        priority: MessagePriority.normal,
        recipients: recipients,
      );
      
      expect(packet.recipients, hasLength(5));
      expect(packet.recipients, containsAll(recipients));
      
      print('✅ Message sent to multiple recipients');
      print('   Recipients: ${packet.recipients.join(', ')}');
    });

    test('3.6 - Emergency priority message', () async {
      final packet = await engine.sendMessage(
        conversationId: 'emergency_conv',
        content: 'EMERGENCY! Need immediate help!',
        type: MessageType.sos,
        priority: MessagePriority.emergency,
        recipients: ['emergency_responder'],
      );
      
      expect(packet.priority, equals(MessagePriority.emergency.name));
      expect(packet.type, equals(MessageType.sos.name));
      
      print('✅ Emergency message sent');
      print('   Priority: ${packet.priority}');
      print('   Type: ${packet.type}');
    });

    test('3.7 - Message with metadata', () async {
      final metadata = {
        'location': {'lat': 40.7128, 'lng': -74.0060},
        'battery': 85,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final packet = await engine.sendMessage(
        conversationId: 'metadata_conv',
        content: 'Message with location data',
        type: MessageType.location,
        priority: MessagePriority.normal,
        recipients: ['recipient'],
        metadata: metadata,
      );
      
      expect(packet.metadata, isNotNull);
      expect(packet.metadata['location'], isNotNull);
      expect(packet.metadata['battery'], equals(85));
      
      print('✅ Message with metadata sent');
      print('   Metadata keys: ${packet.metadata.keys.join(', ')}');
    });

    test('3.8 - Bulk message deduplication check', () async {
      final messageIds = <String>[];
      
      // Generate 20 message IDs
      for (int i = 0; i < 20; i++) {
        messageIds.add('bulk_dedup_$i');
      }
      
      // Mark first 10 as processed
      for (int i = 0; i < 10; i++) {
        await engine.markMessageProcessed(messageIds[i]);
      }
      
      // Check all 20
      int processedCount = 0;
      int newCount = 0;
      
      for (final id in messageIds) {
        if (await engine.isMessageProcessed(id)) {
          processedCount++;
        } else {
          newCount++;
        }
      }
      
      expect(processedCount, equals(10));
      expect(newCount, equals(10));
      
      print('✅ Bulk deduplication check completed');
      print('   Total checked: ${messageIds.length}');
      print('   Already processed: $processedCount');
      print('   New messages: $newCount');
    });

    test('3.9 - Performance: Send 50 messages', () async {
      final startTime = DateTime.now();
      
      for (int i = 0; i < 50; i++) {
        await engine.sendMessage(
          conversationId: 'perf_conv',
          content: 'Performance test message $i',
          type: MessageType.text,
          priority: MessagePriority.normal,
          recipients: ['recipient'],
        );
      }
      
      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 50;
      
      print('✅ Performance test completed');
      print('   50 messages sent in ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per message');
      
      expect(avgTime, lessThan(100), reason: 'Should send under 100ms per message');
    });

    test('3.10 - Deduplication performance: Check 1000 IDs', () async {
      final startTime = DateTime.now();
      
      for (int i = 0; i < 1000; i++) {
        await engine.isMessageProcessed('perf_dedup_$i');
      }
      
      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 1000;
      
      print('✅ Deduplication performance test completed');
      print('   1000 checks in ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per check');
      
      expect(avgTime, lessThan(10), reason: 'Deduplication check should be under 10ms');
    });
  });
}
