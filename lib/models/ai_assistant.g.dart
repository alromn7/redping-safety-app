// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AICommand _$AICommandFromJson(Map<String, dynamic> json) => AICommand(
      id: json['id'] as String,
      command: json['command'] as String,
      type: $enumDecode(_$AICommandTypeEnumMap, json['type']),
      parameters: json['parameters'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      status: $enumDecode(_$AICommandStatusEnumMap, json['status']),
      result: json['result'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$AICommandToJson(AICommand instance) => <String, dynamic>{
      'id': instance.id,
      'command': instance.command,
      'type': _$AICommandTypeEnumMap[instance.type]!,
      'parameters': instance.parameters,
      'timestamp': instance.timestamp.toIso8601String(),
      'userId': instance.userId,
      'status': _$AICommandStatusEnumMap[instance.status]!,
      'result': instance.result,
      'errorMessage': instance.errorMessage,
    };

const _$AICommandTypeEnumMap = {
  AICommandType.navigate: 'navigate',
  AICommandType.checkStatus: 'check_status',
  AICommandType.optimizePerformance: 'optimize_performance',
  AICommandType.safetyAssessment: 'safety_assessment',
  AICommandType.sendNotification: 'send_notification',
  AICommandType.updateSettings: 'update_settings',
  AICommandType.checkLocation: 'check_location',
  AICommandType.checkHazards: 'check_hazards',
  AICommandType.emergencyAction: 'emergency_action',
  AICommandType.helpRequest: 'help_request',
  AICommandType.contactManagement: 'contact_management',
  AICommandType.serviceRecommendation: 'service_recommendation',
  AICommandType.voiceCommand: 'voice_command',
  AICommandType.analyzeCrashDetection: 'analyze_crash_detection',
  AICommandType.analyzeFallDetection: 'analyze_fall_detection',
  AICommandType.sosVerificationInsights: 'sos_verification_insights',
  AICommandType.emergencyCoordination: 'emergency_coordination',
  AICommandType.drowsinessAnalysis: 'drowsiness_analysis',
  AICommandType.drivingSafetyTips: 'driving_safety_tips',
  AICommandType.hazardPatternAnalysis: 'hazard_pattern_analysis',
  AICommandType.environmentalRiskAssessment: 'environmental_risk_assessment',
  AICommandType.sarCoordinationInsights: 'sar_coordination_insights',
  AICommandType.rescueAnalytics: 'rescue_analytics',
  AICommandType.victimLocationPrediction: 'victim_location_prediction',
  AICommandType.resourceOptimization: 'resource_optimization',
  AICommandType.medicalProfileAnalysis: 'medical_profile_analysis',
  AICommandType.emergencyMedicalRecommendations:
      'emergency_medical_recommendations',
  AICommandType.healthRiskAssessment: 'health_risk_assessment',
  AICommandType.routeSafetyScoring: 'route_safety_scoring',
  AICommandType.riskPatternRecognition: 'risk_pattern_recognition',
  AICommandType.emergencyPrediction: 'emergency_prediction',
  AICommandType.proactiveSafetyAlert: 'proactive_safety_alert',
};

const _$AICommandStatusEnumMap = {
  AICommandStatus.pending: 'pending',
  AICommandStatus.processing: 'processing',
  AICommandStatus.completed: 'completed',
  AICommandStatus.failed: 'failed',
  AICommandStatus.cancelled: 'cancelled',
  AICommandStatus.requiresPermission: 'requires_permission',
};

AIMessage _$AIMessageFromJson(Map<String, dynamic> json) => AIMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$AIMessageTypeEnumMap, json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => AISuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      priority:
          $enumDecodeNullable(_$AIMessagePriorityEnumMap, json['priority']) ??
              AIMessagePriority.normal,
    );

Map<String, dynamic> _$AIMessageToJson(AIMessage instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'type': _$AIMessageTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
      'suggestions': instance.suggestions,
      'priority': _$AIMessagePriorityEnumMap[instance.priority]!,
    };

const _$AIMessageTypeEnumMap = {
  AIMessageType.userInput: 'user_input',
  AIMessageType.aiResponse: 'ai_response',
  AIMessageType.systemNotification: 'system_notification',
  AIMessageType.safetyAlert: 'safety_alert',
  AIMessageType.performanceUpdate: 'performance_update',
  AIMessageType.suggestion: 'suggestion',
  AIMessageType.error: 'error',
};

const _$AIMessagePriorityEnumMap = {
  AIMessagePriority.low: 'low',
  AIMessagePriority.normal: 'normal',
  AIMessagePriority.high: 'high',
  AIMessagePriority.critical: 'critical',
};

AISuggestion _$AISuggestionFromJson(Map<String, dynamic> json) => AISuggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionType: $enumDecode(_$AIActionTypeEnumMap, json['actionType']),
      actionParameters: json['actionParameters'] as Map<String, dynamic>,
      priority: $enumDecode(_$AISuggestionPriorityEnumMap, json['priority']),
      validUntil: DateTime.parse(json['validUntil'] as String),
    );

