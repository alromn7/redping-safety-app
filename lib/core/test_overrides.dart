class TestOverrides {
  static bool _isTest = false;

  static bool get isTest => _isTest;

  static void enableTestMode() {
    _isTest = true;
  }
}
