import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_assistant.g.dart';

/// AI Assistant command and interaction models
@JsonSerializable()
class AICommand extends Equatable {
  final String id;
  final String command;
  final AICommandType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String userId;
  final AICommandStatus status;
  final String? result;
  final String? errorMessage;

  const AICommand({
    required this.id,
    required this.command,
    required this.type,
    required this.parameters,
    required this.timestamp,
    required this.userId,
    required this.status,
    this.result,
    this.errorMessage,
  });

  factory AICommand.fromJson(Map<String, dynamic> json) =>
      _$AICommandFromJson(json);

  Map<String, dynamic> toJson() => _$AICommandToJson(this);

  AICommand copyWith({
    String? id,
    String? command,
    AICommandType? type,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
    String? userId,
    AICommandStatus? status,
    String? result,
    String? errorMessage,
  }) {
    return AICommand(
      id: id ?? this.id,
      command: command ?? this.command,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    command,
    type,
    parameters,
    timestamp,
    userId,
    status,
    result,
    errorMessage,
  ];
}

/// AI Assistant conversation message
@JsonSerializable()
class AIMessage extends Equatable {
  final String id;
  final String content;
  final AIMessageType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final List<AISuggestion> suggestions;
  final AIMessagePriority priority;

  const AIMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata = const {},
    this.suggestions = const [],
    this.priority = AIMessagePriority.normal,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) =>
      _$AIMessageFromJson(json);

  Map<String, dynamic> toJson() => _$AIMessageToJson(this);

  @override
  List<Object?> get props => [
    id,
    content,
    type,
    timestamp,
    metadata,
    suggestions,
    priority,
  ];
}

/// AI suggestion for user actions
@JsonSerializable()
class AISuggestion extends Equatable {
  final String id;
  final String title;
  final String description;
  final AIActionType actionType;
  final Map<String, dynamic> actionParameters;
  final AISuggestionPriority priority;
  final DateTime validUntil;

  const AISuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.actionParameters,
    required this.priority,
    required this.validUntil,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) =>
      _$AISuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$AISuggestionToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    actionType,
    actionParameters,
    priority,
    validUntil,
  ];
}

/// AI Assistant permissions
@JsonSerializable()
class AIPermissions extends Equatable {
  final bool canNavigateApp;
  final bool canAccessLocation;
  final bool canSendNotifications;
  final bool canAccessContacts;
  final bool canModifySettings;
  final bool canAccessSensorData;
  final bool canInitiateCalls;
  final bool canSendMessages;
  final bool canAccessCamera;
  final bool canManageEmergencyContacts;
  final bool canTriggerSOS;
  final bool canAccessHazardAlerts;
  final bool canManageProfile;
  final bool canOptimizePerformance;
  final bool canUseSpeechRecognition;
  final bool canUseVoiceCommands;
  final bool canAccessMicrophone;
  final bool canIntegrateWithPhoneAI;
  final List<String> restrictedFeatures;
  final DateTime lastUpdated;

  const AIPermissions({
    this.canNavigateApp = false,
    this.canAccessLocation = false,
    this.canSendNotifications = false,
    this.canAccessContacts = false,
    this.canModifySettings = false,
    this.canAccessSensorData = false,
    this.canInitiateCalls = false,
    this.canSendMessages = false,
    this.canAccessCamera = false,
    this.canManageEmergencyContacts = false,
    this.canTriggerSOS = false,
    this.canAccessHazardAlerts = false,
    this.canManageProfile = false,
    this.canOptimizePerformance = false,
    this.canUseSpeechRecognition = false,
    this.canUseVoiceCommands = false,
    this.canAccessMicrophone = false,
    this.canIntegrateWithPhoneAI = false,
    this.restrictedFeatures = const [],
    required this.lastUpdated,
  });

  factory AIPermissions.fromJson(Map<String, dynamic> json) =>
      _$AIPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$AIPermissionsToJson(this);

