import 'dart:convert';
import 'dart:io';

// Simple CLI to validate TLS certificate pins for a given URL
// Usage: dart run scripts/validate_pins_cli.dart https://host[:port][/path]
// Exits with code 0 on success, non-zero on mismatch or error.

// Removed unused _PinEntry class

Future<int> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run scripts/validate_pins_cli.dart <https-url>',
    );
    return 2;
  }

  final url = args[0];
  late Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (e) {
    stderr.writeln('Invalid URL: $url');
    return 2;
  }
  if (uri.scheme != 'https' || uri.host.isEmpty) {
    stderr.writeln('URL must be https and include a host: $url');
    return 2;
  }

  final pinsPath = 'assets/pins/pins.json';
  Map<String, dynamic> json;
  try {
    final text = await File(pinsPath).readAsString();
    json = jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Failed to read $pinsPath: $e');
    return 3;
  }

  final hosts = (json['hosts'] as Map<String, dynamic>? ?? const {});
  final hostPins = hosts[uri.host] as Map<String, dynamic>?;
  if (hostPins == null) {
    stdout.writeln(
      'No pins configured for host ${uri.host} -> nothing to validate.',
    );
    return 0; // no pins means nothing to enforce here
  }

  final alg = (hostPins['alg'] as String? ?? 'sha1').toLowerCase();
  final fps = List<String>.from(
    hostPins['fingerprints'] ?? const <String>[],
  ).map((s) => s.toLowerCase()).toList();
  if (fps.isEmpty) {
    stderr.writeln(
      'Pins configured for ${uri.host} but fingerprints list is empty.',
    );
    return 4;
  }

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);

  try {
    final req = await client.getUrl(uri);
    final resp = await req.close();
    final cert = resp.certificate;
    if (cert == null) {
      stderr.writeln('No certificate received from ${uri.host}.');
      return 5;
    }

    String got = '';
    if (alg == 'sha1') {
      got = cert.sha1.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } else if (alg == 'sha256-pem') {
      // Hash of the PEM text bytes
      final pem = cert.pem; // String
      final bytes = utf8.encode(pem);
      final digest = _sha256(bytes);
      got = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } else {
      stderr.writeln('Unsupported algorithm "$alg" in pins for ${uri.host}.');
      return 6;
    }

    if (fps.contains(got)) {
      stdout.writeln('TLS pin OK for ${uri.host} (alg=$alg, fp=$got)');
      return 0;
    } else {
      stderr.writeln('TLS pin MISMATCH for ${uri.host} (alg=$alg)');
      stderr.writeln('  got:      $got');
      stderr.writeln('  expected: ${fps.join(', ')}');
      return 7;
    }
  } on HandshakeException catch (e) {
    stderr.writeln('TLS handshake failed for ${uri.host}: $e');
    return 8;
  } catch (e) {
    stderr.writeln('Request error: $e');
    return 9;
  } finally {
    client.close(force: true);
  }
}

// Minimal SHA-256 to avoid external deps (crypto not in pure Dart by default in some contexts)
List<int> _sha256(List<int> input) {
  // Use Process.run to call "dart:io"'s crypto via SecureSocket? No.
  // Implement a tiny wrapper around Crypto API if available, else fallback to insecure hash.
  // However, the Dart SDK includes "crypto" package only when added as dependency.
  // Here, we rely on SecurityContext.hashCode not suitable. So implement a quick FFI-less sha256.
  // For simplicity and to avoid adding dependencies, we will attempt to use Platform.resolvedExecutable
  // via a separate process `dart --snapshot-kind=kernel` is overkill.
  // Better: use the builtin WebCrypto is not available. Thus, ship a tiny pure Dart sha256 implementation.

  // This is a minimal, public domain style implementation adapted inline to avoid dependency bloat.
  // Reference: https://tools.ietf.org/html/rfc6234 (constants and operations)

  int rotr(int x, int n) =>
      (x >>> n) | ((x & 0xFFFFFFFF) << (32 - n) & 0xFFFFFFFF);
  int shr(int x, int n) => x >>> n;
  int ch(int x, int y, int z) => (x & y) ^ ((~x) & z);
  int maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
  int bsig0(int x) => rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
  int bsig1(int x) => rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
  int ssig0(int x) => rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3);
  int ssig1(int x) => rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10);

  final k = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;

  // Pre-processing
  final ml = input.length * 8;
  final data = List<int>.from(input)..add(0x80);
  while (((data.length * 8) % 512) != 448) {
    data.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    data.add((ml >> (8 * i)) & 0xFF);
  }

  // Process the message in successive 512-bit chunks
  for (var i = 0; i < data.length; i += 64) {
    final w = List<int>.filled(64, 0);
    for (var t = 0; t < 16; t++) {
      final j = i + t * 4;
      w[t] =
          ((data[j] << 24) |
              (data[j + 1] << 16) |
              (data[j + 2] << 8) |
              (data[j + 3])) &
          0xFFFFFFFF;
    }
    for (var t = 16; t < 64; t++) {
      final s0 = ssig0(w[t - 15]);
      final s1 = ssig1(w[t - 2]);
      w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF;
    }

    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;

    for (var t = 0; t < 64; t++) {
      final t1 = (h + bsig1(e) + ch(e, f, g) + k[t] + w[t]) & 0xFFFFFFFF;
      final t2 = (bsig0(a) + maj(a, b, c)) & 0xFFFFFFFF;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xFFFFFFFF;
    }

    h0 = (h0 + a) & 0xFFFFFFFF;
    h1 = (h1 + b) & 0xFFFFFFFF;
    h2 = (h2 + c) & 0xFFFFFFFF;
    h3 = (h3 + d) & 0xFFFFFFFF;
    h4 = (h4 + e) & 0xFFFFFFFF;
    h5 = (h5 + f) & 0xFFFFFFFF;
    h6 = (h6 + g) & 0xFFFFFFFF;
    h7 = (h7 + h) & 0xFFFFFFFF;
  }

  List<int> toBytes(int v) => [
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];

  return [
    ...toBytes(h0),
    ...toBytes(h1),
    ...toBytes(h2),
    ...toBytes(h3),
    ...toBytes(h4),
    ...toBytes(h5),
    ...toBytes(h6),
    ...toBytes(h7),
  ];
}
