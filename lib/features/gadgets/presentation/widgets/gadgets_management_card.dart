import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../models/gadget_device.dart';
import '../../../../services/gadget_integration_service.dart';
import 'package:go_router/go_router.dart';

/// Card widget for gadgets management on the main dashboard
class GadgetsManagementCard extends StatefulWidget {
  const GadgetsManagementCard({super.key});

  @override
  State<GadgetsManagementCard> createState() => _GadgetsManagementCardState();
}

class _GadgetsManagementCardState extends State<GadgetsManagementCard> {
  final GadgetIntegrationService _gadgetService =
      GadgetIntegrationService.instance;

  List<GadgetDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGadgets();
  }

  Future<void> _initializeGadgets() async {
    try {
      await _gadgetService.initialize();

      setState(() {
        _devices = _gadgetService.registeredDevices;
        _isLoading = false;
      });

      // Listen for device updates
      _gadgetService.deviceUpdateStream.listen((device) {
        if (mounted) {
          setState(() {
            final index = _devices.indexWhere((d) => d.id == device.id);
            if (index != -1) {
              _devices[index] = device;
            } else {
              _devices.add(device);
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('GadgetsManagementCard: Error initializing gadgets - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.devices,
                  color: AppTheme.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Gadgets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDeviceStatusText(),
                      style: TextStyle(
                        color: AppTheme.neutralGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onPressed: _handleGadgetsAccess,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDevicePreview(),
        ],
      ),
    );
  }

  String _getDeviceStatusText() {
    if (_isLoading) {
      return 'Loading devices...';
    }

    if (_devices.isEmpty) {
      return 'No devices connected';
    }

    final connectedDevices = _devices.where((d) => d.isOnline).length;
    final totalDevices = _devices.length;

    if (connectedDevices == totalDevices) {
      return 'All $totalDevices devices online';
    } else {
      return '$connectedDevices of $totalDevices devices online';
    }
  }

  Widget _buildDevicePreview() {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryRed,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return _buildEmptyState();
    }

    // Show up to 3 devices
    final displayDevices = _devices.take(3).toList();
    final remainingCount = _devices.length - displayDevices.length;

    return Column(
      children: [
        ...displayDevices.map((device) => _buildDeviceItem(device)),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+$remainingCount more devices',
              style: TextStyle(
                color: AppTheme.neutralGray,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(
            Icons.devices_other,
            color: AppTheme.neutralGray,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your devices',
            style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Smart watches, cars, tablets & more',
            style: TextStyle(
              color: AppTheme.neutralGray.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(GadgetDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: device.isOnline
              ? AppTheme.accentGreen.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Text(device.deviceIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: device.isOnline
                            ? AppTheme.accentGreen
                            : AppTheme.neutralGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: device.isOnline
                            ? AppTheme.accentGreen
                            : AppTheme.neutralGray,
                        fontSize: 10,
                      ),
                    ),
                    if (device.hasCapability(
                      GadgetCapability.batteryLevel,
                    )) ...[
                      const SizedBox(width: 8),
                      Icon(
                        device.isCharging
                            ? Icons.battery_charging_full
                            : Icons.battery_std,
                        color: device.batteryLevel < 0.2
                            ? AppTheme.primaryRed
                            : AppTheme.accentGreen,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${(device.batteryLevel * 100).toInt()}%',
                        style: TextStyle(
                          color: device.batteryLevel < 0.2
                              ? AppTheme.primaryRed
                              : AppTheme.accentGreen,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (device.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryRed.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Primary',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleGadgetsAccess() {
    // Navigate directly to gadgets management page
    context.push('${AppRouter.settings}/gadgets');
  }
}
