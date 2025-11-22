import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'pins_loader.dart';

class TlsPinningException implements Exception {
  final String message;
  TlsPinningException(this.message);
  @override
  String toString() => 'TlsPinningException: $message';
}

class PinnedHttpClient {
  final HttpClient _client;
  final PinsConfig _pins;

  PinnedHttpClient._(this._client, this._pins);

  static Future<PinnedHttpClient> create() async {
    final pins = await PinsLoader.load();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    return PinnedHttpClient._(client, pins);
  }

  Future<PinnedResponse> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final req = await _client.openUrl(method, uri);
    (headers ?? const {}).forEach((k, v) => req.headers.set(k, v));
    if (body != null && body.isNotEmpty) {
      final bytes = utf8.encode(body);
      req.headers.contentLength = bytes.length;
      req.add(bytes);
    }

    final resp = await req.close();
    await _verifyPinIfRequired(uri.host, resp.certificate);

    final data = await consolidateHttpClientResponseBytes(resp);
    return PinnedResponse(resp.statusCode, utf8.decode(data), resp.headers);
  }

  Future<void> _verifyPinIfRequired(String host, X509Certificate? cert) async {
    final entry = _pins.hosts[host];
    if (entry == null) return; // no pin for this host

    if (cert == null) {
      if (_pins.enforce) {
        throw TlsPinningException('No certificate provided for host $host');
      } else {
        debugPrint('TLS Pinning (warn): No certificate for $host');
        return;
      }
    }

    // Supports 'sha1' (DER) and 'sha256-pem' (hash of PEM bytes)
    final algo = entry.algorithm;
    String fingerprintHex = '';
    if (algo == 'sha1') {
      final sha1 = cert.sha1; // List<int>
      fingerprintHex = sha1
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    } else if (algo == 'sha256-pem') {
      try {
        final pem = cert.pem; // String
        final bytes = utf8.encode(pem);
        final digest = sha256.convert(bytes).bytes;
        fingerprintHex = digest
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      } catch (_) {
        fingerprintHex = '';
      }
    }

    final allowed = entry.fingerprints.map((f) => f.toLowerCase()).toSet();
    final matches = allowed.contains(fingerprintHex);
    if (!matches) {
      final msg =
          'Certificate pin mismatch for $host (alg=$algo, got=$fingerprintHex)';
      if (_pins.enforce) {
        throw TlsPinningException(msg);
      } else {
        debugPrint('TLS Pinning (warn): $msg');
      }
    }
  }

  void close() {
    _client.close(force: true);
  }
}

class PinnedResponse {
  final int statusCode;
  final String body;
  final HttpHeaders headers;
  PinnedResponse(this.statusCode, this.body, this.headers);
}
