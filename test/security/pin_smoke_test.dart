import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:redping_14v/security/pinned_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow opt-in, as this test performs real network requests.
  const runNetwork = bool.fromEnvironment(
    'RUN_NETWORK_TESTS',
    defaultValue: false,
  );

  group('TLS pinning smoke', () {
    test('Staging Cloud Functions host passes pin check', () async {
      if (!runNetwork) {
        return; // Framework stubs HttpClient; skip in Flutter tests
      }
      // Ensure assets are available
      final data = await rootBundle.loadString('assets/pins/pins.json');
      expect(data.isNotEmpty, true);

      final client = await PinnedHttpClient.create();
      try {
        // Root path may return 404, but handshake should succeed and not throw TlsPinningException
        final resp = await client.request(
          'GET',
          Uri.parse('https://us-central1-redping-staging.cloudfunctions.net/'),
        );
        // 2xx/3xx not guaranteed; presence of response implies handshake + pin verified
        expect(resp.statusCode, isNonNegative);
      } on TlsPinningException catch (e) {
        fail('Pinning failed unexpectedly: $e');
      } on HandshakeException catch (e) {
        fail('TLS handshake failed: $e');
      } finally {
        client.close();
      }
    }, skip: true);

    test('Prod Cloud Functions host passes pin check', () async {
      if (!runNetwork) {
        return; // Framework stubs HttpClient; skip in Flutter tests
      }
      final client = await PinnedHttpClient.create();
      try {
        final resp = await client.request(
          'GET',
          Uri.parse('https://us-central1-redping-prod.cloudfunctions.net/'),
        );
        expect(resp.statusCode, isNonNegative);
      } on TlsPinningException catch (e) {
        fail('Pinning failed unexpectedly: $e');
      } on HandshakeException catch (e) {
        fail('TLS handshake failed: $e');
      } finally {
        client.close();
      }
    }, skip: true);
  });
}