Map<String, dynamic> _$AISuggestionToJson(AISuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'actionType': _$AIActionTypeEnumMap[instance.actionType]!,
      'actionParameters': instance.actionParameters,
      'priority': _$AISuggestionPriorityEnumMap[instance.priority]!,
      'validUntil': instance.validUntil.toIso8601String(),
    };

const _$AIActionTypeEnumMap = {
  AIActionType.navigateToPage: 'navigate_to_page',
  AIActionType.toggleSetting: 'toggle_setting',
  AIActionType.checkSystemStatus: 'check_system_status',
  AIActionType.optimizeBattery: 'optimize_battery',
  AIActionType.updateLocation: 'update_location',
  AIActionType.checkWeather: 'check_weather',
  AIActionType.sendHelpRequest: 'send_help_request',
  AIActionType.callEmergencyContact: 'call_emergency_contact',
  AIActionType.activateSOS: 'activate_sos',
  AIActionType.checkNearbyServices: 'check_nearby_services',
  AIActionType.updateProfile: 'update_profile',
  AIActionType.backupData: 'backup_data',
  AIActionType.clearCache: 'clear_cache',
  AIActionType.restartServices: 'restart_services',
};

const _$AISuggestionPriorityEnumMap = {
  AISuggestionPriority.low: 'low',
  AISuggestionPriority.medium: 'medium',
  AISuggestionPriority.high: 'high',
  AISuggestionPriority.urgent: 'urgent',
};

