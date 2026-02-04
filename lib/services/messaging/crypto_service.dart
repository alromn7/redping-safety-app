import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../security/secure_storage_service.dart';

/// Cryptographic service for end-to-end encryption
/// Uses X25519 for key exchange, Ed25519 for signatures, AES-GCM for encryption
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureStorage = SecureStorageService.instance;
  final _algorithm = AesGcm.with256bits();
  final _x25519 = X25519();
  final _ed25519 = Ed25519();

  // Storage keys
  static const String _keyPairPrefix = 'redping_keypair_';
  static const String _signingKeyPrefix = 'redping_signing_';
  static const String _conversationKeyPrefix = 'redping_conv_';

  /// Initialize crypto service and generate device keys if needed
  Future<void> initialize(String deviceId) async {
    await _secureStorage.initialize();
    await _ensureDeviceKeys(deviceId);
  }

  // ============================================================================
  // KEY GENERATION
  // ============================================================================

  /// Generate X25519 key pair for key exchange
  Future<Map<String, String>> generateX25519KeyPair(String deviceId) async {
    try {
      final keyPair = await _x25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

      // Convert to base64 for storage
      final publicKeyBase64 = base64.encode(publicKey.bytes);
      final privateKeyBase64 = base64.encode(privateKeyBytes);

      // Store private key securely
      await _secureStorage.write(
        key: '$_keyPairPrefix${deviceId}_private',
        value: privateKeyBase64,
      );

      debugPrint('✅ Generated X25519 key pair for device $deviceId');

      return {
        'publicKey': publicKeyBase64,
        'privateKey': privateKeyBase64,
      };
    } catch (e) {
      debugPrint('❌ Failed to generate X25519 key pair: $e');
      rethrow;
    }
  }

  /// Generate Ed25519 key pair for signatures
  Future<Map<String, String>> generateEd25519KeyPair(String deviceId) async {
    try {
      final keyPair = await _ed25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

      // Convert to base64
      final publicKeyBase64 = base64.encode(publicKey.bytes);
      final privateKeyBase64 = base64.encode(privateKeyBytes);

      // Store private key securely
      await _secureStorage.write(
        key: '$_signingKeyPrefix${deviceId}_private',
        value: privateKeyBase64,
      );

      debugPrint('✅ Generated Ed25519 signing key pair for device $deviceId');

      return {
        'publicKey': publicKeyBase64,
        'privateKey': privateKeyBase64,
      };
    } catch (e) {
      debugPrint('❌ Failed to generate Ed25519 key pair: $e');
      rethrow;
    }
  }

  /// Ensure device has necessary keys, generate if missing
  Future<void> _ensureDeviceKeys(String deviceId) async {
    // Check X25519 key
    final x25519Private = await _secureStorage.read(
      key: '$_keyPairPrefix${deviceId}_private',
    );
    if (x25519Private == null) {
      await generateX25519KeyPair(deviceId);
    }

    // Check Ed25519 signing key
    final ed25519Private = await _secureStorage.read(
      key: '$_signingKeyPrefix${deviceId}_private',
    );
    if (ed25519Private == null) {
      await generateEd25519KeyPair(deviceId);
    }
  }

  // ============================================================================
  // KEY EXCHANGE
  // ============================================================================

  /// Perform X25519 key exchange to derive shared secret
  Future<String> performKeyExchange(
    String deviceId,
    String remotePublicKeyBase64,
  ) async {
    try {
      // Get our private key
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_keyPairPrefix${deviceId}_private',
      );
      if (privateKeyBase64 == null) {
        throw Exception('Device private key not found');
      }

      // Decode keys
      final privateKeyBytes = base64.decode(privateKeyBase64);
      final remotePublicKeyBytes = base64.decode(remotePublicKeyBase64);

      // Create key pair from private key
      final keyPair = await _x25519.newKeyPairFromSeed(privateKeyBytes);
      final remotePublicKey = SimplePublicKey(
        remotePublicKeyBytes,
        type: KeyPairType.x25519,
      );

      // Perform key exchange
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: remotePublicKey,
      );

      final sharedSecretBytes = await sharedSecret.extractBytes();
      final sharedSecretBase64 = base64.encode(sharedSecretBytes);

      debugPrint('✅ Key exchange successful');
      return sharedSecretBase64;
    } catch (e) {
      debugPrint('❌ Key exchange failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ENCRYPTION / DECRYPTION
  // ============================================================================

  /// Encrypt message with AES-GCM
  Future<String> encryptMessage(String plaintext, String conversationKey) async {
    try {
      // Decode conversation key
      final keyBytes = base64.decode(conversationKey);
      final secretKey = SecretKey(keyBytes);

      // Generate random nonce
      final nonce = _algorithm.newNonce();

      // Encrypt
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: secretKey,
        nonce: nonce,
      );

      // Combine nonce + ciphertext + mac for transmission
      final combined = <int>[
        ...nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ];

      return base64.encode(combined);
    } catch (e) {
      debugPrint('❌ Encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt message with AES-GCM
  Future<String> decryptMessage(String ciphertext, String conversationKey) async {
    try {
      // Decode conversation key
      final keyBytes = base64.decode(conversationKey);
      final secretKey = SecretKey(keyBytes);

      // Decode combined data
      final combined = base64.decode(ciphertext);

      // Extract components (nonce is 12 bytes, MAC is 16 bytes)
      final nonceLength = 12;
      final macLength = 16;

      final nonce = combined.sublist(0, nonceLength);
      final ciphertextBytes = combined.sublist(
        nonceLength,
        combined.length - macLength,
      );
      final macBytes = combined.sublist(combined.length - macLength);

      // Create SecretBox
      final secretBox = SecretBox(
        ciphertextBytes,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      // Decrypt
      final plaintext = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(plaintext);
    } catch (e) {
      debugPrint('❌ Decryption failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SIGNATURES
  // ============================================================================

  /// Sign message with Ed25519
  Future<String> signMessage(String message, String deviceId) async {
    try {
      // Get private signing key
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_signingKeyPrefix${deviceId}_private',
      );
      if (privateKeyBase64 == null) {
        throw Exception('Signing key not found');
      }

      final privateKeyBytes = base64.decode(privateKeyBase64);
      final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);

      // Sign message
      final messageBytes = utf8.encode(message);
      final signature = await _ed25519.sign(messageBytes, keyPair: keyPair);

      return base64.encode(signature.bytes);
    } catch (e) {
      debugPrint('❌ Signature failed: $e');
      rethrow;
    }
  }

  /// Verify Ed25519 signature
  Future<bool> verifySignature(
    String message,
    String signatureBase64,
    String publicKeyBase64,
  ) async {
    try {
      final messageBytes = utf8.encode(message);
      final signatureBytes = base64.decode(signatureBase64);
      final publicKeyBytes = base64.decode(publicKeyBase64);

      final signature = Signature(signatureBytes, publicKey: SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      ));

      final isValid = await _ed25519.verify(messageBytes, signature: signature);

      if (!isValid) {
        debugPrint('⚠️ Signature verification failed');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Signature verification error: $e');
      return false;
    }
  }

  // ============================================================================
  // KEY STORAGE & RETRIEVAL
  // ============================================================================

  /// Store conversation key securely
  Future<void> storeConversationKey(
    String conversationId,
    String conversationKey,
  ) async {
    await _secureStorage.write(
      key: '$_conversationKeyPrefix$conversationId',
      value: conversationKey,
    );
  }

  /// Retrieve conversation key
  Future<String?> getConversationKey(String conversationId) async {
    return await _secureStorage.read(
      key: '$_conversationKeyPrefix$conversationId',
    );
  }

  /// Get device public key for X25519
  Future<String?> getDevicePublicKey(String deviceId) async {
    final privateKeyBase64 = await _secureStorage.read(
      key: '$_keyPairPrefix${deviceId}_private',
    );
    if (privateKeyBase64 == null) return null;

    // Derive public key from private key
    final privateKeyBytes = base64.decode(privateKeyBase64);
    final keyPair = await _x25519.newKeyPairFromSeed(privateKeyBytes);
    final publicKey = await keyPair.extractPublicKey();

    return base64.encode(publicKey.bytes);
  }

  /// Get device signing public key
  Future<String?> getSigningPublicKey(String deviceId) async {
    final privateKeyBase64 = await _secureStorage.read(
      key: '$_signingKeyPrefix${deviceId}_private',
    );
    if (privateKeyBase64 == null) return null;

    // Derive public key from private key
    final privateKeyBytes = base64.decode(privateKeyBase64);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final publicKey = await keyPair.extractPublicKey();

    return base64.encode(publicKey.bytes);
  }

  /// Store any key securely
  Future<void> storeKeySecurely(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Retrieve any key securely
  Future<String?> retrieveKeySecurely(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Generate random conversation key
  Future<String> generateConversationKey() async {
    final secretKey = await _algorithm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    return base64.encode(keyBytes);
  }

  /// Hash data with SHA-256
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Delete all keys for a device
  Future<void> deleteDeviceKeys(String deviceId) async {
    await _secureStorage.delete(key: '$_keyPairPrefix${deviceId}_private');
    await _secureStorage.delete(key: '$_signingKeyPrefix${deviceId}_private');
    debugPrint('🗑️ Deleted keys for device $deviceId');
  }

  /// Delete conversation key
  Future<void> deleteConversationKey(String conversationId) async {
    await _secureStorage.delete(key: '$_conversationKeyPrefix$conversationId');
  }
}