  AIPermissions copyWith({
    bool? canNavigateApp,
    bool? canAccessLocation,
    bool? canSendNotifications,
    bool? canAccessContacts,
    bool? canModifySettings,
    bool? canAccessSensorData,
    bool? canInitiateCalls,
    bool? canSendMessages,
    bool? canAccessCamera,
    bool? canManageEmergencyContacts,
    bool? canTriggerSOS,
    bool? canAccessHazardAlerts,
    bool? canManageProfile,
    bool? canOptimizePerformance,
    bool? canUseSpeechRecognition,
    bool? canUseVoiceCommands,
    bool? canAccessMicrophone,
    bool? canIntegrateWithPhoneAI,
    List<String>? restrictedFeatures,
    DateTime? lastUpdated,
  }) {
    return AIPermissions(
      canNavigateApp: canNavigateApp ?? this.canNavigateApp,
      canAccessLocation: canAccessLocation ?? this.canAccessLocation,
      canSendNotifications: canSendNotifications ?? this.canSendNotifications,
      canAccessContacts: canAccessContacts ?? this.canAccessContacts,
      canModifySettings: canModifySettings ?? this.canModifySettings,
      canAccessSensorData: canAccessSensorData ?? this.canAccessSensorData,
      canInitiateCalls: canInitiateCalls ?? this.canInitiateCalls,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      canAccessCamera: canAccessCamera ?? this.canAccessCamera,
      canManageEmergencyContacts:
          canManageEmergencyContacts ?? this.canManageEmergencyContacts,
      canTriggerSOS: canTriggerSOS ?? this.canTriggerSOS,
      canAccessHazardAlerts:
          canAccessHazardAlerts ?? this.canAccessHazardAlerts,
      canManageProfile: canManageProfile ?? this.canManageProfile,
      canOptimizePerformance:
          canOptimizePerformance ?? this.canOptimizePerformance,
      canUseSpeechRecognition:
          canUseSpeechRecognition ?? this.canUseSpeechRecognition,
      canUseVoiceCommands: canUseVoiceCommands ?? this.canUseVoiceCommands,
      canAccessMicrophone: canAccessMicrophone ?? this.canAccessMicrophone,
      canIntegrateWithPhoneAI:
          canIntegrateWithPhoneAI ?? this.canIntegrateWithPhoneAI,
      restrictedFeatures: restrictedFeatures ?? this.restrictedFeatures,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    canNavigateApp,
    canAccessLocation,
    canSendNotifications,
    canAccessContacts,
    canModifySettings,
    canAccessSensorData,
    canInitiateCalls,
    canSendMessages,
    canAccessCamera,
    canManageEmergencyContacts,
    canTriggerSOS,
    canAccessHazardAlerts,
    canManageProfile,
    canOptimizePerformance,
    canUseSpeechRecognition,
    canUseVoiceCommands,
    canAccessMicrophone,
    canIntegrateWithPhoneAI,
    restrictedFeatures,
    lastUpdated,
  ];
}

/// AI performance monitoring data
@JsonSerializable()
class AIPerformanceData extends Equatable {
  final double cpuUsage;
  final double memoryUsage;
  final double batteryLevel;
  final bool isLocationActive;
  final bool areSensorsActive;
  final int activeNotifications;
  final double networkUsage;
  final DateTime lastOptimization;
  final List<String> optimizationSuggestions;
  final Map<String, double> servicePerformance;

  const AIPerformanceData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.isLocationActive,
    required this.areSensorsActive,
    required this.activeNotifications,
    required this.networkUsage,
    required this.lastOptimization,
    this.optimizationSuggestions = const [],
    this.servicePerformance = const {},
  });

  factory AIPerformanceData.fromJson(Map<String, dynamic> json) =>
      _$AIPerformanceDataFromJson(json);

  Map<String, dynamic> toJson() => _$AIPerformanceDataToJson(this);

  @override
  List<Object?> get props => [
    cpuUsage,
    memoryUsage,
    batteryLevel,
    isLocationActive,
    areSensorsActive,
    activeNotifications,
    networkUsage,
    lastOptimization,
    optimizationSuggestions,
    servicePerformance,
  ];
}

/// AI safety assessment
@JsonSerializable()
class AISafetyAssessment extends Equatable {
  final String id;
  final DateTime timestamp;
  final AISafetyLevel overallLevel;
  final Map<String, AISafetyLevel> categoryLevels;
  final List<AISafetyRecommendation> recommendations;
  final List<String> activeThreats;
  final Map<String, dynamic> environmentalFactors;

  const AISafetyAssessment({
    required this.id,
    required this.timestamp,
    required this.overallLevel,
    required this.categoryLevels,
    required this.recommendations,
    this.activeThreats = const [],
    this.environmentalFactors = const {},
  });

