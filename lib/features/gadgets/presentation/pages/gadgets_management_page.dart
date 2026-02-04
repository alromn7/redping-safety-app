import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/gadget_device.dart';
import '../../../../services/gadget_integration_service.dart';
import '../../../../services/bluetooth_scanner_service.dart';
import '../widgets/bluetooth_scanner_widget.dart';
import '../widgets/qr_scanner_widget.dart';
import 'find_my_gadget_page.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/entitlements/entitlement_service.dart';

/// Page for managing gadget devices integration
class GadgetsManagementPage extends StatefulWidget {
  const GadgetsManagementPage({super.key});

  @override
  State<GadgetsManagementPage> createState() => _GadgetsManagementPageState();
}

class _GadgetsManagementPageState extends State<GadgetsManagementPage> {
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
      debugPrint('GadgetsManagementPage: Error initializing gadgets - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('My Gadgets', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDeviceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_devices.isEmpty) {
      return Column(
        children: [
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return _buildDeviceCard(device);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final connectedDevices = _devices.where((d) => d.isOnline).length;
    final totalDevices = _devices.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.devices,
              color: AppTheme.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$connectedDevices of $totalDevices devices connected',
                  style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
                ),
              ],
            ),
          ),
          if (connectedDevices > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGreen),
              ),
              child: Text(
                'Online',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.devices_other,
                  size: 64,
                  color: AppTheme.neutralGray,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Gadgets Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect your smart watch, car, tablet, or other devices to enhance your REDP!NG experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddDeviceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(GadgetDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isOnline ? AppTheme.accentGreen : AppTheme.borderColor,
          width: device.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(device.deviceIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (device.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryRed),
                            ),
                            child: Text(
                              'Primary',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.manufacturer} ${device.model}',
                      style: TextStyle(
                        color: AppTheme.neutralGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildConnectionStatus(device),
            ],
          ),
          const SizedBox(height: 12),
          _buildDeviceInfo(device),
          const SizedBox(height: 12),
          _buildDeviceActions(device),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(GadgetDevice device) {
    Color statusColor;
    IconData statusIcon;

    switch (device.connectionStatus) {
      case GadgetConnectionStatus.connected:
        statusColor = AppTheme.accentGreen;
        statusIcon = Icons.wifi;
        break;
      case GadgetConnectionStatus.connecting:
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.wifi_find;
        break;
      case GadgetConnectionStatus.disconnected:
        statusColor = AppTheme.neutralGray;
        statusIcon = Icons.wifi_off;
        break;
      case GadgetConnectionStatus.error:
        statusColor = AppTheme.primaryRed;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppTheme.neutralGray;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 4),
          Text(
            device.connectionStatusDisplayName,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(GadgetDevice device) {
    return Row(
      children: [
        if (device.hasCapability(GadgetCapability.batteryLevel))
          _buildInfoChip(
            icon: device.isCharging
                ? Icons.battery_charging_full
                : Icons.battery_std,
            label: device.batteryStatusText,
            color: device.batteryLevel < 0.2
                ? AppTheme.primaryRed
                : AppTheme.accentGreen,
          ),
        const SizedBox(width: 8),
        if (device.hasCapability(GadgetCapability.locationTracking))
          _buildInfoChip(
            icon: Icons.location_on,
            label: 'GPS',
            color: AppTheme.accentGreen,
          ),
        const SizedBox(width: 8),
        if (device.hasCapability(GadgetCapability.sosButton))
          _buildInfoChip(
            icon: Icons.emergency,
            label: 'SOS',
            color: AppTheme.primaryRed,
          ),
        const Spacer(),
        Text(
          '${device.capabilities.length} features',
          style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceActions(GadgetDevice device) {
    return Column(
      children: [
        // Find My Gadget button (if device has location tracking)
        if (device.hasCapability(GadgetCapability.locationTracking)) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showFindMyGadget(device),
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Find My Gadget'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: BorderSide(color: AppTheme.primaryRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Connection/Sync actions
        Row(
          children: [
            if (device.connectionStatus == GadgetConnectionStatus.disconnected)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _connectDevice(device),
                  icon: const Icon(Icons.wifi, size: 16),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            if (device.connectionStatus ==
                GadgetConnectionStatus.connected) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _syncDevice(device),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _disconnectDevice(device),
                  icon: const Icon(Icons.wifi_off, size: 16),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.neutralGray,
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.neutralGray),
              onSelected: (value) => _handleDeviceMenuAction(value, device),
              itemBuilder: (context) => [
                if (device.hasCapability(GadgetCapability.locationTracking))
                  const PopupMenuItem(
                    value: 'find',
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 18,
                          color: AppTheme.primaryRed,
                        ),
                        SizedBox(width: 8),
                        Text('Find My Gadget'),
                      ],
                    ),
                  ),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'stats', child: Text('Statistics')),
                if (!device.isPrimary)
                  const PopupMenuItem(
                    value: 'set_primary',
                    child: Text('Set as Primary'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove Device'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Add Device', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.bluetooth_searching,
                color: AppTheme.primaryRed,
              ),
              title: const Text(
                'Scan Bluetooth',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically discover nearby devices',
                style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBluetoothScanner();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner,
                color: AppTheme.primaryRed,
              ),
              title: const Text(
                'Scan QR Code',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Scan device QR code for instant setup',
                style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showQRScanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryRed),
              title: const Text(
                'Manual Entry',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Enter device details manually',
                style: TextStyle(color: AppTheme.neutralGray, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddDeviceDialog(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBluetoothScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BluetoothScannerWidget(
        onDeviceSelected: (device, type) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final bluetoothScanner = BluetoothScannerService();
            final gadgetDevice = await bluetoothScanner.convertToGadgetDevice(
              device,
              type: type,
            );

            if (gadgetDevice != null) {
              await _gadgetService.registerDevice(
                name: gadgetDevice.name,
                type: gadgetDevice.type,
                manufacturer: gadgetDevice.manufacturer,
                model: gadgetDevice.model,
                serialNumber: gadgetDevice.serialNumber,
                firmwareVersion: gadgetDevice.firmwareVersion,
                hardwareVersion: gadgetDevice.hardwareVersion,
                capabilities: gadgetDevice.capabilities,
                connectionType: 'Bluetooth',
                macAddress: gadgetDevice.macAddress,
              );

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${gadgetDevice.name} added successfully'),
                    backgroundColor: AppTheme.safeGreen,
                  ),
                );
                _initializeGadgets();
              }
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to add device: $e'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRScannerWidget(
        onQRScanned: (qrData) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            // Determine device type from QR data
            GadgetType deviceType = GadgetType.other;
            final typeString = qrData['type']?.toString().toLowerCase() ?? '';

            if (typeString.contains('watch')) {
              deviceType = GadgetType.smartwatch;
            } else if (typeString.contains('car')) {
              deviceType = GadgetType.car;
            } else if (typeString.contains('bike')) {
              deviceType = GadgetType.other;
            } else if (typeString.contains('tracker') ||
                typeString.contains('fitness')) {
              deviceType = GadgetType.fitnessTracker;
            } else if (typeString.contains('drone')) {
              deviceType = GadgetType.drone;
            } else if (typeString.contains('sensor')) {
              deviceType = GadgetType.iotSensor;
            }

            await _gadgetService.registerDevice(
              name: qrData['model'] ?? 'Unknown Device',
              type: deviceType,
              manufacturer: qrData['manufacturer'] ?? 'Unknown',
              model: qrData['model'] ?? 'Unknown',
              serialNumber: qrData['serialNumber'] ?? 'Unknown',
              firmwareVersion: qrData['firmwareVersion'] ?? 'Unknown',
              hardwareVersion: qrData['hardwareVersion'] ?? 'Unknown',
              capabilities: [], // Will be detected later
              connectionType: 'Bluetooth',
              macAddress: qrData['macAddress'] ?? '',
            );

            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${qrData['model']} added successfully'),
                  backgroundColor: AppTheme.safeGreen,
                ),
              );
              _initializeGadgets();
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to add device: $e'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _connectDevice(GadgetDevice device) async {
    try {
      await _gadgetService.connectDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting to ${device.name}...'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice(GadgetDevice device) async {
    try {
      await _gadgetService.disconnectDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${device.name}'),
            backgroundColor: AppTheme.neutralGray,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _syncDevice(GadgetDevice device) async {
    try {
      await _gadgetService.syncDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Syncing ${device.name}...'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _handleDeviceMenuAction(String action, GadgetDevice device) {
    switch (action) {
      case 'find':
        _showFindMyGadget(device);
        break;
      case 'settings':
        _showDeviceSettings(device);
        break;
      case 'stats':
        _showDeviceStats(device);
        break;
      case 'set_primary':
        _setPrimaryDevice(device);
        break;
      case 'remove':
        _removeDevice(device);
        break;
    }
  }

  void _showFindMyGadget(GadgetDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FindMyGadgetPage(device: device)),
    );
  }

  void _showDeviceSettings(GadgetDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceSettingsPage(device: device),
      ),
    );
  }

  void _showDeviceStats(GadgetDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceStatsPage(device: device)),
    );
  }

  Future<void> _setPrimaryDevice(GadgetDevice device) async {
    try {
      await _gadgetService.setPrimaryDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${device.name} set as primary device'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary device: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _removeDevice(GadgetDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Remove Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${device.name}"? This action cannot be undone.',
          style: TextStyle(color: AppTheme.neutralGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutralGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _gadgetService.removeDevice(device.id);
                if (!mounted) return;
                setState(() {
                  _devices.removeWhere((d) => d.id == device.id);
                });
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${device.name} removed successfully'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove device: $e'),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a new device
class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _firmwareVersionController = TextEditingController();
  final _hardwareVersionController = TextEditingController();
  final _macAddressController = TextEditingController();
  final _ipAddressController = TextEditingController();
  final _notesController = TextEditingController();

  GadgetType _selectedType = GadgetType.smartphone;
  String _selectedConnectionType = 'bluetooth';
  final List<GadgetCapability> _selectedCapabilities = [];

  final GadgetIntegrationService _gadgetService =
      GadgetIntegrationService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _firmwareVersionController.dispose();
    _hardwareVersionController.dispose();
    _macAddressController.dispose();
    _ipAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: const Text(
        'Add New Device',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  _nameController,
                  'Device Name',
                  'Enter device name',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _manufacturerController,
                  'Manufacturer',
                  'e.g., Apple, Samsung',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _modelController,
                  'Model',
                  'e.g., iPhone 15, Galaxy Watch',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _serialNumberController,
                  'Serial Number',
                  'Enter serial number',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _firmwareVersionController,
                  'Firmware Version',
                  'e.g., 1.0.0',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _hardwareVersionController,
                  'Hardware Version',
                  'e.g., A1',
                ),
                const SizedBox(height: 12),
                _buildConnectionTypeSelector(),
                const SizedBox(height: 12),
                _buildTextField(
                  _macAddressController,
                  'MAC Address',
                  'Enter MAC address',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _ipAddressController,
                  'IP Address (optional)',
                  'Enter IP address',
                ),
                const SizedBox(height: 16),
                _buildCapabilitiesSelector(),
                const SizedBox(height: 12),
                _buildTextField(
                  _notesController,
                  'Notes (optional)',
                  'Additional notes',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppTheme.neutralGray)),
        ),
        ElevatedButton(
          onPressed: _addDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Device'),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GadgetType>(
          initialValue: _selectedType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          items: GadgetType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                _getDeviceTypeDisplayName(type),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildConnectionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connection Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedConnectionType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          items: const [
            DropdownMenuItem(
              value: 'bluetooth',
              child: Text('Bluetooth', style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem(
              value: 'wifi',
              child: Text('WiFi', style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem(
              value: 'cellular',
              child: Text('Cellular', style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem(
              value: 'usb',
              child: Text('USB', style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem(
              value: 'local',
              child: Text('Local', style: TextStyle(color: Colors.white)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedConnectionType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCapabilitiesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Capabilities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GadgetCapability.values.map((capability) {
            final isSelected = _selectedCapabilities.contains(capability);
            return FilterChip(
              label: Text(
                _getCapabilityDisplayName(capability),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.neutralGray,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCapabilities.add(capability);
                  } else {
                    _selectedCapabilities.remove(capability);
                  }
                });
              },
              selectedColor: AppTheme.primaryRed,
              checkmarkColor: Colors.white,
              backgroundColor: AppTheme.inputBackground,
              side: BorderSide(color: AppTheme.borderColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.neutralGray),
        hintStyle: TextStyle(
          color: AppTheme.neutralGray.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: AppTheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryRed),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _gadgetService.registerDevice(
        name: _nameController.text,
        type: _selectedType,
        manufacturer: _manufacturerController.text,
        model: _modelController.text,
        serialNumber: _serialNumberController.text,
        firmwareVersion: _firmwareVersionController.text,
        hardwareVersion: _hardwareVersionController.text,
        capabilities: _selectedCapabilities,
        connectionType: _selectedConnectionType,
        macAddress: _macAddressController.text,
        ipAddress: _ipAddressController.text.isNotEmpty
            ? _ipAddressController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} added successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add device: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  String _getDeviceTypeDisplayName(GadgetType type) {
    switch (type) {
      case GadgetType.smartwatch:
        return 'Smart Watch';
      case GadgetType.car:
        return 'Car';
      case GadgetType.tablet:
        return 'Tablet';
      case GadgetType.ipad:
        return 'iPad';
      case GadgetType.laptop:
        return 'Laptop';
      case GadgetType.desktop:
        return 'Desktop';
      case GadgetType.headphones:
        return 'Headphones';
      case GadgetType.smartphone:
        return 'Smartphone';
      case GadgetType.fitnessTracker:
        return 'Fitness Tracker';
      case GadgetType.drone:
        return 'Drone';
      case GadgetType.smartGlasses:
        return 'Smart Glasses';
      case GadgetType.vrHeadset:
        return 'VR Headset';
      case GadgetType.iotSensor:
        return 'IoT Sensor';
      case GadgetType.securityCamera:
        return 'Security Camera';
      case GadgetType.smartSpeaker:
        return 'Smart Speaker';
      case GadgetType.other:
        return 'Other Device';
    }
  }

  String _getCapabilityDisplayName(GadgetCapability capability) {
    switch (capability) {
      case GadgetCapability.sosButton:
        return 'SOS Button';
      case GadgetCapability.locationTracking:
        return 'Location Tracking';
      case GadgetCapability.crashDetection:
        return 'Crash Detection';
      case GadgetCapability.fallDetection:
        return 'Fall Detection';
      case GadgetCapability.heartRateMonitoring:
        return 'Heart Rate';
      case GadgetCapability.voiceCommands:
        return 'Voice Commands';
      case GadgetCapability.notifications:
        return 'Notifications';
      case GadgetCapability.camera:
        return 'Camera';
      case GadgetCapability.microphone:
        return 'Microphone';
      case GadgetCapability.speaker:
        return 'Speaker';
      case GadgetCapability.bluetooth:
        return 'Bluetooth';
      case GadgetCapability.wifi:
        return 'WiFi';
      case GadgetCapability.cellular:
        return 'Cellular';
      case GadgetCapability.gps:
        return 'GPS';
      case GadgetCapability.accelerometer:
        return 'Accelerometer';
      case GadgetCapability.gyroscope:
        return 'Gyroscope';
      case GadgetCapability.magnetometer:
        return 'Magnetometer';
      case GadgetCapability.barometer:
        return 'Barometer';
      case GadgetCapability.temperature:
        return 'Temperature';
      case GadgetCapability.humidity:
        return 'Humidity';
      case GadgetCapability.light:
        return 'Light Sensor';
      case GadgetCapability.proximity:
        return 'Proximity';
      case GadgetCapability.batteryLevel:
        return 'Battery Level';
      case GadgetCapability.chargingStatus:
        return 'Charging Status';
      case GadgetCapability.storageSpace:
        return 'Storage Space';
      case GadgetCapability.networkStatus:
        return 'Network Status';
      case GadgetCapability.emergencyBroadcast:
        return 'Emergency Broadcast';
      case GadgetCapability.sosAutomatic:
        return 'Automatic SOS';
      case GadgetCapability.familySharing:
        return 'Family Sharing';
      case GadgetCapability.remoteMonitoring:
        return 'Remote Monitoring';
      case GadgetCapability.dataSync:
        return 'Data Sync';
      case GadgetCapability.firmwareUpdate:
        return 'Firmware Update';
      case GadgetCapability.diagnostics:
        return 'Diagnostics';
      case GadgetCapability.maintenanceAlerts:
        return 'Maintenance Alerts';
    }
  }
}

/// Placeholder pages for device settings and stats
class DeviceSettingsPage extends StatelessWidget {
  final GadgetDevice device;

  const DeviceSettingsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('${device.name} Settings'),
      ),
      body: const Center(
        child: Text(
          'Device Settings - Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class DeviceStatsPage extends StatelessWidget {
  final GadgetDevice device;

  const DeviceStatsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('${device.name} Statistics'),
      ),
      body: const Center(
        child: Text(
          'Device Statistics - Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
