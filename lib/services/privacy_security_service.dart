import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import '../models/privacy_security.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';
import '../core/config/security_config.dart';

/// Service for managing privacy, security, and compliance
class PrivacySecurityService {
  static final PrivacySecurityService _instance =
      PrivacySecurityService._internal();
  factory PrivacySecurityService() => _instance;
  PrivacySecurityService._internal();

  // State
  bool _isInitialized = false;
  List<PrivacyPermission> _permissions = [];
  List<DataCollectionPolicy> _policies = [];
  PrivacyPreferences _privacyPreferences = PrivacyPreferences(
    lastUpdated: DateTime.now(),
  );
  SecurityConfiguration _securityConfig = SecurityConfiguration(
    lastUpdated: DateTime.now(),
  );
  SecurityStatus? _currentSecurityStatus;
  ComplianceStatus? _complianceStatus;

  // Monitoring
  Timer? _securityMonitoringTimer;

  // Platform channels for native security features
  static const EventChannel _securityEventChannel = EventChannel(
    'redping.security.events',
  );
  static const MethodChannel _securityChannel = MethodChannel(
    'redping.security',
  );

  // Callbacks
  Function(PrivacyPermission)? _onPermissionChanged;
  Function(SecurityStatus)? _onSecurityStatusChanged;

  /// Initialize the privacy and security service
  Future<void> initialize({
    NotificationService? notificationService,
    UserProfileService? userProfileService,
  }) async {
    if (_isInitialized) return;

    try {
      // Load configurations
      await _loadPrivacyPreferences();
      await _loadSecurityConfiguration();
      await _loadPermissions();
      await _loadPolicies();

      // Setup native security monitoring (optional)
      try {
        await _setupNativeSecurityMonitoring();
      } catch (e) {
        debugPrint(
          'PrivacySecurityService: Native monitoring setup failed (continuing without it) - $e',
        );
      }

      // Perform initial security assessment
      try {
        await performSecurityAssessment();
      } catch (e) {
        debugPrint(
          'PrivacySecurityService: Security assessment failed (continuing with defaults) - $e',
        );
      }

      // Start monitoring (optional)
      try {
        _startSecurityMonitoring();
      } catch (e) {
        debugPrint(
          'PrivacySecurityService: Monitoring start failed (continuing without it) - $e',
        );
      }

      _isInitialized = true;
      debugPrint('PrivacySecurityService: Initialized successfully');
    } catch (e) {
      debugPrint('PrivacySecurityService: Initialization error - $e');
      throw Exception('Failed to initialize PrivacySecurityService: $e');
    }
  }

