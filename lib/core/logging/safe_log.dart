import 'package:flutter/foundation.dart';

class SafeLog {
  static final RegExp _email = RegExp(
    r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
    caseSensitive: false,
  );
  static final RegExp _phone = RegExp(r"(?<!\d)(\+?\d[\d\-\s]{8,}\d)(?!\d)");
  static final RegExp _jwt = RegExp(
    r"[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+",
  );
  static final RegExp _bearer = RegExp(
    r"Bearer\s+[A-Za-z0-9\-._~+/=]+",
    caseSensitive: false,
  );
  static final RegExp _sig = RegExp(
    r"(X-?Signature(-Alg)?|Signature)\s*[:=]\s*[^\s,;]+",
    caseSensitive: false,
  );
  static final RegExp _nonce = RegExp(
    r"(X-?Nonce|Nonce)\s*[:=]\s*[^\s,;]+",
    caseSensitive: false,
  );
  static final RegExp _playIntegrity = RegExp(
    r"X-?Play-Integrity\s*[:=]\s*[^\s,;]+",
    caseSensitive: false,
  );
  static final RegExp _lat = RegExp(
    r"(lat\s*[:=]\s*)(-?\d{1,3}\.\d+)",
    caseSensitive: false,
  );
  static final RegExp _lng = RegExp(
    r"(lng\s*[:=]\s*)(-?\d{1,3}\.\d+)",
    caseSensitive: false,
  );

  static String scrub(String input) {
    var out = input;
    out = out.replaceAllMapped(_email, (m) {
      final v = m.group(0)!;
      final at = v.indexOf('@');
      if (at <= 1) return '***@***';
      return '${v.substring(0, 1)}***${v.substring(at)}';
    });
    out = out.replaceAllMapped(_phone, (m) {
      final v = m.group(1)!;
      final digits = v.replaceAll(RegExp(r"\D"), '');
      if (digits.length <= 4) return '***';
      return '${digits.substring(0, 2)}***${digits.substring(digits.length - 2)}';
    });
    out = out.replaceAllMapped(_jwt, (_) => '***');
    out = out.replaceAllMapped(
      _bearer,
      (m) => '${m.group(0)!.split(' ').first} ***',
    );
    out = out.replaceAllMapped(_sig, (m) {
      final key = m.group(0)!.split(RegExp(r"[:=]"))[0];
      return '$key: ***';
    });
    out = out.replaceAllMapped(_nonce, (m) {
      final key = m.group(0)!.split(RegExp(r"[:=]"))[0];
      return '$key: ***';
    });
    out = out.replaceAllMapped(_playIntegrity, (m) {
      final key = m.group(0)!.split(RegExp(r"[:=]"))[0];
      return '$key: ***';
    });
    out = out.replaceAllMapped(
      _lat,
      (m) => '${m.group(1)}${_coarse(m.group(2)!)}',
    );
    out = out.replaceAllMapped(
      _lng,
      (m) => '${m.group(1)}${_coarse(m.group(2)!)}',
    );
    return out;
  }

  static String _coarse(String v) {
    final d = double.tryParse(v);
    if (d == null) return '***';
    return d.toStringAsFixed(2);
  }
}

void installSafeDebugPrint() {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    final out = message == null ? null : SafeLog.scrub(message);
    original(out, wrapWidth: wrapWidth);
  };
}
