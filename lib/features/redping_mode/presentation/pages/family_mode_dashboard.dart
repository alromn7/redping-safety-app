import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/family_member_location.dart';
import '../../../../models/auth_user.dart';
import '../../../../services/family_location_service.dart';
import '../../../../services/geofence_service.dart';
import '../../../../services/subscription_service.dart';
import '../widgets/family_member_location_card.dart';
import '../widgets/geofence_zone_card.dart';

/// Family Mode Dashboard showing member locations and geofences
class FamilyModeDashboard extends StatefulWidget {
  const FamilyModeDashboard({super.key});

  @override
  State<FamilyModeDashboard> createState() => _FamilyModeDashboardState();
}

class _FamilyModeDashboardState extends State<FamilyModeDashboard>
    with SingleTickerProviderStateMixin {
  late final FamilyLocationService _locationService;
  late final GeofenceService _geofenceService;
  late final SubscriptionService _subscriptionService;
  late final TabController _tabController;

  List<FamilyMemberLocation> _memberLocations = [];
  List<GeofenceZone> _geofences = [];
  FamilySubscription? _family;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _locationService = FamilyLocationService.instance;
    _geofenceService = GeofenceService.instance;
    _subscriptionService = SubscriptionService.instance;
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _locationService.initialize();
      await _geofenceService.initialize();
      await _subscriptionService.initialize();

      setState(() {
        _memberLocations = _locationService.allLocations;
        _geofences = _geofenceService.allZones;
        _family = _subscriptionService.currentFamily;
        _isLoading = false;
      });

      // Listen to location updates
      _locationService.locationsStream.listen((locations) {
        if (mounted) {
          setState(() => _memberLocations = locations);
        }
      });

      // Listen to geofence updates
      _geofenceService.zonesStream.listen((zones) {
        if (mounted) {
          setState(() => _geofences = zones);
        }
      });

      // Listen to geofence alerts
      _geofenceService.alertStream.listen((alert) {
        if (mounted) {
          _showGeofenceAlert(alert);
        }
      });
    } catch (e) {
      debugPrint('FamilyModeDashboard: Initialization error - $e');
      setState(() => _isLoading = false);
    }
  }

  void _showGeofenceAlert(GeofenceAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              alert.eventType == GeofenceEventType.entry
                  ? Icons.login
                  : Icons.logout,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(alert.message)),
          ],
        ),
        backgroundColor: alert.eventType == GeofenceEventType.entry
            ? AppTheme.safeGreen
            : AppTheme.warningOrange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if user has Family tier subscription OR existing family subscription
    final currentSub = _subscriptionService.currentSubscription;
    final hasFamilyTier =
        currentSub?.plan.tier.toString().contains('family') ?? false;
    final hasFamilySubscription = _family != null;

    if (!hasFamilyTier && !hasFamilySubscription) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Mode Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Family Plan Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upgrade to Family Plan to access\nfamily tracking features',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/subscription/plans'),
                icon: const Icon(Icons.upgrade),
                label: const Text('View Plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_family!.familyName ?? "Family"} Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.location_city), text: 'Safe Zones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMapView(), _buildMembersView(), _buildGeofencesView()],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: _addGeofence,
              icon: const Icon(Icons.add_location),
              label: const Text('Add Safe Zone'),
            )
          : null,
    );
  }

  Widget _buildMapView() {
    // Placeholder for map view - would integrate with actual map package
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            'Map View',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${_memberLocations.length} family members\n${_geofences.length} safe zones',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.infoBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoBlue),
                SizedBox(height: 8),
                Text(
                  'Map integration coming soon',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoBlue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Will show real-time family member locations\nand geofence boundaries on an interactive map',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersView() {
    if (_memberLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Member Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Family members will appear here\nwhen they share their location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // Member locations
        ..._memberLocations.map((location) {
          final isInSafeZone = _geofenceService.isMemberInSafeZone(
            location.memberId,
          );
          return FamilyMemberLocationCard(
            location: location,
            isInSafeZone: isInSafeZone,
            onTap: () => _showMemberDetails(location),
          );
        }),
      ],
    );
  }

  Widget _buildGeofencesView() {
    if (_geofences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Safe Zones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create safe zones like home, school, or work\nto monitor family member movements',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addGeofence,
              icon: const Icon(Icons.add_location),
              label: const Text('Add Safe Zone'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _geofences.map((zone) {
        final membersInZone = _memberLocations.where((loc) {
          return _geofenceService.isLocationInZone(
            lat: loc.latitude,
            lon: loc.longitude,
            zone: zone,
          );
        }).toList();

        return GeofenceZoneCard(
          zone: zone,
          membersInZone: membersInZone,
          onEdit: () => _editGeofence(zone),
          onDelete: () => _deleteGeofence(zone),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final onlineCount = _memberLocations.where((loc) => loc.isOnline).length;
    final inSafeZoneCount = _memberLocations.where((loc) {
      return _geofenceService.isMemberInSafeZone(loc.memberId);
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Online',
                    '$onlineCount/${_memberLocations.length}',
                    Icons.wifi,
                    AppTheme.safeGreen,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'In Safe Zone',
                    '$inSafeZoneCount',
                    Icons.shield,
                    AppTheme.infoBlue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Safe Zones',
                    '${_geofences.length}',
                    Icons.location_city,
                    AppTheme.warningOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showMemberDetails(FamilyMemberLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.2),
                  child: Text(
                    location.memberName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.infoBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.memberName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        location.timeSinceUpdate,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(
              'Location',
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            ),
            _buildDetailRow('Accuracy', location.accuracyFormatted),
            _buildDetailRow('Speed', location.speedKmh),
            _buildDetailRow('Battery', location.batteryFormatted),
            _buildDetailRow('Status', location.isOnline ? 'Online' : 'Offline'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _addGeofence() {
    // Navigate to add geofence page (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geofence editor coming soon')),
    );
  }

  void _editGeofence(GeofenceZone zone) {
    // Navigate to edit geofence page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit "${zone.name}"')));
  }

  Future<void> _deleteGeofence(GeofenceZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Safe Zone'),
        content: Text('Are you sure you want to delete "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _geofenceService.deleteZone(zone.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "${zone.name}"')));
      }
    }
  }
}
