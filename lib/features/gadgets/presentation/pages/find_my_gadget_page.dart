import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import '../../../../models/gadget_device.dart';
import '../../../../services/gadget_integration_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page for finding and tracking lost/stolen gadgets
class FindMyGadgetPage extends StatefulWidget {
  final GadgetDevice device;

  const FindMyGadgetPage({super.key, required this.device});

  @override
  State<FindMyGadgetPage> createState() => _FindMyGadgetPageState();
}

class _FindMyGadgetPageState extends State<FindMyGadgetPage> {
  final GadgetIntegrationService _gadgetService =
      GadgetIntegrationService.instance;

  Position? _lastKnownLocation;
  Position? _currentLocation;
  bool _isTracking = false;
  bool _isLostModeEnabled = false;
  bool _isLoading = true;
  StreamSubscription<Position>? _locationSubscription;
  final List<Position> _locationHistory = [];
  DateTime? _lastLocationUpdate;
  // Low-power ping fields
  bool _isPinging = false;
  String? _lastPingCode;
  DateTime? _lastPingAt;
  List<Map<String, dynamic>> _pingHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    setState(() => _isLoading = true);

    try {
      // Get last known location from device metadata
      final metadata = widget.device.metadata ?? {};
      if (metadata.containsKey('lastKnownLocation')) {
        final locationData =
            metadata['lastKnownLocation'] as Map<String, dynamic>;
        _lastKnownLocation = Position(
          latitude: locationData['latitude'] as double,
          longitude: locationData['longitude'] as double,
          timestamp: DateTime.parse(locationData['timestamp'] as String),
          accuracy: locationData['accuracy'] as double? ?? 0.0,
          altitude: locationData['altitude'] as double? ?? 0.0,
          heading: locationData['heading'] as double? ?? 0.0,
          speed: locationData['speed'] as double? ?? 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _lastLocationUpdate = _lastKnownLocation!.timestamp;
      }

      // Check if device is in lost mode
      _isLostModeEnabled = metadata['isLostMode'] as bool? ?? false;

      // Load ping metadata if present
      if (metadata['lastPingCode'] is String) {
        _lastPingCode = metadata['lastPingCode'] as String;
      }
      if (metadata['lastPingAt'] is String) {
        try {
          _lastPingAt = DateTime.parse(metadata['lastPingAt'] as String);
        } catch (_) {}
      }
      if (metadata['pingHistory'] is List) {
        final rawList = metadata['pingHistory'] as List;
        _pingHistory = rawList
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      }

      // Removed auto-start live tracking for battery savings. User can start manually or ping.
    } catch (e) {
      debugPrint('FindMyGadgetPage: Error initializing tracking - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startLiveTracking() async {
    if (_isTracking) return;

    setState(() => _isTracking = true);

    try {
      // In a real app, this would connect to the device's location service
      // For now, we'll simulate tracking with the phone's location as a demo
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission required for live tracking');
        setState(() => _isTracking = false);
        return;
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 10,
                forceLocationManager: true,
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 10,
              ),
      ).listen((position) {
            if (mounted) {
              setState(() {
                _currentLocation = position;
                _lastLocationUpdate = position.timestamp;
                _locationHistory.add(position);

                // Keep only last 50 locations
                if (_locationHistory.length > 50) {
                  _locationHistory.removeAt(0);
                }
              });

              // Persist latest location to gadget metadata
              try {
                final currentMeta = widget.device.metadata ?? {};
                final updated = widget.device.copyWith(
                  metadata: {
                    ...currentMeta,
                    'lastKnownLocation': {
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                      // position.timestamp is non-null (SDK guarantees), so just use it
                      'timestamp': position.timestamp.toIso8601String(),
                      'accuracy': position.accuracy,
                      'altitude': position.altitude,
                      'heading': position.heading,
                      'speed': position.speed,
                    },
                  },
                );
                _gadgetService.updateDevice(updated);
              } catch (e) {
                debugPrint('FindMyGadgetPage: Failed to persist location - $e');
              }
            }
          });
    } catch (e) {
      debugPrint('FindMyGadgetPage: Error starting tracking - $e');
      _showSnackBar('Failed to start live tracking');
      setState(() => _isTracking = false);
    }
  }

