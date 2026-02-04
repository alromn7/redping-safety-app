import 'package:logger/logger.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';  // REMOVED: Phase 2
// import '../config/app_optimization_config.dart';  // REMOVED: Phase 2 - no longer needed

/// App-wide logger wrapper for consistent, leveled logging.
class AppLogger {
  AppLogger._();
  static final _emailRx = RegExp(
    r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
    caseSensitive: false,
  );
  static final _phoneRx = RegExp(r"(?<!\d)(\+?\d[\d\s\-()]{6,}\d)(?!\d)");
  // Rough lat/long pattern; avoids overeager matches
  static final _latLngRx = RegExp(
    r"(-?\d{1,2}\.\d{3,}),\s*(-?\d{1,3}\.\d{3,})",
  );
  // Common API key patterns. Best-effort redaction only.
  static final _googleApiKeyRx = RegExp(r"AIza[0-9A-Za-z-_]{35}");
  static final _genericSkKeyRx = RegExp(r"sk-[A-Za-z0-9]{20,}");

  static String _sanitize(String input) {
    var out = input;
    out = out.replaceAllMapped(_emailRx, (_) => '<redacted@email>');
    out = out.replaceAllMapped(_phoneRx, (_) => '<redacted:phone>');
    out = out.replaceAllMapped(_latLngRx, (_) => '<redacted:coords>');
    out = out.replaceAllMapped(
      _googleApiKeyRx,
      (_) => '<redacted:google-api-key>',
    );
    out = out.replaceAllMapped(_genericSkKeyRx, (_) => '<redacted:api-key>');
    return out;
  }

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      // Replaced deprecated `printTime` with `dateTimeFormat` per logger 2.5.0+
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static void d(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final m = _sanitize(tag != null ? '$tag: $message' : message);
    _logger.d(m, error: error, stackTrace: stackTrace);
    // Phase 2: Crashlytics removed
  }

  static void i(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final m = _sanitize(tag != null ? '$tag: $message' : message);
    _logger.i(m, error: error, stackTrace: stackTrace);
    // Phase 2: Crashlytics removed
  }

  static void w(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final m = _sanitize(tag != null ? '$tag: $message' : message);
    _logger.w(m, error: error, stackTrace: stackTrace);
    // Phase 2: Crashlytics removed
  }

  static void e(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final m = _sanitize(tag != null ? '$tag: $message' : message);
    _logger.e(m, error: error, stackTrace: stackTrace);
    // Phase 2: Crashlytics removed
  }

  /// Phase 2: Crashlytics removed
  static Future<void> setUserId(String userId) async {
    // No-op
  }
}
