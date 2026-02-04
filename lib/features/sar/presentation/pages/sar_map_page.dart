import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../../../config/google_cloud_config.dart';
import '../../../../core/routing/sar_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';
import '../../../../services/location_service.dart';
import '../../../../services/native_map_service.dart';

class SarMapPage extends StatefulWidget {
  const SarMapPage({super.key});

  @override
  State<SarMapPage> createState() => _SarMapPageState();
}

class _Incident {
  final String sessionId;
  final double latitude;
  final double longitude;
  final String? status;
  final String? userName;
  final String? address;
  final DateTime? updatedAt;
  final String? type;
  final String? impactSeverity;

  const _Incident({
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.status,
    this.userName,
    this.address,
    this.updatedAt,
    this.type,
    this.impactSeverity,
  });
}

class _SarMapPageState extends State<SarMapPage> {
  final LocationService _locationService = LocationService();
  final NativeMapService _nativeMapService = NativeMapService();
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LocationInfo? _location;
  bool _isLoading = true;
  String? _error;
  bool _followUser = true;
  bool _showIncidents = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incidentsSub;
  List<_Incident> _incidents = const [];

  late final void Function(LocationInfo) _locationListener;

  @override
  void initState() {
    super.initState();
    _locationListener = (loc) {
      if (!mounted) return;
      setState(() => _location = loc);
      if (_followUser) {
        _moveMapTo(loc);
      }
    };
    _locationService.addLocationListener(_locationListener);
    _startIncidentsListener();
    _load();
  }

  @override
  void dispose() {
    _incidentsSub?.cancel();
    _locationService.removeLocationListener(_locationListener);
    // Map view should not keep background GPS running.
    _locationService.stopTracking();
    super.dispose();
  }

  void _startIncidentsListener() {
    _incidentsSub?.cancel();
    if (!_showIncidents) return;

    _incidentsSub = _activeSessionsStream().listen(
      (snapshot) {
        final incidents = <_Incident>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();

          final sessionId = (data['id'] as String?) ?? doc.id;
          final lastLoc = data['lastLocation'] as Map<String, dynamic>?;
          final loc = data['location'] as Map<String, dynamic>?;

          final lat = _asDouble(lastLoc?['lat']) ?? _asDouble(loc?['latitude']);
          final lng = _asDouble(lastLoc?['lng']) ?? _asDouble(loc?['longitude']);

          if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
            continue;
          }

          final status = data['status'] as String?;
          final userName = data['userName'] as String?;
          final address = (lastLoc?['address'] as String?) ??
              (loc?['address'] as String?);

          DateTime? updatedAt;
          final ts = lastLoc?['ts'];
          if (ts is Timestamp) {
            updatedAt = ts.toDate();
          } else if (ts is String) {
            updatedAt = DateTime.tryParse(ts);
          }

          final type = data['type'] as String?;
          final impactInfo = data['impactInfo'] as Map<String, dynamic>?;
          final impactSeverity = impactInfo?['severity'] as String?;

          incidents.add(
            _Incident(
              sessionId: sessionId,
              latitude: lat,
              longitude: lng,
              status: status,
              userName: userName,
              address: address,
              updatedAt: updatedAt,
              type: type,
              impactSeverity: impactSeverity,
            ),
          );
        }

        if (!mounted) return;
        setState(() => _incidents = List.unmodifiable(incidents));
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _incidents = const []);
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _activeSessionsStream() {
    // Keep this intentionally narrow: only sessions that should be actionable in SAR.
    // Firestore whereIn supports up to 10 values.
    const actionableStatuses = <String>[
      'countdown',
      'active',
      'acknowledged',
      'assigned',
      'en_route',
      'on_scene',
      'in_progress',
    ];

    return _firestore
        .collection(GoogleCloudConfig.firestoreCollectionSosAlerts)
        .where('status', whereIn: actionableStatuses)
        .snapshots();
  }

  Color _incidentColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'countdown':
        return Colors.orange;
      case 'active':
        return AppTheme.primaryRed;
      case 'acknowledged':
        return Colors.redAccent;
      case 'assigned':
        return Colors.purpleAccent;
      case 'en_route':
        return Colors.lightBlueAccent;
      case 'on_scene':
        return Colors.lightGreenAccent;
      case 'in_progress':
        return Colors.tealAccent;
      default:
        return Colors.white;
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _fitToIncidents() {
    if (_incidents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active incidents to fit')),
      );
      return;
    }

    final points = _incidents
        .map((i) => LatLng(i.latitude, i.longitude))
        .toList(growable: false);

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (_) {
      // Fallback: move to first incident.
      final first = points.first;
      _mapController.move(first, 13);
    }
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _showIncidentActionsSheet({
    required String sessionId,
    required double latitude,
    required double longitude,
    String? userName,
    String? status,
    String? address,
    String? type,
    String? impactSeverity,
    DateTime? updatedAt,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName?.isNotEmpty == true ? userName! : 'SOS Incident',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (status != null && status.isNotEmpty) 'Status: $status',
                    if (type != null && type.isNotEmpty) 'Type: $type',
                    if (impactSeverity != null && impactSeverity.isNotEmpty)
                      'Impact: $impactSeverity',
                    if (updatedAt != null)
                      'Updated: ${_formatRelativeTime(updatedAt)}',
                    if (address != null && address.isNotEmpty) address,
                    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  ].join(' • '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push('/sos/$sessionId');
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await _nativeMapService.openNavigation(
                            latitude: latitude,
                            longitude: longitude,
                            label: userName?.isNotEmpty == true
                                ? 'SOS: $userName'
                                : 'SOS Incident',
                            address: address,
                          );
                          if (!mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open navigation'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Navigate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                            ),
                          );
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coordinates copied')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Coords'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: 'redping://sos/$sessionId'),
                          );
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deep link copied')),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _nativeMapService.initialize();
      final ok = await _locationService.initialize();
      if (!ok) {
        setState(() {
          _error = 'Location permission is required for SAR map tools.';
          _isLoading = false;
        });
        return;
      }

