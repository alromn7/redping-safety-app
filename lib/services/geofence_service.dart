import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_member_location.dart';

/// Service for managing geofence zones and alerts
class GeofenceService {
  GeofenceService._();
  static final GeofenceService _instance = GeofenceService._();
  static GeofenceService get instance => _instance;

  // Stream controllers
  final StreamController<List<GeofenceZone>> _zonesController =
      StreamController<List<GeofenceZone>>.broadcast();
  final StreamController<GeofenceAlert> _alertController =
      StreamController<GeofenceAlert>.broadcast();

  // Current state
  final Map<String, GeofenceZone> _zones = {};
  final Map<String, Set<String>> _memberZoneStatus =
      {}; // memberId -> Set of zone IDs they're in
  bool _isInitialized = false;

  // Storage keys
  static const String _zonesKey = 'geofence_zones';

  // Getters
  Stream<List<GeofenceZone>> get zonesStream => _zonesController.stream;
  Stream<GeofenceAlert> get alertStream => _alertController.stream;
  List<GeofenceZone> get allZones => _zones.values.toList();
  List<GeofenceZone> get activeZones =>
      _zones.values.where((zone) => zone.isActive).toList();
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('GeofenceService: Already initialized');
      return;
    }

    try {
      await _loadZones();
      _isInitialized = true;
      debugPrint('GeofenceService: Initialized successfully');
    } catch (e) {
      debugPrint('GeofenceService: Initialization error - $e');
      rethrow;
    }
  }

  /// Load zones from storage
  Future<void> _loadZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = prefs.getString(_zonesKey);

      if (zonesJson != null) {
        final List<dynamic> data = jsonDecode(zonesJson);
        _zones.clear();
        for (var item in data) {
          final zone = GeofenceZone.fromJson(item);
          _zones[zone.id] = zone;
        }
      }

      _zonesController.add(allZones);
      debugPrint('GeofenceService: Loaded ${_zones.length} zones');
    } catch (e) {
      debugPrint('GeofenceService: Error loading zones - $e');
    }
  }

  /// Save zones to storage
  Future<void> _saveZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = jsonEncode(
        _zones.values.map((zone) => zone.toJson()).toList(),
      );
      await prefs.setString(_zonesKey, zonesJson);
    } catch (e) {
      debugPrint('GeofenceService: Error saving zones - $e');
    }
  }

  /// Create a new geofence zone
  Future<GeofenceZone> createZone({
    required String name,
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
    required String createdBy,
    String? description,
    String? color,
    bool alertOnEntry = false,
    bool alertOnExit = true,
    List<String>? allowedMembers,
  }) async {
    try {
      final zone = GeofenceZone(
        id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        centerLat: centerLat,
        centerLon: centerLon,
        radiusMeters: radiusMeters,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        description: description,
        color: color,
        alertOnEntry: alertOnEntry,
        alertOnExit: alertOnExit,
        allowedMembers: allowedMembers ?? [],
      );

      _zones[zone.id] = zone;
      _zonesController.add(allZones);
      await _saveZones();

      debugPrint('GeofenceService: Created zone "${zone.name}"');
      return zone;
    } catch (e) {
      debugPrint('GeofenceService: Error creating zone - $e');
      rethrow;
    }
  }

  /// Update an existing zone
  Future<void> updateZone(GeofenceZone zone) async {
    try {
      _zones[zone.id] = zone;
      _zonesController.add(allZones);
      await _saveZones();
      debugPrint('GeofenceService: Updated zone "${zone.name}"');
    } catch (e) {
      debugPrint('GeofenceService: Error updating zone - $e');
      rethrow;
    }
  }

  /// Delete a zone
  Future<void> deleteZone(String zoneId) async {
    try {
      final zone = _zones.remove(zoneId);
      if (zone != null) {
        _zonesController.add(allZones);
        await _saveZones();
        debugPrint('GeofenceService: Deleted zone "${zone.name}"');
      }
    } catch (e) {
      debugPrint('GeofenceService: Error deleting zone - $e');
      rethrow;
    }
  }

  /// Get zone by ID
  GeofenceZone? getZone(String zoneId) {
    return _zones[zoneId];
  }

  /// Check if a location is within a zone
  bool isLocationInZone({
    required double lat,
    required double lon,
    required GeofenceZone zone,
  }) {
    final distance = _calculateDistance(
      lat,
      lon,
      zone.centerLat,
      zone.centerLon,
    );
    return distance <= zone.radiusMeters;
  }

  /// Check member location against all zones
  Future<void> checkMemberLocation({
    required String memberId,
    required String memberName,
    required double lat,
    required double lon,
  }) async {
    try {
      final currentZones = _memberZoneStatus[memberId] ?? {};
      final newZones = <String>{};

      for (var zone in activeZones) {
        // Check if member is allowed in this zone (empty list = all allowed)
        if (zone.allowedMembers.isNotEmpty &&
            !zone.allowedMembers.contains(memberId)) {
          continue;
        }

        final isInZone = isLocationInZone(lat: lat, lon: lon, zone: zone);

        if (isInZone) {
          newZones.add(zone.id);

          // Trigger entry alert if member just entered
          if (!currentZones.contains(zone.id) && zone.alertOnEntry) {
            _triggerAlert(
              memberId: memberId,
              memberName: memberName,
              zone: zone,
              eventType: GeofenceEventType.entry,
            );
          }
        } else {
          // Trigger exit alert if member just exited
          if (currentZones.contains(zone.id) && zone.alertOnExit) {
            _triggerAlert(
              memberId: memberId,
              memberName: memberName,
              zone: zone,
              eventType: GeofenceEventType.exit,
            );
          }
        }
      }

      _memberZoneStatus[memberId] = newZones;
    } catch (e) {
      debugPrint('GeofenceService: Error checking member location - $e');
    }
  }

  /// Trigger a geofence alert
  void _triggerAlert({
    required String memberId,
    required String memberName,
    required GeofenceZone zone,
    required GeofenceEventType eventType,
  }) {
    final alert = GeofenceAlert(
      memberId: memberId,
      memberName: memberName,
      zone: zone,
      eventType: eventType,
      timestamp: DateTime.now(),
    );

    _alertController.add(alert);
    debugPrint(
      'GeofenceService: ${eventType.name.toUpperCase()} alert - $memberName ${eventType == GeofenceEventType.entry ? "entered" : "exited"} "${zone.name}"',
    );
  }

  /// Get zones containing a member
  List<GeofenceZone> getZonesForMember(String memberId) {
    final zoneIds = _memberZoneStatus[memberId] ?? {};
    return zoneIds.map((id) => _zones[id]).whereType<GeofenceZone>().toList();
  }

  /// Check if member is in any safe zone
  bool isMemberInSafeZone(String memberId) {
    final zones = getZonesForMember(memberId);
    return zones.isNotEmpty;
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

  /// Clear all zones
  Future<void> clearAllZones() async {
    try {
      _zones.clear();
      _memberZoneStatus.clear();
      _zonesController.add(allZones);
      await _saveZones();
      debugPrint('GeofenceService: Cleared all zones');
    } catch (e) {
      debugPrint('GeofenceService: Error clearing zones - $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _zonesController.close();
    _alertController.close();
  }
}

/// Geofence event type
enum GeofenceEventType { entry, exit }

/// Geofence alert model
class GeofenceAlert {
  const GeofenceAlert({
    required this.memberId,
    required this.memberName,
    required this.zone,
    required this.eventType,
    required this.timestamp,
  });

  final String memberId;
  final String memberName;
  final GeofenceZone zone;
  final GeofenceEventType eventType;
  final DateTime timestamp;

  String get message {
    final action = eventType == GeofenceEventType.entry ? 'entered' : 'exited';
    return '$memberName $action ${zone.name}';
  }
}
