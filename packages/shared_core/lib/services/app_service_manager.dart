import '../core/app_variant.dart';
import '../core/env/feature_flags.dart';

class AppServiceManager {
  final AppVariant variant;
  FeatureFlags flags;

  AppServiceManager({required this.variant, required Map<String, dynamic> rawFlags})
      : flags = FeatureFlags(rawFlags);

  bool get acfdEnabled => flags.flag<bool>('acfdEnabled', false) && variant == AppVariant.emergency;
  bool get hazardAlertsEnabled => flags.flag<bool>('hazardAlertsEnabled', false) && variant == AppVariant.emergency;
  bool get sosSmsEnabled => flags.flag<bool>('sosSmsEnabled', false) && variant == AppVariant.emergency;

  bool get sarParticipationEnabled => flags.flag<bool>('sarParticipationEnabled', false) && variant == AppVariant.sar;
  bool get sarTeamManagementEnabled => flags.flag<bool>('sarTeamManagementEnabled', false) && variant == AppVariant.sar;

  void updateFlag(String key, dynamic value) {
    final raw = Map<String, dynamic>.from(flags.raw);
    raw[key] = value;
    flags = FeatureFlags(raw);
  }
}
