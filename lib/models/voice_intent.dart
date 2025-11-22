class VoiceIntent {
  final String
  type; // drowsiness_report, hazard_report, generic_query, emergency
  final String rawText;
  final Map<String, dynamic> slots;
  final double confidence;
  VoiceIntent(this.type, this.rawText, this.slots, this.confidence);
}
