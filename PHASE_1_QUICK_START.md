# Phase 1 Quick Start Guide

**For Developers**: How to use the new messaging system

---

## 🚀 Quick Start

### 1. Initialize the System

```dart
import 'package:redping_14v/services/messaging_initializer.dart';

// In your app initialization (e.g., main.dart)
final messaging = MessagingInitializer();
await messaging.initialize();
```

### 2. Send a Message

```dart
import 'package:redping_14v/models/messaging/message_packet.dart';

// Send a text message
final packet = await messaging.engine.sendMessage(
  conversationId: 'conv_123',
  content: 'Hello, this is a secure message!',
  type: MessageType.text,
  priority: MessagePriority.normal,
  recipients: ['user_456', 'user_789'],
);

// Send an emergency SOS
final sosPacket = await messaging.engine.sendMessage(
  conversationId: 'sos_${DateTime.now().millisecondsSinceEpoch}',
  content: 'Emergency! Need help at current location.',
  type: MessageType.sos,
  priority: MessagePriority.emergency,
  recipients: ['sar_team_001'],
);
```

### 3. Receive Messages

```dart
// Listen to incoming messages
messaging.engine.receivedStream.listen((packet) {
  print('📨 Received message: ${packet.messageId}');
  print('   From: ${packet.senderId}');
  print('   Type: ${packet.type}');
  
  // Decrypt if you have the conversation key
  // (automatic in MessageEngine)
});
```

### 4. Check Outbox Status

```dart
// Listen to outbox changes
messaging.engine.outboxStream.listen((messages) {
  print('📤 Outbox: ${messages.length} messages pending');
});

// Get unsent messages
final unsent = await messaging.engine.getUnsentMessages();
print('Waiting to send: ${unsent.length} messages');
```

---

## 📦 Core Components

### MessagePacket
The fundamental message unit with encryption and signatures.

```dart
class MessagePacket {
  final String messageId;         // Unique ID
  final String conversationId;    // Conversation/thread ID
  final String senderId;          // User who sent it
  final String deviceId;          // Device ID
  final String encryptedPayload;  // AES-GCM encrypted content
  final String signature;         // Ed25519 signature
  final int timestamp;            // When it was created
  final MessagePriority priority; // normal, high, emergency
  // ... more fields
}
```

### MessageEngine
Core engine for sending/receiving messages.

```dart
// Initialize
await messageEngine.initialize(
  deviceId: 'device_123',
  userId: 'user_456',
);

// Send
await messageEngine.sendMessage(...);

// Receive
await messageEngine.receiveMessage(packet);

// Deduplication
final isProcessed = await messageEngine.isMessageProcessed(messageId);
await messageEngine.markMessageProcessed(messageId);

// Queue management
final unsent = await messageEngine.getUnsentMessages();
await messageEngine.markMessageSent(messageId);
```

### CryptoService
Handles all encryption/decryption.

```dart
// Generate keys (automatic on init)
await crypto.initialize(deviceId);

// Encrypt
final encrypted = await crypto.encryptMessage(plaintext, conversationKey);

// Decrypt
final plaintext = await crypto.decryptMessage(encrypted, conversationKey);

// Sign
final signature = await crypto.signMessage(message, deviceId);

// Verify
final isValid = await crypto.verifySignature(message, signature, publicKey);

// Key exchange
final sharedSecret = await crypto.performKeyExchange(deviceId, remotePublicKey);
```

### DTNStorageService
Persistent offline queue.

```dart
// Store message for later
await storage.storeOutboxMessage(packet);

// Retrieve for sending
final messages = await storage.getOutboxMessages();

// Mark as sent
await storage.removeFromOutbox(messageId);

// Conversation state
await storage.storeConversationState(state);
final state = await storage.getConversationState(conversationId);
```

---

## 🔐 Security Features

### End-to-End Encryption
- **Algorithm**: AES-GCM with 256-bit keys
- **Nonce**: Unique per message
- **Authentication**: Built-in MAC verification

### Key Exchange
- **Algorithm**: X25519 Elliptic Curve Diffie-Hellman
- **Storage**: Flutter Secure Storage (Keychain/Keystore)
- **Rotation**: Automatic every 30 days

### Digital Signatures
- **Algorithm**: Ed25519
- **Purpose**: Sender authentication and tamper detection
- **Verification**: Automatic on receive

---

## 🛠️ Advanced Usage

### Custom Transport Priority

```dart
await engine.sendMessage(
  conversationId: 'conv_123',
  content: 'Prefer mesh for this message',
  type: MessageType.text,
  transportHint: TransportHint.preferMesh, // Force mesh if available
);
```

