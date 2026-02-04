// ignore_for_file: unused_field
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/location_service.dart';
import '../../../../models/sos_session.dart';
// Safety Fund feature removed

/// Safety dashboard showing detection status, settings, and history
class SafetyDashboardPage extends StatefulWidget {
  const SafetyDashboardPage({super.key});

  @override
  State<SafetyDashboardPage> createState() => _SafetyDashboardPageState();
}

class _SafetyDashboardPageState extends State<SafetyDashboardPage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  // Real-time sensor data
  Map<String, dynamic> _sensorStatus = {};
  Map<String, dynamic> _locationStatus = {};
  final List<SensorReading> _recentSensorReadings = [];

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Services are already initialized by AppServiceManager
      // Set up real-time callbacks
      _serviceManager.sensorService.setSensorUpdateCallback(_onSensorUpdate);
      _serviceManager.locationService.setLocationUpdateCallback(
        _onLocationUpdate,
      );

      // Get initial status
      _updateStatus();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('SafetyDashboard: Error connecting to services - $e');
    }
  }

  void _onSensorUpdate(SensorReading reading) {
    if (!mounted) return;
    setState(() {
      _recentSensorReadings.add(reading);
      // Keep only last 100 readings
      if (_recentSensorReadings.length > 100) {
        _recentSensorReadings.removeAt(0);
      }
    });
  }

  void _onLocationUpdate(LocationInfo location) {
    if (!mounted) return;
    _updateStatus();
  }

  void _updateStatus() {
    if (!mounted) return;
    setState(() {
      _sensorStatus = _serviceManager.sensorService.getSensorStatus();
      _locationStatus = _serviceManager.locationService.getLocationStatus();
    });
  }

  @override
  void dispose() {
    // Note: Don't dispose services here as they're shared singletons
    super.dispose();
  }

  Future<void> _openExternalMaps() async {
    final current = _locationStatus['currentLocation'];
    if (current is! Map) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available yet')),
      );
      return;
    }

    final lat = current['latitude'];
    final lng = current['longitude'];
    if (lat is! num || lng is! num) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available yet')),
      );
      return;
    }

    await LocationService.openMapApp(lat.toDouble(), lng.toDouble());
  }

  double _computeCrashSensitivityProgress(double crashThreshold) {
    // Map 180..220 to 1.0..0.0
    final clamped = crashThreshold.clamp(180.0, 220.0);
    final progress = 1.0 - ((clamped - 180.0) / 40.0);
    return progress.clamp(0.0, 1.0);
  }

  double _computeFallSensitivityProgress(double fallThreshold) {
    // Map 140..200 to 1.0..0.0
    final clamped = fallThreshold.clamp(140.0, 200.0);
    final progress = 1.0 - ((clamped - 140.0) / 60.0);
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // Navigate to sensor settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Fund card removed

            // Detection Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildDetectionCard(
                    title: 'Crash Detection',
                    subtitle: _sensorStatus['crashDetectionEnabled'] == true
                        ? 'Active & Monitoring'
                        : 'Disabled',
                    icon: Icons.car_crash,
                    isActive: _sensorStatus['crashDetectionEnabled'] ?? false,
                    sensitivity: _computeCrashSensitivityProgress(
                      (_sensorStatus['crashThreshold'] ?? 180.0) as double,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetectionCard(
                    title: 'Fall Detection',
                    subtitle: _sensorStatus['fallDetectionEnabled'] == true
                        ? 'Active & Monitoring'
                        : 'Disabled',
                    icon: Icons.accessibility_new,
                    isActive: _sensorStatus['fallDetectionEnabled'] ?? false,
                    sensitivity: _computeFallSensitivityProgress(
                      (_sensorStatus['fallThreshold'] ?? 150.0) as double,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sensor Status
            Text(
              'Sensor Status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSensorRow(
                      'Accelerometer',
                      _sensorStatus['isMonitoring'] ?? false,
                      _getSensorStatusText('accelerometer'),
                    ),
                    const Divider(),
                    _buildSensorRow(
                      'Gyroscope',
                      _sensorStatus['isMonitoring'] ?? false,
                      _getSensorStatusText('gyroscope'),
                    ),
                    const Divider(),
                    _buildSensorRow(
                      'Location Services',
                      _locationStatus['hasPermission'] ?? false,
                      _getLocationStatusText(),
                    ),
                    const Divider(),
                    _buildSensorRow(
                      'GPS Tracking',
                      _locationStatus['isTracking'] ?? false,
                      _locationStatus['isTracking'] == true
                          ? 'Active'
                          : 'Stopped',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActivityRow(
                      'System Test',
                      'All systems checked successfully',
                      '2 hours ago',
                      Icons.check_circle,
                      AppTheme.safeGreen,
                    ),
                    const Divider(),
                    _buildActivityRow(
                      'Location Update',
                      'GPS coordinates updated',
                      '5 hours ago',
                      Icons.location_on,
                      AppTheme.infoBlue,
                    ),
                    const Divider(),
                    _buildActivityRow(
                      'Sensor Calibration',
                      'Motion sensors recalibrated',
                      '1 day ago',
                      Icons.sensors,
                      AppTheme.warningOrange,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Primary quick actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'SOS Now',
                    Icons.emergency,
                    AppTheme.primaryRed,
                    () => context.push(AppRouter.sos),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'SAR Dashboard',
                    Icons.safety_check,
                    AppTheme.infoBlue,
                    () => context.push(AppRouter.sar),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Secondary quick actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Help Assistant',
                    Icons.volunteer_activism,
                    AppTheme.safeGreen,
                    () => context.push(AppRouter.helpAssistant),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Open Maps',
                    Icons.map_outlined,
                    AppTheme.infoBlue,
                    _openExternalMaps,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Contacts',
                    Icons.group,
                    AppTheme.warningOrange,
                    () => context.push(AppRouter.profile),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Calibrate Sensors',
                    Icons.tune,
                    AppTheme.warningOrange,
                    _calibrateSensors,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Real-time Sensor Data
            if (_recentSensorReadings.isNotEmpty) ...[
              Text(
                'Real-time Sensor Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildSensorDataCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required double sensitivity,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.safeGreen : AppTheme.neutralGray,
                  size: 24,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.safeGreen.withValues(alpha: 0.2)
                        : AppTheme.neutralGray.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.safeGreen
                          : AppTheme.neutralGray,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Sensitivity:',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: sensitivity,
                    backgroundColor: AppTheme.neutralGray.withValues(
                      alpha: 0.3,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? AppTheme.safeGreen : AppTheme.neutralGray,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String name, bool isActive, String status) {
    return Row(
      children: [
        Icon(
          Icons.sensors,
          color: isActive ? AppTheme.safeGreen : AppTheme.neutralGray,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: isActive ? AppTheme.safeGreen : AppTheme.neutralGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.safeGreen : AppTheme.neutralGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: AppTheme.disabledText, fontSize: 11),
        ),
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
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSensorDataCard() {
    if (_recentSensorReadings.isEmpty) return const SizedBox();

    final latestReading = _recentSensorReadings.last;
    final magnitude = latestReading.magnitude;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: AppTheme.infoBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Latest ${latestReading.sensorType.toUpperCase()} Reading',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMagnitudeColor(magnitude).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${magnitude.toStringAsFixed(2)} m/s²',
                    style: TextStyle(
                      color: _getMagnitudeColor(magnitude),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAxisReading('X', latestReading.x)),
                const SizedBox(width: 16),
                Expanded(child: _buildAxisReading('Y', latestReading.y)),
                const SizedBox(width: 16),
                Expanded(child: _buildAxisReading('Z', latestReading.z)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Buffer: ${_sensorStatus['accelerometerBufferSize'] ?? 0} readings',
              style: const TextStyle(
                color: AppTheme.disabledText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisReading(String axis, double value) {
    return Column(
      children: [
        Text(
          axis,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude > 20.0) return AppTheme.criticalRed;
    if (magnitude > 15.0) return AppTheme.warningOrange;
    if (magnitude > 10.0) return AppTheme.infoBlue;
    return AppTheme.safeGreen;
  }

  String _getSensorStatusText(String sensorType) {
    final isMonitoring = _sensorStatus['isMonitoring'] ?? false;
    if (!isMonitoring) return 'Stopped';

    if (_recentSensorReadings.isNotEmpty) {
      final latestReading = _recentSensorReadings.last;
      if (latestReading.sensorType == sensorType) {
        return 'Active (${latestReading.magnitude.toStringAsFixed(1)} m/s²)';
      }
    }

    return 'Active';
  }

  String _getLocationStatusText() {
    final hasPermission = _locationStatus['hasPermission'] ?? false;
    if (!hasPermission) return 'No Permission';

    final currentLocation = _locationStatus['currentLocation'];
    if (currentLocation != null) {
      final accuracy = currentLocation['accuracy'] ?? 0.0;
      return 'Active (±${accuracy.toStringAsFixed(0)}m)';
    }

    return 'Acquiring...';
  }

  // Test menu removed for production release
  // All testing functionality has been disabled for security

  Future<void> _calibrateSensors() async {
    _showSnackBar('Calibrating sensors...');

    try {
      await _serviceManager.sensorService.calibrateSensors();
      _showSnackBar('Sensor calibration completed');
      _updateStatus();
    } catch (e) {
      _showSnackBar('Calibration failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
