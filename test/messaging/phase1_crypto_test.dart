import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/messaging/crypto_service.dart';
import '../test_utils/test_environment.dart';

/// Phase 1: Cryptography & Security Layer Tests
/// Tests X25519 key exchange, Ed25519 signatures, AES-GCM encryption
void main() {
  group('Phase 1: Cryptography Tests', () {
    late CryptoService crypto;
    const deviceId = 'test_device_001';

    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() async {
      await TestEnvironment.tearDown();
    });

    setUp(() async {
      crypto = CryptoService();
      await crypto.initialize(deviceId);
    });

    test('1.1 - CryptoService initializes successfully', () async {
      final pub = await crypto.getDevicePublicKey(deviceId);
      final signingPub = await crypto.getSigningPublicKey(deviceId);
      expect(pub, isNotNull);
      expect(signingPub, isNotNull);
      print('✅ CryptoService initialized and device keys present');
    });

    test('1.2 - Generate X25519 key pair for key exchange', () async {
      final keyPair = await crypto.generateX25519KeyPair(deviceId);

      expect(keyPair['publicKey'], isNotNull);
      expect(keyPair['privateKey'], isNotNull);
      expect(keyPair['publicKey']!, isNotEmpty);
      expect(keyPair['privateKey']!, isNotEmpty);

      print('✅ X25519 key pair generated');
      print('   Public key length: ${keyPair['publicKey']!.length}');
      print('   Private key length: ${keyPair['privateKey']!.length}');
    });

    test('1.3 - Generate Ed25519 key pair for signatures', () async {
      final keyPair = await crypto.generateEd25519KeyPair(deviceId);

      expect(keyPair['publicKey'], isNotNull);
      expect(keyPair['privateKey'], isNotNull);
      expect(keyPair['publicKey']!, isNotEmpty);
      expect(keyPair['privateKey']!, isNotEmpty);

      print('✅ Ed25519 key pair generated');
      print('   Public key length: ${keyPair['publicKey']!.length}');
      print('   Private key length: ${keyPair['privateKey']!.length}');
    });

    test('1.4 - Derive shared secret using X25519', () async {
      const alice = 'alice_device';
      const bob = 'bob_device';

      await crypto.initialize(alice);
      await crypto.initialize(bob);

      final alicePub = await crypto.getDevicePublicKey(alice);
      final bobPub = await crypto.getDevicePublicKey(bob);
      expect(alicePub, isNotNull);
      expect(bobPub, isNotNull);

      final aliceShared = await crypto.performKeyExchange(alice, bobPub!);
      final bobShared = await crypto.performKeyExchange(bob, alicePub!);

      expect(aliceShared, equals(bobShared));
      expect(aliceShared, isNotEmpty);

      print('✅ Shared secret derived successfully');
    });

    test('1.5 - Encrypt and decrypt message with AES-GCM', () async {
      final plaintext = 'This is a secret message that needs encryption!';

      final conversationKey = await crypto.generateConversationKey();

      // Encrypt message
      final encrypted = await crypto.encryptMessage(plaintext, conversationKey);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));
      expect(
        encrypted.length,
        greaterThan(plaintext.length),
      ); // Includes IV and tag

      print('✅ Message encrypted');
      print('   Original: $plaintext');
      print('   Encrypted length: ${encrypted.length}');

      // Decrypt message
      final decrypted = await crypto.decryptMessage(encrypted, conversationKey);

      expect(decrypted, equals(plaintext));

      print('✅ Message decrypted successfully');
      print('   Decrypted: $decrypted');
    });

    test('1.6 - Sign and verify message with Ed25519', () async {
      final message = 'Important message that needs verification';

      final signature = await crypto.signMessage(message, deviceId);
      final publicKey = await crypto.getSigningPublicKey(deviceId);
      expect(publicKey, isNotNull);

      expect(signature, isNotEmpty);
      expect(signature.length, greaterThan(60));

      print('✅ Message signed');
      print('   Signature length: ${signature.length}');

      final isValid = await crypto.verifySignature(message, signature, publicKey!);

      expect(isValid, isTrue);

      print('✅ Signature verified successfully');
    });

    test('1.7 - Signature verification fails for tampered message', () async {
      final message = 'Original message';
      final tamperedMessage = 'Tampered message';

      final signature = await crypto.signMessage(message, deviceId);
      final publicKey = await crypto.getSigningPublicKey(deviceId);
      expect(publicKey, isNotNull);

      final isValid = await crypto.verifySignature(tamperedMessage, signature, publicKey!);

      expect(isValid, isFalse);

      print('✅ Signature verification correctly failed for tampered message');
    });

    test('1.8 - Conversation key management', () async {
      final conversationId = 'test_conversation_002';

      final key = await crypto.generateConversationKey();
      await crypto.storeConversationKey(conversationId, key);

      // Retrieve key
      final retrieved = await crypto.getConversationKey(conversationId);

      expect(retrieved, isNotNull);
      expect(retrieved!.length, greaterThan(30));

      print('✅ Conversation key stored and retrieved');
      print('   Key fingerprint: ${retrieved.substring(0, 16)}...');

      // Delete key
      await crypto.deleteConversationKey(conversationId);

      final deletedKey = await crypto.getConversationKey(conversationId);
      expect(deletedKey, isNull);

      print('✅ Conversation key deleted successfully');
    });

    test('1.9 - Performance: Encrypt 50 messages', () async {
      final conversationKey = await crypto.generateConversationKey();

      final startTime = DateTime.now();

      for (int i = 0; i < 50; i++) {
        final message = 'Performance test message $i with some content';
        await crypto.encryptMessage(message, conversationKey);
      }

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / 50;

      print('✅ Performance test completed');
      print('   50 messages encrypted in ${duration.inMilliseconds}ms');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms per message');

      expect(
        avgTime,
        lessThan(100),
        reason: 'Encryption should be under 100ms per message',
      );
    });

    test('1.10 - Key rotation', () async {
      final conversationId = 'rotation_test_conv';

      final key1 = await crypto.generateConversationKey();
      await crypto.storeConversationKey(conversationId, key1);
      final key2 = await crypto.generateConversationKey();
      await crypto.storeConversationKey(conversationId, key2);

      expect(key2, isNot(equals(key1)));

      print('✅ Key rotation successful');
      print('   Old key: ${key1.substring(0, 16)}...');
      print('   New key: ${key2.substring(0, 16)}...');
    });
  });
}
