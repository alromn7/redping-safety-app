import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/gadget_device.dart';
import '../models/sos_session.dart';
// import '../models/location_info.dart'; // TODO: Create location_info model
import 'user_profile_service.dart';
import 'sensor_service.dart';
import 'connectivity_monitor_service.dart';
import 'app_service_manager.dart';

/// Service for managing gadget device integration and synchronization
class GadgetIntegrationService {
  void wake() {
    // TODO: Implement wake logic if needed
    debugPrint('GadgetIntegrationService: wake called');
  }

  void hibernate() {
    // TODO: Implement hibernate logic if needed
    debugPrint('GadgetIntegrationService: hibernate called');
  }

  static final GadgetIntegrationService _instance =
      GadgetIntegrationService._internal();
  factory GadgetIntegrationService() => _instance;
  GadgetIntegrationService._internal();

  /// Get the singleton instance
  static GadgetIntegrationService get instance => _instance;

  final UserProfileService _userProfileService = UserProfileService();
  final SensorService _sensorService = SensorService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  List<GadgetDevice> _registeredDevices = [];
  List<GadgetDeviceStats> _deviceStats = [];
  final Map<String, StreamSubscription> _deviceSubscriptions = {};
  final Map<String, Timer> _syncTimers = {};
  bool _isInitialized = false;

  // Stream controllers
  final StreamController<List<GadgetDevice>> _devicesController =
      StreamController<List<GadgetDevice>>.broadcast();
  final StreamController<GadgetDevice> _deviceUpdateController =
      StreamController<GadgetDevice>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Callbacks
  Function(GadgetDevice)? _onDeviceConnected;
  Function(GadgetDevice)? _onDeviceDisconnected;
  Function(GadgetDevice)? _onDeviceSynced;
  Function(GadgetDevice, Map<String, dynamic>)? _onDeviceDataReceived;

  // User-requested flag for gadget sync
  bool _userRequestedGadgetSync = false;

  /// Initialize the gadget integration service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadRegisteredDevices();
      await _loadDeviceStats();
      await _initializeCurrentDevice();
      await _startDeviceMonitoring();

      ConnectivityMonitorService().offlineStream.listen((isOffline) {
        final sosActive = AppServiceManager().sosService.isSOSActive;
        if (isOffline && (sosActive || _userRequestedGadgetSync)) {
          // Only sync gadgets when offline AND SOS is active or user requests
          _startGadgetSync();
        } else {
          // Stop gadget sync otherwise
          _stopGadgetSync();
        }
      });

