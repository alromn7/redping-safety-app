import 'package:flutter/foundation.dart';

/// Simple app logger with levels and optional per-tag throttling to reduce spam.
class Logger {
  Logger._();

  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.warn;

  static final Map<String, DateTime> _lastLogTime = {};

  static void d(String tag, String message, {Duration? throttle}) {
    _log(LogLevel.debug, tag, message, throttle: throttle);
  }

  static void i(String tag, String message, {Duration? throttle}) {
    _log(LogLevel.info, tag, message, throttle: throttle);
  }

  static void w(String tag, String message, {Duration? throttle}) {
    _log(LogLevel.warn, tag, message, throttle: throttle);
  }

  static void e(String tag, String message, {Duration? throttle}) {
    _log(LogLevel.error, tag, message, throttle: throttle);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Duration? throttle,
  }) {
    if (level.index < minLevel.index) return;

    final key = '${level.name}|$tag';
    final now = DateTime.now();

    if (throttle != null) {
      final last = _lastLogTime[key];
      if (last != null && now.difference(last) < throttle) {
        return;
      }
      _lastLogTime[key] = now;
    }

    // Prefix with level and tag for clarity
    debugPrint('[${level.name.toUpperCase()}] $tag: $message');
  }
}

enum LogLevel { debug, info, warn, error }