  factory AISafetyAssessment.fromJson(Map<String, dynamic> json) =>
      _$AISafetyAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$AISafetyAssessmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    timestamp,
    overallLevel,
    categoryLevels,
    recommendations,
    activeThreats,
    environmentalFactors,
  ];
}

/// AI safety recommendation
@JsonSerializable()
class AISafetyRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final AISafetyLevel urgency;
  final AIActionType recommendedAction;
  final Map<String, dynamic> actionParameters;
  final DateTime validUntil;

  const AISafetyRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.urgency,
    required this.recommendedAction,
    required this.actionParameters,
    required this.validUntil,
  });

  factory AISafetyRecommendation.fromJson(Map<String, dynamic> json) =>
      _$AISafetyRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$AISafetyRecommendationToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    urgency,
    recommendedAction,
    actionParameters,
    validUntil,
  ];
}

/// AI command types
enum AICommandType {
  @JsonValue('navigate')
  navigate,
  @JsonValue('check_status')
  checkStatus,
  @JsonValue('optimize_performance')
  optimizePerformance,
  @JsonValue('safety_assessment')
  safetyAssessment,
  @JsonValue('send_notification')
  sendNotification,
  @JsonValue('update_settings')
  updateSettings,
  @JsonValue('check_location')
  checkLocation,
  @JsonValue('check_hazards')
  checkHazards,
  @JsonValue('emergency_action')
  emergencyAction,
  @JsonValue('help_request')
  helpRequest,
  @JsonValue('contact_management')
  contactManagement,
  @JsonValue('service_recommendation')
  serviceRecommendation,
  @JsonValue('voice_command')
  voiceCommand,
  // Comprehensive Emergency Features
  @JsonValue('analyze_crash_detection')
  analyzeCrashDetection,
  @JsonValue('analyze_fall_detection')
  analyzeFallDetection,
  @JsonValue('sos_verification_insights')
  sosVerificationInsights,
  @JsonValue('emergency_coordination')
  emergencyCoordination,
  // Real-Time Safety Monitoring
  @JsonValue('drowsiness_analysis')
  drowsinessAnalysis,
  @JsonValue('driving_safety_tips')
  drivingSafetyTips,
  @JsonValue('hazard_pattern_analysis')
  hazardPatternAnalysis,
  @JsonValue('environmental_risk_assessment')
  environmentalRiskAssessment,
  // SAR Operations Intelligence
  @JsonValue('sar_coordination_insights')
  sarCoordinationInsights,
  @JsonValue('rescue_analytics')
  rescueAnalytics,
  @JsonValue('victim_location_prediction')
  victimLocationPrediction,
  @JsonValue('resource_optimization')
  resourceOptimization,
  // Health & Medical Insights
  @JsonValue('medical_profile_analysis')
  medicalProfileAnalysis,
  @JsonValue('emergency_medical_recommendations')
  emergencyMedicalRecommendations,
  @JsonValue('health_risk_assessment')
  healthRiskAssessment,
  // Predictive Analytics
  @JsonValue('route_safety_scoring')
  routeSafetyScoring,
  @JsonValue('risk_pattern_recognition')
  riskPatternRecognition,
  @JsonValue('emergency_prediction')
  emergencyPrediction,
  @JsonValue('proactive_safety_alert')
  proactiveSafetyAlert,
}

/// AI command status
enum AICommandStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('requires_permission')
  requiresPermission,
}

/// AI message types
enum AIMessageType {
  @JsonValue('user_input')
  userInput,
  @JsonValue('ai_response')
  aiResponse,
  @JsonValue('system_notification')
  systemNotification,
  @JsonValue('safety_alert')
  safetyAlert,
  @JsonValue('performance_update')
  performanceUpdate,
  @JsonValue('suggestion')
  suggestion,
  @JsonValue('error')
  error,
}

/// AI message priority
enum AIMessagePriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// AI action types
enum AIActionType {
  @JsonValue('navigate_to_page')
  navigateToPage,
  @JsonValue('toggle_setting')
  toggleSetting,
  @JsonValue('check_system_status')
  checkSystemStatus,
  @JsonValue('optimize_battery')
  optimizeBattery,
  @JsonValue('update_location')
  updateLocation,
  @JsonValue('check_weather')
  checkWeather,
  @JsonValue('send_help_request')
  sendHelpRequest,
  @JsonValue('call_emergency_contact')
  callEmergencyContact,
  @JsonValue('activate_sos')
  activateSOS,
  @JsonValue('check_nearby_services')
  checkNearbyServices,
  @JsonValue('update_profile')
  updateProfile,
  @JsonValue('backup_data')
  backupData,
  @JsonValue('clear_cache')
  clearCache,
  @JsonValue('restart_services')
  restartServices,
}

