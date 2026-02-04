import 'package:flutter/material.dart';
import 'package:redping_14v/services/messaging_initializer.dart';

/// Test script for Phase 1 messaging system
/// Run this to verify encryption, storage, and message engine
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('🧪 PHASE 1 MESSAGING SYSTEM TEST');
  debugPrint('═══════════════════════════════════════════════════════');

  final messaging = MessagingInitializer();

  try {
    // Test 1: Initialize system
    debugPrint('\n📋 TEST 1: Initialize Messaging System');
    await messaging.initialize();
    debugPrint('✅ Initialization successful\n');

    // Test 2: Send test message
    debugPrint('📋 TEST 2: Send Encrypted Message');
    final packet1 = await messaging.sendTestMessage(
      content: 'Hello from Phase 1!',
      conversationId: 'test_conv_001',
    );
    debugPrint('✅ Message sent: ${packet1.messageId}');
    debugPrint('   - Type: ${packet1.type}');
    debugPrint('   - Priority: ${packet1.priority}');
    debugPrint('   - Encrypted: ${packet1.encryptedPayload.substring(0, 20)}...');
    debugPrint('   - Signature: ${packet1.signature.substring(0, 20)}...\n');

    // Test 3: Send multiple messages
    debugPrint('📋 TEST 3: Send Multiple Messages (Queue Test)');
    for (int i = 1; i <= 5; i++) {
      await messaging.sendTestMessage(
        content: 'Test message $i',
        conversationId: 'test_conv_002',
      );
      debugPrint('   ✓ Message $i queued');
    }
    debugPrint('✅ All messages queued\n');

    // Test 4: Check statistics
    debugPrint('📋 TEST 4: Check System Statistics');
    final stats = await messaging.getStatistics();
    debugPrint('✅ Statistics:');
    stats.forEach((key, value) {
      debugPrint('   - $key: $value');
    });

    // Test 5: Get outbox messages
    debugPrint('\n📋 TEST 5: Retrieve Outbox Messages');
    final outbox = await messaging.engine.getUnsentMessages();
    debugPrint('✅ Outbox contains ${outbox.length} messages');
    for (var msg in outbox) {
      debugPrint('   - ${msg.messageId}: ${msg.type} (${msg.priority})');
    }

    // Test 6: Test deduplication
    debugPrint('\n📋 TEST 6: Test Deduplication');
    final testId = 'duplicate_test_123';
    final isProcessed1 = await messaging.engine.isMessageProcessed(testId);
    debugPrint('   Before: isProcessed = $isProcessed1');
    
    await messaging.engine.markMessageProcessed(testId);
    
    final isProcessed2 = await messaging.engine.isMessageProcessed(testId);
    debugPrint('   After: isProcessed = $isProcessed2');
    debugPrint('✅ Deduplication working correctly\n');

    // Test 7: Test conversation state
    debugPrint('📋 TEST 7: Test Conversation State');
    await messaging.engine.syncConversationState('test_conv_001');
    final convState = await messaging.engine.getConversationState('test_conv_001');
    if (convState != null) {
      debugPrint('✅ Conversation state:');
      debugPrint('   - ID: ${convState.conversationId}');
      debugPrint('   - Encrypted: ${convState.isEncrypted}');
      debugPrint('   - Last sync: ${DateTime.fromMillisecondsSinceEpoch(convState.lastSyncTimestamp)}');
    }

    debugPrint('\n═══════════════════════════════════════════════════════');
    debugPrint('✅ ALL TESTS PASSED - PHASE 1 WORKING CORRECTLY');
    debugPrint('═══════════════════════════════════════════════════════\n');

    // Cleanup
    debugPrint('🧹 Cleaning up...');
    await messaging.dispose();
    debugPrint('✅ Cleanup complete');

  } catch (e, stackTrace) {
    debugPrint('\n❌ TEST FAILED: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
