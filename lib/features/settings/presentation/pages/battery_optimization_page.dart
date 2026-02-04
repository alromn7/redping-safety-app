import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/battery_optimization_settings.dart';

class BatteryOptimizationPage extends StatefulWidget {
  const BatteryOptimizationPage({super.key});

  @override
  State<BatteryOptimizationPage> createState() =>
      _BatteryOptimizationPageState();
}

class _BatteryOptimizationPageState extends State<BatteryOptimizationPage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  late BatteryOptimizationSettings _settings;
  // bool _initialized = false; // reserved for future use
  int _batteryLevel = 100;
  String _batteryStateText = 'Unknown';

  @override
  void initState() {
    super.initState();
    _settings = _serviceManager.batteryOptimizationService.optimizationSettings;
    _init();
  }

  Future<void> _init() async {
    await _serviceManager.batteryOptimizationService.initialize();
    _refresh();
    // setState(() => _initialized = true);
  }

  void _refresh() {
    final svc = _serviceManager.batteryOptimizationService;
    setState(() {
      _settings = svc.optimizationSettings;
      _batteryLevel = svc.currentBatteryLevel;
      _batteryStateText = svc.currentBatteryState.toString().split('.').last;
    });
  }

  Future<void> _apply() async {
    _serviceManager.batteryOptimizationService.updateSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Battery optimization settings applied'),
          backgroundColor: AppTheme.safeGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Optimization')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_full, color: AppTheme.infoBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Device Battery',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '$_batteryLevel%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'State: $_batteryStateText',
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _levelChip('None', BatteryOptimizationLevel.none),
                      _levelChip('Light', BatteryOptimizationLevel.light),
                      _levelChip('Moderate', BatteryOptimizationLevel.moderate),
                      _levelChip(
                        'Aggressive',
                        BatteryOptimizationLevel.aggressive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, color: AppTheme.infoBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Optimization Settings',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    title: const Text('Enable optimization'),
                    subtitle: const Text(
                      'Dynamically reduce workload as battery drops',
                    ),
                    value: _settings.enabled,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(enabled: v),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Reduce animations'),
                    value: _settings.reduceAnimations,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(reduceAnimations: v),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Reduce background processing'),
                    value: _settings.reduceBackgroundProcessing,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        reduceBackgroundProcessing: v,
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Batch network requests'),
                    value: _settings.batchNetworkRequests,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        batchNetworkRequests: v,
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Disable non-essential features'),
                    value: _settings.disableNonEssentialFeatures,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        disableNonEssentialFeatures: v,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _sliderRow(
                    label: 'Low battery threshold',
                    value: _settings.lowBatteryThreshold.toDouble(),
                    min: 5,
                    max: 40,
                    divisions: 35,
                    format: (v) => '${v.round()}%',
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        lowBatteryThreshold: v.round(),
                      ),
                    ),
                  ),
                  _sliderRow(
                    label: 'Critical battery threshold',
                    value: _settings.criticalBatteryThreshold.toDouble(),
                    min: 3,
                    max: 20,
                    divisions: 17,
                    format: (v) => '${v.round()}%',
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        criticalBatteryThreshold: v.round(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.save),
                      label: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _RecommendationsCard(serviceManager: _serviceManager),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    String Function(double)? format,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ),
            Text(
              (format ?? (v) => v.toStringAsFixed(0))(value),
              style: const TextStyle(color: AppTheme.primaryText),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _levelChip(String label, BatteryOptimizationLevel level) {
    final svc = _serviceManager.batteryOptimizationService;
    final current = svc.shouldReduceBackgroundProcessing()
        ? (svc.isBatteryCritical
              ? BatteryOptimizationLevel.aggressive
              : BatteryOptimizationLevel.moderate)
        : BatteryOptimizationLevel.none;
    final selected = _approxLevelMatch(level, current);
    return Chip(
      label: Text(label),
      backgroundColor: selected ? AppTheme.infoBlue.withValues(alpha: 0.2) : null,
      labelStyle: TextStyle(
        color: selected ? AppTheme.infoBlue : AppTheme.secondaryText,
      ),
    );
  }

  bool _approxLevelMatch(
    BatteryOptimizationLevel a,
    BatteryOptimizationLevel b,
  ) {
    if (a == b) return true;
    // Treat 'light' as between none and moderate for display
    if ((a == BatteryOptimizationLevel.light &&
            b == BatteryOptimizationLevel.none) ||
        (a == BatteryOptimizationLevel.none &&
            b == BatteryOptimizationLevel.light)) {
      return true;
    }
    return false;
  }
}

class _RecommendationsCard extends StatelessWidget {
  final AppServiceManager serviceManager;
  const _RecommendationsCard({required this.serviceManager});

  @override
  Widget build(BuildContext context) {
    final sensorInterval = serviceManager.batteryOptimizationService
        .getRecommendedSensorInterval();
    final locInterval = serviceManager.batteryOptimizationService
        .getRecommendedLocationInterval();
    final backgroundInterval = serviceManager.batteryOptimizationService
      .getRecommendedBackgroundProcessingInterval();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, color: AppTheme.infoBlue),
                const SizedBox(width: 8),
                Text(
                  'Recommended Intervals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('Sensors', '${sensorInterval.inMilliseconds} ms'),
            _kv('Location', _fmt(locInterval)),
            _kv('Background Processing', _fmt(backgroundInterval)),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes} min';
    if (d.inSeconds >= 1) return '${d.inSeconds} s';
    return '${d.inMilliseconds} ms';
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          Text(v, style: const TextStyle(color: AppTheme.primaryText)),
        ],
      ),
    );
  }
}
