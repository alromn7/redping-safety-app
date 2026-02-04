import 'dart:async';

/// Minimal stub for Auto Crash/Fall Detection (ACFD) pipeline.
/// Real implementation should wire accelerometer/gyroscope and verification UX.
class AcfdService {
  bool _monitoring = false;
  StreamController<String>? _events;

  Stream<String>? get events => _events?.stream;

  Future<void> startMonitoring() async {
    if (_monitoring) return;
    _monitoring = true;
    _events = StreamController<String>.broadcast();
    // NOTE: shared_core is intentionally platform-agnostic.
    // Sensor wiring/adaptive sampling lives in the app layer (e.g. SensorService).
    _events?.add('acfd_monitoring_started');
  }

  Future<void> stopMonitoring() async {
    if (!_monitoring) return;
    _monitoring = false;
    await _events?.close();
    _events = null;
  }
}