  void _stopLiveTracking() {
    _locationSubscription?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _pingForLocation() async {
    if (_isPinging) return;
    setState(() => _isPinging = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission required for ping');
        setState(() => _isPinging = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        // GPS-first to avoid Wi‑Fi accuracy prompts
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      setState(() {
        _currentLocation = position;
        _lastLocationUpdate = position.timestamp;
        _locationHistory.add(position);
        if (_locationHistory.length > 50) _locationHistory.removeAt(0);
      });

      final pingCode = _generatePingCode();
      final currentMeta = widget.device.metadata ?? {};
      final updated = widget.device.copyWith(
        metadata: {
          ...currentMeta,
          'lastKnownLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': position.timestamp.toIso8601String(),
            'accuracy': position.accuracy,
            'altitude': position.altitude,
            'heading': position.heading,
            'speed': position.speed,
          },
          'lastPingCode': pingCode,
          'lastPingAt': DateTime.now().toIso8601String(),
          'pingHistory': _buildUpdatedPingHistory(
            currentMeta['pingHistory'],
            position,
            pingCode,
          ),
        },
      );
      await _gadgetService.updateDevice(updated);
      setState(() {
        _lastPingCode = pingCode;
        _lastPingAt = DateTime.now();
        // Rebuild local ping history for display
        _pingHistory = _buildUpdatedPingHistory(
          currentMeta['pingHistory'],
          position,
          pingCode,
        );
      });
      _showSnackBar('Ping complete. Code: $pingCode');
    } catch (e) {
      debugPrint('FindMyGadgetPage: Ping failed - $e');
      _showSnackBar('Ping failed');
    } finally {
      if (mounted) setState(() => _isPinging = false);
    }
  }

  String _generatePingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  List<Map<String, dynamic>> _buildUpdatedPingHistory(
    dynamic existing,
    Position pos,
    String code,
  ) {
    List<Map<String, dynamic>> list = [];
    if (existing is List) {
      list = existing
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    }
    list.add({
      'timestamp': DateTime.now().toIso8601String(),
      'code': code,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
    });
    // Keep last 10 only
    if (list.length > 10) {
      list = list.sublist(list.length - 10);
    }
    return list;
  }

  Future<void> _toggleLostMode() async {
    final enable = !_isLostModeEnabled;

    String? message;
    String? contact;

    if (enable) {
      // Ask user for lost mode message & contact
      final result = await showDialog<Map<String, String>?>(
        context: context,
        builder: (ctx) {
          final msgController = TextEditingController();
          final contactController = TextEditingController();
          return AlertDialog(
            title: const Text('Enable Lost Mode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter a message and contact info to display if the device is recovered.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgController,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Message',
                    hintText: 'This device is lost. Please contact me.',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact (email/phone)',
                    hintText: 'email@example.com / +1 555 123 4567',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, {
                  'message': msgController.text,
                  'contact': contactController.text,
                }),
                child: const Text('Enable'),
              ),
            ],
          );
        },
      );

      if (result == null) {
        // User cancelled
        return;
      }
      message = result['message']?.trim().isEmpty == true
          ? null
          : result['message']!.trim();
      contact = result['contact']?.trim().isEmpty == true
          ? null
          : result['contact']!.trim();
    }

    setState(() => _isLostModeEnabled = enable);

