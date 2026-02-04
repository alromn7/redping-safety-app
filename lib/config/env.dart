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

  // Magic Link / Passwordless auth
  static const String _magicLinkContinueUrl = String.fromEnvironment(
    EnvKeys.magicLinkContinueUrl,
    defaultValue: '',
  );
  static const String _androidPackageName = String.fromEnvironment(
    EnvKeys.androidPackageName,
    defaultValue: 'com.redping.redping',
  );
  static const String _iosBundleId = String.fromEnvironment(
    EnvKeys.iosBundleId,
    defaultValue: 'com.redping.redping',
  );

  /// API base URL (e.g. https://api.example.com/v1)
  static String get baseUrl => _baseUrl;

  /// WebSocket base URL if set (e.g. wss://api.example.com/ws)
  static String get websocketBaseUrl => _wsUrl;

  static String get projectId => _projectId;
  static String get apiKey => _apiKey;
  static String get clientId => _clientId;

  // Magic Link / Passwordless auth
  static String get magicLinkContinueUrl =>
      _magicLinkContinueUrl.isNotEmpty
          ? _magicLinkContinueUrl
          : 'https://redping.app/auth';
  static String get androidPackageName => _androidPackageName;
  static String get iosBundleId => _iosBundleId;

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
