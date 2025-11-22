import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gadget_device.g.dart';

/// Enumeration of supported gadget device types
enum GadgetType {
  @JsonValue('smartwatch')
  smartwatch,
  @JsonValue('car')
  car,
  @JsonValue('tablet')
  tablet,
  @JsonValue('ipad')
  ipad,
  @JsonValue('laptop')
  laptop,
  @JsonValue('desktop')
  desktop,
  @JsonValue('headphones')
  headphones,
  @JsonValue('smartphone')
  smartphone,
  @JsonValue('fitness_tracker')
  fitnessTracker,
  @JsonValue('drone')
  drone,
  @JsonValue('smart_glasses')
  smartGlasses,
  @JsonValue('vr_headset')
  vrHeadset,
  @JsonValue('iot_sensor')
  iotSensor,
  @JsonValue('security_camera')
  securityCamera,
  @JsonValue('smart_speaker')
  smartSpeaker,
  @JsonValue('other')
  other,
}

/// Enumeration of gadget connection status
enum GadgetConnectionStatus {
  @JsonValue('disconnected')
  disconnected,
  @JsonValue('connecting')
  connecting,
  @JsonValue('connected')
  connected,
  @JsonValue('error')
  error,
  @JsonValue('unknown')
  unknown,
}

/// Enumeration of gadget synchronization status
enum GadgetSyncStatus {
  @JsonValue('synced')
  synced,
  @JsonValue('syncing')
  syncing,
  @JsonValue('pending')
  pending,
  @JsonValue('failed')
  failed,
  @JsonValue('not_supported')
  notSupported,
}

/// Enumeration of gadget capabilities
enum GadgetCapability {
  @JsonValue('sos_button')
  sosButton,
  @JsonValue('location_tracking')
  locationTracking,
  @JsonValue('crash_detection')
  crashDetection,
  @JsonValue('fall_detection')
  fallDetection,
  @JsonValue('heart_rate_monitoring')
  heartRateMonitoring,
  @JsonValue('voice_commands')
  voiceCommands,
  @JsonValue('notifications')
  notifications,
  @JsonValue('camera')
  camera,
  @JsonValue('microphone')
  microphone,
  @JsonValue('speaker')
  speaker,
  @JsonValue('bluetooth')
  bluetooth,
  @JsonValue('wifi')
  wifi,
  @JsonValue('cellular')
  cellular,
  @JsonValue('gps')
  gps,
  @JsonValue('accelerometer')
  accelerometer,
  @JsonValue('gyroscope')
  gyroscope,
  @JsonValue('magnetometer')
  magnetometer,
  @JsonValue('barometer')
  barometer,
  @JsonValue('temperature')
  temperature,
  @JsonValue('humidity')
  humidity,
  @JsonValue('light')
  light,
  @JsonValue('proximity')
  proximity,
  @JsonValue('battery_level')
  batteryLevel,
  @JsonValue('charging_status')
  chargingStatus,
  @JsonValue('storage_space')
  storageSpace,
  @JsonValue('network_status')
  networkStatus,
  @JsonValue('emergency_broadcast')
  emergencyBroadcast,
  @JsonValue('sos_automatic')
  sosAutomatic,
  @JsonValue('family_sharing')
  familySharing,
  @JsonValue('remote_monitoring')
  remoteMonitoring,
  @JsonValue('data_sync')
  dataSync,
  @JsonValue('firmware_update')
  firmwareUpdate,
  @JsonValue('diagnostics')
  diagnostics,
  @JsonValue('maintenance_alerts')
  maintenanceAlerts,
}