    try {
      final updatedDevice = widget.device.copyWith(
        metadata: {
          ...widget.device.metadata ?? {},
          'isLostMode': _isLostModeEnabled,
          'lostModeActivatedAt': _isLostModeEnabled
              ? DateTime.now().toIso8601String()
              : null,
          'lostModeMessage': message,
          'lostModeContact': contact,
        },
      );
      await _gadgetService.updateDevice(updatedDevice);
      _showSnackBar(
        _isLostModeEnabled ? 'Lost Mode enabled' : 'Lost Mode disabled',
      );
    } catch (e) {
      debugPrint('FindMyGadgetPage: Error toggling lost mode - $e');
      _showSnackBar('Failed to update lost mode');
      setState(() => _isLostModeEnabled = !enable); // revert
    }
  }

  Future<void> _playSound() async {
    try {
      _showSnackBar('Playing sound on ${widget.device.name}...');
      // In a real app, this would send a command to the device to play a sound
      await Future.delayed(const Duration(seconds: 1));
      _showSnackBar('Sound playing on device');
    } catch (e) {
      _showSnackBar('Failed to play sound on device');
    }
  }

  Future<void> _lockDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Device'),
        content: const Text(
          'This will lock the device remotely. The device will require authentication to unlock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Lock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showSnackBar('Locking device...');
        // In a real app, this would send a lock command to the device
        await Future.delayed(const Duration(seconds: 1));
        _showSnackBar('Device locked successfully');
      } catch (e) {
        _showSnackBar('Failed to lock device');
      }
    }
  }

  Future<void> _eraseDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase Device'),
        content: const Text(
          'WARNING: This will permanently erase all data on the device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Erase'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showSnackBar('Erasing device data...');
        // In a real app, this would send an erase command to the device
        await Future.delayed(const Duration(seconds: 1));
        _showSnackBar('Device data erased successfully');
      } catch (e) {
        _showSnackBar('Failed to erase device');
      }
    }
  }

  Future<void> _getDirections() async {
    if (_currentLocation != null || _lastKnownLocation != null) {
      final location = _currentLocation ?? _lastKnownLocation!;
      final lat = location.latitude;
      final lng = location.longitude;

      // Open Google Maps with directions
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open maps application');
      }
    } else {
      _showSnackBar('No location available');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.cardBackground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find My Gadget', style: TextStyle(color: Colors.white)),
            Text(
              widget.device.name,
              style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.stop, color: AppTheme.primaryRed),
              onPressed: _stopLiveTracking,
              tooltip: 'Stop Tracking',
            )
          else if (widget.device.isOnline &&
              widget.device.hasCapability(GadgetCapability.locationTracking))
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.accentGreen,
                  ),
                  onPressed: _startLiveTracking,
                  tooltip: 'Start Live Tracking (higher battery use)',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppTheme.neutralGray,
                  ),
                  onPressed: _showTrackingInfo,
                  tooltip: 'Tracking Mode Info',
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : Column(
              children: [
                // Status Card
                _buildStatusCard(),
                // Map
                Expanded(child: _buildMap()),
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    final location = _currentLocation ?? _lastKnownLocation;
    // Removed unused isRecent calculation after low-power refactor.

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLostModeEnabled
              ? AppTheme.primaryRed
              : (widget.device.isOnline
                    ? AppTheme.accentGreen
                    : AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLostModeEnabled
                    ? Icons.warning
                    : (widget.device.isOnline
                          ? Icons.location_on
                          : Icons.location_off),
                color: _isLostModeEnabled
                    ? AppTheme.primaryRed
                    : (widget.device.isOnline
                          ? AppTheme.accentGreen
                          : AppTheme.neutralGray),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLostModeEnabled
                          ? 'Lost Mode Active'
                          : (widget.device.isOnline
                                ? 'Device Online'
                                : 'Device Offline'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      () {
                        if (location != null) {
                          if (_isTracking) return 'Live tracking active';
                          if (_lastPingAt != null && _lastPingCode != null) {
                            return 'Last ping ${_getTimeAgo(_lastPingAt)} (code $_lastPingCode)';
                          }
                          return 'Last seen ${_getTimeAgo(_lastLocationUpdate)}';
                        }
                        return 'No location available';
                      }(),
                      style: TextStyle(
                        color: AppTheme.neutralGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTracking)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.my_location,
                    'Coordinates',
                    '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.speed,
                    'Accuracy',
                    '±${location.accuracy.toStringAsFixed(0)}m',
                  ),
                  if (widget.device.hasCapability(
                    GadgetCapability.batteryLevel,
                  )) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.battery_std,
                      'Battery',
                      widget.device.batteryStatusText,
                    ),
                  ],
                  if (_pingHistory.isNotEmpty) ...[
                    const Divider(height: 16, color: Colors.grey),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Pings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._pingHistory.reversed.take(3).map((p) {
                      DateTime? ts;
                      try {
                        ts = DateTime.parse(p['timestamp'] as String);
                      } catch (_) {}
                      final age = _getTimeAgo(ts);
                      final code = p['code'];
                      final acc = p['accuracy'];
                      return _buildInfoRow(
                        Icons.bolt,
                        'Ping $code',
                        '$age • ±${(acc as double).toStringAsFixed(0)}m',
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neutralGray, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final location = _currentLocation ?? _lastKnownLocation;

    if (location == null) {
      return Container(
        color: AppTheme.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: AppTheme.neutralGray),
              const SizedBox(height: 16),
              Text(
                'No Location Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Device location is not available',
                style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Simple location display with map preview
    return Container(
      color: AppTheme.cardBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isTracking ? Icons.gps_fixed : Icons.location_on,
            size: 80,
            color: _isTracking ? AppTheme.accentGreen : AppTheme.primaryRed,
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isTracking ? AppTheme.accentGreen : AppTheme.primaryRed,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLocationDetail(
                  Icons.pin_drop,
                  'Latitude',
                  location.latitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 8),
                _buildLocationDetail(
                  Icons.pin_drop,
                  'Longitude',
                  location.longitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 8),
                _buildLocationDetail(
                  Icons.speed,
                  'Accuracy',
                  '±${location.accuracy.toStringAsFixed(0)}m',
                ),
                if (_isTracking && _locationHistory.length > 1) ...[
                  const SizedBox(height: 8),
                  _buildLocationDetail(
                    Icons.route,
                    'Tracking Points',
                    '${_locationHistory.length}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _getDirections,
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neutralGray, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleLostMode,
                  icon: Icon(_isLostModeEnabled ? Icons.lock_open : Icons.lock),
                  label: Text(
                    _isLostModeEnabled
                        ? 'Disable Lost Mode'
                        : 'Enable Lost Mode',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLostModeEnabled
                        ? AppTheme.accentGreen
                        : AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPinging ? null : _pingForLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(_isPinging ? 'Pinging...' : 'Ping Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side: BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      widget.device.hasCapability(GadgetCapability.speaker)
                      ? _playSound
                      : null,
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('Play Sound'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _currentLocation != null || _lastKnownLocation != null
                      ? _getDirections
                      : null,
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _lockDevice,
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text('Lock Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningOrange,
                    side: BorderSide(color: AppTheme.warningOrange),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _eraseDevice,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Erase Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side: BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'unknown';

    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  void _showTrackingInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tracking Modes'),
        content: const Text(
          'Ping Location performs a one-time precise location fetch and stores a short code without continuous battery drain.\n\nLive Tracking subscribes to continuous updates (higher battery usage). Use it only when actively recovering a device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