      _isInitialized = true;
      debugPrint('GadgetIntegrationService: Initialized successfully');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Initialization error - $e');
      throw Exception('Failed to initialize gadget integration service: $e');
    }
  }

  /// Allow user to manually request gadget sync
  void setUserRequestedGadgetSync(bool requested) {
    _userRequestedGadgetSync = requested;
    // Re-evaluate gadget sync loop
    final isOffline = true; // Should be set based on actual connectivity status
    final sosActive = AppServiceManager().sosService.isSOSActive;
    if (isOffline && (sosActive || _userRequestedGadgetSync)) {
      _startGadgetSync();
    } else {
      _stopGadgetSync();
    }
  }

  void _startGadgetSync() {
    for (final device in _registeredDevices) {
      if (device.connectionStatus == GadgetConnectionStatus.connected) {
        _startSyncTimer(device);
      }
    }
  }

  void _stopGadgetSync() {
    for (final device in _registeredDevices) {
      _stopSyncTimer(device.id);
    }
  }

  /// Register a new gadget device
  Future<GadgetDevice> registerDevice({
    required String name,
    required GadgetType type,
    required String manufacturer,
    required String model,
    required String serialNumber,
    required String firmwareVersion,
    required String hardwareVersion,
    required List<GadgetCapability> capabilities,
    required String connectionType,
    required String macAddress,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
    GadgetDeviceSettings? settings,
    String? notes,
  }) async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required to register device');
      }

      // Check if device already exists
      final existingDevice = _registeredDevices
          .where(
            (d) => d.macAddress == macAddress || d.serialNumber == serialNumber,
          )
          .firstOrNull;

      if (existingDevice != null) {
        throw Exception('Device already registered');
      }

      // Create new device
      final device = GadgetDevice(
        id: _generateDeviceId(),
        name: name,
        type: type,
        manufacturer: manufacturer,
        model: model,
        serialNumber: serialNumber,
        firmwareVersion: firmwareVersion,
        hardwareVersion: hardwareVersion,
        connectionStatus: GadgetConnectionStatus.disconnected,
        syncStatus: GadgetSyncStatus.pending,
        capabilities: capabilities,
        deviceInfo: deviceInfo ?? {},
        lastConnected: DateTime.now(),
        lastSynced: DateTime.now(),
        batteryLevel: 1.0, // Will be updated when connected
        isCharging: false,
        connectionType: connectionType,
        macAddress: macAddress,
        ipAddress: ipAddress ?? '',
        settings: settings?.toJson() ?? const GadgetDeviceSettings().toJson(),
        isActive: true,
        isPrimary: _registeredDevices.isEmpty, // First device is primary
        userId: userProfile.id,
        registeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
      );

      _registeredDevices.add(device);
      await _saveRegisteredDevices();

      // Start monitoring the device
      await _startDeviceMonitoring(device);

      // Notify callbacks
      _onDeviceConnected?.call(device);
      _devicesController.add(_registeredDevices);

      debugPrint('GadgetIntegrationService: Device registered - ${device.id}');
      return device;
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error registering device - $e');
      rethrow;
    }
  }

  /// Connect to a registered device
  Future<void> connectDevice(String deviceId) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      // Update connection status
      final device = _registeredDevices[deviceIndex];
      final updatedDevice = device.copyWith(
        connectionStatus: GadgetConnectionStatus.connecting,
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = updatedDevice;
      await _saveRegisteredDevices();
      _deviceUpdateController.add(updatedDevice);

      // Simulate connection process
      await Future.delayed(const Duration(seconds: 2));

      // Update to connected status
      final connectedDevice = updatedDevice.copyWith(
        connectionStatus: GadgetConnectionStatus.connected,
        lastConnected: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = connectedDevice;
      await _saveRegisteredDevices();

      // Start device monitoring
      await _startDeviceMonitoring(connectedDevice);

      // Start sync timer
      _startSyncTimer(connectedDevice);

      _onDeviceConnected?.call(connectedDevice);
      _deviceUpdateController.add(connectedDevice);

      debugPrint('GadgetIntegrationService: Device connected - $deviceId');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error connecting device - $e');
      rethrow;
    }
  }

  /// Disconnect from a device
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      final device = _registeredDevices[deviceIndex];

      // Stop device monitoring
      _stopDeviceMonitoring(deviceId);
      _stopSyncTimer(deviceId);

      // Update connection status
      final updatedDevice = device.copyWith(
        connectionStatus: GadgetConnectionStatus.disconnected,
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = updatedDevice;
      await _saveRegisteredDevices();

      _onDeviceDisconnected?.call(updatedDevice);
      _deviceUpdateController.add(updatedDevice);

      debugPrint('GadgetIntegrationService: Device disconnected - $deviceId');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error disconnecting device - $e');
      rethrow;
    }
  }

  /// Sync data with a device
  Future<void> syncDevice(String deviceId) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      final device = _registeredDevices[deviceIndex];
      if (device.connectionStatus != GadgetConnectionStatus.connected) {
        throw Exception('Device not connected');
      }

      // Update sync status
      final syncingDevice = device.copyWith(
        syncStatus: GadgetSyncStatus.syncing,
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = syncingDevice;
      await _saveRegisteredDevices();
      _deviceUpdateController.add(syncingDevice);

      // Simulate sync process
      await Future.delayed(const Duration(seconds: 3));

      // Update sync status to completed
      final syncedDevice = syncingDevice.copyWith(
        syncStatus: GadgetSyncStatus.synced,
        lastSynced: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = syncedDevice;
      await _saveRegisteredDevices();

      // Update device statistics
      await _updateDeviceStats(deviceId, syncCompleted: true);

      _onDeviceSynced?.call(syncedDevice);
      _deviceUpdateController.add(syncedDevice);

      debugPrint('GadgetIntegrationService: Device synced - $deviceId');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error syncing device - $e');

      // Update sync status to failed
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex != -1) {
        final device = _registeredDevices[deviceIndex];
        final failedDevice = device.copyWith(
          syncStatus: GadgetSyncStatus.failed,
          updatedAt: DateTime.now(),
        );
        _registeredDevices[deviceIndex] = failedDevice;
        await _saveRegisteredDevices();
        _deviceUpdateController.add(failedDevice);
      }

      rethrow;
    }
  }

  /// Update device settings
  Future<void> updateDeviceSettings(
    String deviceId,
    GadgetDeviceSettings settings,
  ) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      final device = _registeredDevices[deviceIndex];
      final updatedDevice = device.copyWith(
        settings: settings.toJson(),
        updatedAt: DateTime.now(),
      );

      _registeredDevices[deviceIndex] = updatedDevice;
      await _saveRegisteredDevices();

      _deviceUpdateController.add(updatedDevice);
      debugPrint(
        'GadgetIntegrationService: Device settings updated - $deviceId',
      );
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error updating device settings - $e',
      );
      rethrow;
    }
  }

  /// Remove a device
  Future<void> removeDevice(String deviceId) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      // Stop device monitoring
      _stopDeviceMonitoring(deviceId);
      _stopSyncTimer(deviceId);

      // Remove device
      _registeredDevices.removeAt(deviceIndex);
      await _saveRegisteredDevices();

      _devicesController.add(_registeredDevices);
      debugPrint('GadgetIntegrationService: Device removed - $deviceId');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error removing device - $e');
      rethrow;
    }
  }

  /// Update a device
  Future<void> updateDevice(GadgetDevice updatedDevice) async {
    try {
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == updatedDevice.id,
      );
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      // Update the device in the list
      _registeredDevices[deviceIndex] = updatedDevice.copyWith(
        updatedAt: DateTime.now(),
      );

      await _saveRegisteredDevices();
      _deviceUpdateController.add(_registeredDevices[deviceIndex]);

      debugPrint(
        'GadgetIntegrationService: Device updated - ${updatedDevice.id}',
      );
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error updating device - $e');
      rethrow;
    }
  }

  /// Get device by ID
  GadgetDevice? getDevice(String deviceId) {
    try {
      return _registeredDevices.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  /// Get devices by type
  List<GadgetDevice> getDevicesByType(GadgetType type) {
    return _registeredDevices.where((d) => d.type == type).toList();
  }

  /// Get connected devices
  List<GadgetDevice> getConnectedDevices() {
    return _registeredDevices
        .where((d) => d.connectionStatus == GadgetConnectionStatus.connected)
        .toList();
  }

  /// Get primary device
  GadgetDevice? getPrimaryDevice() {
    try {
      return _registeredDevices.firstWhere((d) => d.isPrimary);
    } catch (e) {
      return null;
    }
  }

  /// Set primary device
  Future<void> setPrimaryDevice(String deviceId) async {
    try {
      // Remove primary status from all devices
      for (int i = 0; i < _registeredDevices.length; i++) {
        if (_registeredDevices[i].isPrimary) {
          _registeredDevices[i] = _registeredDevices[i].copyWith(
            isPrimary: false,
          );
        }
      }

      // Set new primary device
      final deviceIndex = _registeredDevices.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex != -1) {
        _registeredDevices[deviceIndex] = _registeredDevices[deviceIndex]
            .copyWith(isPrimary: true, updatedAt: DateTime.now());
      }

      await _saveRegisteredDevices();
      _devicesController.add(_registeredDevices);
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error setting primary device - $e');
      rethrow;
    }
  }

  /// Get device statistics
  List<GadgetDeviceStats> getDeviceStats([String? deviceId]) {
    if (deviceId != null) {
      return _deviceStats.where((s) => s.deviceId == deviceId).toList();
    }
    return List.from(_deviceStats);
  }

  /// Send SOS alert to all connected devices
  Future<void> sendSOSAlertToDevices(SOSSession session) async {
    try {
      final connectedDevices = getConnectedDevices();

      for (final device in connectedDevices) {
        if (device.hasCapability(GadgetCapability.emergencyBroadcast)) {
          await _sendSOSAlertToDevice(device, session);
        }
      }

      debugPrint(
        'GadgetIntegrationService: SOS alert sent to ${connectedDevices.length} devices',
      );
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error sending SOS alert to devices - $e',
      );
    }
  }

  /// Send data to a specific device
  Future<void> sendDataToDevice(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      final device = getDevice(deviceId);
      if (device == null) {
        throw Exception('Device not found');
      }

      if (device.connectionStatus != GadgetConnectionStatus.connected) {
        throw Exception('Device not connected');
      }

      await _sendDataToDevice(device, data);
      debugPrint('GadgetIntegrationService: Data sent to device - $deviceId');
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error sending data to device - $e');
      rethrow;
    }
  }

  /// Receive data from a device
  void receiveDataFromDevice(String deviceId, Map<String, dynamic> data) {
    try {
      final device = getDevice(deviceId);
      if (device != null) {
        _onDeviceDataReceived?.call(device, data);
        _deviceDataController.add({'deviceId': deviceId, 'data': data});

        // Update device statistics
        _updateDeviceStats(deviceId, dataReceived: true);
      }
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error receiving data from device - $e',
      );
    }
  }

  /// Initialize current device (the device running the app)
  Future<void> _initializeCurrentDevice() async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) return;

      // Check if current device is already registered
      final currentDeviceId = await _getCurrentDeviceId();
      if (currentDeviceId != null) {
        final existingDevice = _registeredDevices
            .where((d) => d.id == currentDeviceId)
            .firstOrNull;
        if (existingDevice != null) return;
      }

      // Get device information
      final deviceInfo = await _getCurrentDeviceInfo();
      final batteryLevel = await _battery.batteryLevel / 100.0;
      final isCharging = await _battery.isInBatterySaveMode == false;

      // Create current device
      final currentDevice = GadgetDevice(
        id: await _getCurrentDeviceId() ?? _generateDeviceId(),
        name: '${deviceInfo['model']} (This Device)',
        type: _getDeviceTypeFromInfo(deviceInfo),
        manufacturer: deviceInfo['manufacturer'] ?? 'Unknown',
        model: deviceInfo['model'] ?? 'Unknown',
        serialNumber: deviceInfo['serialNumber'] ?? 'Unknown',
        firmwareVersion: deviceInfo['firmwareVersion'] ?? 'Unknown',
        hardwareVersion: deviceInfo['hardwareVersion'] ?? 'Unknown',
        connectionStatus: GadgetConnectionStatus.connected,
        syncStatus: GadgetSyncStatus.synced,
        capabilities: _getCurrentDeviceCapabilities(),
        deviceInfo: deviceInfo,
        lastConnected: DateTime.now(),
        lastSynced: DateTime.now(),
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        connectionType: 'local',
        macAddress: deviceInfo['macAddress'] ?? 'Unknown',
        ipAddress: deviceInfo['ipAddress'] ?? 'Unknown',
        settings: const GadgetDeviceSettings().toJson(),
        isActive: true,
        isPrimary: _registeredDevices.isEmpty,
        userId: userProfile.id,
        registeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: 'Current device running REDP!NG app',
      );

      _registeredDevices.add(currentDevice);
      await _saveRegisteredDevices();

      // Save current device ID
      await _saveCurrentDeviceId(currentDevice.id);

      debugPrint(
        'GadgetIntegrationService: Current device initialized - ${currentDevice.id}',
      );
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error initializing current device - $e',
      );
    }
  }

  /// Get current device information
  Future<Map<String, dynamic>> _getCurrentDeviceInfo() async {
    try {
      final deviceInfo = <String, dynamic>{};

      // Get platform-specific device info
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo['manufacturer'] = androidInfo.manufacturer;
        deviceInfo['model'] = androidInfo.model;
        deviceInfo['serialNumber'] = androidInfo.id;
        deviceInfo['firmwareVersion'] = androidInfo.version.release;
        deviceInfo['hardwareVersion'] = androidInfo.hardware;
        deviceInfo['macAddress'] = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo['manufacturer'] = 'Apple';
        deviceInfo['model'] = iosInfo.model;
        deviceInfo['serialNumber'] = iosInfo.identifierForVendor;
        deviceInfo['firmwareVersion'] = iosInfo.systemVersion;
        deviceInfo['hardwareVersion'] = iosInfo.model;
        deviceInfo['macAddress'] = iosInfo.identifierForVendor;
      }

      // Get connectivity info
      final connectivityResult = await _connectivity.checkConnectivity();
      deviceInfo['connectivity'] = connectivityResult.first.name;

      // Get battery info
      deviceInfo['batteryLevel'] = await _battery.batteryLevel;
      deviceInfo['isCharging'] = await _battery.isInBatterySaveMode == false;

      return deviceInfo;
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error getting current device info - $e',
      );
      return {};
    }
  }

  /// Get device type from device info
  GadgetType _getDeviceTypeFromInfo(Map<String, dynamic> deviceInfo) {
    final model = deviceInfo['model']?.toString().toLowerCase() ?? '';

    if (model.contains('ipad')) return GadgetType.ipad;
    if (model.contains('tablet')) return GadgetType.tablet;
    if (model.contains('watch')) return GadgetType.smartwatch;
    if (model.contains('car')) return GadgetType.car;
    if (model.contains('laptop')) return GadgetType.laptop;
    if (model.contains('desktop')) return GadgetType.desktop;

    return GadgetType.smartphone; // Default for mobile devices
  }

  /// Get current device capabilities
  List<GadgetCapability> _getCurrentDeviceCapabilities() {
    return [
      GadgetCapability.sosButton,
      GadgetCapability.locationTracking,
      GadgetCapability.crashDetection,
      GadgetCapability.fallDetection,
      GadgetCapability.notifications,
      GadgetCapability.camera,
      GadgetCapability.microphone,
      GadgetCapability.speaker,
      GadgetCapability.bluetooth,
      GadgetCapability.wifi,
      GadgetCapability.cellular,
      GadgetCapability.gps,
      GadgetCapability.accelerometer,
      GadgetCapability.gyroscope,
      GadgetCapability.batteryLevel,
      GadgetCapability.chargingStatus,
      GadgetCapability.networkStatus,
      GadgetCapability.emergencyBroadcast,
      GadgetCapability.dataSync,
    ];
  }

  /// Start device monitoring
  Future<void> _startDeviceMonitoring([GadgetDevice? specificDevice]) async {
    final devicesToMonitor = specificDevice != null
        ? [specificDevice]
        : _registeredDevices;

    for (final device in devicesToMonitor) {
      if (device.connectionStatus == GadgetConnectionStatus.connected) {
        _startDeviceDataCollection(device);
      }
    }
  }

  /// Start device data collection
  void _startDeviceDataCollection(GadgetDevice device) {
    if (_deviceSubscriptions.containsKey(device.id)) return;

    // Start battery monitoring
    if (device.hasCapability(GadgetCapability.batteryLevel)) {
      _deviceSubscriptions[device.id] = _battery.onBatteryStateChanged.listen((
        state,
      ) async {
        final batteryLevel = await _battery.batteryLevel / 100.0;
        final isCharging = !await _battery.isInBatterySaveMode;
        _updateDeviceBatteryLevel(device.id, batteryLevel, isCharging);
      });
    }

    // Start location monitoring
    if (device.hasCapability(GadgetCapability.locationTracking)) {
      // TODO: Implement location callback when location_info model is available
      // _locationService.setLocationUpdateCallback((location) {
      //   _updateDeviceLocation(device.id, location);
      // });
    }

    // Start sensor monitoring
    if (device.hasCapability(GadgetCapability.accelerometer)) {
      _sensorService.setSensorUpdateCallback((reading) {
        _updateDeviceSensorData(device.id, reading);
      });
    }
  }

  /// Stop device monitoring
  void _stopDeviceMonitoring(String deviceId) {
    _deviceSubscriptions[deviceId]?.cancel();
    _deviceSubscriptions.remove(deviceId);
  }

  /// Start sync timer for device
  void _startSyncTimer(GadgetDevice device) {
    if (_syncTimers.containsKey(device.id)) return;

    _syncTimers[device.id] = Timer.periodic(
      const Duration(minutes: 5), // Sync every 5 minutes
      (_) => syncDevice(device.id),
    );
  }

  /// Stop sync timer for device
  void _stopSyncTimer(String deviceId) {
    _syncTimers[deviceId]?.cancel();
    _syncTimers.remove(deviceId);
  }

  /// Update device battery level
  void _updateDeviceBatteryLevel(
    String deviceId,
    double level,
    bool isCharging,
  ) {
    final deviceIndex = _registeredDevices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex != -1) {
      final device = _registeredDevices[deviceIndex];
      final updatedDevice = device.copyWith(
        batteryLevel: level,
        isCharging: isCharging,
        updatedAt: DateTime.now(),
      );
      _registeredDevices[deviceIndex] = updatedDevice;
      _deviceUpdateController.add(updatedDevice);
    }
  }

  /// Update device location

  /// Update device sensor data
  void _updateDeviceSensorData(String deviceId, dynamic reading) {
    // Update device statistics
    _updateDeviceStats(deviceId, sensorReadings: 1);
  }

  /// Send SOS alert to device
  Future<void> _sendSOSAlertToDevice(
    GadgetDevice device,
    SOSSession session,
  ) async {
    try {
      final alertData = {
        'type': 'sos_alert',
        'sessionId': session.id,
        'userId': session.userId,
        'location': session.location.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'priority': 'critical',
      };

      await _sendDataToDevice(device, alertData);

      // Update device statistics
      _updateDeviceStats(device.id, emergencyActivations: 1);
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error sending SOS alert to device - $e',
      );
    }
  }

  /// Send data to device
  Future<void> _sendDataToDevice(
    GadgetDevice device,
    Map<String, dynamic> data,
  ) async {
    // In a real implementation, this would send data via Bluetooth, WiFi, or other protocols
    // For now, we'll simulate the data transmission
    await Future.delayed(const Duration(milliseconds: 100));

    // Update device statistics
    _updateDeviceStats(device.id, dataSent: true);
  }

  /// Update device statistics
  Future<void> _updateDeviceStats(
    String deviceId, {
    bool? syncCompleted,
    bool? dataReceived,
    bool? dataSent,
    int? locationUpdates,
    int? sensorReadings,
    int? emergencyActivations,
  }) async {
    try {
      final today = DateTime.now();

      final existingStats = _deviceStats
          .where((s) => s.deviceId == deviceId && s.date.day == today.day)
          .firstOrNull;

      GadgetDeviceStats updatedStats;
      if (existingStats != null) {
        updatedStats = existingStats.copyWith(
          syncCount: syncCompleted == true
              ? existingStats.syncCount + 1
              : existingStats.syncCount,
          successfulSyncs: syncCompleted == true
              ? existingStats.successfulSyncs + 1
              : existingStats.successfulSyncs,
          locationUpdates: locationUpdates != null
              ? existingStats.locationUpdates + locationUpdates
              : existingStats.locationUpdates,
          emergencyActivations: emergencyActivations != null
              ? existingStats.emergencyActivations + emergencyActivations
              : existingStats.emergencyActivations,
        );

        final index = _deviceStats.indexOf(existingStats);
        _deviceStats[index] = updatedStats;
      } else {
        updatedStats = GadgetDeviceStats(
          deviceId: deviceId,
          date: today,
          syncCount: syncCompleted == true ? 1 : 0,
          successfulSyncs: syncCompleted == true ? 1 : 0,
          locationUpdates: locationUpdates ?? 0,
          emergencyActivations: emergencyActivations ?? 0,
        );
        _deviceStats.add(updatedStats);
      }

      await _saveDeviceStats();
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error updating device stats - $e');
    }
  }

  /// Load registered devices from storage
  Future<void> _loadRegisteredDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = prefs.getString('registered_gadget_devices') ?? '[]';
      final devicesList = jsonDecode(devicesJson) as List;

      _registeredDevices = devicesList
          .map((json) => GadgetDevice.fromJson(json))
          .toList();

      debugPrint(
        'GadgetIntegrationService: Loaded ${_registeredDevices.length} registered devices',
      );
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error loading registered devices - $e',
      );
      _registeredDevices = [];
    }
  }

  /// Save registered devices to storage
  Future<void> _saveRegisteredDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = jsonEncode(
        _registeredDevices.map((device) => device.toJson()).toList(),
      );
      await prefs.setString('registered_gadget_devices', devicesJson);
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error saving registered devices - $e',
      );
    }
  }

  /// Load device statistics from storage
  Future<void> _loadDeviceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('gadget_device_stats') ?? '[]';
      final statsList = jsonDecode(statsJson) as List;

      _deviceStats = statsList
          .map((json) => GadgetDeviceStats.fromJson(json))
          .toList();

      debugPrint(
        'GadgetIntegrationService: Loaded ${_deviceStats.length} device stats',
      );
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error loading device stats - $e');
      _deviceStats = [];
    }
  }

  /// Save device statistics to storage
  Future<void> _saveDeviceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = jsonEncode(
        _deviceStats.map((stats) => stats.toJson()).toList(),
      );
      await prefs.setString('gadget_device_stats', statsJson);
    } catch (e) {
      debugPrint('GadgetIntegrationService: Error saving device stats - $e');
    }
  }

  /// Get current device ID
  Future<String?> _getCurrentDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_device_id');
    } catch (e) {
      return null;
    }
  }

  /// Save current device ID
  Future<void> _saveCurrentDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_device_id', deviceId);
    } catch (e) {
      debugPrint(
        'GadgetIntegrationService: Error saving current device ID - $e',
      );
    }
  }

  /// Generate unique device ID
  String _generateDeviceId() {
    return 'GADGET_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Getters
  List<GadgetDevice> get registeredDevices =>
      List.unmodifiable(_registeredDevices);
  List<GadgetDeviceStats> get deviceStats => List.unmodifiable(_deviceStats);
  bool get isInitialized => _isInitialized;

  // Streams
  Stream<List<GadgetDevice>> get devicesStream => _devicesController.stream;
  Stream<GadgetDevice> get deviceUpdateStream => _deviceUpdateController.stream;
  Stream<Map<String, dynamic>> get deviceDataStream =>
      _deviceDataController.stream;

  // Event handlers
  void setDeviceConnectedCallback(Function(GadgetDevice) callback) {
    _onDeviceConnected = callback;
  }

  void setDeviceDisconnectedCallback(Function(GadgetDevice) callback) {
    _onDeviceDisconnected = callback;
  }

  void setDeviceSyncedCallback(Function(GadgetDevice) callback) {
    _onDeviceSynced = callback;
  }

  void setDeviceDataReceivedCallback(
    Function(GadgetDevice, Map<String, dynamic>) callback,
  ) {
    _onDeviceDataReceived = callback;
  }

  /// Dispose of the service
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _deviceSubscriptions.values) {
      subscription.cancel();
    }
    _deviceSubscriptions.clear();

    // Cancel all timers
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();

    // Close stream controllers
    _devicesController.close();
    _deviceUpdateController.close();
    _deviceDataController.close();
  }
}