/// Model representing a gadget device
@JsonSerializable()
class GadgetDevice extends Equatable {
  final String id;
  final String name;
  final GadgetType type;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String firmwareVersion;
  final String hardwareVersion;
  final GadgetConnectionStatus connectionStatus;
  final GadgetSyncStatus syncStatus;
  final List<GadgetCapability> capabilities;
  final Map<String, dynamic> deviceInfo;
  final DateTime lastConnected;
  final DateTime lastSynced;
  final double batteryLevel;
  final bool isCharging;
  final String connectionType; // bluetooth, wifi, cellular, usb
  final String macAddress;
  final String ipAddress;
  final Map<String, dynamic> settings;
  final bool isActive;
  final bool isPrimary;
  final String userId;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const GadgetDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.connectionStatus,
    required this.syncStatus,
    required this.capabilities,
    required this.deviceInfo,
    required this.lastConnected,
    required this.lastSynced,
    required this.batteryLevel,
    required this.isCharging,
    required this.connectionType,
    required this.macAddress,
    this.ipAddress = '',
    this.settings = const {},
    this.isActive = true,
    this.isPrimary = false,
    required this.userId,
    required this.registeredAt,
    required this.updatedAt,
    this.notes,
    this.metadata,
  });

  factory GadgetDevice.fromJson(Map<String, dynamic> json) =>
      _$GadgetDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$GadgetDeviceToJson(this);

  GadgetDevice copyWith({
    String? id,
    String? name,
    GadgetType? type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? firmwareVersion,
    String? hardwareVersion,
    GadgetConnectionStatus? connectionStatus,
    GadgetSyncStatus? syncStatus,
    List<GadgetCapability>? capabilities,
    Map<String, dynamic>? deviceInfo,
    DateTime? lastConnected,
    DateTime? lastSynced,
    double? batteryLevel,
    bool? isCharging,
    String? connectionType,
    String? macAddress,
    String? ipAddress,
    Map<String, dynamic>? settings,
    bool? isActive,
    bool? isPrimary,
    String? userId,
    DateTime? registeredAt,
    DateTime? updatedAt,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return GadgetDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      capabilities: capabilities ?? this.capabilities,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      lastConnected: lastConnected ?? this.lastConnected,
      lastSynced: lastSynced ?? this.lastSynced,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      connectionType: connectionType ?? this.connectionType,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
      userId: userId ?? this.userId,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    manufacturer,
    model,
    serialNumber,
    firmwareVersion,
    hardwareVersion,
    connectionStatus,
    syncStatus,
    capabilities,
    deviceInfo,
    lastConnected,
    lastSynced,
    batteryLevel,
    isCharging,
    connectionType,
    macAddress,
    ipAddress,
    settings,
    isActive,
    isPrimary,
    userId,
    registeredAt,
    updatedAt,
    notes,
    metadata,
  ];

  /// Get device type display name
  String get typeDisplayName {
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

  /// Get connection status display name
  String get connectionStatusDisplayName {
    switch (connectionStatus) {
      case GadgetConnectionStatus.disconnected:
        return 'Disconnected';
      case GadgetConnectionStatus.connecting:
        return 'Connecting';
      case GadgetConnectionStatus.connected:
        return 'Connected';
      case GadgetConnectionStatus.error:
        return 'Error';
      case GadgetConnectionStatus.unknown:
        return 'Unknown';
    }
  }

  /// Get sync status display name
  String get syncStatusDisplayName {
    switch (syncStatus) {
      case GadgetSyncStatus.synced:
        return 'Synced';
      case GadgetSyncStatus.syncing:
        return 'Syncing';
      case GadgetSyncStatus.pending:
        return 'Pending';
      case GadgetSyncStatus.failed:
        return 'Failed';
      case GadgetSyncStatus.notSupported:
        return 'Not Supported';
    }
  }

  /// Check if device has a specific capability
  bool hasCapability(GadgetCapability capability) {
    return capabilities.contains(capability);
  }

  /// Get battery status text
  String get batteryStatusText {
    if (isCharging) {
      return 'Charging (${(batteryLevel * 100).toInt()}%)';
    } else {
      return '${(batteryLevel * 100).toInt()}%';
    }
  }

  /// Check if device is online
  bool get isOnline {
    return connectionStatus == GadgetConnectionStatus.connected;
  }

  /// Check if device supports emergency features
  bool get supportsEmergencyFeatures {
    return hasCapability(GadgetCapability.sosButton) ||
        hasCapability(GadgetCapability.sosAutomatic) ||
        hasCapability(GadgetCapability.emergencyBroadcast);
  }

  /// Get device icon based on type
  String get deviceIcon {
    switch (type) {
      case GadgetType.smartwatch:
        return '⌚';
      case GadgetType.car:
        return '🚗';
      case GadgetType.tablet:
        return '📱';
      case GadgetType.ipad:
        return '📱';
      case GadgetType.laptop:
        return '💻';
      case GadgetType.desktop:
        return '🖥️';
      case GadgetType.headphones:
        return '🎧';
      case GadgetType.smartphone:
        return '📱';
      case GadgetType.fitnessTracker:
        return '🏃';
      case GadgetType.drone:
        return '🚁';
      case GadgetType.smartGlasses:
        return '🥽';
      case GadgetType.vrHeadset:
        return '🥽';
      case GadgetType.iotSensor:
        return '📡';
      case GadgetType.securityCamera:
        return '📹';
      case GadgetType.smartSpeaker:
        return '🔊';
      case GadgetType.other:
        return '📱';
    }
  }
}

/// Model representing gadget device settings
@JsonSerializable()
class GadgetDeviceSettings extends Equatable {
  final bool autoConnect;
  final bool autoSync;
  final bool emergencyNotifications;
  final bool locationSharing;
  final bool crashDetection;
  final bool fallDetection;
  final bool heartRateMonitoring;
  final bool voiceCommands;
  final bool notifications;
  final bool camera;
  final bool microphone;
  final bool speaker;
  final bool bluetooth;
  final bool wifi;
  final bool cellular;
  final bool gps;
  final bool accelerometer;
  final bool gyroscope;
  final bool magnetometer;
  final bool barometer;
  final bool temperature;
  final bool humidity;
  final bool light;
  final bool proximity;
  final bool batteryLevel;
  final bool chargingStatus;
  final bool storageSpace;
  final bool networkStatus;
  final bool emergencyBroadcast;
  final bool sosAutomatic;
  final bool familySharing;
  final bool remoteMonitoring;
  final bool dataSync;
  final bool firmwareUpdate;
  final bool diagnostics;
  final bool maintenanceAlerts;
  final Map<String, dynamic> customSettings;

  const GadgetDeviceSettings({
    this.autoConnect = true,
    this.autoSync = true,
    this.emergencyNotifications = true,
    this.locationSharing = true,
    this.crashDetection = true,
    this.fallDetection = true,
    this.heartRateMonitoring = false,
    this.voiceCommands = false,
    this.notifications = true,
    this.camera = false,
    this.microphone = false,
    this.speaker = true,
    this.bluetooth = true,
    this.wifi = true,
    this.cellular = false,
    this.gps = true,
    this.accelerometer = true,
    this.gyroscope = true,
    this.magnetometer = false,
    this.barometer = false,
    this.temperature = false,
    this.humidity = false,
    this.light = false,
    this.proximity = false,
    this.batteryLevel = true,
    this.chargingStatus = true,
    this.storageSpace = false,
    this.networkStatus = true,
    this.emergencyBroadcast = true,
    this.sosAutomatic = false,
    this.familySharing = false,
    this.remoteMonitoring = false,
    this.dataSync = true,
    this.firmwareUpdate = true,
    this.diagnostics = true,
    this.maintenanceAlerts = true,
    this.customSettings = const {},
  });

  factory GadgetDeviceSettings.fromJson(Map<String, dynamic> json) =>
      _$GadgetDeviceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$GadgetDeviceSettingsToJson(this);

  GadgetDeviceSettings copyWith({
    bool? autoConnect,
    bool? autoSync,
    bool? emergencyNotifications,
    bool? locationSharing,
    bool? crashDetection,
    bool? fallDetection,
    bool? heartRateMonitoring,
    bool? voiceCommands,
    bool? notifications,
    bool? camera,
    bool? microphone,
    bool? speaker,
    bool? bluetooth,
    bool? wifi,
    bool? cellular,
    bool? gps,
    bool? accelerometer,
    bool? gyroscope,
    bool? magnetometer,
    bool? barometer,
    bool? temperature,
    bool? humidity,
    bool? light,
    bool? proximity,
    bool? batteryLevel,
    bool? chargingStatus,
    bool? storageSpace,
    bool? networkStatus,
    bool? emergencyBroadcast,
    bool? sosAutomatic,
    bool? familySharing,
    bool? remoteMonitoring,
    bool? dataSync,
    bool? firmwareUpdate,
    bool? diagnostics,
    bool? maintenanceAlerts,
    Map<String, dynamic>? customSettings,
  }) {
    return GadgetDeviceSettings(
      autoConnect: autoConnect ?? this.autoConnect,
      autoSync: autoSync ?? this.autoSync,
      emergencyNotifications:
          emergencyNotifications ?? this.emergencyNotifications,
      locationSharing: locationSharing ?? this.locationSharing,
      crashDetection: crashDetection ?? this.crashDetection,
      fallDetection: fallDetection ?? this.fallDetection,
      heartRateMonitoring: heartRateMonitoring ?? this.heartRateMonitoring,
      voiceCommands: voiceCommands ?? this.voiceCommands,
      notifications: notifications ?? this.notifications,
      camera: camera ?? this.camera,
      microphone: microphone ?? this.microphone,
      speaker: speaker ?? this.speaker,
      bluetooth: bluetooth ?? this.bluetooth,
      wifi: wifi ?? this.wifi,
      cellular: cellular ?? this.cellular,
      gps: gps ?? this.gps,
      accelerometer: accelerometer ?? this.accelerometer,
      gyroscope: gyroscope ?? this.gyroscope,
      magnetometer: magnetometer ?? this.magnetometer,
      barometer: barometer ?? this.barometer,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      light: light ?? this.light,
      proximity: proximity ?? this.proximity,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      chargingStatus: chargingStatus ?? this.chargingStatus,
      storageSpace: storageSpace ?? this.storageSpace,
      networkStatus: networkStatus ?? this.networkStatus,
      emergencyBroadcast: emergencyBroadcast ?? this.emergencyBroadcast,
      sosAutomatic: sosAutomatic ?? this.sosAutomatic,
      familySharing: familySharing ?? this.familySharing,
      remoteMonitoring: remoteMonitoring ?? this.remoteMonitoring,
      dataSync: dataSync ?? this.dataSync,
      firmwareUpdate: firmwareUpdate ?? this.firmwareUpdate,
      diagnostics: diagnostics ?? this.diagnostics,
      maintenanceAlerts: maintenanceAlerts ?? this.maintenanceAlerts,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
    autoConnect,
    autoSync,
    emergencyNotifications,
    locationSharing,
    crashDetection,
    fallDetection,
    heartRateMonitoring,
    voiceCommands,
    notifications,
    camera,
    microphone,
    speaker,
    bluetooth,
    wifi,
    cellular,
    gps,
    accelerometer,
    gyroscope,
    magnetometer,
    barometer,
    temperature,
    humidity,
    light,
    proximity,
    batteryLevel,
    chargingStatus,
    storageSpace,
    networkStatus,
    emergencyBroadcast,
    sosAutomatic,
    familySharing,
    remoteMonitoring,
    dataSync,
    firmwareUpdate,
    diagnostics,
    maintenanceAlerts,
    customSettings,
  ];
}

/// Model representing gadget device statistics
@JsonSerializable()
class GadgetDeviceStats extends Equatable {
  final String deviceId;
  final DateTime date;
  final int connectionCount;
  final Duration totalConnectedTime;
  final int syncCount;
  final int successfulSyncs;
  final int failedSyncs;
  final double averageBatteryLevel;
  final int emergencyActivations;
  final int sosButtonPresses;
  final int crashDetections;
  final int fallDetections;
  final int heartRateReadings;
  final int locationUpdates;
  final int notificationsSent;
  final int notificationsReceived;
  final Map<String, dynamic> customStats;

  const GadgetDeviceStats({
    required this.deviceId,
    required this.date,
    this.connectionCount = 0,
    this.totalConnectedTime = Duration.zero,
    this.syncCount = 0,
    this.successfulSyncs = 0,
    this.failedSyncs = 0,
    this.averageBatteryLevel = 0.0,
    this.emergencyActivations = 0,
    this.sosButtonPresses = 0,
    this.crashDetections = 0,
    this.fallDetections = 0,
    this.heartRateReadings = 0,
    this.locationUpdates = 0,
    this.notificationsSent = 0,
    this.notificationsReceived = 0,
    this.customStats = const {},
  });

  factory GadgetDeviceStats.fromJson(Map<String, dynamic> json) =>
      _$GadgetDeviceStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GadgetDeviceStatsToJson(this);

  GadgetDeviceStats copyWith({
    String? deviceId,
    DateTime? date,
    int? connectionCount,
    Duration? totalConnectedTime,
    int? syncCount,
    int? successfulSyncs,
    int? failedSyncs,
    double? averageBatteryLevel,
    int? emergencyActivations,
    int? sosButtonPresses,
    int? crashDetections,
    int? fallDetections,
    int? heartRateReadings,
    int? locationUpdates,
    int? notificationsSent,
    int? notificationsReceived,
    Map<String, dynamic>? customStats,
  }) {
    return GadgetDeviceStats(
      deviceId: deviceId ?? this.deviceId,
      date: date ?? this.date,
      connectionCount: connectionCount ?? this.connectionCount,
      totalConnectedTime: totalConnectedTime ?? this.totalConnectedTime,
      syncCount: syncCount ?? this.syncCount,
      successfulSyncs: successfulSyncs ?? this.successfulSyncs,
      failedSyncs: failedSyncs ?? this.failedSyncs,
      averageBatteryLevel: averageBatteryLevel ?? this.averageBatteryLevel,
      emergencyActivations: emergencyActivations ?? this.emergencyActivations,
      sosButtonPresses: sosButtonPresses ?? this.sosButtonPresses,
      crashDetections: crashDetections ?? this.crashDetections,
      fallDetections: fallDetections ?? this.fallDetections,
      heartRateReadings: heartRateReadings ?? this.heartRateReadings,
      locationUpdates: locationUpdates ?? this.locationUpdates,
      notificationsSent: notificationsSent ?? this.notificationsSent,
      notificationsReceived:
          notificationsReceived ?? this.notificationsReceived,
      customStats: customStats ?? this.customStats,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    date,
    connectionCount,
    totalConnectedTime,
    syncCount,
    successfulSyncs,
    failedSyncs,
    averageBatteryLevel,
    emergencyActivations,
    sosButtonPresses,
    crashDetections,
    fallDetections,
    heartRateReadings,
    locationUpdates,
    notificationsSent,
    notificationsReceived,
    customStats,
  ];

  /// Get sync success rate
  double get syncSuccessRate {
    if (syncCount == 0) return 0.0;
    return successfulSyncs / syncCount;
  }

  /// Get average connection time per session
  Duration get averageConnectionTime {
    if (connectionCount == 0) return Duration.zero;
    return Duration(
      milliseconds: totalConnectedTime.inMilliseconds ~/ connectionCount,
    );
  }
}
