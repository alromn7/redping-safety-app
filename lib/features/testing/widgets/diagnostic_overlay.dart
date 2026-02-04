import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/test_mode_diagnostic_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/sensor_service.dart';

/// Real-time diagnostic overlay for Test Mode v2.0
/// Displays sensor data, detection state, and threshold comparisons
class DiagnosticOverlay extends StatefulWidget {
  const DiagnosticOverlay({super.key});

  @override
  State<DiagnosticOverlay> createState() => _DiagnosticOverlayState();
}

class _DiagnosticOverlayState extends State<DiagnosticOverlay> {
  final _diagnosticService = TestModeDiagnosticService();

  Timer? _updateTimer;
  Offset _position = const Offset(20, 100);
  bool _isExpanded = true;

  // Latest sensor data
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _magnitude = 0.0;

  // Detection state
  int _eventCount = 0;
  String _lastDetectionType = 'None';
  DateTime? _lastDetectionTime;
  Duration _sessionDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          final session = _diagnosticService.currentSession;
          if (session != null) {
            _eventCount = session['events']?.length ?? 0;
            _sessionDuration = DateTime.now().difference(
              DateTime.parse(session['sessionStart'] as String),
            );

            // Get latest sensor sample
            final sensorTrace = session['sensorTrace'] as List?;
            if (sensorTrace != null && sensorTrace.isNotEmpty) {
              final latest = sensorTrace.last as Map<String, dynamic>;
              final accel = latest['accelerometer'] as List<dynamic>;
              _accelX = (accel[0] as num).toDouble();
              _accelY = (accel[1] as num).toDouble();
              _accelZ = (accel[2] as num).toDouble();
              _magnitude = (latest['magnitude'] as num).toDouble();
            }

            // Get latest detection
            final events = session['events'] as List?;
            if (events != null && events.isNotEmpty) {
              final detectionEvents = events
                  .where((e) => (e as Map)['type'] == 'detection')
                  .toList();
              if (detectionEvents.isNotEmpty) {
                final latest = detectionEvents.last as Map<String, dynamic>;
                final data = latest['data'] as Map<String, dynamic>;
                _lastDetectionType =
                    data['detectionType'] as String? ?? 'Unknown';
                _lastDetectionTime = DateTime.parse(
                  latest['timestamp'] as String,
                );
              }
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.testingModeEnabled || !_diagnosticService.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0,
                MediaQuery.of(context).size.width - 300,
              ),
              (_position.dy + details.delta.dy).clamp(
                0,
                MediaQuery.of(context).size.height - 400,
              ),
            );
          });
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.85),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_isExpanded) ...[
                  const Divider(color: Colors.white24, height: 16),
                  _buildSensorData(),
                  const SizedBox(height: 12),
                  _buildThresholdComparison(),
                  const SizedBox(height: 12),
                  _buildDetectionState(),
                  const SizedBox(height: 12),
                  _buildSessionInfo(),
                  const SizedBox(height: 12),
                  _buildActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.bug_report, color: Colors.yellow, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Test Mode Diagnostics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSensorData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Accelerometer'),
        _buildDataRow('X', _accelX, 'm/s²', _getAccelColor(_accelX.abs())),
        _buildDataRow('Y', _accelY, 'm/s²', _getAccelColor(_accelY.abs())),
        _buildDataRow('Z', _accelZ, 'm/s²', _getAccelColor(_accelZ.abs())),
        _buildDataRow('Mag', _magnitude, 'm/s²', _getAccelColor(_magnitude)),
      ],
    );
  }

  Widget _buildThresholdComparison() {
    final sensor = SensorService();
    final crashThreshold = sensor.crashThreshold;
    final fallThreshold = sensor.fallThreshold;
    final crashProgress = (_magnitude / crashThreshold).clamp(0.0, 1.0);
    final fallProgress = (_magnitude / fallThreshold).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Thresholds'),
        _buildThresholdBar(
          'Crash',
          crashThreshold,
          crashProgress,
          _magnitude >= crashThreshold ? Colors.red : Colors.orange,
        ),
        const SizedBox(height: 4),
        _buildThresholdBar(
          'Fall',
          fallThreshold,
          fallProgress,
          _magnitude >= fallThreshold ? Colors.red : Colors.blue,
        ),
      ],
    );
  }

  Widget _buildThresholdBar(
    String label,
    double threshold,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label: ${threshold.toStringAsFixed(1)} m/s²',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: progress >= 1.0 ? Colors.red : Colors.white70,
                fontSize: 11,
                fontWeight: progress >= 1.0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Detection State'),
        _buildInfoRow('Last Detection', _lastDetectionType),
        if (_lastDetectionTime != null)
          _buildInfoRow(
            'Time',
            '${DateTime.now().difference(_lastDetectionTime!).inSeconds}s ago',
          ),
        _buildInfoRow('Event Count', _eventCount.toString()),
      ],
    );
  }

  Widget _buildSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Session'),
        _buildInfoRow(
          'Duration',
          '${_sessionDuration.inMinutes}:${(_sessionDuration.inSeconds % 60).toString().padLeft(2, '0')}',
        ),
        _buildInfoRow(
          'Mode',
          AppConstants.useSmsTestMode ? 'Full Test' : 'Sensors Only',
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          'Export',
          Icons.file_download,
          Colors.blue,
          () async {
            await _diagnosticService.exportSessionAsCsv();
            await _diagnosticService.shareExport();
          },
        ),
        _buildActionButton('Stop', Icons.stop, Colors.red, () {
          _diagnosticService.stopSession();
          if (mounted) setState(() {});
        }),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccelColor(double value) {
    final crashThreshold = AppConstants.getCrashThreshold();
    if (value >= crashThreshold) return Colors.red;
    if (value >= crashThreshold * 0.5) return Colors.orange;
    return Colors.green;
  }
}
