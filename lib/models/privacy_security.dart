import 'package:equatable/equatable.dart';

/// Privacy permission types
enum PrivacyPermissionType {
  location,
  camera,
  microphone,
  contacts,
  storage,
  notifications,
  bluetooth,
  sensors,
  phone,
  sms,
  calendar,
  photos,
  satellite,
  emergencyServices,
  biometric,
  deviceInfo,
}

/// Privacy permission status
enum PermissionStatus {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  provisional, // iOS specific
}

/// Data collection purpose
enum DataCollectionPurpose {
  emergencyResponse,
  locationTracking,
  activityMonitoring,
  hazardAlerts,
  communicationServices,
  userProfile,
  analytics,
  crashReporting,
  performanceMonitoring,
  securityMonitoring,
  backupRestore,
  serviceImprovement,
}

/// Data retention period
enum DataRetentionPeriod {
  session, // Until app closes
  day, // 24 hours
  week, // 7 days
  month, // 30 days
  year, // 365 days
  indefinite, // Until user deletes
  legal, // As required by law
}

/// Encryption level
enum EncryptionLevel {
  none,
  basic, // AES-128
  standard, // AES-256
  enterprise, // AES-256 + additional layers
}

/// Security threat level
enum ThreatLevel { none, low, medium, high, critical }

/// Privacy permission details
class PrivacyPermission extends Equatable {
  final PrivacyPermissionType type;
  final PermissionStatus status;
  final String displayName;
  final String description;
  final String purpose;
  final bool isRequired;
  final bool isSystemLevel;
  final DateTime? grantedAt;
  final DateTime? lastUsed;
  final List<DataCollectionPurpose> purposes;

  const PrivacyPermission({
    required this.type,
    required this.status,
    required this.displayName,
    required this.description,
    required this.purpose,
    required this.isRequired,
    this.isSystemLevel = false,
    this.grantedAt,
    this.lastUsed,
    this.purposes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'status': status.name,
      'displayName': displayName,
      'description': description,
      'purpose': purpose,
      'isRequired': isRequired,
      'isSystemLevel': isSystemLevel,
      'grantedAt': grantedAt?.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'purposes': purposes.map((p) => p.name).toList(),
    };
  }

  factory PrivacyPermission.fromJson(Map<String, dynamic> json) {
    return PrivacyPermission(
      type: PrivacyPermissionType.values.firstWhere(
        (t) => t.name == json['type'],
      ),
      status: PermissionStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      purpose: json['purpose'] as String,
      isRequired: json['isRequired'] as bool,
      isSystemLevel: json['isSystemLevel'] as bool? ?? false,
      grantedAt: json['grantedAt'] != null
          ? DateTime.parse(json['grantedAt'] as String)
          : null,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      purposes: (json['purposes'] as List? ?? [])
          .map(
            (name) =>
                DataCollectionPurpose.values.firstWhere((p) => p.name == name),
          )
          .toList(),
    );
  }

  PrivacyPermission copyWith({
    PrivacyPermissionType? type,
    PermissionStatus? status,
    String? displayName,
    String? description,
    String? purpose,
    bool? isRequired,
    bool? isSystemLevel,
    DateTime? grantedAt,
    DateTime? lastUsed,
    List<DataCollectionPurpose>? purposes,
  }) {
    return PrivacyPermission(
      type: type ?? this.type,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      isRequired: isRequired ?? this.isRequired,
      isSystemLevel: isSystemLevel ?? this.isSystemLevel,
      grantedAt: grantedAt ?? this.grantedAt,
      lastUsed: lastUsed ?? this.lastUsed,
      purposes: purposes ?? this.purposes,
    );
  }

  @override
  List<Object?> get props => [
    type,
    status,
    displayName,
    description,
    purpose,
    isRequired,
    isSystemLevel,
    grantedAt,
    lastUsed,
    purposes,
  ];
}

/// Data collection policy
class DataCollectionPolicy extends Equatable {
  final DataCollectionPurpose purpose;
  final String description;
  final List<String> dataTypes;
  final DataRetentionPeriod retentionPeriod;
  final EncryptionLevel encryptionLevel;
  final bool isOptional;
  final bool canBeDeleted;
  final bool isSharedWithThirdParties;
  final List<String> thirdParties;
  final DateTime lastUpdated;