  /// Request privacy permission
  Future<PermissionStatus> requestPermission(PrivacyPermissionType type) async {
    try {
      ph.Permission? permission = _getPermissionForType(type);
      if (permission == null) {
        return PermissionStatus.notRequested;
      }

      // Request permission
      final status = await permission.request();
      final permissionStatus = _mapPermissionStatus(status);

      // Update permission record
      await _updatePermissionStatus(type, permissionStatus);

      debugPrint(
        'PrivacySecurityService: Permission ${type.name} - ${permissionStatus.name}',
      );
      return permissionStatus;
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error requesting permission ${type.name} - $e',
      );
      return PermissionStatus.denied;
    }
  }

  /// Update privacy preferences
  Future<void> updatePrivacyPreferences(
    PrivacyPreferences newPreferences,
  ) async {
    try {
      _privacyPreferences = newPreferences.copyWith(
        lastUpdated: DateTime.now(),
      );
      await _savePrivacyPreferences();
      debugPrint('PrivacySecurityService: Privacy preferences updated');
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error updating privacy preferences - $e',
      );
    }
  }

  /// Update security configuration
  Future<void> updateSecurityConfiguration(
    SecurityConfiguration newConfig,
  ) async {
    try {
      _securityConfig = newConfig.copyWith(lastUpdated: DateTime.now());
      await _saveSecurityConfiguration();
      debugPrint('PrivacySecurityService: Security configuration updated');
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error updating security configuration - $e',
      );
    }
  }

  /// Perform security assessment
  Future<void> performSecurityAssessment() async {
    try {
      // Get device security info
      final deviceInfo = await _getDeviceSecurityInfo();
      final isDeviceSecure = deviceInfo['isSecure'] as bool? ?? false;

      bool appSignatureVerified = true;
      if (Platform.isAndroid &&
          SecurityConfig.expectedAndroidSignatureSha256.isNotEmpty) {
        try {
          final verified = await _securityChannel.invokeMethod<bool>(
            'verifyAppSignature',
            {'sha256': SecurityConfig.expectedAndroidSignatureSha256},
          );
          appSignatureVerified = verified ?? false;
        } catch (_) {
          appSignatureVerified = false;
        }
      }

      // Debugger attach detection (Android only for now)
      bool debuggerAttached = false;
      if (Platform.isAndroid) {
        try {
          final attached = await _securityChannel.invokeMethod<bool>(
            'isDebuggerAttached',
          );
          debuggerAttached = attached ?? false;
        } catch (_) {}
      }

      // Play Integrity placeholder (non-blocking)
      Map<String, dynamic> integrityInfo = const {};
      if (Platform.isAndroid) {
        try {
          final resp = await _securityChannel.invokeMethod<dynamic>(
            'requestPlayIntegrity',
          );
          if (resp is Map) {
            integrityInfo = Map<String, dynamic>.from(resp);
          }
        } catch (_) {}
      }

      // Simple security status
      _currentSecurityStatus = SecurityStatus(
        overallThreatLevel:
            (isDeviceSecure && appSignatureVerified && !debuggerAttached)
            ? ThreatLevel.none
            : ThreatLevel.medium,
        isDeviceSecure: isDeviceSecure,
        isNetworkSecure: true,
        isDataEncrypted: _securityConfig.enableSecureStorage,
        hasRecentIncidents: false,
        activeThreats: 0,
        lastSecurityScan: DateTime.now(),
        securityRecommendations: isDeviceSecure
            ? (appSignatureVerified
                  ? (debuggerAttached
                        ? ['Disable debugging on production devices']
                        : [])
                  : ['Reinstall from trusted source'])
            : ['Enable device lock screen'],
        securityMetrics: {
          ...deviceInfo,
          'appSignatureVerified': appSignatureVerified,
          'debuggerAttached': debuggerAttached,
          if (integrityInfo.isNotEmpty) 'playIntegrity': integrityInfo,
        },
      );

      // Notify callback
      _onSecurityStatusChanged?.call(_currentSecurityStatus!);

      debugPrint('PrivacySecurityService: Security assessment completed');
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error performing security assessment - $e',
      );
    }
  }

  /// Export user data for portability
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exportData = <String, dynamic>{};

      // Export user data (simplified)
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (!key.startsWith('system_')) {
          final value = prefs.get(key);
          if (value != null) {
            exportData[key] = value;
          }
        }
      }

      exportData['export_metadata'] = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      debugPrint('PrivacySecurityService: User data exported');
      return exportData;
    } catch (e) {
      debugPrint('PrivacySecurityService: Error exporting user data - $e');
      return {};
    }
  }

  /// Delete user data
  Future<void> deleteUserData({
    required List<String> dataTypes,
    String? reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final dataType in dataTypes) {
        await prefs.remove(dataType);
      }

      debugPrint(
        'PrivacySecurityService: Deleted data types: ${dataTypes.join(', ')}',
      );
    } catch (e) {
      debugPrint('PrivacySecurityService: Error deleting user data - $e');
    }
  }

  /// Get device security information
  Future<Map<String, dynamic>> _getDeviceSecurityInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'isSecure': true, // Simplified
          'platform': 'android',
          'version': androidInfo.version.release,
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'isSecure': true, // Simplified
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
        };
      }

      return {'isSecure': false};
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error getting device security info - $e',
      );
      return {'isSecure': false};
    }
  }

  /// Setup native security monitoring
  Future<void> _setupNativeSecurityMonitoring() async {
    try {
      // Setup event channel for security events
      _securityEventChannel.receiveBroadcastStream().listen(
        (event) => _handleSecurityEvent(event),
        onError: (error) =>
            debugPrint('PrivacySecurityService: Security event error - $error'),
      );

      debugPrint('PrivacySecurityService: Native security monitoring enabled');
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error setting up native security monitoring - $e',
      );
    }
  }

  /// Handle security events from native platform
  void _handleSecurityEvent(dynamic event) {
    try {
      final eventData = Map<String, dynamic>.from(event);
      final eventType = eventData['type'] as String;
      debugPrint('PrivacySecurityService: Security event - $eventType');
    } catch (e) {
      debugPrint('PrivacySecurityService: Error handling security event - $e');
    }
  }

  /// Start security monitoring
  void _startSecurityMonitoring() {
    _securityMonitoringTimer?.cancel();
    _securityMonitoringTimer = Timer.periodic(const Duration(minutes: 15), (
      _,
    ) async {
      await performSecurityAssessment();
    });

    debugPrint('PrivacySecurityService: Security monitoring started');
  }

  /// Update permission status
  Future<void> _updatePermissionStatus(
    PrivacyPermissionType type,
    PermissionStatus status,
  ) async {
    try {
      final permissionIndex = _permissions.indexWhere((p) => p.type == type);

      if (permissionIndex != -1) {
        final updatedPermission = _permissions[permissionIndex].copyWith(
          status: status,
          grantedAt: status == PermissionStatus.granted ? DateTime.now() : null,
        );
        _permissions[permissionIndex] = updatedPermission;

        // Trigger callback
        _onPermissionChanged?.call(updatedPermission);
      }

      await _savePermissions();
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error updating permission status - $e',
      );
    }
  }

  /// Get permission for type
  ph.Permission? _getPermissionForType(PrivacyPermissionType type) {
    switch (type) {
      case PrivacyPermissionType.location:
        return ph.Permission.location;
      case PrivacyPermissionType.camera:
        return ph.Permission.camera;
      case PrivacyPermissionType.microphone:
        return ph.Permission.microphone;
      case PrivacyPermissionType.contacts:
        return ph.Permission.contacts;
      case PrivacyPermissionType.storage:
        return ph.Permission.storage;
      case PrivacyPermissionType.notifications:
        return ph.Permission.notification;
      default:
        return null;
    }
  }

  /// Map permission status
  PermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.provisional:
        return PermissionStatus.provisional;
      default:
        return PermissionStatus.notRequested;
    }
  }

  /// Load/Save methods
  Future<void> _loadPrivacyPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('privacy_preferences');
      if (json != null) {
        _privacyPreferences = PrivacyPreferences.fromJson(jsonDecode(json));
      }
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error loading privacy preferences - $e',
      );
    }
  }

  Future<void> _savePrivacyPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'privacy_preferences',
        jsonEncode(_privacyPreferences.toJson()),
      );
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error saving privacy preferences - $e',
      );
    }
  }

  Future<void> _loadSecurityConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('security_configuration');
      if (json != null) {
        _securityConfig = SecurityConfiguration.fromJson(jsonDecode(json));
      }
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error loading security configuration - $e',
      );
    }
  }

  Future<void> _saveSecurityConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'security_configuration',
        jsonEncode(_securityConfig.toJson()),
      );
    } catch (e) {
      debugPrint(
        'PrivacySecurityService: Error saving security configuration - $e',
      );
    }
  }

  Future<void> _loadPermissions() async {
    try {
      _permissions = _getDefaultPermissions();
      debugPrint(
        'PrivacySecurityService: Loaded ${_permissions.length} default permissions',
      );
    } catch (e) {
      debugPrint('PrivacySecurityService: Error loading permissions - $e');
      _permissions = _getDefaultPermissions();
      debugPrint(
        'PrivacySecurityService: Fallback loaded ${_permissions.length} permissions',
      );
    }
  }

  Future<void> _savePermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_permissions.map((p) => p.toJson()).toList());
      await prefs.setString('privacy_permissions', json);
    } catch (e) {
      debugPrint('PrivacySecurityService: Error saving permissions - $e');
    }
  }

  Future<void> _loadPolicies() async {
    try {
      _policies = _getDefaultPolicies();
      debugPrint(
        'PrivacySecurityService: Loaded ${_policies.length} default policies',
      );
    } catch (e) {
      debugPrint('PrivacySecurityService: Error loading policies - $e');
      _policies = _getDefaultPolicies();
      debugPrint(
        'PrivacySecurityService: Fallback loaded ${_policies.length} policies',
      );
    }
  }

  /// Get default permissions
  List<PrivacyPermission> _getDefaultPermissions() {
    return [
      PrivacyPermission(
        type: PrivacyPermissionType.location,
        status: PermissionStatus.notRequested,
        displayName: 'Location',
        description:
            'Access your location for emergency services and activity tracking',
        purpose: 'Emergency response and safety monitoring',
        isRequired: true,
        purposes: const [
          DataCollectionPurpose.emergencyResponse,
          DataCollectionPurpose.locationTracking,
        ],
      ),
      PrivacyPermission(
        type: PrivacyPermissionType.camera,
        status: PermissionStatus.notRequested,
        displayName: 'Camera',
        description: 'Take photos for incident reporting and profile pictures',
        purpose: 'Photo capture for reports and user profile',
        isRequired: false,
        purposes: const [DataCollectionPurpose.userProfile],
      ),
      PrivacyPermission(
        type: PrivacyPermissionType.notifications,
        status: PermissionStatus.notRequested,
        displayName: 'Notifications',
        description: 'Send emergency alerts and safety notifications',
        purpose: 'Critical safety and emergency notifications',
        isRequired: true,
        purposes: const [DataCollectionPurpose.emergencyResponse],
      ),
    ];
  }

  /// Get default data collection policies
  List<DataCollectionPolicy> _getDefaultPolicies() {
    return [
      DataCollectionPolicy(
        purpose: DataCollectionPurpose.emergencyResponse,
        description:
            'Location, sensor data, and user information for emergency response',
        dataTypes: const ['location', 'sensor_data', 'user_profile'],
        retentionPeriod: DataRetentionPeriod.year,
        encryptionLevel: EncryptionLevel.enterprise,
        isOptional: false,
        canBeDeleted: false,
        isSharedWithThirdParties: true,
        thirdParties: const ['Emergency Services'],
        lastUpdated: DateTime.now(),
      ),
      DataCollectionPolicy(
        purpose: DataCollectionPurpose.activityMonitoring,
        description: 'Activity data for safety monitoring during adventures',
        dataTypes: const ['activity_data', 'location'],
        retentionPeriod: DataRetentionPeriod.month,
        encryptionLevel: EncryptionLevel.standard,
        isOptional: true,
        canBeDeleted: true,
        isSharedWithThirdParties: false,
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  /// Set callbacks
  // Callback setters (for future implementation)
  void setPermissionChangedCallback(Function(PrivacyPermission) callback) {
    _onPermissionChanged = callback;
  }

  void setSecurityStatusChangedCallback(Function(SecurityStatus) callback) {
    _onSecurityStatusChanged = callback;
  }

  /// Dispose resources
  void dispose() {
    _securityMonitoringTimer?.cancel();
    _onPermissionChanged = null;
    _onSecurityStatusChanged = null;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  List<PrivacyPermission> get permissions => List.unmodifiable(_permissions);
  List<DataCollectionPolicy> get policies => List.unmodifiable(_policies);
  PrivacyPreferences get privacyPreferences => _privacyPreferences;
  SecurityConfiguration get securityConfiguration => _securityConfig;
  SecurityStatus? get currentSecurityStatus => _currentSecurityStatus;
  ComplianceStatus? get complianceStatus => _complianceStatus;
}