      // Start live updates (uses platform stream inside LocationService).
      await _locationService.startTracking();

      final location = await _locationService.getCurrentLocation(
        highAccuracy: true,
        forceFresh: true,
      );

      setState(() {
        _location = location;
        _isLoading = false;
      });

      if (location != null) {
        _moveMapTo(location);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyCoords() async {
    final loc = _location;
    if (loc == null) return;
    final text = '${loc.latitude}, ${loc.longitude}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied')),
    );
  }

  Future<void> _openInMaps() async {
    final loc = _location;
    if (loc == null) return;
    final ok = await _nativeMapService.openCurrentLocation(
      latitude: loc.latitude,
      longitude: loc.longitude,
      label: 'Current Location',
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps app')),
      );
    }
  }

  Future<void> _openNearby(String query) async {
    final loc = _location;
    final ok = await _nativeMapService.openNearbySearch(
      query: query,
      latitude: loc?.latitude,
      longitude: loc?.longitude,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps search')),
      );
    }
  }

  void _moveMapTo(LocationInfo loc) {
    try {
      _mapController.move(LatLng(loc.latitude, loc.longitude), 16);
    } catch (_) {
      // Ignore if controller not yet attached.
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _location;
    final center = (loc != null)
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(0, 0);

    final trail = _locationService.breadcrumbTrail
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('SAR Map'),
        leading: IconButton(
          tooltip: 'Back to SAR Dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(SarRouter.sar);
            }
          },
        ),
        actions: [
          if (_showIncidents)
            IconButton(
              tooltip: 'Fit to incidents',
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _fitToIncidents,
            ),
          IconButton(
            tooltip: _showIncidents ? 'Hide incidents' : 'Show incidents',
            icon: Icon(_showIncidents ? Icons.warning : Icons.warning_amber),
            onPressed: () {
              setState(() => _showIncidents = !_showIncidents);
              _startIncidentsListener();
            },
          ),
          IconButton(
            tooltip: _followUser ? 'Following' : 'Not following',
            icon: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() => _followUser = !_followUser);
              if (_followUser && _location != null) {
                _moveMapTo(_location!);
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Embedded map (OSM)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 260,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: loc != null ? 16 : 2,
                          onPositionChanged: (pos, hasGesture) {
                            if (hasGesture && _followUser) {
                              setState(() => _followUser = false);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'redping_14v',
                            maxZoom: 19,
                          ),
                          if (trail.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: trail,
                                  strokeWidth: 4,
                                  color: AppTheme.infoBlue.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          if (_showIncidents && _incidents.isNotEmpty)
                            MarkerLayer(
                              markers: _incidents
                                  .map(
                                    (i) => Marker(
                                      point: LatLng(i.latitude, i.longitude),
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        onTap: () => _showIncidentActionsSheet(
                                          sessionId: i.sessionId,
                                          latitude: i.latitude,
                                          longitude: i.longitude,
                                          userName: i.userName,
                                          status: i.status,
                                          address: i.address,
                                          type: i.type,
                                          impactSeverity: i.impactSeverity,
                                          updatedAt: i.updatedAt,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _incidentColor(i.status)
                                                .withValues(alpha: 0.22),
                                            border: Border.all(
                                              color: _incidentColor(i.status),
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.sos,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          if (loc != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: center,
                                  width: 48,
                                  height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryRed
                                          .withValues(alpha: 0.18),
                                      border: Border.all(
                                        color: AppTheme.primaryRed,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.my_location,
                                        color: AppTheme.primaryRed,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_error != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.primaryText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Position',
                            style: TextStyle(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _kv('Latitude', _location?.latitude.toStringAsFixed(6) ?? '—'),
                          _kv('Longitude', _location?.longitude.toStringAsFixed(6) ?? '—'),
                          _kv('Accuracy', _location != null ? '${_location!.accuracy.toStringAsFixed(1)} m' : '—'),
                          _kv('Timestamp', _location?.timestamp.toIso8601String() ?? '—'),
                          if ((_location?.address?.isNotEmpty ?? false))
                            _kv('Address', _location!.address!),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _location == null ? null : _copyCoords,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _location == null ? null : _openInMaps,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Open Maps'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Nearby',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Hospital', () => _openNearby('hospital')),
                      _chip('Police', () => _openNearby('police')),
                      _chip('Fire station', () => _openNearby('fire station')),
                      _chip('Pharmacy', () => _openNearby('pharmacy')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Operations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.emergency, color: AppTheme.criticalRed),
                          title: const Text('SOS Ping Dashboard'),
                          subtitle: const Text('Monitor active incidents'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push('/sos-ping-dashboard'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.history, color: AppTheme.warningOrange),
                          title: const Text('Session History'),
                          subtitle: const Text('Review previous missions'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push('/session-history'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              k,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
