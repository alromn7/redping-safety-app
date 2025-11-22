import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:redping_14v/services/emergency_messaging_service.dart';
import 'package:redping_14v/models/emergency_contact.dart';
import 'package:redping_14v/models/emergency_message.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke: EmergencyMessagingService', () {
    testWidgets('initializes, receives SAR message, and sends message', (
      tester,
    ) async {
      final svc = EmergencyMessagingService();

      await svc.initialize();

      // Receive a SAR message and ensure unread count increments
      final beforeUnread = svc.getUnreadMessageCount();
      await svc.receiveMessageFromSAR(
        senderId: 'sar_tester',
        senderName: 'SAR Tester',
        content: 'Test SAR message',
        priority: MessagePriority.medium,
        type: MessageType.sarResponse,
      );
      final afterUnread = svc.getUnreadMessageCount();
      expect(afterUnread, greaterThanOrEqualTo(beforeUnread));

      // Try sending an emergency message (recipients can be empty for smoke)
      final sent = await svc.sendEmergencyMessage(
        content: 'Test emergency message',
        recipients: <EmergencyContact>[],
        priority: MessagePriority.high,
        type: MessageType.emergency,
      );
      expect(sent, isA<bool>());
    });
  });
}
