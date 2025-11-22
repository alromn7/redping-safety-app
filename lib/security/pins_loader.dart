import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PinEntry {
  final String algorithm; // e.g., 'sha1', 'sha256-pem'
  final List<String> fingerprints; // hex lowercase
  const PinEntry({required this.algorithm, required this.fingerprints});
}

class PinsConfig {
  final Map<String, PinEntry> hosts; // host -> pins
  final bool enforce; // if false, only logs; if true, blocks on mismatch
  const PinsConfig({required this.hosts, required this.enforce});
}

class PinsLoader {
  static Future<PinsConfig> load() async {
    try {
      final raw = await rootBundle.loadString('assets/pins/pins.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final hostsJson = json['hosts'] as Map<String, dynamic>? ?? {};
      final hosts = <String, PinEntry>{};
      hostsJson.forEach((host, value) {
        final v = value as Map<String, dynamic>;
        hosts[host] = PinEntry(
          algorithm: (v['alg'] as String? ?? 'sha1').toLowerCase(),
          fingerprints: List<String>.from(v['fingerprints'] ?? const []),
        );
      });
      final enforce = (json['enforce'] as bool?) ?? false;
      return PinsConfig(hosts: hosts, enforce: enforce);
    } catch (_) {
      return const PinsConfig(hosts: {}, enforce: false);
    }
  }
}
