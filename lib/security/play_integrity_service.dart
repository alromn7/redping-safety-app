import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Caches and retrieves Play Integrity tokens for Android.
class PlayIntegrityService {
  PlayIntegrityService._();
  static final PlayIntegrityService instance = PlayIntegrityService._();

  static const MethodChannel _channel = MethodChannel('redping.security');

  String? _token;
  DateTime? _tokenTs;
  String? _nonce;

  /// Last nonce used to request the cached token (if any).
  String? get nonce => _nonce;

  /// Get a Play Integrity token, cached for [ttl].
  /// Returns null on iOS/unsupported or on error.
  Future<String?> getToken({Duration ttl = const Duration(minutes: 10)}) async {
    if (!Platform.isAndroid) return null;
    if (_token != null && _tokenTs != null) {
      final age = DateTime.now().difference(_tokenTs!);
      if (age < ttl) return _token;
    }

    try {
      final nonce = _nonce ?? _generateNonce();
      final resp = await _channel.invokeMethod<dynamic>(
        'requestPlayIntegrity',
        {'nonce': nonce},
      );
      if (resp is Map) {
        final map = Map<String, dynamic>.from(resp);
        if (map['status'] == 'OK' && map['token'] is String) {
          _token = map['token'] as String;
          _tokenTs = DateTime.now();
          _nonce = map['nonce'] as String? ?? nonce;
          return _token;
        }
      }
    } catch (_) {}
    return null;
  }

  String _generateNonce() {
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return base64.encode(bytes);
  }

  void clearCache() {
    _token = null;
    _tokenTs = null;
    _nonce = null;
  }
}
