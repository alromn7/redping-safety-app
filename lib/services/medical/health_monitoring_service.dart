import 'package:shared_preferences/shared_preferences.dart';

class HealthMonitoringService {
  bool _initialized = false;
  bool _enabled = false;

  int _latestHeartRate = 0; // bpm
  int _dailySteps = 0;
  int _lastSleepScore = 0; // 0..100

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('health_monitoring_enabled') ?? false;
    _latestHeartRate = prefs.getInt('hm_latest_hr') ?? 0;
    _dailySteps = prefs.getInt('hm_daily_steps') ?? 0;
    _lastSleepScore = prefs.getInt('hm_last_sleep_score') ?? 0;
    _initialized = true;
  }

  bool get isEnabled => _enabled;
  set isEnabled(bool v) {
    _enabled = v;
    SharedPreferences.getInstance().then(
      (p) => p.setBool('health_monitoring_enabled', v),
    );
  }

  // Simple setters to simulate updates (extensible for real integrations)
  Future<void> setLatestHeartRate(int bpm) async {
    _latestHeartRate = bpm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hm_latest_hr', bpm);
  }

  Future<void> setDailySteps(int steps) async {
    _dailySteps = steps;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hm_daily_steps', steps);
  }

  Future<void> setLastSleepScore(int score) async {
    _lastSleepScore = score.clamp(0, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hm_last_sleep_score', _lastSleepScore);
  }

  int get latestHeartRate => _latestHeartRate;
  int get dailySteps => _dailySteps;
  int get lastSleepScore => _lastSleepScore;
}
