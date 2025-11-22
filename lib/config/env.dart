import 'dart:convert';
import 'env_keys.dart';

/// Env reads compile-time values passed via --dart-define.
/// Provides safe defaults and simple helpers.
class Env {
  static const String appEnv = String.fromEnvironment(
    EnvKeys.appEnv,
    defaultValue: 'dev',
  );
  static const String _baseUrl = String.fromEnvironment(
    EnvKeys.baseUrl,
    defaultValue: '',
  );
  static const String _wsUrl = String.fromEnvironment(
    EnvKeys.websocketUrl,
    defaultValue: '',
  );
  static const String region = String.fromEnvironment(
    EnvKeys.region,
    defaultValue: 'global',
  );
  static const String _featureFlagsRaw = String.fromEnvironment(
    EnvKeys.featureFlags,
    defaultValue: '',
  );
  static const bool allowClientSosPingWrites = bool.fromEnvironment(
    EnvKeys.allowClientSosPingWrites,
    defaultValue: true,
  );
  static const String _projectId = String.fromEnvironment(
    EnvKeys.projectId,
    defaultValue: '',
  );
  static const String _apiKey = String.fromEnvironment(
    EnvKeys.apiKey,
    defaultValue: '',
  );
  static const String _clientId = String.fromEnvironment(
    EnvKeys.clientId,
    defaultValue: '',
  );
  static const String _openaiBaseUrl = String.fromEnvironment(
    EnvKeys.openaiBaseUrl,
    defaultValue: '',
  );
  static const String _openaiModel = String.fromEnvironment(
    EnvKeys.openaiModel,
    defaultValue: '',
  );
  static const String _openaiApiKey = String.fromEnvironment(
    EnvKeys.openaiApiKey,
    defaultValue: '',
  );
  // Gemini
  static const String _geminiApiKey = String.fromEnvironment(
    EnvKeys.geminiApiKey,
    defaultValue: '',
  );
  static const String _geminiModel = String.fromEnvironment(
    EnvKeys.geminiModel,
    defaultValue: '',
  );

  /// API base URL (e.g. https://api.example.com/v1)
  static String get baseUrl => _baseUrl;

  /// WebSocket base URL if set (e.g. wss://api.example.com/ws)
  static String get websocketBaseUrl => _wsUrl;

  static String get projectId => _projectId;
  static String get apiKey => _apiKey;
  static String get clientId => _clientId;

  // AI/LLM
  static String get openaiBaseUrl => _openaiBaseUrl;
  static String get openaiModel => _openaiModel;
  static String get openaiApiKey => _openaiApiKey;
  // Gemini
  static String get geminiApiKey => _geminiApiKey;
  static String get geminiModel => _geminiModel;

  /// Parsed feature flags from JSON string, empty on parse failure or missing.
  static Map<String, dynamic> get featureFlags {
    if (_featureFlagsRaw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(_featureFlagsRaw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  /// Convenience flag lookup
  static T flag<T>(String key, T fallback) {
    final v = featureFlags[key];
    if (v is T) return v;
    return fallback;
  }
}
