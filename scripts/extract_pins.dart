import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

// Usage: dart run scripts/extract_pins.dart <host> [port]
// Prints sha256-pem and sha1 fingerprints for the leaf certificate.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run scripts/extract_pins.dart <host> [port]');
    exit(64);
  }
  final host = args[0];
  final port = args.length > 1 ? int.tryParse(args[1]) ?? 443 : 443;

  try {
    stdout.writeln('Connecting to $host:$port ...');
    final socket = await SecureSocket.connect(
      host,
      port,
      timeout: const Duration(seconds: 15),
      onBadCertificate: (_) =>
          true, // allow extraction despite hostname mismatch
    );
    try {
      final cert = socket.peerCertificate;
      if (cert == null) {
        stderr.writeln('No peer certificate received.');
        exit(1);
      }

      final pem = cert.pem; // String
      final pemBytes = utf8.encode(pem);
      final sha256Pem = sha256.convert(pemBytes).bytes;
      final sha256PemHex = sha256Pem
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // sha1 DER if available
      String sha1Hex = '';
      try {
        final derSha1 = cert.sha1; // List<int>
        sha1Hex = derSha1
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      } catch (_) {
        // property may not exist on some platforms
      }

      stdout.writeln('Host: $host');
      stdout.writeln('Algorithm: sha256-pem');
      stdout.writeln('Fingerprint: $sha256PemHex');
      if (sha1Hex.isNotEmpty) {
        stdout.writeln('Algorithm: sha1');
        stdout.writeln('Fingerprint: $sha1Hex');
      }
    } finally {
      socket.destroy();
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