AIPermissions _$AIPermissionsFromJson(Map<String, dynamic> json) =>
    AIPermissions(
      canNavigateApp: json['canNavigateApp'] as bool? ?? false,
      canAccessLocation: json['canAccessLocation'] as bool? ?? false,
      canSendNotifications: json['canSendNotifications'] as bool? ?? false,
      canAccessContacts: json['canAccessContacts'] as bool? ?? false,
      canModifySettings: json['canModifySettings'] as bool? ?? false,
      canAccessSensorData: json['canAccessSensorData'] as bool? ?? false,
      canInitiateCalls: json['canInitiateCalls'] as bool? ?? false,
      canSendMessages: json['canSendMessages'] as bool? ?? false,
      canAccessCamera: json['canAccessCamera'] as bool? ?? false,
      canManageEmergencyContacts:
          json['canManageEmergencyContacts'] as bool? ?? false,
      canTriggerSOS: json['canTriggerSOS'] as bool? ?? false,
      canAccessHazardAlerts: json['canAccessHazardAlerts'] as bool? ?? false,
      canManageProfile: json['canManageProfile'] as bool? ?? false,
      canOptimizePerformance: json['canOptimizePerformance'] as bool? ?? false,
      canUseSpeechRecognition:
          json['canUseSpeechRecognition'] as bool? ?? false,
      canUseVoiceCommands: json['canUseVoiceCommands'] as bool? ?? false,
      canAccessMicrophone: json['canAccessMicrophone'] as bool? ?? false,
      canIntegrateWithPhoneAI:
          json['canIntegrateWithPhoneAI'] as bool? ?? false,
      restrictedFeatures: (json['restrictedFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AIPermissionsToJson(AIPermissions instance) =>
    <String, dynamic>{
      'canNavigateApp': instance.canNavigateApp,
      'canAccessLocation': instance.canAccessLocation,
      'canSendNotifications': instance.canSendNotifications,
      'canAccessContacts': instance.canAccessContacts,
      'canModifySettings': instance.canModifySettings,
      'canAccessSensorData': instance.canAccessSensorData,
      'canInitiateCalls': instance.canInitiateCalls,
      'canSendMessages': instance.canSendMessages,
      'canAccessCamera': instance.canAccessCamera,
      'canManageEmergencyContacts': instance.canManageEmergencyContacts,
      'canTriggerSOS': instance.canTriggerSOS,
      'canAccessHazardAlerts': instance.canAccessHazardAlerts,
      'canManageProfile': instance.canManageProfile,
      'canOptimizePerformance': instance.canOptimizePerformance,
      'canUseSpeechRecognition': instance.canUseSpeechRecognition,
      'canUseVoiceCommands': instance.canUseVoiceCommands,
      'canAccessMicrophone': instance.canAccessMicrophone,
      'canIntegrateWithPhoneAI': instance.canIntegrateWithPhoneAI,
      'restrictedFeatures': instance.restrictedFeatures,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

AIPerformanceData _$AIPerformanceDataFromJson(Map<String, dynamic> json) =>
    AIPerformanceData(
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      isLocationActive: json['isLocationActive'] as bool,
      areSensorsActive: json['areSensorsActive'] as bool,
      activeNotifications: (json['activeNotifications'] as num).toInt(),
      networkUsage: (json['networkUsage'] as num).toDouble(),
      lastOptimization: DateTime.parse(json['lastOptimization'] as String),
      optimizationSuggestions:
          (json['optimizationSuggestions'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      servicePerformance:
          (json['servicePerformance'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ) ??
              const {},
    );

Map<String, dynamic> _$AIPerformanceDataToJson(AIPerformanceData instance) =>
    <String, dynamic>{
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
      'batteryLevel': instance.batteryLevel,
      'isLocationActive': instance.isLocationActive,
      'areSensorsActive': instance.areSensorsActive,
      'activeNotifications': instance.activeNotifications,
      'networkUsage': instance.networkUsage,
      'lastOptimization': instance.lastOptimization.toIso8601String(),
      'optimizationSuggestions': instance.optimizationSuggestions,
      'servicePerformance': instance.servicePerformance,
    };

AISafetyAssessment _$AISafetyAssessmentFromJson(Map<String, dynamic> json) =>
    AISafetyAssessment(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      overallLevel: $enumDecode(_$AISafetyLevelEnumMap, json['overallLevel']),
      categoryLevels: (json['categoryLevels'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, $enumDecode(_$AISafetyLevelEnumMap, e)),
      ),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map(
              (e) => AISafetyRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeThreats: (json['activeThreats'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      environmentalFactors:
          json['environmentalFactors'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$AISafetyAssessmentToJson(AISafetyAssessment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'overallLevel': _$AISafetyLevelEnumMap[instance.overallLevel]!,
      'categoryLevels': instance.categoryLevels
          .map((k, e) => MapEntry(k, _$AISafetyLevelEnumMap[e]!)),
      'recommendations': instance.recommendations,
      'activeThreats': instance.activeThreats,
      'environmentalFactors': instance.environmentalFactors,
    };

const _$AISafetyLevelEnumMap = {
  AISafetyLevel.safe: 'safe',
  AISafetyLevel.caution: 'caution',
  AISafetyLevel.warning: 'warning',
  AISafetyLevel.danger: 'danger',
  AISafetyLevel.critical: 'critical',
};

AISafetyRecommendation _$AISafetyRecommendationFromJson(
        Map<String, dynamic> json) =>
    AISafetyRecommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      urgency: $enumDecode(_$AISafetyLevelEnumMap, json['urgency']),
      recommendedAction:
          $enumDecode(_$AIActionTypeEnumMap, json['recommendedAction']),
      actionParameters: json['actionParameters'] as Map<String, dynamic>,
      validUntil: DateTime.parse(json['validUntil'] as String),
    );

Map<String, dynamic> _$AISafetyRecommendationToJson(
        AISafetyRecommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'urgency': _$AISafetyLevelEnumMap[instance.urgency]!,
      'recommendedAction': _$AIActionTypeEnumMap[instance.recommendedAction]!,
      'actionParameters': instance.actionParameters,
      'validUntil': instance.validUntil.toIso8601String(),
    };

AIConversationContext _$AIConversationContextFromJson(
        Map<String, dynamic> json) =>
    AIConversationContext(
      sessionId: json['sessionId'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => AIMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      userContext: json['userContext'] as Map<String, dynamic>,
      startTime: DateTime.parse(json['startTime'] as String),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      mode: $enumDecode(_$AIConversationModeEnumMap, json['mode']),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$AIConversationContextToJson(
        AIConversationContext instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'messages': instance.messages,
      'userContext': instance.userContext,
      'startTime': instance.startTime.toIso8601String(),
      'lastActivity': instance.lastActivity.toIso8601String(),
      'mode': _$AIConversationModeEnumMap[instance.mode]!,
      'isActive': instance.isActive,
    };

const _$AIConversationModeEnumMap = {
  AIConversationMode.text: 'text',
  AIConversationMode.voice: 'voice',
  AIConversationMode.emergency: 'emergency',
  AIConversationMode.guidance: 'guidance',
  AIConversationMode.performance: 'performance',
};

AILearningData _$AILearningDataFromJson(Map<String, dynamic> json) =>
    AILearningData(
      userId: json['userId'] as String,
      commandFrequency: Map<String, int>.from(json['commandFrequency'] as Map),
      commandSuccessRate:
          (json['commandSuccessRate'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      preferredFeatures: (json['preferredFeatures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      userPreferences: Map<String, String>.from(json['userPreferences'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AILearningDataToJson(AILearningData instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'commandFrequency': instance.commandFrequency,
      'commandSuccessRate': instance.commandSuccessRate,
      'preferredFeatures': instance.preferredFeatures,
      'userPreferences': instance.userPreferences,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

AIHazardSummary _$AIHazardSummaryFromJson(Map<String, dynamic> json) =>
    AIHazardSummary(
      emoji: json['emoji'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severityScore: (json['severityScore'] as num).toInt(),
      distanceEta: json['distanceEta'] as String,
      primaryAction: json['primaryAction'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$AIHazardSummaryToJson(AIHazardSummary instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'title': instance.title,
      'description': instance.description,
      'severityScore': instance.severityScore,
      'distanceEta': instance.distanceEta,
      'primaryAction': instance.primaryAction,
      'timestamp': instance.timestamp.toIso8601String(),
    };
