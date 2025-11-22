import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import '../core/constants/app_constants.dart';
import '../models/sos_session.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import 'connectivity_monitor_service.dart';
import 'app_service_manager.dart';
import 'sensor_service.dart';

/// Service for handling GPS location tracking and breadcrumb trail
class LocationService {
  // Battery saver: adaptive throttling
  Timer? _adaptiveThrottleTimer;
  bool _isStationary = false;

  /// Call this to enable adaptive battery saving
  void enableAdaptiveBatterySaving() {
    _adaptiveThrottleTimer?.cancel();
    _adaptiveThrottleTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      // Check last known position and motion
      if (_currentPosition != null) {
        // If stationary, reduce update frequency
        if (_isStationary) {
          _stopLocationUpdates();
          debugPrint(
            'LocationService: Stationary, location updates paused for battery savings',
          );
        } else {
          if (!_isTracking) {
            _startLocationUpdates();
            debugPrint(
              'LocationService: Motion detected, location updates resumed',
            );
          }
        }
      }
    });
  }

  /// Call this to disable adaptive battery saving
  void disableAdaptiveBatterySaving() {
    _adaptiveThrottleTimer?.cancel();
  }

  /// Motion-triggered wake logic
  void onMotionDetected(double acceleration) {
    if (acceleration > 2.0) {
      // threshold for significant movement
      _isStationary = false;
      if (!_isTracking) {
        _startLocationUpdates();
        debugPrint('LocationService: Woken by motion');
      }
    } else {
      _isStationary = true;
      _stopLocationUpdates();
      debugPrint('LocationService: Hibernated by lack of motion');
    }
  }

  /// Hibernate location service (pause all location updates)
  void hibernate() {
    _stopLocationUpdates();
    debugPrint('LocationService: Hibernated');
  }

  /// Wake location service (resume location updates if needed)
  void wake({bool sosActive = false, bool userRequested = false}) {
    if (sosActive || userRequested) {
      _startLocationUpdates();
      debugPrint('LocationService: Woken up');
    } else {
      hibernate();
    }
  }

  /// Public method to start location tracking
  Future<void> startTracking() async {
    await _startLocationUpdates();
  }

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static bool _isInitializing = false;

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  LocationInfo? _currentLocationInfo;
  final List<BreadcrumbPoint> _breadcrumbTrail = [];

  bool _isTracking = false;
  bool _hasPermission = false;
  bool _isLocationServiceEnabled = false;
  // User-requested flag for location updates
  bool _userRequestedLocationUpdates = false;
  DateTime? _lastLocationUpdate;
  DateTime? _lastLocationRequest;
  static const Duration _locationCacheTimeout = Duration(minutes: 5);
  static const Duration _requestDebounceTimeout = Duration(seconds: 10);

  // GPS and permission status
  LocationPermission _currentPermission = LocationPermission.denied;
  bool _locationServiceStatus = false;

  // Callbacks
  Function(LocationInfo)? _onLocationUpdate;
  Function(String)? _onLocationError;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      debugPrint('LocationService: Already initializing, waiting...');
      // Wait for current initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _hasPermission;
    }

    if (_hasPermission) {
      debugPrint('LocationService: Already initialized');
      return true;
    }

    _isInitializing = true;
    try {
      // Check and enable location services
      final serviceEnabled = await _checkAndEnableLocationServices();
      if (!serviceEnabled) {
        _onLocationError?.call('Location services are disabled');
        return false;
      }

      // Check and request permissions
      final permissionGranted = await _checkAndRequestPermissions();
      if (!permissionGranted) {
        _onLocationError?.call('Location permissions are denied');
        return false;
      }

      _hasPermission = true;
      _isLocationServiceEnabled = true;
      AppLogger.i('Initialized successfully', tag: 'LocationService');
      ConnectivityMonitorService().offlineStream.listen((isOffline) {
        final sosActive = AppServiceManager().sosService.isSOSActive;
        if (isOffline && (sosActive || _userRequestedLocationUpdates)) {
          // Only update location when offline AND SOS is active or user requests
          _startLocationUpdates();
        } else {
          // Stop location updates otherwise
          _stopLocationUpdates();
        }
      });

      return true;
    } catch (e) {
      AppLogger.e('Initialization error', tag: 'LocationService', error: e);
      _onLocationError?.call('Failed to initialize location service: $e');
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startLocationUpdates() async {
    if (_isTracking) return;

    if (!_hasPermission) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: const Duration(seconds: 30),
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _handlePositionUpdate,
            onError: (error) {
              debugPrint('LocationService: Position stream error - $error');
              _onLocationError?.call('Location tracking error: $error');
            },
          );

      _isTracking = true;
      debugPrint('LocationService: Started tracking');
    } catch (e) {
      debugPrint('LocationService: Error starting tracking - $e');
      _onLocationError?.call('Failed to start location tracking: $e');
    }
  }

  void _stopLocationUpdates() {
    _adaptiveThrottleTimer?.cancel();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    debugPrint('LocationService: Stopped tracking');
  }

  /// Check and enable location services
  Future<bool> _checkAndEnableLocationServices() async {
    try {
      _locationServiceStatus = await Geolocator.isLocationServiceEnabled();
      _isLocationServiceEnabled = _locationServiceStatus;

      if (!_isLocationServiceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        // Try to open location settings
        await _openLocationSettings();
        return false;
      }

      debugPrint('LocationService: Location services are enabled');
      return true;
    } catch (e) {
      debugPrint('LocationService: Error checking location services - $e');
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      // Check current permission status
      _currentPermission = await Geolocator.checkPermission();
      debugPrint(
        'LocationService: Current permission status: $_currentPermission',
      );

      if (_currentPermission == LocationPermission.denied) {
        // Request permission
        _currentPermission = await Geolocator.requestPermission();
        debugPrint(
          'LocationService: Requested permission, new status: $_currentPermission',
        );

        if (_currentPermission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied by user');
          return false;
        }
      }

      if (_currentPermission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission permanently denied');
        // Try to open app settings
        await _openAppSettings();
        return false;
      }

      if (_currentPermission == LocationPermission.whileInUse ||
          _currentPermission == LocationPermission.always) {
        debugPrint('LocationService: Permission granted');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('LocationService: Error checking permissions - $e');
      return false;
    }
  }

  /// Open location settings
  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      debugPrint('LocationService: Opened location settings');
    } catch (e) {
      debugPrint('LocationService: Failed to open location settings - $e');
    }
  }

  /// Open app settings for permission management
  Future<void> _openAppSettings() async {
    try {
      await permission_handler.openAppSettings();
      debugPrint('LocationService: Opened app settings');
    } catch (e) {
      debugPrint('LocationService: Failed to open app settings - $e');
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    debugPrint('LocationService: Stopped tracking');
  }

  /// Handle position updates
  void _handlePositionUpdate(Position position) async {
    _currentPosition = position;

    // Update sensor service with speed and altitude for airplane detection
    try {
      final sensorService = SensorService();
      final speedKmh = position.speed * 3.6; // Convert m/s to km/h
      sensorService.updateLocationData(
        speed: speedKmh,
        altitude: position.altitude,
      );
    } catch (e) {
      debugPrint('LocationService: Error updating sensor service - $e');
    }

    // Create breadcrumb point
    final breadcrumbPoint = BreadcrumbPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed,
    );

    // Add to trail and limit size
    _addToBreadcrumbTrail(breadcrumbPoint);

    // Get address (optional, may be slow)
    String? address;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
    } catch (e) {
      debugPrint('LocationService: Geocoding error - $e');
    }

    // Create location info
    _currentLocationInfo = LocationInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: DateTime.now(),
      address: address,
      breadcrumbTrail: List.from(_breadcrumbTrail),
    );

    debugPrint(
      'LocationService: Location updated - ${position.latitude}, ${position.longitude}',
    );
    _onLocationUpdate?.call(_currentLocationInfo!);
  }

  /// Add point to breadcrumb trail
  void _addToBreadcrumbTrail(BreadcrumbPoint point) {
    _breadcrumbTrail.add(point);

    // Limit trail size
    while (_breadcrumbTrail.length > AppConstants.breadcrumbTrailMaxPoints) {
      _breadcrumbTrail.removeAt(0);
    }
  }

  /// Get current position (one-time request)
  Future<LocationInfo?> getCurrentLocation({
    bool highAccuracy = true,
    bool forceFresh = false,
  }) async {
    if (!_hasPermission) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    // Debounce rapid requests
    final now = DateTime.now();
    if (!forceFresh && _lastLocationRequest != null) {
      final timeSinceLastRequest = now.difference(_lastLocationRequest!);
      if (timeSinceLastRequest < _requestDebounceTimeout) {
        if (kDebugMode) {
          debugPrint('LocationService: Request debounced (too frequent)');
        }
        return _currentLocationInfo;
      }
    }
    _lastLocationRequest = now;

    // Check if we have a recent cached location
    if (!forceFresh &&
        _currentLocationInfo != null &&
        _lastLocationUpdate != null) {
      final timeSinceLastUpdate = now.difference(_lastLocationUpdate!);
      if (timeSinceLastUpdate < _locationCacheTimeout) {
        // Reduced logging to prevent spam
        if (kDebugMode) {
          debugPrint('LocationService: Using cached location');
        }
        return _currentLocationInfo;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy
            ? LocationAccuracy.best
            : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Reduced timeout
      );

      // Get address
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address =
              '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        }
      } catch (e) {
        debugPrint('LocationService: Geocoding error - $e');
      }

      final locationInfo = LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
        address: address,
        breadcrumbTrail: List.from(_breadcrumbTrail),
      );

      _currentLocationInfo = locationInfo;
      _lastLocationUpdate = DateTime.now();
      debugPrint(
        'LocationService: Got current location - ${position.latitude}, ${position.longitude}',
      );
      return locationInfo;
    } catch (e) {
      debugPrint('LocationService: Error getting current location - $e');
      _onLocationError?.call('Failed to get current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if location accuracy is acceptable
  bool isLocationAccurate(LocationInfo location) {
    return location.accuracy <= AppConstants.locationAccuracyThreshold;
  }

  /// Get location status information
  Map<String, dynamic> getLocationStatus() {
    return {
      'isTracking': _isTracking,
      'hasPermission': _hasPermission,
      'currentLocation': _currentLocationInfo?.toJson(),
      'breadcrumbTrailLength': _breadcrumbTrail.length,
      'lastUpdate': _currentLocationInfo?.timestamp.toIso8601String(),
    };
  }

  /// Clear breadcrumb trail
  void clearBreadcrumbTrail() {
    _breadcrumbTrail.clear();
    debugPrint('LocationService: Breadcrumb trail cleared');
  }

  /// Export breadcrumb trail
  List<BreadcrumbPoint> exportBreadcrumbTrail() {
    return List.from(_breadcrumbTrail);
  }

  /// Import breadcrumb trail
  void importBreadcrumbTrail(List<BreadcrumbPoint> trail) {
    _breadcrumbTrail.clear();
    _breadcrumbTrail.addAll(trail);
    debugPrint('LocationService: Imported ${trail.length} breadcrumb points');
  }

  /// Get trail statistics
  Map<String, dynamic> getTrailStatistics() {
    if (_breadcrumbTrail.isEmpty) {
      return {
        'totalPoints': 0,
        'totalDistance': 0.0,
        'duration': 0,
        'averageSpeed': 0.0,
      };
    }

    double totalDistance = 0.0;
    double totalSpeed = 0.0;
    int speedCount = 0;

    for (int i = 1; i < _breadcrumbTrail.length; i++) {
      final prev = _breadcrumbTrail[i - 1];
      final curr = _breadcrumbTrail[i];

      totalDistance += calculateDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      if (curr.speed != null && curr.speed! > 0) {
        totalSpeed += curr.speed!;
        speedCount++;
      }
    }

    final duration = _breadcrumbTrail.last.timestamp
        .difference(_breadcrumbTrail.first.timestamp)
        .inSeconds;

    return {
      'totalPoints': _breadcrumbTrail.length,
      'totalDistance': totalDistance,
      'duration': duration,
      'averageSpeed': speedCount > 0 ? totalSpeed / speedCount : 0.0,
    };
  }

  // Getters
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  Position? get currentPosition => _currentPosition;
  LocationInfo? get currentLocationInfo => _currentLocationInfo;
  List<BreadcrumbPoint> get breadcrumbTrail => List.from(_breadcrumbTrail);

  // Event handlers
  void setLocationUpdateCallback(Function(LocationInfo) callback) {
    _onLocationUpdate = callback;
  }

  void setLocationErrorCallback(Function(String) callback) {
    _onLocationError = callback;
  }

  /// Get current location (static method)
  static Future<Position> getCurrentLocationStatic() async {
    try {
      // STEP 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        // Try to open location settings
        await Geolocator.openLocationSettings();
        throw Exception(
          'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // STEP 2: Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('LocationService: Current permission status: $permission');

      // STEP 3: Request permission if needed
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permissions are denied');
          throw Exception(
            'Location permissions are denied. Please grant location access in your device settings.',
          );
        }
      }

      // STEP 4: Handle permanently denied
      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'LocationService: Location permissions are permanently denied',
        );
        // Open app settings
        await Geolocator.openAppSettings();
        throw Exception(
          'Location permissions are permanently denied. Please enable location access in app settings.',
        );
      }

      // STEP 5: Permission granted, get location
      debugPrint('LocationService: Permission granted, getting location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
        'LocationService: ✅ Location obtained: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('LocationService: ❌ Failed to get current location - $e');
      rethrow;
    }
  }

  /// Open phone's map app with location
  static Future<void> openMapApp(double lat, double lng) async {
    try {
      final url = 'https://maps.google.com/maps?q=$lat,$lng';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('LocationService: Opened map app with location $lat, $lng');
      } else {
        debugPrint('LocationService: Could not launch map app');
      }
    } catch (e) {
      debugPrint('LocationService: Failed to open map app - $e');
    }
  }

  /// Open map app with navigation to location
  static Future<void> openMapWithNavigation(double lat, double lng) async {
    try {
      final url =
          'https://maps.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('LocationService: Opened map with navigation to $lat, $lng');
      } else {
        debugPrint('LocationService: Could not launch map navigation');
      }
    } catch (e) {
      debugPrint('LocationService: Failed to open map navigation - $e');
    }
  }

  /// Open map app with multiple waypoints
  static Future<void> openMapWithWaypoints(
    List<Map<String, double>> waypoints,
  ) async {
    try {
      if (waypoints.isEmpty) return;

      String url = 'https://maps.google.com/maps/dir/';
      for (int i = 0; i < waypoints.length; i++) {
        final point = waypoints[i];
        url += '${point['lat']},${point['lng']}';
        if (i < waypoints.length - 1) url += '/';
      }
      url += '/@${waypoints.first['lat']},${waypoints.first['lng']},15z';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint(
          'LocationService: Opened map with ${waypoints.length} waypoints',
        );
      } else {
        debugPrint('LocationService: Could not launch map with waypoints');
      }
    } catch (e) {
      debugPrint('LocationService: Failed to open map with waypoints - $e');
    }
  }

  /// Reverse geocode coordinates into a readable address (best-effort)
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if ((p.street ?? '').isNotEmpty) p.street,
          if ((p.locality ?? '').isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea,
          if ((p.country ?? '').isNotEmpty) p.country,
        ];
        return parts
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .join(', ');
      }
    } catch (e) {
      debugPrint('LocationService: reverseGeocode failed - $e');
    }
    return null;
  }

  /// Open map app with search query
  static Future<void> openMapWithSearch(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://maps.google.com/maps/search/?api=1&query=$encodedQuery';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('LocationService: Opened map with search: $query');
      } else {
        debugPrint('LocationService: Could not launch map search');
      }
    } catch (e) {
      debugPrint('LocationService: Failed to open map search - $e');
    }
  }

  /// Send location to SAR system
  static Future<void> sendLocationToSAR(double lat, double lng) async {
    try {
      // Get current user ID
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      // Send to Firebase
      await firebaseService.updateUserLocation(
        userId,
        lat,
        lng,
        10.0, // Default accuracy
      );

      // Send to SAR service
      final sarService = SARService();
      final locationInfo = LocationInfo(
        latitude: lat,
        longitude: lng,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      await sarService.addLocationUpdate(locationInfo);

      debugPrint('LocationService: Location sent to SAR system - $lat, $lng');
    } catch (e) {
      debugPrint('LocationService: Failed to send location to SAR - $e');
    }
  }

  /// Get comprehensive service status
  Map<String, dynamic> getStatus() {
    return {
      'isTracking': _isTracking,
      'hasPermission': _hasPermission,
      'isLocationServiceEnabled': _isLocationServiceEnabled,
      'currentPermission': _currentPermission.toString(),
      'locationServiceStatus': _locationServiceStatus.toString(),
      'currentPosition': _currentPosition?.toJson(),
      'breadcrumbCount': _breadcrumbTrail.length,
      'lastLocationUpdate': _lastLocationUpdate?.toIso8601String(),
    };
  }

  /// Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationServiceEnabled = serviceEnabled;
      return serviceEnabled;
    } catch (e) {
      debugPrint(
        'LocationService: Error checking location service availability - $e',
      );
      return false;
    }
  }

  /// Check current permission status
  Future<LocationPermission> getCurrentPermissionStatus() async {
    try {
      _currentPermission = await Geolocator.checkPermission();
      return _currentPermission;
    } catch (e) {
      debugPrint('LocationService: Error checking permission status - $e');
      return LocationPermission.denied;
    }
  }

  /// Check if we have location permission
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await getCurrentPermissionStatus();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('LocationService: Error checking location permission - $e');
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      _currentPermission = permission;

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission permanently denied');
        await _openAppSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('LocationService: Error requesting location permission - $e');
      return false;
    }
  }

  /// Get location accuracy information
  Future<Map<String, dynamic>> getLocationAccuracy() async {
    try {
      if (_currentPosition == null) {
        return {'error': 'No current position available'};
      }

      return {
        'accuracy': _currentPosition!.accuracy,
        'altitude': _currentPosition!.altitude,
        'altitudeAccuracy': _currentPosition!.altitudeAccuracy,
        'heading': _currentPosition!.heading,
        'headingAccuracy': _currentPosition!.headingAccuracy,
        'speed': _currentPosition!.speed,
        'speedAccuracy': _currentPosition!.speedAccuracy,
        'timestamp': _currentPosition!.timestamp.toIso8601String(),
      };
    } catch (e) {
      debugPrint('LocationService: Error getting location accuracy - $e');
      return {'error': e.toString()};
    }
  }

  /// Get distance between two points
  static double getDistanceBetweenPoints(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Get bearing between two points
  static double getBearingBetweenPoints(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.bearingBetween(lat1, lng1, lat2, lng2);
  }

  /// Dispose of the service
  void dispose() {
    stopTracking();
  }

  /// Allow user to manually request location updates
  void setUserRequestedLocationUpdates(bool requested) {
    _userRequestedLocationUpdates = requested;
    final isOffline = true; // Should be set based on actual connectivity status
    final sosActive = AppServiceManager().sosService.isSOSActive;
    if (isOffline && (sosActive || _userRequestedLocationUpdates)) {
      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }
  }
}
