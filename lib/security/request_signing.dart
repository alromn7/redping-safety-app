import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/config/security_config.dart';
import 'secure_storage_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RequestSigner {
  static Future<Map<String, String>> signHeaders({
    required Map<String, String> headers,
    required String method,
    required String endpoint,
    String? body,
  }) async {
    if (!SecurityConfig.enableRequestSigning) return headers;

    await SecureStorageService.instance.initialize();
    final secret = await SecureStorageService.instance.read(
      key: SecurityConfig.signingKeyStorageKey,
    );
    if (secret == null || secret.isEmpty) return headers;

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final nonce = _randomHex(16);
    final bodyBytes = utf8.encode(body ?? '');
    final bodyHash = base64.encode(sha256.convert(bodyBytes).bytes);

    final canonical = [
      method.toUpperCase(),
      endpoint,
      timestamp,
      nonce,
      bodyHash,
    ].join('\n');

    final keyBytes = utf8.encode(secret);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final signature = base64.encode(
      hmacSha256.convert(utf8.encode(canonical)).bytes,
    );

    final updated = Map<String, String>.from(headers);
    updated['X-Signature'] = signature;
    updated['X-Signature-Alg'] = 'HMAC-SHA256';
    updated['X-Timestamp'] = timestamp;
    updated['X-Nonce'] = nonce;
    return updated;
  }

  static String _randomHex(int length) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Ensure a per-user signing secret exists locally. If absent, request one
  /// from the backend via callable function and persist it in secure storage.
  static Future<bool> ensureSigningSecret() async {
    await SecureStorageService.instance.initialize();
    final existing = await SecureStorageService.instance.read(
      key: SecurityConfig.signingKeyStorageKey,
    );
    if (existing != null && existing.isNotEmpty) return true;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'rotateSigningSecret',
      );
      final res = await callable.call();
      final data = res.data as Map?;
      final secret = data?['signingSecret'] as String?;
      if (secret != null && secret.isNotEmpty) {
        await SecureStorageService.instance.write(
          key: SecurityConfig.signingKeyStorageKey,
          value: secret,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}
