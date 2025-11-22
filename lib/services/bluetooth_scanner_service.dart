import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/gadget_device.dart';

/// Service for scanning and connecting to Bluetooth devices
class BluetoothScannerService {
  static final BluetoothScannerService _instance =
      BluetoothScannerService._internal();
  factory BluetoothScannerService() => _instance;
  BluetoothScannerService._internal();

  bool _isScanning = false;
  bool _isInitialized = false;
  final List<BluetoothDevice> _discoveredDevices = [];
  final Map<String, int> _deviceRSSI = {};

  // Stream controllers
  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  final StreamController<bool> _scanningStateController =
      StreamController<bool>.broadcast();

  // Getters
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<bool> get scanningStateStream => _scanningStateController.stream;

  /// Initialize Bluetooth scanner
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('BluetoothScannerService: Bluetooth not supported');
        throw Exception('Bluetooth not supported on this device');
      }

      // Request Bluetooth permissions
      final hasPermission = await _requestBluetoothPermissions();
      if (!hasPermission) {
        debugPrint('BluetoothScannerService: Bluetooth permissions denied');
        throw Exception('Bluetooth permissions required');
      }

      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint(
          'BluetoothScannerService: Bluetooth is off, waiting for it to turn on',
        );
        // Turn on Bluetooth (Android only)
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          debugPrint(
            'BluetoothScannerService: Could not turn on Bluetooth - $e',
          );
        }
      }

      _isInitialized = true;
      debugPrint('BluetoothScannerService: Initialized successfully');
    } catch (e) {
      debugPrint('BluetoothScannerService: Initialization error - $e');
      throw Exception('Failed to initialize Bluetooth scanner: $e');
    }
  }

  /// Request Bluetooth permissions
  Future<bool> _requestBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = {};

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android 12+ requires these permissions
        statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location, // Required for BLE scanning on Android
        ].request();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS requires Bluetooth permission
        statuses = await [Permission.bluetooth].request();
      }

      // Check if all permissions are granted
      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      debugPrint('BluetoothScannerService: Error requesting permissions - $e');
      return false;
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
    List<String>? withServices,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isScanning) {
      debugPrint('BluetoothScannerService: Already scanning');
      return;
    }

    try {
      _isScanning = true;
      _scanningStateController.add(true);
      _discoveredDevices.clear();
      _deviceRSSI.clear();

      debugPrint('BluetoothScannerService: Starting scan...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            // Update discovered devices list
            if (!_discoveredDevices.contains(result.device)) {
              _discoveredDevices.add(result.device);
            }

            // Update RSSI values
            _deviceRSSI[result.device.remoteId.toString()] = result.rssi;
          }

          // Emit scan results
          _scanResultsController.add(results);
        },
        onError: (e) {
          debugPrint('BluetoothScannerService: Scan error - $e');
        },
      );

      // Auto-stop after timeout
      Future.delayed(timeout, () async {
        await stopScan();
        subscription.cancel();
      });
    } catch (e) {
      debugPrint('BluetoothScannerService: Error starting scan - $e');
      _isScanning = false;
      _scanningStateController.add(false);
      rethrow;
    }
  }

  /// Stop scanning for Bluetooth devices
  Future<void> stopScan() async {
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
        _isScanning = false;
        _scanningStateController.add(false);
        debugPrint('BluetoothScannerService: Scan stopped');
      }
    } catch (e) {
      debugPrint('BluetoothScannerService: Error stopping scan - $e');
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      debugPrint(
        'BluetoothScannerService: Connecting to ${device.platformName}...',
      );

      await device.connect(timeout: timeout);

      // Wait for connection state to change
      await device.connectionState
          .firstWhere((state) => state == BluetoothConnectionState.connected)
          .timeout(timeout);

      debugPrint(
        'BluetoothScannerService: Connected to ${device.platformName}',
      );
      return true;
    } catch (e) {
      debugPrint('BluetoothScannerService: Connection error - $e');
      return false;
    }
  }

  /// Disconnect from a Bluetooth device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      debugPrint(
        'BluetoothScannerService: Disconnected from ${device.platformName}',
      );
    } catch (e) {
      debugPrint('BluetoothScannerService: Disconnect error - $e');
    }
  }

  /// Discover services on a connected device
  Future<List<BluetoothService>> discoverServices(
    BluetoothDevice device,
  ) async {
    try {
      debugPrint(
        'BluetoothScannerService: Discovering services for ${device.platformName}...',
      );
      final services = await device.discoverServices();
      debugPrint('BluetoothScannerService: Found ${services.length} services');
      return services;
    } catch (e) {
      debugPrint('BluetoothScannerService: Service discovery error - $e');
      return [];
    }
  }

  /// Get device info from Bluetooth device
  Future<Map<String, dynamic>> getDeviceInfo(BluetoothDevice device) async {
    final info = <String, dynamic>{
      'id': device.remoteId.toString(),
      'name': device.platformName,
      'rssi': _deviceRSSI[device.remoteId.toString()] ?? -100,
      'isConnected': await device.connectionState
          .firstWhere((state) => true)
          .then((state) => state == BluetoothConnectionState.connected)
          .timeout(const Duration(seconds: 2), onTimeout: () => false),
    };

    try {
      // Get MTU if connected
      final connectionState = await device.connectionState
          .firstWhere((state) => true)
          .timeout(const Duration(seconds: 2));

      if (connectionState == BluetoothConnectionState.connected) {
        final mtu = await device.mtu.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => 23,
        );
        info['mtu'] = mtu;
      }
    } catch (e) {
      debugPrint('BluetoothScannerService: Error getting device info - $e');
    }

    return info;
  }

  /// Convert Bluetooth device to GadgetDevice
  Future<GadgetDevice?> convertToGadgetDevice(
    BluetoothDevice btDevice, {
    required GadgetType type,
  }) async {
    try {
      final deviceInfo = await getDeviceInfo(btDevice);
      final services = await discoverServices(btDevice);

      // Extract capabilities from services
      final capabilities = <GadgetCapability>[];
      for (final service in services) {
        // Map service UUIDs to capabilities
        if (service.uuid.toString().contains('180d')) {
          // Heart Rate Service
          capabilities.add(GadgetCapability.heartRateMonitoring);
        } else if (service.uuid.toString().contains('1816')) {
          // Cycling Speed and Cadence
          capabilities.add(GadgetCapability.bluetooth);
        } else if (service.uuid.toString().contains('180f')) {
          // Battery Service
          capabilities.add(GadgetCapability.batteryLevel);
        }
      }

      // Create GadgetDevice
      return GadgetDevice(
        id: btDevice.remoteId.toString(),
        name: deviceInfo['name'] ?? 'Unknown Device',
        type: type,
        manufacturer: 'Unknown', // BLE doesn't expose this easily
        model: 'BLE Device',
        serialNumber: btDevice.remoteId.toString(),
        firmwareVersion: 'Unknown',
        hardwareVersion: 'Unknown',
        connectionStatus: deviceInfo['isConnected'] == true
            ? GadgetConnectionStatus.connected
            : GadgetConnectionStatus.disconnected,
        syncStatus: GadgetSyncStatus.pending,
        capabilities: capabilities,
        deviceInfo: deviceInfo,
        lastConnected: DateTime.now(),
        lastSynced: DateTime.now(),
        batteryLevel: 1.0,
        isCharging: false,
        connectionType: 'Bluetooth',
        macAddress: btDevice.remoteId.toString(),
        ipAddress: '',
        settings: const GadgetDeviceSettings().toJson(),
        isActive: true,
        isPrimary: false,
        userId: '', // Will be set by service
        registeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('BluetoothScannerService: Error converting device - $e');
      return null;
    }
  }

  /// Get signal strength for a device
  int getDeviceRSSI(String deviceId) {
    return _deviceRSSI[deviceId] ?? -100;
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Get list of connected devices
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    try {
      return FlutterBluePlus.connectedDevices;
    } catch (e) {
      debugPrint(
        'BluetoothScannerService: Error getting connected devices - $e',
      );
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _scanResultsController.close();
    _scanningStateController.close();
    _discoveredDevices.clear();
    _deviceRSSI.clear();
  }
}
