import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import '../services/app_service_manager.dart';
import '../services/location_service.dart';
import '../services/location_sharing_service.dart';
import '../models/sos_session.dart';

/// Emergency screen with SOS button and phone map integration
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;

  // Service Manager
  final AppServiceManager _serviceManager = AppServiceManager();

  // State
  bool _isSOSActivated = false;
  bool _isCountdownActive = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  Timer? _resetTimer;

  // Location and emergency status
  Position? _currentLocation;
  bool _isLocationAvailable = false;
  final bool _isEmergencyDetectionActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  /// Initialize animations
  void _initializeAnimations() {
    // Pulse animation for SOS button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shake animation for emergency state
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  /// Initialize services
  Future<void> _initializeServices() async {
    try {
      // Initialize location service
      await _serviceManager.locationService.initialize();

      // Check location availability
      _isLocationAvailable = await _serviceManager.locationService
          .hasLocationPermission();

      // Get current location
      if (_isLocationAvailable) {
        _currentLocation = await LocationService.getCurrentLocationStatic();
      }

      // Note: Emergency detection (ACFD) is handled by SensorService via AppServiceManager.
      // SensorService provides production-grade crash/fall detection with adaptive sampling.

      setState(() {});
    } catch (e) {
      debugPrint('EmergencyScreen: Initialization error - $e');
    }
  }

  /// Handle SOS button activation
  void _onSOSActivated() async {
    if (_isSOSActivated) return;

    try {
      setState(() {
        _isSOSActivated = true;
        _isCountdownActive = true;
        _countdownSeconds = 5;
      });

      // Start countdown
      _startCountdown();

      // Haptic feedback
      HapticFeedback.heavyImpact();

      // Show emergency instructions
      _showEmergencyInstructions();
    } catch (e) {
      debugPrint('EmergencyScreen: SOS activation error - $e');
      _showErrorDialog('Failed to activate SOS: ${e.toString()}');
    }
  }

  /// Start countdown timer
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _executeEmergencySOS();
      }
    });
  }

  /// Execute emergency SOS with phone map integration
  Future<void> _executeEmergencySOS() async {
    try {
      setState(() {
        _isCountdownActive = false;
      });

      // 1. Get current location
      final location = await LocationService.getCurrentLocationStatic();
      _currentLocation = location;

      // 2. Send SOS to SAR system via Firebase
      final firebaseService = _serviceManager.firebaseService;
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      // Create SOS session for Firebase
      final sosSession = SOSSession(
        id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: SOSType.manual,
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: DateTime.now(),
        ),
        userMessage: 'Emergency SOS - Location shared via phone map',
      );

      // Send to Firebase
      await firebaseService.sendSosAlert(sosSession);

      // 3. Open phone's map app
      await LocationService.openMapApp(location.latitude, location.longitude);

      // 4. Share location with SAR teams
      await LocationSharingService.shareLocationWithSAR();

      // 5. Show success message
      _showSuccessMessage();

      // 6. Start reset timer
      _startResetTimer();

      debugPrint(
        'Emergency SOS executed with location: ${location.latitude}, ${location.longitude}',
      );
    } catch (e) {
      debugPrint('EmergencyScreen: Emergency SOS execution error - $e');
      _showErrorDialog('Failed to execute emergency SOS: ${e.toString()}');
    }
  }

  /// Start reset timer
  void _startResetTimer() {
    _resetTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _isSOSActivated = false;
      });
    });
  }

  /// Show emergency instructions dialog
  void _showEmergencyInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text(
            '🚨 EMERGENCY SOS ACTIVATING',
            style: TextStyle(
              color: AppTheme.criticalRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hold the button for 5 seconds to activate emergency SOS.',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              const SizedBox(height: 16),
              const Text(
                'When activated:',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '📱 Your location will be shared with your emergency contacts',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              const Text(
                '🗺️ Your phone\'s map app will open with your location',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              const Text(
                '👥 Emergency contacts will be notified',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              const Text(
                '📞 Emergency hotline is available (manual dial)',
                style: TextStyle(color: AppTheme.primaryText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Understood',
                style: TextStyle(color: AppTheme.accentGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show success message
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ EMERGENCY SOS ACTIVATED - Location shared with your emergency contacts!',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text(
            'Error',
            style: TextStyle(color: AppTheme.criticalRed),
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppTheme.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: AppTheme.accentGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.primaryText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Status cards
              _buildStatusCards(),

              const SizedBox(height: 32),

              // Main SOS button
              _buildSOSButton(),

              const SizedBox(height: 32),

              // Emergency actions
              _buildEmergencyActions(),

              const SizedBox(height: 32),

              // SAR Chat button
              ElevatedButton.icon(
                icon: Icon(Icons.chat),
                label: Text('Messaging (not in-app)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: AppTheme.primaryText,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Messaging is not available in-app in this build.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const Spacer(),

              // Emergency detection status
              _buildEmergencyDetectionStatus(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status cards
  Widget _buildStatusCards() {
    return Column(
      children: [
        // Location status
        Card(
          color: AppTheme.darkSurface,
          child: ListTile(
            leading: Icon(
              _isLocationAvailable ? Icons.location_on : Icons.location_off,
              color: _isLocationAvailable
                  ? AppTheme.accentGreen
                  : AppTheme.criticalRed,
            ),
            title: const Text(
              'Location Status',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            subtitle: Text(
              _isLocationAvailable
                  ? 'GPS location available'
                  : 'Location services disabled',
              style: TextStyle(
                color: _isLocationAvailable
                    ? AppTheme.accentGreen
                    : AppTheme.criticalRed,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Emergency detection status
        Card(
          color: AppTheme.darkSurface,
          child: ListTile(
            leading: Icon(
              _isEmergencyDetectionActive ? Icons.sensors : Icons.sensors_off,
              color: _isEmergencyDetectionActive
                  ? AppTheme.accentGreen
                  : AppTheme.criticalRed,
            ),
            title: const Text(
              'Auto Detection',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            subtitle: Text(
              _isEmergencyDetectionActive
                  ? 'Crash/fall detection active'
                  : 'Auto detection disabled',
              style: TextStyle(
                color: _isEmergencyDetectionActive
                    ? AppTheme.accentGreen
                    : AppTheme.criticalRed,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build main SOS button
  Widget _buildSOSButton() {
    return Column(
      children: [
        // Countdown display
        if (_isCountdownActive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.criticalRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.criticalRed),
            ),
            child: Column(
              children: [
                const Text(
                  'RELEASE TO CANCEL',
                  style: TextStyle(
                    color: AppTheme.criticalRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activating in $_countdownSeconds seconds...',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // SOS Button
        GestureDetector(
          onTapDown: (_) => _onSOSActivated(),
          onTapUp: (_) => _onSOSReleased(),
          onTapCancel: () => _onSOSReleased(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSOSActivated
                        ? AppTheme.criticalRed
                        : AppTheme.criticalRed,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isSOSActivated
                                    ? AppTheme.criticalRed
                                    : AppTheme.criticalRed)
                                .withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emergency, size: 60, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          _isSOSActivated ? 'RELEASE' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Instructions
        Text(
          _isSOSActivated
              ? 'Hold to activate emergency SOS'
              : 'Press and hold for 5 seconds to activate',
          style: const TextStyle(color: AppTheme.secondaryText, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Handle SOS button release
  void _onSOSReleased() {
    if (_isCountdownActive) {
      setState(() {
        _isSOSActivated = false;
        _isCountdownActive = false;
        _countdownSeconds = 5;
      });
      _countdownTimer?.cancel();
    }
  }

  /// Build emergency actions
  Widget _buildEmergencyActions() {
    return Column(
      children: [
        const Text(
          'Emergency Actions',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.location_on,
                label: 'Share Location',
                onTap: () async {
                  if (_currentLocation != null) {
                    await LocationSharingService.shareLocationWithSAR();
                    _showSuccessMessage();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.map,
                label: 'Open Map',
                onTap: () async {
                  if (_currentLocation != null) {
                    await LocationService.openMapApp(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    );
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.navigation,
                label: 'Navigation',
                onTap: () async {
                  if (_currentLocation != null) {
                    await LocationService.openMapWithNavigation(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.search,
                label: 'Search',
                onTap: () async {
                  await LocationService.openMapWithSearch('Emergency Services');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.primaryText,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  /// Build emergency detection status
  Widget _buildEmergencyDetectionStatus() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto Emergency Detection',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitoring for:',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Vehicle crashes',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            const Text(
              '• Falls and impacts',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            const Text(
              '• Panic situations',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              _isEmergencyDetectionActive
                  ? '✅ Active monitoring'
                  : '❌ Monitoring disabled',
              style: TextStyle(
                color: _isEmergencyDetectionActive
                    ? AppTheme.accentGreen
                    : AppTheme.criticalRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