/// AI suggestion priority
enum AISuggestionPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// AI safety levels
enum AISafetyLevel {
  @JsonValue('safe')
  safe,
  @JsonValue('caution')
  caution,
  @JsonValue('warning')
  warning,
  @JsonValue('danger')
  danger,
  @JsonValue('critical')
  critical,
}

/// AI conversation context
@JsonSerializable()
class AIConversationContext extends Equatable {
  final String sessionId;
  final List<AIMessage> messages;
  final Map<String, dynamic> userContext;
  final DateTime startTime;
  final DateTime lastActivity;
  final AIConversationMode mode;
  final bool isActive;

  const AIConversationContext({
    required this.sessionId,
    required this.messages,
    required this.userContext,
    required this.startTime,
    required this.lastActivity,
    required this.mode,
    required this.isActive,
  });

  factory AIConversationContext.fromJson(Map<String, dynamic> json) =>
      _$AIConversationContextFromJson(json);

  Map<String, dynamic> toJson() => _$AIConversationContextToJson(this);

  AIConversationContext copyWith({
    String? sessionId,
    List<AIMessage>? messages,
    Map<String, dynamic>? userContext,
    DateTime? startTime,
    DateTime? lastActivity,
    AIConversationMode? mode,
    bool? isActive,
  }) {
    return AIConversationContext(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      userContext: userContext ?? this.userContext,
      startTime: startTime ?? this.startTime,
      lastActivity: lastActivity ?? this.lastActivity,
      mode: mode ?? this.mode,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    messages,
    userContext,
    startTime,
    lastActivity,
    mode,
    isActive,
  ];
}

/// AI conversation modes
enum AIConversationMode {
  @JsonValue('text')
  text,
  @JsonValue('voice')
  voice,
  @JsonValue('emergency')
  emergency,
  @JsonValue('guidance')
  guidance,
  @JsonValue('performance')
  performance,
}

/// AI learning data for improving responses
@JsonSerializable()
class AILearningData extends Equatable {
  final String userId;
  final Map<String, int> commandFrequency;
  final Map<String, double> commandSuccessRate;
  final List<String> preferredFeatures;
  final Map<String, String> userPreferences;
  final DateTime lastUpdated;

  const AILearningData({
    required this.userId,
    required this.commandFrequency,
    required this.commandSuccessRate,
    required this.preferredFeatures,
    required this.userPreferences,
    required this.lastUpdated,
  });

  factory AILearningData.fromJson(Map<String, dynamic> json) =>
      _$AILearningDataFromJson(json);

  Map<String, dynamic> toJson() => _$AILearningDataToJson(this);

  AILearningData copyWith({
    String? userId,
    Map<String, int>? commandFrequency,
    Map<String, double>? commandSuccessRate,
    List<String>? preferredFeatures,
    Map<String, String>? userPreferences,
    DateTime? lastUpdated,
  }) {
    return AILearningData(
      userId: userId ?? this.userId,
      commandFrequency: commandFrequency ?? this.commandFrequency,
      commandSuccessRate: commandSuccessRate ?? this.commandSuccessRate,
      preferredFeatures: preferredFeatures ?? this.preferredFeatures,
      userPreferences: userPreferences ?? this.userPreferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    commandFrequency,
    commandSuccessRate,
    preferredFeatures,
    userPreferences,
    lastUpdated,
  ];
}

/// AI-powered hazard summary for display on hazard alerts page
@JsonSerializable()
class AIHazardSummary extends Equatable {
  final String emoji;
  final String title;
  final String description;
  final int severityScore; // 1-10 scale
  final String distanceEta; // e.g., "5km, 15min"
  final String primaryAction;
  final DateTime timestamp;

  const AIHazardSummary({
    required this.emoji,
    required this.title,
    required this.description,
    required this.severityScore,
    required this.distanceEta,
    required this.primaryAction,
    required this.timestamp,
  });

  factory AIHazardSummary.fromJson(Map<String, dynamic> json) =>
      _$AIHazardSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AIHazardSummaryToJson(this);

  @override
  List<Object?> get props => [
    emoji,
    title,
    description,
    severityScore,
    distanceEta,
    primaryAction,
    timestamp,
  ];
}