### Message Metadata

```dart
await engine.sendMessage(
  conversationId: 'conv_123',
  content: 'Message with location',
  type: MessageType.location,
  metadata: {
    'latitude': 37.7749,
    'longitude': -122.4194,
    'accuracy': 10.0,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  },
);
```

### Conversation Key Rotation

```dart
// Check if rotation needed
final state = await engine.getConversationState(conversationId);
if (state?.needsKeyRotation == true) {
  // Rotation happens automatically on next sync
  await engine.syncConversationState(conversationId);
}
```

### Statistics & Monitoring

```dart
// Get system statistics
final stats = await messaging.getStatistics();
print('Outbox: ${stats['outboxCount']}');
print('Processed: ${stats['processedIdsCount']}');
print('Conversations: ${stats['conversationCount']}');

// Storage statistics
final storageStats = await storage.getStatistics();
```

---

## 🧪 Testing

### Run Phase 1 Test

```bash
# Run the test script
dart test_phase1_messaging.dart
```

### Expected Output

```
═══════════════════════════════════════════════════════
🧪 PHASE 1 MESSAGING SYSTEM TEST
═══════════════════════════════════════════════════════

📋 TEST 1: Initialize Messaging System
✅ Initialization successful

📋 TEST 2: Send Encrypted Message
✅ Message sent: abc-123-def-456
   - Type: text
   - Priority: normal
   - Encrypted: U2FsdGVkX1+...
   - Signature: MEUCIQDw...

📋 TEST 3: Send Multiple Messages (Queue Test)
   ✓ Message 1 queued
   ✓ Message 2 queued
   ✓ Message 3 queued
   ✓ Message 4 queued
   ✓ Message 5 queued
✅ All messages queued

📋 TEST 4: Check System Statistics
✅ Statistics:
   - outboxCount: 6
   - conversationCount: 2
   - processedIdsCount: 1
   - initialized: true

📋 TEST 5: Retrieve Outbox Messages
✅ Outbox contains 6 messages

📋 TEST 6: Test Deduplication
   Before: isProcessed = false
   After: isProcessed = true
✅ Deduplication working correctly

📋 TEST 7: Test Conversation State
✅ Conversation state:
   - ID: test_conv_001
   - Encrypted: true
   - Last sync: 2025-11-30 15:30:45.123

═══════════════════════════════════════════════════════
✅ ALL TESTS PASSED - PHASE 1 WORKING CORRECTLY
═══════════════════════════════════════════════════════
```

---

## 📝 Migration from Old System

### Before (Old System)

```dart
// Old EmergencyMessagingService
await emergencyMessagingService.sendEmergencyMessage(
  recipientId: 'user_123',
  message: 'Help needed!',
);
```

### After (New System)

```dart
// New MessageEngine with encryption
await messaging.engine.sendMessage(
  conversationId: 'emergency_${userId}',
  content: 'Help needed!',
  type: MessageType.sos,
  priority: MessagePriority.emergency,
  recipients: ['user_123'],
);
```

### Migration Strategy
1. **Phase 1 (Current)**: Both systems run in parallel
2. **Phase 2**: New messages use MessageEngine, old messages still supported
3. **Phase 3**: Migrate all historical messages to new format
4. **Phase 4**: Deprecate old system

---

## 🐛 Troubleshooting

### Issue: "MessageEngine not initialized"
**Solution**: Call `await messaging.initialize()` before use

### Issue: "Failed to decrypt message"
**Solution**: Ensure conversation key exists with `crypto.getConversationKey()`

### Issue: "Duplicate messages"
**Solution**: System auto-deduplicates, check `isMessageProcessed()`

### Issue: Messages stuck in outbox
**Solution**: Transport layer will handle delivery (Phase 2)

---

## 📚 Next Steps

### For Phase 2 (Week 3)
- Internet transport will deliver queued messages
- Integration with existing Firestore
- Auto-sync on reconnection
- Existing services migration

### For Phase 3+ (Weeks 4-8)
- Bluetooth mesh networking
- WiFi Direct support
- UI connectivity indicators
- Advanced routing features

---

## 🔗 Related Documentation

- [Full Implementation Plan](MESSAGING_UPGRADE_IMPLEMENTATION_PLAN.md)
- [Phase 1 Complete Summary](PHASE_1_IMPLEMENTATION_COMPLETE.md)
- [Original Blueprint](docs/archive/App to App messaging)

---

**Questions?** Check the implementation files or run the test script!
