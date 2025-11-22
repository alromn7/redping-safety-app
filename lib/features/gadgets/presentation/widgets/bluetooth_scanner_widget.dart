import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/bluetooth_scanner_service.dart';
import '../../../../models/gadget_device.dart';

/// Widget for scanning and connecting to Bluetooth devices
class BluetoothScannerWidget extends StatefulWidget {
  final Function(BluetoothDevice device, GadgetType type) onDeviceSelected;

  const BluetoothScannerWidget({super.key, required this.onDeviceSelected});

  @override
  State<BluetoothScannerWidget> createState() => _BluetoothScannerWidgetState();
}

class _BluetoothScannerWidgetState extends State<BluetoothScannerWidget> {
  final BluetoothScannerService _scanner = BluetoothScannerService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isInitializing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await _scanner.initialize();

      // Listen to scan results
      _scanner.scanResultsStream.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results;
          });
        }
      });

      // Listen to scanning state
      _scanner.scanningStateStream.listen((isScanning) {
        if (mounted) {
          setState(() {
            _isScanning = isScanning;
          });
        }
      });

      setState(() {
        _isInitializing = false;
      });

      // Auto-start scanning
      _startScan();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _errorMessage = null;
      });
      await _scanner.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start scan: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    await _scanner.stopScan();
  }

  void _onDeviceTap(ScanResult result) {
    // Show device type selection dialog
    showDialog(
      context: context,
      builder: (context) => _DeviceTypeSelectionDialog(
        deviceName: result.device.platformName,
        onTypeSelected: (type) {
          widget.onDeviceSelected(result.device, type);
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Close scanner
        },
      ),
    );
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth_searching,
                  color: AppTheme.primaryRed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluetooth Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scanning for nearby devices...',
                        style: TextStyle(
                          color: AppTheme.neutralGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isScanning)
                  IconButton(
                    icon: const Icon(Icons.stop, color: AppTheme.primaryRed),
                    onPressed: _stopScan,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _startScan,
                  ),
              ],
            ),
          ),

          const Divider(color: AppTheme.neutralGray, height: 32),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryRed),
            SizedBox(height: 16),
            Text(
              'Initializing Bluetooth...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.primaryRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeScanner,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              const CircularProgressIndicator(color: AppTheme.primaryRed)
            else
              const Icon(
                Icons.bluetooth_disabled,
                color: AppTheme.neutralGray,
                size: 64,
              ),
            const SizedBox(height: 16),
            Text(
              _isScanning ? 'Searching for devices...' : 'No devices found',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (!_isScanning) ...[
              const SizedBox(height: 8),
              const Text(
                'Make sure your device is turned on\nand in pairing mode',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh),
                label: const Text('Start Scan'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        return _buildDeviceCard(result);
      },
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    final rssi = result.rssi;
    final signalStrength = _getSignalStrength(rssi);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: () => _onDeviceTap(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceIcon(device),
                  color: AppTheme.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.remoteId.toString(),
                      style: const TextStyle(
                        color: AppTheme.neutralGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    _getSignalIcon(signalStrength),
                    color: _getSignalColor(signalStrength),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$rssi dBm',
                    style: const TextStyle(
                      color: AppTheme.neutralGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    if (name.contains('watch')) {
      return Icons.watch;
    } else if (name.contains('phone')) {
      return Icons.phone_android;
    } else if (name.contains('car')) {
      return Icons.directions_car;
    } else if (name.contains('bike')) {
      return Icons.directions_bike;
    } else if (name.contains('band') || name.contains('fit')) {
      return Icons.fitness_center;
    }
    return Icons.bluetooth;
  }

  String _getSignalStrength(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  IconData _getSignalIcon(String strength) {
    switch (strength) {
      case 'Excellent':
        return Icons.signal_cellular_alt;
      case 'Good':
        return Icons.signal_cellular_alt_2_bar;
      case 'Fair':
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }

  Color _getSignalColor(String strength) {
    switch (strength) {
      case 'Excellent':
        return AppTheme.safeGreen;
      case 'Good':
        return Colors.lightGreenAccent;
      case 'Fair':
        return AppTheme.warningOrange;
      default:
        return AppTheme.primaryRed;
    }
  }
}

class _DeviceTypeSelectionDialog extends StatelessWidget {
  final String deviceName;
  final Function(GadgetType) onTypeSelected;

  const _DeviceTypeSelectionDialog({
    required this.deviceName,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final deviceTypes = [
      (GadgetType.smartwatch, Icons.watch, 'Smartwatch'),
      (GadgetType.fitnessTracker, Icons.fitness_center, 'Fitness Tracker'),
      (GadgetType.car, Icons.directions_car, 'Car System'),
      (GadgetType.other, Icons.directions_bike, 'Bike Computer'),
      (GadgetType.iotSensor, Icons.sensors, 'IoT Sensor'),
      (GadgetType.other, Icons.devices_other, 'Other'),
    ];

    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: const Text(
        'Select Device Type',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of device is "$deviceName"?',
            style: const TextStyle(color: AppTheme.neutralGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...deviceTypes.map((typeData) {
            return ListTile(
              leading: Icon(typeData.$2, color: AppTheme.primaryRed),
              title: Text(
                typeData.$3,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => onTypeSelected(typeData.$1),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
