import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_member_location.dart';
import '../models/auth_user.dart';
import 'subscription_service.dart';

/// Service for managing family member location tracking and sharing
class FamilyLocationService {
  FamilyLocationService._();
  static final FamilyLocationService _instance = FamilyLocationService._();
  static FamilyLocationService get instance => _instance;

  // Stream controllers
  final StreamController<List<FamilyMemberLocation>> _locationsController =
      StreamController<List<FamilyMemberLocation>>.broadcast();

  // Current state
  final Map<String, FamilyMemberLocation> _memberLocations = {};
  bool _isInitialized = false;
  bool _isSharing = false;

  // Storage keys
  static const String _locationsKey = 'family_locations';
  static const String _sharingKey = 'location_sharing_enabled';

  // Getters
  Stream<List<FamilyMemberLocation>> get locationsStream =>
      _locationsController.stream;
  List<FamilyMemberLocation> get allLocations =>
      _memberLocations.values.toList();
  bool get isSharing => _isSharing;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('FamilyLocationService: Already initialized');
      return;
    }

    try {
      await _loadLocationData();
      _isInitialized = true;
      debugPrint('FamilyLocationService: Initialized successfully');
    } catch (e) {
      debugPrint('FamilyLocationService: Initialization error - $e');
      rethrow;
    }
  }

  /// Load location data from storage
  Future<void> _loadLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load sharing preference
      _isSharing = prefs.getBool(_sharingKey) ?? false;

      // Load member locations
      final locationsJson = prefs.getString(_locationsKey);
      if (locationsJson != null) {
        final List<dynamic> data = jsonDecode(locationsJson);
        _memberLocations.clear();
        for (var item in data) {
          final location = FamilyMemberLocation.fromJson(item);
          _memberLocations[location.memberId] = location;
        }
      }

      _locationsController.add(allLocations);
      debugPrint(
        'FamilyLocationService: Loaded ${_memberLocations.length} member locations',
      );
    } catch (e) {
      debugPrint('FamilyLocationService: Error loading data - $e');
    }
  }

  /// Save location data to storage
  Future<void> _saveLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = jsonEncode(
        _memberLocations.values.map((loc) => loc.toJson()).toList(),
      );
      await prefs.setString(_locationsKey, locationsJson);
      await prefs.setBool(_sharingKey, _isSharing);
    } catch (e) {
      debugPrint('FamilyLocationService: Error saving data - $e');
    }
  }

  /// Update member location
  Future<void> updateMemberLocation({
    required String memberId,
    required String memberName,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    int? batteryLevel,
  }) async {
    try {
      final location = FamilyMemberLocation(
        memberId: memberId,
        memberName: memberName,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        heading: heading,
        altitude: altitude,
        batteryLevel: batteryLevel,
        timestamp: DateTime.now(),
        isOnline: true,
      );

      _memberLocations[memberId] = location;
      _locationsController.add(allLocations);
      await _saveLocationData();

      debugPrint('FamilyLocationService: Updated location for $memberName');
    } catch (e) {
      debugPrint('FamilyLocationService: Error updating location - $e');
      rethrow;
    }
  }

  /// Get location for specific member
  FamilyMemberLocation? getMemberLocation(String memberId) {
    return _memberLocations[memberId];
  }

  /// Get locations for all online members
  List<FamilyMemberLocation> getOnlineMembers() {
    return _memberLocations.values
        .where((loc) => loc.isOnline && _isLocationRecent(loc))
        .toList();
  }

  /// Check if location is recent (within last 10 minutes)
  bool _isLocationRecent(FamilyMemberLocation location) {
    final now = DateTime.now();
    final diff = now.difference(location.timestamp);
    return diff.inMinutes < 10;
  }

  /// Set member offline
  Future<void> setMemberOffline(String memberId) async {
    try {
      final location = _memberLocations[memberId];
      if (location != null) {
        _memberLocations[memberId] = location.copyWith(isOnline: false);
        _locationsController.add(allLocations);
        await _saveLocationData();
      }
    } catch (e) {
      debugPrint('FamilyLocationService: Error setting member offline - $e');
    }
  }

  /// Enable location sharing
  Future<void> enableSharing() async {
    try {
      _isSharing = true;
      await _saveLocationData();
      debugPrint('FamilyLocationService: Location sharing enabled');
    } catch (e) {
      debugPrint('FamilyLocationService: Error enabling sharing - $e');
      rethrow;
    }
  }

  /// Disable location sharing
  Future<void> disableSharing() async {
    try {
      _isSharing = false;
      await _saveLocationData();
      debugPrint('FamilyLocationService: Location sharing disabled');
    } catch (e) {
      debugPrint('FamilyLocationService: Error disabling sharing - $e');
      rethrow;
    }
  }

  /// Clear member location
  Future<void> clearMemberLocation(String memberId) async {
    try {
      _memberLocations.remove(memberId);
      _locationsController.add(allLocations);
      await _saveLocationData();
      debugPrint(
        'FamilyLocationService: Cleared location for member $memberId',
      );
    } catch (e) {
      debugPrint('FamilyLocationService: Error clearing location - $e');
    }
  }

  /// Clear all locations
  Future<void> clearAllLocations() async {
    try {
      _memberLocations.clear();
      _locationsController.add(allLocations);
      await _saveLocationData();
      debugPrint('FamilyLocationService: Cleared all member locations');
    } catch (e) {
      debugPrint('FamilyLocationService: Error clearing all locations - $e');
    }
  }

  /// Get distance between two members (in meters)
  double? getDistanceBetweenMembers(String memberId1, String memberId2) {
    final loc1 = _memberLocations[memberId1];
    final loc2 = _memberLocations[memberId2];

    if (loc1 == null || loc2 == null) return null;

    return _calculateDistance(
      loc1.latitude,
      loc1.longitude,
      loc2.latitude,
      loc2.longitude,
    );
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Get members within radius of a point (in meters)
  List<FamilyMemberLocation> getMembersInRadius({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) {
    return _memberLocations.values.where((location) {
      final distance = _calculateDistance(
        centerLat,
        centerLon,
        location.latitude,
        location.longitude,
      );
      return distance <= radiusMeters;
    }).toList();
  }

  /// Check if family member is in Family subscription
  Future<bool> canTrackMember(String memberId) async {
    try {
      final subscriptionService = SubscriptionService.instance;
      final family = subscriptionService.currentFamily;

      if (family == null) return false;

      // Check if member exists in family
      final member = family.members.firstWhere(
        (m) => m.userId == memberId,
        orElse: () => FamilyMember(
          id: '',
          userId: '',
          name: '',
          assignedTier: family.plan.tier,
          addedDate: DateTime.now(),
        ),
      );

      return member.id.isNotEmpty && member.isActive;
    } catch (e) {
      debugPrint('FamilyLocationService: Error checking member access - $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _locationsController.close();
  }
}
