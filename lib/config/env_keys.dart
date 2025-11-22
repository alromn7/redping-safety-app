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
  // AI/LLM
  static const String openaiBaseUrl = 'OPENAI_BASE_URL';
  static const String openaiModel = 'OPENAI_MODEL';
  static const String openaiApiKey = 'OPENAI_API_KEY';
  // Gemini
  static const String geminiApiKey = 'GEMINI_API_KEY';
  static const String geminiModel = 'GEMINI_MODEL';
}
