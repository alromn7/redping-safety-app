import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';

class SensorCalibrationPage extends StatefulWidget {
  const SensorCalibrationPage({super.key});

  @override
  State<SensorCalibrationPage> createState() => _SensorCalibrationPageState();
}

class _SensorCalibrationPageState extends State<SensorCalibrationPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  bool _isCalibrating = false;
  Map<String, dynamic> _status = const {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() {
    final sensor = _serviceManager.sensorService;
    setState(() {
      _status = sensor.getSensorStatus();
    });
  }

  Future<void> _calibrate() async {
    if (_isCalibrating) return;
    setState(() => _isCalibrating = true);
    try {
      await _serviceManager.sensorService.calibrateSensors();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sensor calibration completed'),
          backgroundColor: AppTheme.safeGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calibration failed: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    } finally {
      _loadStatus();
      if (mounted) setState(() => _isCalibrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCalibrated = _status['isCalibrated'] == true;
    final conversionActive = _status['realWorldConversionActive'] == true;
    final calibratedGravity = (_status['calibratedGravity'] ?? 9.8) as double;
    final scaling = (_status['accelerationScalingFactor'] ?? 1.0) as double;
    final noise = (_status['sensorNoiseFactor'] ?? 1.0) as double;
    final crashThreshold = (_status['crashThreshold'] ?? 180.0) as double;
    final fallThreshold = (_status['fallThreshold'] ?? 150.0) as double;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Calibration')),
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
                      const Icon(Icons.sensors, color: AppTheme.infoBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Calibration Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(isCalibrated ? 'Calibrated' : 'Pending'),
                        backgroundColor: isCalibrated
                            ? AppTheme.safeGreen.withValues(alpha: 0.2)
                            : AppTheme.warningOrange.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isCalibrated
                              ? AppTheme.safeGreen
                              : AppTheme.warningOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _kvRow(
                    'Real-World Conversion',
                    conversionActive ? 'Active' : 'Fallback',
                  ),
                  _kvRow(
                    'Calibrated Gravity',
                    '${calibratedGravity.toStringAsFixed(2)} m/s²',
                  ),
                  _kvRow('Scaling Factor', scaling.toStringAsFixed(2)),
                  _kvRow('Noise Factor', noise.toStringAsFixed(2)),
                  const Divider(height: 24),
                  _kvRow(
                    'Crash Threshold',
                    '${crashThreshold.toStringAsFixed(0)} m/s²',
                  ),
                  _kvRow(
                    'Fall Threshold',
                    '${fallThreshold.toStringAsFixed(0)} m/s²',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCalibrating ? null : _calibrate,
                      icon: _isCalibrating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.tune),
                      label: Text(
                        _isCalibrating ? 'Calibrating…' : 'Calibrate Now',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
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
