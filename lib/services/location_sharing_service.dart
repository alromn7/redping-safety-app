import 'dart:async';
import 'package:flutter/foundation.dart';
import 'location_service.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import '../models/sos_session.dart';

/// Service for sharing location with SAR teams
class LocationSharingService {
  static final LocationSharingService _instance =
      LocationSharingService._internal();
  factory LocationSharingService() => _instance;
  LocationSharingService._internal();

  bool _isInitialized = false;
  FirebaseService? _firebaseService;
  SARService? _sarService;

  /// Initialize the location sharing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('LocationSharingService: Initializing...');

    try {
      _firebaseService = FirebaseService();
      _sarService = SARService();

      _isInitialized = true;
      debugPrint('LocationSharingService: Initialized successfully');
    } catch (e) {
      debugPrint('LocationSharingService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Share current location with SAR teams
  static Future<void> shareLocationWithSAR() async {
    try {
      debugPrint(
        'LocationSharingService: Starting location sharing with SAR teams...',
      );

      // 1. Get current location
      final location = await LocationService.getCurrentLocationStatic();
      debugPrint(
        'LocationSharingService: Got location - ${location.latitude}, ${location.longitude}',
      );

      // 2. Send to Firebase (real-time)
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      await firebaseService.updateUserLocation(
        userId,
        location.latitude,
        location.longitude,
        location.accuracy,
      );
      debugPrint('LocationSharingService: Location sent to Firebase');

      // 3. Send to SAR service
      final sarService = SARService();
      final locationInfo = LocationInfo(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        timestamp: DateTime.now(),
      );
      await sarService.addLocationUpdate(locationInfo);
      debugPrint('LocationSharingService: Location sent to SAR service');

      // 4. Open phone map for user
      await LocationService.openMapApp(location.latitude, location.longitude);
      debugPrint('LocationSharingService: Map app opened with location');

      debugPrint(
        'LocationSharingService: Location sharing completed successfully',
      );
    } catch (e) {
      debugPrint('LocationSharingService: Failed to share location - $e');
      rethrow;
    }
  }

  /// Share location with specific SAR team
  static Future<void> shareLocationWithTeam(String teamId) async {
    try {
      debugPrint(
        'LocationSharingService: Sharing location with SAR team: $teamId',
      );

      // Get current location
      final location = await LocationService.getCurrentLocationStatic();

      // Send to Firebase with team context
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      await firebaseService.updateUserLocation(
        userId,
        location.latitude,
        location.longitude,
        location.accuracy,
      );

      // Send to SAR service with team context
      final sarService = SARService();
      final locationInfo = LocationInfo(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        timestamp: DateTime.now(),
      );
      await sarService.addLocationUpdate(locationInfo);

      // Open map with team context
      await LocationService.openMapApp(location.latitude, location.longitude);

      debugPrint(
        'LocationSharingService: Location shared with SAR team: $teamId',
      );
    } catch (e) {
      debugPrint(
        'LocationSharingService: Failed to share location with team - $e',
      );
      rethrow;
    }
  }

  /// Share location with emergency contacts
  static Future<void> shareLocationWithContacts() async {
    try {
      debugPrint(
        'LocationSharingService: Sharing location with emergency contacts...',
      );

      // Get current location
      final location = await LocationService.getCurrentLocationStatic();

      // Send to Firebase
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      await firebaseService.updateUserLocation(
        userId,
        location.latitude,
        location.longitude,
        location.accuracy,
      );

      // Send to SAR service
      final sarService = SARService();
      final locationInfo = LocationInfo(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        timestamp: DateTime.now(),
      );
      await sarService.addLocationUpdate(locationInfo);

      // Open map for user
      await LocationService.openMapApp(location.latitude, location.longitude);

      debugPrint(
        'LocationSharingService: Location shared with emergency contacts',
      );
    } catch (e) {
      debugPrint(
        'LocationSharingService: Failed to share location with contacts - $e',
      );
      rethrow;
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'firebaseService': _firebaseService != null,
      'sarService': _sarService != null,
    };
  }

  /// Dispose of resources
  void dispose() {
    _isInitialized = false;
    _firebaseService = null;
    _sarService = null;
  }
}
