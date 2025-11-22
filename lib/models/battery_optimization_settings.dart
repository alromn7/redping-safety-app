/// Battery optimization settings model
class BatteryOptimizationSettings {
  final bool enabled;
  final bool reduceAnimations;
  final bool reduceBackgroundProcessing;
  final bool batchNetworkRequests;
  final bool disableNonEssentialFeatures;
  final int lowBatteryThreshold;
  final int criticalBatteryThreshold;

  const BatteryOptimizationSettings({
    this.enabled = true,
    this.reduceAnimations = true,
    this.reduceBackgroundProcessing = true,
    this.batchNetworkRequests = true,
    this.disableNonEssentialFeatures = false,
    this.lowBatteryThreshold = 20,
    this.criticalBatteryThreshold = 10,
  });

  BatteryOptimizationSettings copyWith({
    bool? enabled,
    bool? reduceAnimations,
    bool? reduceBackgroundProcessing,
    bool? batchNetworkRequests,
    bool? disableNonEssentialFeatures,
    int? lowBatteryThreshold,
    int? criticalBatteryThreshold,
  }) {
    return BatteryOptimizationSettings(
      enabled: enabled ?? this.enabled,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      reduceBackgroundProcessing:
          reduceBackgroundProcessing ?? this.reduceBackgroundProcessing,
      batchNetworkRequests: batchNetworkRequests ?? this.batchNetworkRequests,
      disableNonEssentialFeatures:
          disableNonEssentialFeatures ?? this.disableNonEssentialFeatures,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      criticalBatteryThreshold:
          criticalBatteryThreshold ?? this.criticalBatteryThreshold,
    );
  }
}

/// Battery optimization levels
enum BatteryOptimizationLevel { none, light, moderate, aggressive }

