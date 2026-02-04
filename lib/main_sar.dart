import 'core/app_variant.dart';
import 'core/routing/sar_router.dart';
import 'main.dart' as base;

/// SAR-focused entrypoint.
void main() {
  base.runRedPingApp(
    variant: AppVariant.sar,
    router: SarRouter.router,
  );
}
