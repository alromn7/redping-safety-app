import 'dart:io';
import 'package:flutter/services.dart';

/// Thin wrapper over native foreground service (Android only)
class ForegroundServiceManager {
  static const MethodChannel _channel =
      MethodChannel('redping/foreground_service');

  static Future<void> start({
    String title = 'REDP!NG Running',
    String text = 'Monitoring for SOS delivery and location updates',
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('start', {
        'title': title,
        'text': text,
      });
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}

