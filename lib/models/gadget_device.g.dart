// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gadget_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GadgetDevice _$GadgetDeviceFromJson(Map<String, dynamic> json) => GadgetDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$GadgetTypeEnumMap, json['type']),
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      serialNumber: json['serialNumber'] as String,
      firmwareVersion: json['firmwareVersion'] as String,
      hardwareVersion: json['hardwareVersion'] as String,
      connectionStatus: $enumDecode(
          _$GadgetConnectionStatusEnumMap, json['connectionStatus']),
      syncStatus: $enumDecode(_$GadgetSyncStatusEnumMap, json['syncStatus']),
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => $enumDecode(_$GadgetCapabilityEnumMap, e))
          .toList(),
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>,
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      lastSynced: DateTime.parse(json['lastSynced'] as String),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      isCharging: json['isCharging'] as bool,
      connectionType: json['connectionType'] as String,
      macAddress: json['macAddress'] as String,
      ipAddress: json['ipAddress'] as String? ?? '',
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
      isActive: json['isActive'] as bool? ?? true,
      isPrimary: json['isPrimary'] as bool? ?? false,
      userId: json['userId'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GadgetDeviceToJson(GadgetDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$GadgetTypeEnumMap[instance.type]!,
      'manufacturer': instance.manufacturer,
      'model': instance.model,
      'serialNumber': instance.serialNumber,
      'firmwareVersion': instance.firmwareVersion,
      'hardwareVersion': instance.hardwareVersion,
      'connectionStatus':
          _$GadgetConnectionStatusEnumMap[instance.connectionStatus]!,
      'syncStatus': _$GadgetSyncStatusEnumMap[instance.syncStatus]!,
      'capabilities': instance.capabilities
          .map((e) => _$GadgetCapabilityEnumMap[e]!)
          .toList(),
      'deviceInfo': instance.deviceInfo,
      'lastConnected': instance.lastConnected.toIso8601String(),
      'lastSynced': instance.lastSynced.toIso8601String(),
      'batteryLevel': instance.batteryLevel,
      'isCharging': instance.isCharging,
      'connectionType': instance.connectionType,
      'macAddress': instance.macAddress,
      'ipAddress': instance.ipAddress,
      'settings': instance.settings,
      'isActive': instance.isActive,
      'isPrimary': instance.isPrimary,
      'userId': instance.userId,
      'registeredAt': instance.registeredAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notes': instance.notes,
      'metadata': instance.metadata,
    };

const _$GadgetTypeEnumMap = {
  GadgetType.smartwatch: 'smartwatch',
  GadgetType.car: 'car',
  GadgetType.tablet: 'tablet',
  GadgetType.ipad: 'ipad',
  GadgetType.laptop: 'laptop',
  GadgetType.desktop: 'desktop',
  GadgetType.headphones: 'headphones',
  GadgetType.smartphone: 'smartphone',
  GadgetType.fitnessTracker: 'fitness_tracker',
  GadgetType.drone: 'drone',
  GadgetType.smartGlasses: 'smart_glasses',
  GadgetType.vrHeadset: 'vr_headset',
  GadgetType.iotSensor: 'iot_sensor',
  GadgetType.securityCamera: 'security_camera',
  GadgetType.smartSpeaker: 'smart_speaker',
  GadgetType.other: 'other',
};

const _$GadgetConnectionStatusEnumMap = {
  GadgetConnectionStatus.disconnected: 'disconnected',
  GadgetConnectionStatus.connecting: 'connecting',
  GadgetConnectionStatus.connected: 'connected',
  GadgetConnectionStatus.error: 'error',
  GadgetConnectionStatus.unknown: 'unknown',
};

const _$GadgetSyncStatusEnumMap = {
  GadgetSyncStatus.synced: 'synced',
  GadgetSyncStatus.syncing: 'syncing',
  GadgetSyncStatus.pending: 'pending',
  GadgetSyncStatus.failed: 'failed',
  GadgetSyncStatus.notSupported: 'not_supported',
};

const _$GadgetCapabilityEnumMap = {
  GadgetCapability.sosButton: 'sos_button',
  GadgetCapability.locationTracking: 'location_tracking',
  GadgetCapability.crashDetection: 'crash_detection',
  GadgetCapability.fallDetection: 'fall_detection',
  GadgetCapability.heartRateMonitoring: 'heart_rate_monitoring',
  GadgetCapability.voiceCommands: 'voice_commands',
  GadgetCapability.notifications: 'notifications',
  GadgetCapability.camera: 'camera',
  GadgetCapability.microphone: 'microphone',
  GadgetCapability.speaker: 'speaker',
  GadgetCapability.bluetooth: 'bluetooth',
  GadgetCapability.wifi: 'wifi',
  GadgetCapability.cellular: 'cellular',
  GadgetCapability.gps: 'gps',
  GadgetCapability.accelerometer: 'accelerometer',
  GadgetCapability.gyroscope: 'gyroscope',
  GadgetCapability.magnetometer: 'magnetometer',
  GadgetCapability.barometer: 'barometer',
  GadgetCapability.temperature: 'temperature',
  GadgetCapability.humidity: 'humidity',
  GadgetCapability.light: 'light',
  GadgetCapability.proximity: 'proximity',
  GadgetCapability.batteryLevel: 'battery_level',
  GadgetCapability.chargingStatus: 'charging_status',
  GadgetCapability.storageSpace: 'storage_space',
  GadgetCapability.networkStatus: 'network_status',
  GadgetCapability.emergencyBroadcast: 'emergency_broadcast',
  GadgetCapability.sosAutomatic: 'sos_automatic',
  GadgetCapability.familySharing: 'family_sharing',
  GadgetCapability.remoteMonitoring: 'remote_monitoring',
  GadgetCapability.dataSync: 'data_sync',
  GadgetCapability.firmwareUpdate: 'firmware_update',
  GadgetCapability.diagnostics: 'diagnostics',
  GadgetCapability.maintenanceAlerts: 'maintenance_alerts',
};

GadgetDeviceSettings _$GadgetDeviceSettingsFromJson(
        Map<String, dynamic> json) =>
    GadgetDeviceSettings(
      autoConnect: json['autoConnect'] as bool? ?? true,
      autoSync: json['autoSync'] as bool? ?? true,
      emergencyNotifications: json['emergencyNotifications'] as bool? ?? true,
      locationSharing: json['locationSharing'] as bool? ?? true,
      crashDetection: json['crashDetection'] as bool? ?? true,
      fallDetection: json['fallDetection'] as bool? ?? true,
      heartRateMonitoring: json['heartRateMonitoring'] as bool? ?? false,
      voiceCommands: json['voiceCommands'] as bool? ?? false,
      notifications: json['notifications'] as bool? ?? true,
      camera: json['camera'] as bool? ?? false,
      microphone: json['microphone'] as bool? ?? false,
      speaker: json['speaker'] as bool? ?? true,
      bluetooth: json['bluetooth'] as bool? ?? true,
      wifi: json['wifi'] as bool? ?? true,
      cellular: json['cellular'] as bool? ?? false,
      gps: json['gps'] as bool? ?? true,
      accelerometer: json['accelerometer'] as bool? ?? true,
      gyroscope: json['gyroscope'] as bool? ?? true,
      magnetometer: json['magnetometer'] as bool? ?? false,
      barometer: json['barometer'] as bool? ?? false,
      temperature: json['temperature'] as bool? ?? false,
      humidity: json['humidity'] as bool? ?? false,
      light: json['light'] as bool? ?? false,
      proximity: json['proximity'] as bool? ?? false,
      batteryLevel: json['batteryLevel'] as bool? ?? true,
      chargingStatus: json['chargingStatus'] as bool? ?? true,
      storageSpace: json['storageSpace'] as bool? ?? false,
      networkStatus: json['networkStatus'] as bool? ?? true,
      emergencyBroadcast: json['emergencyBroadcast'] as bool? ?? true,
      sosAutomatic: json['sosAutomatic'] as bool? ?? false,
      familySharing: json['familySharing'] as bool? ?? false,
      remoteMonitoring: json['remoteMonitoring'] as bool? ?? false,
      dataSync: json['dataSync'] as bool? ?? true,
      firmwareUpdate: json['firmwareUpdate'] as bool? ?? true,
      diagnostics: json['diagnostics'] as bool? ?? true,
      maintenanceAlerts: json['maintenanceAlerts'] as bool? ?? true,
      customSettings:
          json['customSettings'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$GadgetDeviceSettingsToJson(
        GadgetDeviceSettings instance) =>
    <String, dynamic>{
      'autoConnect': instance.autoConnect,
      'autoSync': instance.autoSync,
      'emergencyNotifications': instance.emergencyNotifications,
      'locationSharing': instance.locationSharing,
      'crashDetection': instance.crashDetection,
      'fallDetection': instance.fallDetection,
      'heartRateMonitoring': instance.heartRateMonitoring,
      'voiceCommands': instance.voiceCommands,
      'notifications': instance.notifications,
      'camera': instance.camera,
      'microphone': instance.microphone,
      'speaker': instance.speaker,
      'bluetooth': instance.bluetooth,
      'wifi': instance.wifi,
      'cellular': instance.cellular,
      'gps': instance.gps,
      'accelerometer': instance.accelerometer,
      'gyroscope': instance.gyroscope,
      'magnetometer': instance.magnetometer,
      'barometer': instance.barometer,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'light': instance.light,
      'proximity': instance.proximity,
      'batteryLevel': instance.batteryLevel,
      'chargingStatus': instance.chargingStatus,
      'storageSpace': instance.storageSpace,
      'networkStatus': instance.networkStatus,
      'emergencyBroadcast': instance.emergencyBroadcast,
      'sosAutomatic': instance.sosAutomatic,
      'familySharing': instance.familySharing,
      'remoteMonitoring': instance.remoteMonitoring,
      'dataSync': instance.dataSync,
      'firmwareUpdate': instance.firmwareUpdate,
      'diagnostics': instance.diagnostics,
      'maintenanceAlerts': instance.maintenanceAlerts,
      'customSettings': instance.customSettings,
    };

GadgetDeviceStats _$GadgetDeviceStatsFromJson(Map<String, dynamic> json) =>
    GadgetDeviceStats(
      deviceId: json['deviceId'] as String,
      date: DateTime.parse(json['date'] as String),
      connectionCount: (json['connectionCount'] as num?)?.toInt() ?? 0,
      totalConnectedTime: json['totalConnectedTime'] == null
          ? Duration.zero
          : Duration(microseconds: (json['totalConnectedTime'] as num).toInt()),
      syncCount: (json['syncCount'] as num?)?.toInt() ?? 0,
      successfulSyncs: (json['successfulSyncs'] as num?)?.toInt() ?? 0,
      failedSyncs: (json['failedSyncs'] as num?)?.toInt() ?? 0,
      averageBatteryLevel:
          (json['averageBatteryLevel'] as num?)?.toDouble() ?? 0.0,
      emergencyActivations:
          (json['emergencyActivations'] as num?)?.toInt() ?? 0,
      sosButtonPresses: (json['sosButtonPresses'] as num?)?.toInt() ?? 0,
      crashDetections: (json['crashDetections'] as num?)?.toInt() ?? 0,
      fallDetections: (json['fallDetections'] as num?)?.toInt() ?? 0,
      heartRateReadings: (json['heartRateReadings'] as num?)?.toInt() ?? 0,
      locationUpdates: (json['locationUpdates'] as num?)?.toInt() ?? 0,
      notificationsSent: (json['notificationsSent'] as num?)?.toInt() ?? 0,
      notificationsReceived:
          (json['notificationsReceived'] as num?)?.toInt() ?? 0,
      customStats: json['customStats'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$GadgetDeviceStatsToJson(GadgetDeviceStats instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'date': instance.date.toIso8601String(),
      'connectionCount': instance.connectionCount,
      'totalConnectedTime': instance.totalConnectedTime.inMicroseconds,
      'syncCount': instance.syncCount,
      'successfulSyncs': instance.successfulSyncs,
      'failedSyncs': instance.failedSyncs,
      'averageBatteryLevel': instance.averageBatteryLevel,
      'emergencyActivations': instance.emergencyActivations,
      'sosButtonPresses': instance.sosButtonPresses,
      'crashDetections': instance.crashDetections,
      'fallDetections': instance.fallDetections,
      'heartRateReadings': instance.heartRateReadings,
      'locationUpdates': instance.locationUpdates,
      'notificationsSent': instance.notificationsSent,
      'notificationsReceived': instance.notificationsReceived,
      'customStats': instance.customStats,
    };
