/// Keys for --dart-define build-time configuration
class EnvKeys {
  static const String appEnv = 'APP_ENV'; // dev|staging|prod
  static const String baseUrl = 'BASE_URL';
  static const String websocketUrl = 'WEBSOCKET_URL';
  static const String region = 'REGION';
  static const String featureFlags = 'FEATURE_FLAGS'; // JSON string
  static const String allowClientSosPingWrites =
      'ALLOW_CLIENT_SOS_PING_WRITES'; // 'true' | 'false'
  static const String projectId = 'PROJECT_ID';
  static const String apiKey = 'API_KEY';
  static const String clientId = 'CLIENT_ID';

  // Magic Link / Passwordless auth
  static const String magicLinkContinueUrl = 'MAGIC_LINK_CONTINUE_URL';
  static const String androidPackageName = 'ANDROID_PACKAGE_NAME';
  static const String iosBundleId = 'IOS_BUNDLE_ID';
}
