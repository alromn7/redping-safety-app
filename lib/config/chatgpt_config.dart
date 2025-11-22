/// ChatGPT API configuration for REDP!NG AI verification
class ChatGPTConfig {
  // API Configuration
  static const String baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String model =
      'gpt-4o-mini'; // Cost-effective model for real-time analysis
  static const double temperature =
      0.1; // Low temperature for consistent analysis
  static const int maxTokens = 500;

  // Emergency Detection Prompts
  static const String systemPrompt = '''
You are an AI emergency detection specialist for REDP!NG, a safety app that detects vehicle crashes and falls. 

Your role is to analyze sensor data patterns to determine if a real emergency occurred or if it's a false positive.

CRITICAL ANALYSIS CRITERIA:
1. Real Emergencies: Sustained high-impact events, free-fall followed by impact, vehicle rollover patterns
2. False Positives: Phone drops, hard braking, normal movement, device handling, pocket/bag movement
3. Context Matters: GPS speed, location changes, user interaction patterns, device orientation
4. Pattern Recognition: Look for sustained vs momentary events, multiple sensor confirmations
5. Severity Assessment: Distinguish between minor impacts and serious emergencies

RESPONSE FORMAT:
Always respond with valid JSON containing:
- is_emergency: boolean
- confidence: number (0.0-1.0)
- reasoning: string (brief explanation)
- false_positive_indicators: array of strings
- emergency_indicators: array of strings  
- recommendation: "proceed_with_sos" | "suppress_alert" | "request_verification"

Be conservative with emergency detection - only proceed if confident it's real.
''';

  // Detection Thresholds
  static const Map<String, double> thresholds = {
    'crash_deceleration': 8.0, // m/s²
    'crash_jerk': 15.0, // m/s³
    'crash_impact': 20.0, // m/s²
    'severe_impact': 30.0, // m/s² (bypasses AI)
    'fall_freefall': 0.5, // m/s²
    'fall_impact': 12.0, // m/s²
    'stationary_speed': 2.0, // m/s
  };

  // AI Analysis Parameters
  static const Duration analysisWindow = Duration(seconds: 10);
  static const Duration sensorBufferWindow = Duration(seconds: 30);
  static const int maxSensorDataPoints = 100;
  static const int maxContextDataPoints = 50;

  // Confidence Thresholds
  static const double highConfidenceThreshold = 0.8;
  static const double mediumConfidenceThreshold = 0.6;
  static const double lowConfidenceThreshold = 0.4;

  // Rate Limiting
  static const Duration minAnalysisInterval = Duration(seconds: 5);
  static const int maxAnalysesPerMinute = 12;

  // Cost Optimization
  static const bool enableCostOptimization = true;
  static const double maxCostPerAnalysis = 0.01; // $0.01 per analysis
  static const Duration costTrackingWindow = Duration(hours: 24);

  /// Get the system prompt for emergency detection
  static String getSystemPrompt() {
    return systemPrompt;
  }

  /// Get detection threshold for a specific type
  static double getThreshold(String type) {
    return thresholds[type] ?? 0.0;
  }

  /// Check if confidence level is high enough for emergency
  static bool isHighConfidence(double confidence) {
    return confidence >= highConfidenceThreshold;
  }

  /// Check if confidence level is medium
  static bool isMediumConfidence(double confidence) {
    return confidence >= mediumConfidenceThreshold &&
        confidence < highConfidenceThreshold;
  }

  /// Check if confidence level is low
  static bool isLowConfidence(double confidence) {
    return confidence < mediumConfidenceThreshold;
  }

  /// Get recommendation based on confidence and emergency status
  static String getRecommendation(bool isEmergency, double confidence) {
    if (isEmergency && isHighConfidence(confidence)) {
      return 'proceed_with_sos';
    } else if (isEmergency && isMediumConfidence(confidence)) {
      return 'request_verification';
    } else {
      return 'suppress_alert';
    }
  }

  /// Validate API key format
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.startsWith('sk-') && apiKey.length > 20;
  }

  /// Get cost estimate for analysis
  static double getCostEstimate() {
    // GPT-4o-mini pricing (approximate)
    const double inputCostPer1kTokens = 0.00015; // $0.15 per 1M tokens
    const double outputCostPer1kTokens = 0.0006; // $0.60 per 1M tokens

    const int estimatedInputTokens = 200;
    const int estimatedOutputTokens = 100;

    return (estimatedInputTokens / 1000 * inputCostPer1kTokens) +
        (estimatedOutputTokens / 1000 * outputCostPer1kTokens);
  }
}

