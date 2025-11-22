import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for integrating with native map applications on the device
class NativeMapService {
  static final NativeMapService _instance = NativeMapService._internal();
  factory NativeMapService() => _instance;
  NativeMapService._internal();

  bool _isInitialized = false;

  /// Initialize the native map service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint('NativeMapService: Initialized successfully');
    } catch (e) {
      debugPrint('NativeMapService: Initialization error - $e');
      throw Exception('Failed to initialize native map service: $e');
    }
  }

  /// Open native map application with current location
  Future<bool> openCurrentLocation({
    double? latitude,
    double? longitude,
    String? label,
  }) async {
    try {
      if (latitude == null || longitude == null) {
        debugPrint('NativeMapService: No coordinates provided');
        return false;
      }

      final url = _buildMapUrl(latitude, longitude, label);
      return await _launchMapUrl(url);
    } catch (e) {
      debugPrint('NativeMapService: Error opening current location - $e');
      return false;
    }
  }

  /// Open native map application with specific location
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
    String? address,
  }) async {
    try {
      final url = _buildMapUrl(latitude, longitude, label ?? address);
      return await _launchMapUrl(url);
    } catch (e) {
      debugPrint('NativeMapService: Error opening location - $e');
      return false;
    }
  }

  /// Open navigation to specific location
  Future<bool> openNavigation({
    required double latitude,
    required double longitude,
    String? label,
    String? address,
  }) async {
    try {
      final url = _buildNavigationUrl(latitude, longitude, label ?? address);
      return await _launchMapUrl(url);
    } catch (e) {
      debugPrint('NativeMapService: Error opening navigation - $e');
      return false;
    }
  }

  /// Open directions from current location to destination
  Future<bool> openDirections({
    required double destinationLatitude,
    required double destinationLongitude,
    String? destinationLabel,
    double? sourceLatitude,
    double? sourceLongitude,
    String? sourceLabel,
  }) async {
    try {
      final url = _buildDirectionsUrl(
        destinationLatitude,
        destinationLongitude,
        destinationLabel,
        sourceLatitude,
        sourceLongitude,
        sourceLabel,
      );
      return await _launchMapUrl(url);
    } catch (e) {
      debugPrint('NativeMapService: Error opening directions - $e');
      return false;
    }
  }

  /// Open search for nearby places
  Future<bool> openNearbySearch({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = _buildSearchUrl(query, latitude, longitude);
      return await _launchMapUrl(url);
    } catch (e) {
      debugPrint('NativeMapService: Error opening nearby search - $e');
      return false;
    }
  }

  /// Build map URL based on platform
  String _buildMapUrl(double latitude, double longitude, String? label) {
    if (Platform.isIOS) {
      // iOS - try Apple Maps first, fallback to Google Maps
      return _buildAppleMapsUrl(latitude, longitude, label);
    } else if (Platform.isAndroid) {
      // Android - try Google Maps first, fallback to other apps
      return _buildGoogleMapsUrl(latitude, longitude, label);
    } else {
      // Web/Desktop - use Google Maps
      return _buildGoogleMapsUrl(latitude, longitude, label);
    }
  }

  /// Build navigation URL based on platform
  String _buildNavigationUrl(double latitude, double longitude, String? label) {
    if (Platform.isIOS) {
      return _buildAppleMapsNavigationUrl(latitude, longitude, label);
    } else if (Platform.isAndroid) {
      return _buildGoogleMapsNavigationUrl(latitude, longitude, label);
    } else {
      return _buildGoogleMapsNavigationUrl(latitude, longitude, label);
    }
  }

  /// Build directions URL
  String _buildDirectionsUrl(
    double destinationLatitude,
    double destinationLongitude,
    String? destinationLabel,
    double? sourceLatitude,
    double? sourceLongitude,
    String? sourceLabel,
  ) {
    if (Platform.isIOS) {
      return _buildAppleMapsDirectionsUrl(
        destinationLatitude,
        destinationLongitude,
        destinationLabel,
        sourceLatitude,
        sourceLongitude,
        sourceLabel,
      );
    } else if (Platform.isAndroid) {
      return _buildGoogleMapsDirectionsUrl(
        destinationLatitude,
        destinationLongitude,
        destinationLabel,
        sourceLatitude,
        sourceLongitude,
        sourceLabel,
      );
    } else {
      return _buildGoogleMapsDirectionsUrl(
        destinationLatitude,
        destinationLongitude,
        destinationLabel,
        sourceLatitude,
        sourceLongitude,
        sourceLabel,
      );
    }
  }

  /// Build search URL
  String _buildSearchUrl(String query, double? latitude, double? longitude) {
    if (Platform.isIOS) {
      return _buildAppleMapsSearchUrl(query, latitude, longitude);
    } else if (Platform.isAndroid) {
      return _buildGoogleMapsSearchUrl(query, latitude, longitude);
    } else {
      return _buildGoogleMapsSearchUrl(query, latitude, longitude);
    }
  }

  /// Apple Maps URL for viewing location
  String _buildAppleMapsUrl(double latitude, double longitude, String? label) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    return 'https://maps.apple.com/?q=$encodedLabel&ll=$latitude,$longitude';
  }

  /// Apple Maps URL for navigation
  String _buildAppleMapsNavigationUrl(
    double latitude,
    double longitude,
    String? label,
  ) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    return 'https://maps.apple.com/?daddr=$encodedLabel&ll=$latitude,$longitude';
  }

  /// Apple Maps URL for directions
  String _buildAppleMapsDirectionsUrl(
    double destinationLatitude,
    double destinationLongitude,
    String? destinationLabel,
    double? sourceLatitude,
    double? sourceLongitude,
    String? sourceLabel,
  ) {
    final encodedDestination = destinationLabel != null
        ? Uri.encodeComponent(destinationLabel)
        : '$destinationLatitude,$destinationLongitude';

    if (sourceLatitude != null && sourceLongitude != null) {
      final encodedSource = sourceLabel != null
          ? Uri.encodeComponent(sourceLabel)
          : '$sourceLatitude,$sourceLongitude';
      return 'https://maps.apple.com/?saddr=$encodedSource&daddr=$encodedDestination';
    } else {
      return 'https://maps.apple.com/?daddr=$encodedDestination';
    }
  }

  /// Apple Maps URL for search
  String _buildAppleMapsSearchUrl(
    String query,
    double? latitude,
    double? longitude,
  ) {
    final encodedQuery = Uri.encodeComponent(query);
    if (latitude != null && longitude != null) {
      return 'https://maps.apple.com/?q=$encodedQuery&ll=$latitude,$longitude';
    } else {
      return 'https://maps.apple.com/?q=$encodedQuery';
    }
  }

  /// Google Maps URL for viewing location
  String _buildGoogleMapsUrl(double latitude, double longitude, String? label) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedLabel';
  }

  /// Google Maps URL for navigation
  String _buildGoogleMapsNavigationUrl(
    double latitude,
    double longitude,
    String? label,
  ) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$encodedLabel';
  }

  /// Google Maps URL for directions
  String _buildGoogleMapsDirectionsUrl(
    double destinationLatitude,
    double destinationLongitude,
    String? destinationLabel,
    double? sourceLatitude,
    double? sourceLongitude,
    String? sourceLabel,
  ) {
    if (sourceLatitude != null && sourceLongitude != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$sourceLatitude,$sourceLongitude&destination=$destinationLatitude,$destinationLongitude';
    } else {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude';
    }
  }

  /// Google Maps URL for search
  String _buildGoogleMapsSearchUrl(
    String query,
    double? latitude,
    double? longitude,
  ) {
    final encodedQuery = Uri.encodeComponent(query);
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$encodedQuery&ll=$latitude,$longitude';
    } else {
      return 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
    }
  }

  /// Launch map URL
  Future<bool> _launchMapUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('NativeMapService: Map launched - $launched');
        return launched;
      } else {
        debugPrint('NativeMapService: Cannot launch map URL - $url');
        return false;
      }
    } catch (e) {
      debugPrint('NativeMapService: Error launching map URL - $e');
      return false;
    }
  }

  /// Check if native map apps are available
  Future<bool> isMapAppAvailable() async {
    try {
      // Test with a simple location URL
      final testUrl = Platform.isIOS
          ? 'https://maps.apple.com/?ll=37.7749,-122.4194'
          : 'https://www.google.com/maps/?ll=37.7749,-122.4194';

      final uri = Uri.parse(testUrl);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('NativeMapService: Error checking map availability - $e');
      return false;
    }
  }

  /// Get available map applications
  Future<List<String>> getAvailableMapApps() async {
    final apps = <String>[];

    try {
      // Check Apple Maps (iOS)
      if (Platform.isIOS) {
        final appleMapsUrl = Uri.parse(
          'https://maps.apple.com/?ll=37.7749,-122.4194',
        );
        if (await canLaunchUrl(appleMapsUrl)) {
          apps.add('Apple Maps');
        }
      }

      // Check Google Maps
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/?ll=37.7749,-122.4194',
      );
      if (await canLaunchUrl(googleMapsUrl)) {
        apps.add('Google Maps');
      }

      // Check Waze (if available)
      final wazeUrl = Uri.parse('waze://?ll=37.7749,-122.4194');
      if (await canLaunchUrl(wazeUrl)) {
        apps.add('Waze');
      }

      debugPrint('NativeMapService: Available map apps - $apps');
    } catch (e) {
      debugPrint('NativeMapService: Error getting available map apps - $e');
    }

    return apps;
  }

  // Getters
  bool get isInitialized => _isInitialized;
}