  const DataCollectionPolicy({
    required this.purpose,
    required this.description,
    required this.dataTypes,
    required this.retentionPeriod,
    required this.encryptionLevel,
    required this.isOptional,
    required this.canBeDeleted,
    required this.isSharedWithThirdParties,
    this.thirdParties = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'purpose': purpose.name,
      'description': description,
      'dataTypes': dataTypes,
      'retentionPeriod': retentionPeriod.name,
      'encryptionLevel': encryptionLevel.name,
      'isOptional': isOptional,
      'canBeDeleted': canBeDeleted,
      'isSharedWithThirdParties': isSharedWithThirdParties,
      'thirdParties': thirdParties,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory DataCollectionPolicy.fromJson(Map<String, dynamic> json) {
    return DataCollectionPolicy(
      purpose: DataCollectionPurpose.values.firstWhere(
        (p) => p.name == json['purpose'],
      ),
      description: json['description'] as String,
      dataTypes: List<String>.from(json['dataTypes'] ?? []),
      retentionPeriod: DataRetentionPeriod.values.firstWhere(
        (r) => r.name == json['retentionPeriod'],
      ),
      encryptionLevel: EncryptionLevel.values.firstWhere(
        (e) => e.name == json['encryptionLevel'],
      ),
      isOptional: json['isOptional'] as bool,
      canBeDeleted: json['canBeDeleted'] as bool,
      isSharedWithThirdParties: json['isSharedWithThirdParties'] as bool,
      thirdParties: List<String>.from(json['thirdParties'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  @override
  List<Object?> get props => [
    purpose,
    description,
    dataTypes,
    retentionPeriod,
    encryptionLevel,
    isOptional,
    canBeDeleted,
    isSharedWithThirdParties,
    thirdParties,
    lastUpdated,
  ];
}

/// Security incident
class SecurityIncident extends Equatable {
  final String id;
  final DateTime timestamp;
  final ThreatLevel threatLevel;
  final String type;
  final String description;
  final String? source;
  final Map<String, dynamic> details;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolution;

  const SecurityIncident({
    required this.id,
    required this.timestamp,
    required this.threatLevel,
    required this.type,
    required this.description,
    this.source,
    this.details = const {},
    required this.isResolved,
    this.resolvedAt,
    this.resolution,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'threatLevel': threatLevel.name,
      'type': type,
      'description': description,
      'source': source,
      'details': details,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
    };
  }

  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      threatLevel: ThreatLevel.values.firstWhere(
        (t) => t.name == json['threatLevel'],
      ),
      type: json['type'] as String,
      description: json['description'] as String,
      source: json['source'] as String?,
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      isResolved: json['isResolved'] as bool,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolution: json['resolution'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    timestamp,
    threatLevel,
    type,
    description,
    source,
    details,
    isResolved,
    resolvedAt,
    resolution,
  ];
}

/// User privacy preferences
class PrivacyPreferences extends Equatable {
  final bool enableDataCollection;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableLocationSharing;
  final bool enableContactSharing;
  final bool enableActivitySharing;
  final bool enableAutomaticBackup;
  final bool enableBiometricAuth;
  final bool enableSecurityMonitoring;
  final EncryptionLevel preferredEncryptionLevel;
  final DataRetentionPeriod defaultRetentionPeriod;
  final List<DataCollectionPurpose> optedOutPurposes;
  final DateTime lastUpdated;
  final String? privacyPolicyVersion;
  final DateTime? privacyPolicyAcceptedAt;

  const PrivacyPreferences({
    this.enableDataCollection = true,
    this.enableAnalytics = false,
    this.enableCrashReporting = true,
    this.enableLocationSharing = false,
    this.enableContactSharing = false,
    this.enableActivitySharing = false,
    this.enableAutomaticBackup = false,
    this.enableBiometricAuth = false,
    this.enableSecurityMonitoring = true,
    this.preferredEncryptionLevel = EncryptionLevel.standard,
    this.defaultRetentionPeriod = DataRetentionPeriod.month,
    this.optedOutPurposes = const [],
    required this.lastUpdated,
    this.privacyPolicyVersion,
    this.privacyPolicyAcceptedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableDataCollection': enableDataCollection,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableLocationSharing': enableLocationSharing,
      'enableContactSharing': enableContactSharing,
      'enableActivitySharing': enableActivitySharing,
      'enableAutomaticBackup': enableAutomaticBackup,
      'enableBiometricAuth': enableBiometricAuth,
      'enableSecurityMonitoring': enableSecurityMonitoring,
      'preferredEncryptionLevel': preferredEncryptionLevel.name,
      'defaultRetentionPeriod': defaultRetentionPeriod.name,
      'optedOutPurposes': optedOutPurposes.map((p) => p.name).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'privacyPolicyVersion': privacyPolicyVersion,
      'privacyPolicyAcceptedAt': privacyPolicyAcceptedAt?.toIso8601String(),
    };
  }

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferences(
      enableDataCollection: json['enableDataCollection'] as bool? ?? true,
      enableAnalytics: json['enableAnalytics'] as bool? ?? false,
      enableCrashReporting: json['enableCrashReporting'] as bool? ?? true,
      enableLocationSharing: json['enableLocationSharing'] as bool? ?? false,
      enableContactSharing: json['enableContactSharing'] as bool? ?? false,
      enableActivitySharing: json['enableActivitySharing'] as bool? ?? false,
      enableAutomaticBackup: json['enableAutomaticBackup'] as bool? ?? false,
      enableBiometricAuth: json['enableBiometricAuth'] as bool? ?? false,
      enableSecurityMonitoring:
          json['enableSecurityMonitoring'] as bool? ?? true,
      preferredEncryptionLevel: EncryptionLevel.values.firstWhere(
        (e) => e.name == (json['preferredEncryptionLevel'] ?? 'standard'),
      ),
      defaultRetentionPeriod: DataRetentionPeriod.values.firstWhere(
        (r) => r.name == (json['defaultRetentionPeriod'] ?? 'month'),
      ),
      optedOutPurposes: (json['optedOutPurposes'] as List? ?? [])
          .map(
            (name) =>
                DataCollectionPurpose.values.firstWhere((p) => p.name == name),
          )
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      privacyPolicyVersion: json['privacyPolicyVersion'] as String?,
      privacyPolicyAcceptedAt: json['privacyPolicyAcceptedAt'] != null
          ? DateTime.parse(json['privacyPolicyAcceptedAt'] as String)
          : null,
    );
  }

  PrivacyPreferences copyWith({
    bool? enableDataCollection,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    bool? enableLocationSharing,
    bool? enableContactSharing,
    bool? enableActivitySharing,
    bool? enableAutomaticBackup,
    bool? enableBiometricAuth,
    bool? enableSecurityMonitoring,
    EncryptionLevel? preferredEncryptionLevel,
    DataRetentionPeriod? defaultRetentionPeriod,
    List<DataCollectionPurpose>? optedOutPurposes,
    DateTime? lastUpdated,
    String? privacyPolicyVersion,
    DateTime? privacyPolicyAcceptedAt,
  }) {
    return PrivacyPreferences(
      enableDataCollection: enableDataCollection ?? this.enableDataCollection,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      enableLocationSharing:
          enableLocationSharing ?? this.enableLocationSharing,
      enableContactSharing: enableContactSharing ?? this.enableContactSharing,
      enableActivitySharing:
          enableActivitySharing ?? this.enableActivitySharing,
      enableAutomaticBackup:
          enableAutomaticBackup ?? this.enableAutomaticBackup,
      enableBiometricAuth: enableBiometricAuth ?? this.enableBiometricAuth,
      enableSecurityMonitoring:
          enableSecurityMonitoring ?? this.enableSecurityMonitoring,
      preferredEncryptionLevel:
          preferredEncryptionLevel ?? this.preferredEncryptionLevel,
      defaultRetentionPeriod:
          defaultRetentionPeriod ?? this.defaultRetentionPeriod,
      optedOutPurposes: optedOutPurposes ?? this.optedOutPurposes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      privacyPolicyAcceptedAt:
          privacyPolicyAcceptedAt ?? this.privacyPolicyAcceptedAt,
    );
  }

  @override
  List<Object?> get props => [
    enableDataCollection,
    enableAnalytics,
    enableCrashReporting,
    enableLocationSharing,
    enableContactSharing,
    enableActivitySharing,
    enableAutomaticBackup,
    enableBiometricAuth,
    enableSecurityMonitoring,
    preferredEncryptionLevel,
    defaultRetentionPeriod,
    optedOutPurposes,
    lastUpdated,
    privacyPolicyVersion,
    privacyPolicyAcceptedAt,
  ];
}

/// Security configuration
class SecurityConfiguration extends Equatable {
  final bool enableAutoLock;
  final Duration autoLockDuration;
  final bool requireBiometricForSensitiveData;
  final bool enableSecureStorage;
  final bool enableNetworkSecurityMonitoring;
  final bool enableAppIntegrityChecks;
  final bool enableRootDetection;
  final bool enableDebuggingProtection;
  final bool enableScreenshotPrevention;
  final bool enableTamperDetection;
  final EncryptionLevel dataEncryptionLevel;
  final EncryptionLevel communicationEncryptionLevel;
  final DateTime lastUpdated;

  const SecurityConfiguration({
    this.enableAutoLock = true,
    this.autoLockDuration = const Duration(minutes: 5),
    this.requireBiometricForSensitiveData = false,
    this.enableSecureStorage = true,
    this.enableNetworkSecurityMonitoring = true,
    this.enableAppIntegrityChecks = true,
    this.enableRootDetection = true,
    this.enableDebuggingProtection = true,
    this.enableScreenshotPrevention = false,
    this.enableTamperDetection = true,
    this.dataEncryptionLevel = EncryptionLevel.standard,
    this.communicationEncryptionLevel = EncryptionLevel.standard,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableAutoLock': enableAutoLock,
      'autoLockDuration': autoLockDuration.inMinutes,
      'requireBiometricForSensitiveData': requireBiometricForSensitiveData,
      'enableSecureStorage': enableSecureStorage,
      'enableNetworkSecurityMonitoring': enableNetworkSecurityMonitoring,
      'enableAppIntegrityChecks': enableAppIntegrityChecks,
      'enableRootDetection': enableRootDetection,
      'enableDebuggingProtection': enableDebuggingProtection,
      'enableScreenshotPrevention': enableScreenshotPrevention,
      'enableTamperDetection': enableTamperDetection,
      'dataEncryptionLevel': dataEncryptionLevel.name,
      'communicationEncryptionLevel': communicationEncryptionLevel.name,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SecurityConfiguration.fromJson(Map<String, dynamic> json) {
    return SecurityConfiguration(
      enableAutoLock: json['enableAutoLock'] as bool? ?? true,
      autoLockDuration: Duration(
        minutes: json['autoLockDuration'] as int? ?? 5,
      ),
      requireBiometricForSensitiveData:
          json['requireBiometricForSensitiveData'] as bool? ?? false,
      enableSecureStorage: json['enableSecureStorage'] as bool? ?? true,
      enableNetworkSecurityMonitoring:
          json['enableNetworkSecurityMonitoring'] as bool? ?? true,
      enableAppIntegrityChecks:
          json['enableAppIntegrityChecks'] as bool? ?? true,
      enableRootDetection: json['enableRootDetection'] as bool? ?? true,
      enableDebuggingProtection:
          json['enableDebuggingProtection'] as bool? ?? true,
      enableScreenshotPrevention:
          json['enableScreenshotPrevention'] as bool? ?? false,
      enableTamperDetection: json['enableTamperDetection'] as bool? ?? true,
      dataEncryptionLevel: EncryptionLevel.values.firstWhere(
        (e) => e.name == (json['dataEncryptionLevel'] ?? 'standard'),
      ),
      communicationEncryptionLevel: EncryptionLevel.values.firstWhere(
        (e) => e.name == (json['communicationEncryptionLevel'] ?? 'standard'),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  SecurityConfiguration copyWith({
    bool? enableAutoLock,
    Duration? autoLockDuration,
    bool? requireBiometricForSensitiveData,
    bool? enableSecureStorage,
    bool? enableNetworkSecurityMonitoring,
    bool? enableAppIntegrityChecks,
    bool? enableRootDetection,
    bool? enableDebuggingProtection,
    bool? enableScreenshotPrevention,
    bool? enableTamperDetection,
    EncryptionLevel? dataEncryptionLevel,
    EncryptionLevel? communicationEncryptionLevel,
    DateTime? lastUpdated,
  }) {
    return SecurityConfiguration(
      enableAutoLock: enableAutoLock ?? this.enableAutoLock,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      requireBiometricForSensitiveData:
          requireBiometricForSensitiveData ??
          this.requireBiometricForSensitiveData,
      enableSecureStorage: enableSecureStorage ?? this.enableSecureStorage,
      enableNetworkSecurityMonitoring:
          enableNetworkSecurityMonitoring ??
          this.enableNetworkSecurityMonitoring,
      enableAppIntegrityChecks:
          enableAppIntegrityChecks ?? this.enableAppIntegrityChecks,
      enableRootDetection: enableRootDetection ?? this.enableRootDetection,
      enableDebuggingProtection:
          enableDebuggingProtection ?? this.enableDebuggingProtection,
      enableScreenshotPrevention:
          enableScreenshotPrevention ?? this.enableScreenshotPrevention,
      enableTamperDetection:
          enableTamperDetection ?? this.enableTamperDetection,
      dataEncryptionLevel: dataEncryptionLevel ?? this.dataEncryptionLevel,
      communicationEncryptionLevel:
          communicationEncryptionLevel ?? this.communicationEncryptionLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    enableAutoLock,
    autoLockDuration,
    requireBiometricForSensitiveData,
    enableSecureStorage,
    enableNetworkSecurityMonitoring,
    enableAppIntegrityChecks,
    enableRootDetection,
    enableDebuggingProtection,
    enableScreenshotPrevention,
    enableTamperDetection,
    dataEncryptionLevel,
    communicationEncryptionLevel,
    lastUpdated,
  ];
}

/// Data audit log entry
class DataAuditLog extends Equatable {
  final String id;
  final DateTime timestamp;
  final String action; // 'created', 'accessed', 'modified', 'deleted', 'shared'
  final String dataType;
  final String? userId;
  final String? purpose;
  final String? source;
  final Map<String, dynamic> metadata;

  const DataAuditLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.dataType,
    this.userId,
    this.purpose,
    this.source,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'dataType': dataType,
      'userId': userId,
      'purpose': purpose,
      'source': source,
      'metadata': metadata,
    };
  }

  factory DataAuditLog.fromJson(Map<String, dynamic> json) {
    return DataAuditLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      dataType: json['dataType'] as String,
      userId: json['userId'] as String?,
      purpose: json['purpose'] as String?,
      source: json['source'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    id,
    timestamp,
    action,
    dataType,
    userId,
    purpose,
    source,
    metadata,
  ];
}

/// Compliance status
class ComplianceStatus extends Equatable {
  final bool isGDPRCompliant;
  final bool isCCPACompliant;
  final bool isAndroidCompliant;
  final bool isiOSCompliant;
  final bool isHIPAAReady; // For medical data
  final bool isSOCCompliant; // For enterprise
  final DateTime lastAssessment;
  final List<String> complianceIssues;
  final List<String> recommendations;

  const ComplianceStatus({
    required this.isGDPRCompliant,
    required this.isCCPACompliant,
    required this.isAndroidCompliant,
    required this.isiOSCompliant,
    required this.isHIPAAReady,
    required this.isSOCCompliant,
    required this.lastAssessment,
    this.complianceIssues = const [],
    this.recommendations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'isGDPRCompliant': isGDPRCompliant,
      'isCCPACompliant': isCCPACompliant,
      'isAndroidCompliant': isAndroidCompliant,
      'isiOSCompliant': isiOSCompliant,
      'isHIPAAReady': isHIPAAReady,
      'isSOCCompliant': isSOCCompliant,
      'lastAssessment': lastAssessment.toIso8601String(),
      'complianceIssues': complianceIssues,
      'recommendations': recommendations,
    };
  }

  factory ComplianceStatus.fromJson(Map<String, dynamic> json) {
    return ComplianceStatus(
      isGDPRCompliant: json['isGDPRCompliant'] as bool,
      isCCPACompliant: json['isCCPACompliant'] as bool,
      isAndroidCompliant: json['isAndroidCompliant'] as bool,
      isiOSCompliant: json['isiOSCompliant'] as bool,
      isHIPAAReady: json['isHIPAAReady'] as bool,
      isSOCCompliant: json['isSOCCompliant'] as bool,
      lastAssessment: DateTime.parse(json['lastAssessment'] as String),
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    isGDPRCompliant,
    isCCPACompliant,
    isAndroidCompliant,
    isiOSCompliant,
    isHIPAAReady,
    isSOCCompliant,
    lastAssessment,
    complianceIssues,
    recommendations,
  ];
}

/// Security status overview
class SecurityStatus extends Equatable {
  final ThreatLevel overallThreatLevel;
  final bool isDeviceSecure;
  final bool isNetworkSecure;
  final bool isDataEncrypted;
  final bool hasRecentIncidents;
  final int activeThreats;
  final DateTime lastSecurityScan;
  final List<String> securityRecommendations;
  final Map<String, dynamic> securityMetrics;

  const SecurityStatus({
    required this.overallThreatLevel,
    required this.isDeviceSecure,
    required this.isNetworkSecure,
    required this.isDataEncrypted,
    required this.hasRecentIncidents,
    required this.activeThreats,
    required this.lastSecurityScan,
    this.securityRecommendations = const [],
    this.securityMetrics = const {},
  });

  @override
  List<Object?> get props => [
    overallThreatLevel,
    isDeviceSecure,
    isNetworkSecure,
    isDataEncrypted,
    hasRecentIncidents,
    activeThreats,
    lastSecurityScan,
    securityRecommendations,
    securityMetrics,
  ];
}

















