import '../core/constants/app_constants.dart'; // used for mutable lab flags

/// Runtime testing mode helper.
/// Provides an override so you can enable simplified verification behavior
/// without rebuilding with dart-define feature flags.
class TestingMode {
  /// Enables testing mode:
  ///  - Suppresses verification / countdown dialogs if requested
  ///  - Marks AppConstants.testingModeEnabled true
  ///  - Sets internal bypass so AIVerificationService will skip auto-analysis
  static bool _aiBypass = false;

  static void activate({bool suppressDialogs = true, bool aiBypass = true}) {
    AppConstants.testingModeEnabled = true;
    _aiBypass = aiBypass;
    if (suppressDialogs) {
      AppConstants.labSuppressVerificationDialog = true;
      AppConstants.labSuppressCountdownDialog = true;
    }
  }

  static void deactivate() {
    AppConstants.testingModeEnabled = false;
    _aiBypass = false;
    AppConstants.labSuppressVerificationDialog = false;
    AppConstants.labSuppressCountdownDialog = false;
  }

  static bool get aiBypassEnabled => _aiBypass;
}
