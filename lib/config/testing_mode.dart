import '../core/constants/app_constants.dart'; // used for mutable lab flags

/// Runtime testing mode helper.
/// Provides an override so you can enable simplified verification behavior
/// without rebuilding with dart-define feature flags.
class TestingMode {
  /// Enables testing mode:
  ///  - Suppresses verification / countdown dialogs if requested
  ///  - Marks AppConstants.testingModeEnabled true

  static void activate({bool suppressDialogs = true}) {
    AppConstants.testingModeEnabled = true;
    if (suppressDialogs) {
      AppConstants.labSuppressVerificationDialog = true;
      AppConstants.labSuppressCountdownDialog = true;
    }
  }

  static void deactivate() {
    AppConstants.testingModeEnabled = false;
    AppConstants.labSuppressVerificationDialog = false;
    AppConstants.labSuppressCountdownDialog = false;
  }
}
