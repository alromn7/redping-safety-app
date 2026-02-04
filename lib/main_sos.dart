import 'core/app_variant.dart';
import 'core/app/app_launch_config.dart';
import 'core/routing/app_router.dart';
import 'main.dart' as base;

/// SOS-focused entrypoint.
void main() {
  AppLaunchConfig.skipStartupOnboarding = true;
  base.runRedPingApp(
    variant: AppVariant.emergency,
    router: AppRouter.router,
  );
}
