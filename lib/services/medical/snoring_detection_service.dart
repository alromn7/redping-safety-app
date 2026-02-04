import 'package:shared_preferences/shared_preferences.dart';

class SnoringDetectionService {
  bool _initialized = false;
  bool _enabled = false;

  DateTime? _lastSessionDate;
  int _lastSnoringMinutes = 0;
  int _lastSleepDurationMinutes = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('snoring_detection_enabled') ?? false;
    final lastDateMs = prefs.getInt('snore_last_date_ms');
    _lastSessionDate = lastDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastDateMs)
        : null;
    _lastSnoringMinutes = prefs.getInt('snore_last_minutes') ?? 0;
    _lastSleepDurationMinutes = prefs.getInt('snore_last_sleep_minutes') ?? 0;
    _initialized = true;
  }

  bool get isEnabled => _enabled;
  set isEnabled(bool v) {
    _enabled = v;
    SharedPreferences.getInstance().then(
      (p) => p.setBool('snoring_detection_enabled', v),
    );
  }

  // Privacy-first stub: no audio saved or uploaded; only local summary
  Future<void> startNightlySession() async {
    if (!_enabled) return;
    // In a real impl: start local audio processing pipeline; here we reset
    _lastSessionDate = DateTime.now();
    _lastSnoringMinutes = 0;
    _lastSleepDurationMinutes = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'snore_last_date_ms',
      _lastSessionDate!.millisecondsSinceEpoch,
    );
    await prefs.setInt('snore_last_minutes', _lastSnoringMinutes);
    await prefs.setInt('snore_last_sleep_minutes', _lastSleepDurationMinutes);
  }

  Future<void> stopNightlySession({
    required int snoringMinutes,
    required int sleepMinutes,
  }) async {
    if (!_enabled) return;
    _lastSnoringMinutes = snoringMinutes;
    _lastSleepDurationMinutes = sleepMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snore_last_minutes', _lastSnoringMinutes);
    await prefs.setInt('snore_last_sleep_minutes', _lastSleepDurationMinutes);
  }

  DateTime? get lastSessionDate => _lastSessionDate;
  int get lastSnoringMinutes => _lastSnoringMinutes;
  int get lastSleepDurationMinutes => _lastSleepDurationMinutes;
}
