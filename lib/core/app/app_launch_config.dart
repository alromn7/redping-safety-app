import '../app_variant.dart';

/// Global app-launch configuration used to keep routing behavior consistent
/// across multiple entrypoints (SOS vs SAR) without hardcoding paths.
class AppLaunchConfig {
  static AppVariant variant = AppVariant.emergency;
  // SOS-focused entrypoint should skip startup onboarding entirely.
  // This is set by `main_sos.dart`.
  static bool skipStartupOnboarding = false;

  static void setVariant(AppVariant value) {
    variant = value;
  }

  static String get homeRoute {
    return variant == AppVariant.sar ? '/sar' : '/main';
  }
}
