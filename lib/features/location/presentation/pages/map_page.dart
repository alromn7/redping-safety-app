import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/native_map_service.dart';
import '../../../../models/sos_session.dart';

/// Map page with native map integration for opening device map applications
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final NativeMapService _nativeMapService = NativeMapService();

  LocationInfo? _currentLocation;
  final List<LocationInfo> _breadcrumbTrail = [];
  bool _showBreadcrumbTrail = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Initialize native map service
      await _nativeMapService.initialize();

      // Services are already initialized by AppServiceManager
      _serviceManager.locationService.setLocationUpdateCallback(
        _onLocationUpdate,
      );

      // Get current location
      final location = await _serviceManager.locationService
          .getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _isLoading = false;
        });
      }

      // Start tracking if not already active
      if (!_serviceManager.locationService.isTracking) {
        await _serviceManager.locationService.startTracking();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('MapPage: Error connecting to location service - $e');
    }
  }

  void _onLocationUpdate(LocationInfo location) {
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
      _breadcrumbTrail.add(location);

      // Keep only last 50 breadcrumb points
      if (_breadcrumbTrail.length > 50) {
        _breadcrumbTrail.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try to go back, if no previous route, go to home
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Navigate to home/SOS page
              if (context.mounted) {
                context.go('/main');
              }
            }
          },
          tooltip: 'Back',
        ),
        title: const Text('Location & Maps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate to home/SOS page
              context.go('/main');
            },
            tooltip: 'Home',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openNativeMap,
            tooltip: 'Open in Native Maps',
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _openNavigation,
            tooltip: 'Open Navigation',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLocationInterface(),
    );
  }

  Widget _buildLocationInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _currentLocation != null
                            ? AppTheme.safeGreen
                            : AppTheme.warningOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLocation?.address ?? 'Acquiring GPS...',
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_currentLocation != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppTheme.disabledText,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _currentLocation != null
                                ? AppTheme.safeGreen.withValues(alpha: 0.2)
                                : AppTheme.warningOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentLocation != null
                                ? 'GPS Active'
                                : 'GPS Searching',
                            style: TextStyle(
                              color: _currentLocation != null
                                  ? AppTheme.safeGreen
                                  : AppTheme.warningOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentLocation != null) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttonWidth = (constraints.maxWidth - 12) / 2;
                        return Row(
                          children: [
                            SizedBox(
                              width: buttonWidth,
                              child: ElevatedButton.icon(
                                onPressed: _openNativeMap,
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text(
                                  'View on Map',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.infoBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: buttonWidth,
                              child: ElevatedButton.icon(
                                onPressed: _openNavigation,
                                icon: const Icon(Icons.navigation, size: 18),
                                label: const Text(
                                  'Navigate',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.safeGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Breadcrumb Trail Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timeline,
                        color: _showBreadcrumbTrail
                            ? AppTheme.primaryRed
                            : AppTheme.infoBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Breadcrumb Trail',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_breadcrumbTrail.length} location points recorded',
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _showBreadcrumbTrail,
                        onChanged: (value) {
                          setState(() {
                            _showBreadcrumbTrail = value;
                          });
                        },
                        activeThumbColor: AppTheme.primaryRed,
                      ),
                    ],
                  ),
                  if (_breadcrumbTrail.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _breadcrumbTrail.length,
                        itemBuilder: (context, index) {
                          final point = _breadcrumbTrail[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: Card(
                              color: index == _breadcrumbTrail.length - 1
                                  ? AppTheme.primaryRed.withValues(alpha: 0.1)
                                  : AppTheme.darkSurface,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color:
                                          index == _breadcrumbTrail.length - 1
                                          ? AppTheme.primaryRed
                                          : AppTheme.infoBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color:
                                            index == _breadcrumbTrail.length - 1
                                            ? AppTheme.primaryRed
                                            : AppTheme.primaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: AppTheme.secondaryText,
                                        fontSize: 10,
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
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Map Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate optimal grid parameters based on available width
                      final availableWidth = constraints.maxWidth;
                      final crossAxisCount = availableWidth > 600 ? 4 : 2;
                      final cardWidth =
                          (availableWidth - 12 * (crossAxisCount - 1)) /
                          crossAxisCount;
                      final aspectRatio = cardWidth / 60; // Height of 60px

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio.clamp(1.5, 3.5),
                        children: [
                          _buildActionCard(
                            'Open in Maps',
                            Icons.map,
                            AppTheme.infoBlue,
                            _openNativeMap,
                          ),
                          _buildActionCard(
                            'Start Navigation',
                            Icons.navigation,
                            AppTheme.safeGreen,
                            _openNavigation,
                          ),
                          _buildActionCard(
                            'Search Nearby',
                            Icons.search,
                            AppTheme.warningOrange,
                            _openNearbySearch,
                          ),
                          _buildActionCard(
                            'Share Location',
                            Icons.share,
                            AppTheme.primaryRed,
                            _shareLocation,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency Location Sharing
          Card(
            color: AppTheme.criticalRed.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: AppTheme.criticalRed,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emergency Location Sharing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.criticalRed,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your current location with emergency contacts and SAR teams.',
                    style: TextStyle(color: AppTheme.primaryText, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareEmergencyLocation,
                      icon: const Icon(Icons.emergency, size: 18),
                      label: const Text(
                        'Share Emergency Location',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.criticalRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Native Map Integration Methods
  Future<void> _openNativeMap() async {
    if (_currentLocation == null) {
      _showSnackBar('Location not available');
      return;
    }

    try {
      final success = await _nativeMapService.openCurrentLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        label: _currentLocation!.address ?? 'Current Location',
      );

      if (!success) {
        _showSnackBar('Could not open map application');
      }
    } catch (e) {
      _showSnackBar('Error opening map: $e');
    }
  }

  Future<void> _openNavigation() async {
    if (_currentLocation == null) {
      _showSnackBar('Location not available');
      return;
    }

    try {
      final success = await _nativeMapService.openNavigation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        label: _currentLocation!.address ?? 'Current Location',
      );

      if (!success) {
        _showSnackBar('Could not open navigation');
      }
    } catch (e) {
      _showSnackBar('Error opening navigation: $e');
    }
  }

  Future<void> _openNearbySearch() async {
    if (_currentLocation == null) {
      _showSnackBar('Location not available');
      return;
    }

    try {
      final success = await _nativeMapService.openNearbySearch(
        query: 'emergency services',
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
      );

      if (!success) {
        _showSnackBar('Could not open search');
      }
    } catch (e) {
      _showSnackBar('Error opening search: $e');
    }
  }

  Future<void> _shareLocation() async {
    if (_currentLocation == null) {
      _showSnackBar('Location not available');
      return;
    }

    try {
      final success = await _nativeMapService.openCurrentLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        label:
            'REDP!NG Location: ${_currentLocation!.address ?? 'Current Location'}',
      );

      if (!success) {
        _showSnackBar('Could not share location');
      }
    } catch (e) {
      _showSnackBar('Error sharing location: $e');
    }
  }

  Future<void> _shareEmergencyLocation() async {
    if (_currentLocation == null) {
      _showSnackBar('Location not available');
      return;
    }

    try {
      // Open native map with emergency context
      final success = await _nativeMapService.openCurrentLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        label:
            'EMERGENCY: REDP!NG Location - ${_currentLocation!.address ?? 'Current Location'}',
      );

      if (success) {
        _showSnackBar('Emergency location shared');
      } else {
        _showSnackBar('Could not share emergency location');
      }
    } catch (e) {
      _showSnackBar('Error sharing emergency location: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
