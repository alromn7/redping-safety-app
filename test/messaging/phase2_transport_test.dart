import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/messaging/transport_manager.dart';
import 'package:redping_14v/models/messaging/message_packet.dart';
import 'package:redping_14v/models/messaging/transport_type.dart';
import 'package:redping_14v/services/messaging/dtn_storage_service.dart';

import '../test_utils/test_environment.dart';

/// Phase 2: Transport Layer Tests
/// Tests Firestore transport, offline queue, auto-sync
void main() {
  group('Phase 2: Transport Layer Tests', () {
    late TransportManager transportManager;

    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() async {
      await TestEnvironment.tearDown();
    });

    setUp(() async {
      transportManager = TransportManager();
      await transportManager.initialize(userId: 'test_user');
      await DTNStorageService().deleteAllData();
    });

    test('2.1 - TransportManager initializes successfully', () {
      expect(transportManager.isInitialized, isTrue);
      print('✅ TransportManager initialized');
    });

    test('2.2 - Internet transport is registered', () {
      final transports = transportManager.getAllTransports().keys.toList();

      expect(transports, contains(TransportType.internet));

      print('✅ Internet transport registered');
      print('   Available transports: ${transports.map((t) => t.name).join(', ')}');
    });

    test('2.3 - Forced-offline packet goes to outbox', () async {
      final packet = MessagePacket(
        messageId: 'test_msg_001',
        conversationId: 'test_conv_001',
        senderId: 'test_sender',
        deviceId: 'test_device',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        encryptedPayload: 'encrypted_payload_data',
        signature: 'signature_data',
        type: MessageType.text.name,
        priority: MessagePriority.normal.name,
        preferredTransport: TransportHint.forceOffline.name,
        status: MessageStatus.queued.name,
      );

      final sent = await transportManager.sendPacketWithFallback(packet);
      expect(sent, isFalse);

      final queueCount = await transportManager.getOutboxCount();
      expect(queueCount, greaterThan(0));

      print('✅ Message queued successfully');
      print('   Queue count: $queueCount');
    });

    test('2.4 - Current transport status is accessible', () async {
      // Ensure status has a chance to reflect current outbox.
      final queueCount = await transportManager.getOutboxCount();
      final status = transportManager.currentStatus;

      expect(status.hasOutboxMessages, equals(queueCount > 0));

      print('✅ Transport status retrieved');
      print('   Has outbox: ${status.hasOutboxMessages}');
      print('   Internet available flag: ${status.internet}');
      print('   Active transport: ${status.activeTransport?.name}');
    });

    test('2.5 - Multiple forced-offline messages increase outbox count', () async {
      for (int i = 0; i < 10; i++) {
        final msg = MessagePacket(
          messageId: 'test_msg_${i}_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: 'test_conv_001',
          senderId: 'test_sender',
          deviceId: 'test_device',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          encryptedPayload: 'encrypted_payload_$i',
          signature: 'signature_$i',
          type: MessageType.text.name,
          priority: MessagePriority.normal.name,
          preferredTransport: TransportHint.forceOffline.name,
          status: MessageStatus.queued.name,
        );
        await transportManager.sendPacketWithFallback(msg);
      }

      final queueCount = await transportManager.getOutboxCount();
      expect(queueCount, greaterThanOrEqualTo(10));
      print('✅ Multiple messages queued (outbox)');
    });

    test('2.6 - Priority message handling', () async {
      final normalMsg = MessagePacket(
        messageId: 'normal_msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: 'test_conv',
        senderId: 'sender',
        deviceId: 'test_device',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        encryptedPayload: 'payload',
        signature: 'sig',
        type: MessageType.text.name,
        priority: MessagePriority.normal.name,
        preferredTransport: TransportHint.forceOffline.name,
        status: MessageStatus.queued.name,
      );

      final emergencyMsg = MessagePacket(
        messageId: 'emergency_msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: 'test_conv',
        senderId: 'sender',
        deviceId: 'test_device',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        encryptedPayload: 'payload',
        signature: 'sig',
        type: MessageType.sos.name,
        priority: MessagePriority.emergency.name,
        preferredTransport: TransportHint.forceOffline.name,
        status: MessageStatus.queued.name,
      );

      await transportManager.sendPacketWithFallback(normalMsg);
      await transportManager.sendPacketWithFallback(emergencyMsg);

      print('✅ Priority messages queued');
      print('   Normal priority: ${normalMsg.priority}');
      print('   Emergency priority: ${emergencyMsg.priority}');
    });

    test('2.7 - DTN storage outbox count reflects queued messages', () async {
      final before = await transportManager.getOutboxCount();
      final packet = MessagePacket(
        messageId: 'storage_test_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: 'test_conv',
        senderId: 'sender',
        deviceId: 'test_device',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        encryptedPayload: 'test_payload',
        signature: 'test_signature',
        type: MessageType.text.name,
        priority: MessagePriority.normal.name,
        preferredTransport: TransportHint.forceOffline.name,
        status: MessageStatus.queued.name,
      );
      await transportManager.sendPacketWithFallback(packet);
      final after = await transportManager.getOutboxCount();
      expect(after, equals(before + 1));
    });

    test('2.8 - Transport status stream', () async {
      final statusStream = transportManager.statusStream;

      expect(statusStream, isNotNull);

      bool sawUpdate = false;
      final subscription = statusStream.listen((_) {
        sawUpdate = true;
      });

      // Trigger an update by queueing a forced-offline message.
      await transportManager.sendPacketWithFallback(
        MessagePacket(
          messageId: 'stream_test_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: 'test_conv',
          senderId: 'sender',
          deviceId: 'test_device',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          encryptedPayload: 'payload',
          signature: 'sig',
          type: MessageType.text.name,
          priority: MessagePriority.normal.name,
          preferredTransport: TransportHint.forceOffline.name,
          status: MessageStatus.queued.name,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      await subscription.cancel();

      expect(sawUpdate, isTrue);
    });

    test('2.9 - Performance: Queue 100 forced-offline messages', () async {
      final startTime = DateTime.now();

      for (int i = 0; i < 100; i++) {
        final packet = MessagePacket(
          messageId: 'perf_msg_${i}_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: 'perf_conv',
          senderId: 'sender',
          deviceId: 'test_device',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          encryptedPayload: 'payload_$i',
          signature: 'sig_$i',
          type: MessageType.text.name,
          priority: MessagePriority.normal.name,
          preferredTransport: TransportHint.forceOffline.name,
          status: MessageStatus.queued.name,
        );

        await transportManager.sendPacketWithFallback(packet);
      }

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 100;

      print('✅ Performance test completed');
      print('   100 messages queued in ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per message');

      expect(
        avgTime,
        lessThan(50),
        reason: 'Queueing should be under 50ms per message',
      );
    });

    test('2.10 - Outbox count accuracy', () async {
      // Clear any existing messages
      final initialCount = await transportManager.getOutboxCount();

      // Add known number of messages
      for (int i = 0; i < 5; i++) {
        final packet = MessagePacket(
          messageId: 'count_test_${i}_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: 'count_conv',
          senderId: 'sender',
          deviceId: 'test_device',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          encryptedPayload: 'payload',
          signature: 'sig',
          type: MessageType.text.name,
          priority: MessagePriority.normal.name,
          preferredTransport: TransportHint.forceOffline.name,
          status: MessageStatus.queued.name,
        );

        await transportManager.sendPacketWithFallback(packet);
      }

      final finalCount = await transportManager.getOutboxCount();
      expect(finalCount, equals(initialCount + 5));

      print('✅ Outbox count accurate');
      print('   Initial: $initialCount');
      print('   Final: $finalCount');
      print('   Added: ${finalCount - initialCount}');
    });
  });
}
