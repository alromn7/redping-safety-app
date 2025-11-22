// dart run scripts/sign_request_cli.dart METHOD ENDPOINT JSON_BODY SIGNING_SECRET
// Prints X-Signature-Alg, X-Signature, X-Timestamp, X-Nonce headers for testing
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

void main(List<String> args) {
  if (args.length < 4) {
    stderr.writeln(
      'Usage: dart run scripts/sign_request_cli.dart METHOD ENDPOINT JSON_BODY SIGNING_SECRET',
    );
    exit(64);
  }
  final method = args[0].toUpperCase();
  final endpoint = args[1];
  final body = args[2];
  final secret = args[3];

  final ts = DateTime.now().millisecondsSinceEpoch;
  final nonce = _randomNonce(16);
  final base = '$method\n$endpoint\n$ts\n$nonce\n$body';
  final key = utf8.encode(secret);
  final hash = Hmac(sha256, key).convert(utf8.encode(base)).toString();

  stdout.writeln('X-Signature-Alg: HMAC-SHA256');
  stdout.writeln('X-Signature: $hash');
  stdout.writeln('X-Timestamp: $ts');
  stdout.writeln('X-Nonce: $nonce');
}

String _randomNonce(int length) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final r = Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}
