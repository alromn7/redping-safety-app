import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../services/sensor_service.dart';

class SensorCalibrationStatusBanner extends StatefulWidget {
  const SensorCalibrationStatusBanner({
    super.key,
    required this.sensorService,
    this.showWhenIdleIfUncalibrated = true,
  });

  final SensorService sensorService;
  final bool showWhenIdleIfUncalibrated;

  @override
  State<SensorCalibrationStatusBanner> createState() =>
      _SensorCalibrationStatusBannerState();
}

class _SensorCalibrationStatusBannerState
    extends State<SensorCalibrationStatusBanner> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.sensorService.calibrationStatus;
    final isCalibrating = status['isCalibrating'] == true;
    final isCalibrated = status['isCalibrated'] == true;

    if (!isCalibrating &&
        (isCalibrated || !widget.showWhenIdleIfUncalibrated)) {
      return const SizedBox.shrink();
    }

    final collected = (status['samplesCollected'] as int?) ?? 0;
    final required = (status['samplesRequired'] as int?) ?? 100;
    final progress = required > 0
        ? (collected / required).clamp(0.0, 1.0)
        : 0.0;

    final title = isCalibrating
        ? 'Calibrating sensors…'
        : 'Sensors not calibrated';

    final subtitle = isCalibrating
        ? 'Keep phone still for a few seconds ($collected/$required)'
        : 'Open app again with phone still for best accuracy.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                (isCalibrating ? AppTheme.warningOrange : AppTheme.neutralGray)
                    .withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCalibrating ? Icons.tune : Icons.info_outline,
                  size: 18,
                  color: isCalibrating
                      ? AppTheme.warningOrange
                      : AppTheme.secondaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isCalibrating && !isCalibrated)
                  TextButton(
                    onPressed: () {
                      widget.sensorService.startCalibration(force: true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Calibrate now',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
                height: 1.25,
              ),
            ),
            if (isCalibrating) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.warningOrange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
