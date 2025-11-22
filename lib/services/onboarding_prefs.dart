import 'package:shared_preferences/shared_preferences.dart';

/// Simple onboarding completion preference helper
class OnboardingPrefs {
  OnboardingPrefs._();
  static final OnboardingPrefs instance = OnboardingPrefs._();

  bool _loaded = false;
  bool _completed = false;

  bool get isCompleted => _completed;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed = prefs.getBool('onboarding_completed') ?? false;
      _loaded = true;
    } catch (_) {
      _completed = false;
      _loaded = true;
    }
  }

  Future<void> setCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', value);
    } catch (_) {}
    _completed = value;
    _loaded = true;
  }
}

