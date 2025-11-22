# Phone AI Integration & RedPing Adoption Blueprint

Date: 2025-11-18
Owner: AI Systems & Safety Team
Revision: v1.0

## 1. Purpose
Deliver a unified voice and intelligence experience by integrating the phone's native OS assistant ("Phone AI") with RedPing's safety ecosystem. Prevent AI conflicts (dual audio, duplicate intents) while preserving: (a) System AI (ChatGPT) for backend/system logic, (b) Safety Assistant (Gemini) for user safety coaching. This blueprint defines architecture, wiring, UI alignment, rollout, testing, and governance.

## 2. Role Separation
| Component | Model/Source | Primary Responsibilities | User Voice? | Runs When |
|-----------|--------------|--------------------------|-------------|-----------|
| System AI (ChatGPT) | OpenAI model via `openaiApiKey` | Structured analysis, safety text classification, enrichment, automation reasoning | No (silent) | Background system flows, enrichment tasks |
| Safety Assistant (Gemini) | Google Gemini (future integration path) | Real-time coaching, drowsiness prompts, conversational safety guidance, emotional support | Yes (gated) | Active driving/safety sessions |
| Phone AI (OS Assistant) | Android: Assistant / App Actions; iOS: SiriKit | Voice capture (STT), invocation, intent routing, secure OS-level voice triggers | Yes | User triggers (wake phrase, CarPlay, Siri, Assistant) |
| Companion TTS Layer | FlutterTTS | Spoken feedback (if Phone AI delegates speaking to app) | Conditional | When `enableCompanionAI=true` |

## 3. Feature Flags
JSON passed via `FEATURE_FLAGS`:
- `enableSystemAI` (bool, default true): Allow ChatGPT system reasoning.
- `enableInAppVoiceAI` (bool, default false): Enable internal voice mediation service (bridges to Phone AI APIs when direct OS assistant is unavailable).
- `enableCompanionAI` (bool, default false): Allow app-originated TTS responses (avoid dual audio unless explicitly needed).
- `showBarIndicator` (bool): Visual protected ping / health bar.

## 4. High-Level Architecture
```
+----------------------+            +-----------------------+
|   Phone OS Assistant |<---------->|  Intent/Action Layer  |
| (Siri / Assistant)   |  Voice     |  (Platform Channels)  |
+----------+-----------+            +-----------+-----------+
           |                                    |
           v (Intent Payload / Speech Text)     v
   +--------------+                      +-----------------+
   | Voice Session|<---------------------| PhoneAIIntegration|
   | Controller   |                      | Service (Dart)   |
   +------+-------+                      +--------+--------+
          |                                       |
          v                                       v
   +-------------+                         +-------------+
   | Safety AI   | (Gemini)                | System AI   |
   | Coach Logic |                         | (ChatGPT)   |
   +------+------+                         +------+------+ 
          |                                      |
     Safety Events                           System Enrichment
          |                                      |
          v                                      v
      +-------------------- Shared Pipelines ---------------------+
      |    Telemetry, Protected Ping, HMAC Request Signing,       |
      |    Location/SAR Services, Emergency Workflows             |
      +-----------------------------------------------------------+
```

## 5. Data Flow (Driving Session Example)
1. User invokes Phone AI ("Hey Siri" / "Hey Google") and speaks: "I'm getting sleepy".
2. OS assistant resolves utterance → App Action / Siri Intent → passes structured text to app via platform channel.
3. `PhoneAIIntegrationService.handleIncomingUtterance()` routes to Safety AI Analyzer.
4. Analyzer consults System AI (ChatGPT) for classification (drowsiness, sentiment) if `enableSystemAI=true`.
5. Safety Assistant selects intervention (breathing technique sequence) and optional voice output path:
   - If `enableCompanionAI=true`: speak via TTS.
   - Else: send silent UI prompts + haptic feedback.
6. UI updates: status bar pulses; drowsiness card slides into view.
7. Telemetry: event logged with privacy scrubbing (PII removed before AI send).

## 6. Module Responsibilities
| Module | Responsibility | Notes |
|--------|----------------|-------|
| `PhoneAIIntegrationService` | Entry for OS assistant intents, STT fallback, audio focus arbitration | Wrap platform channels (MethodChannel on Android/iOS) |
| `RedPingAI` (System AI) | Classification, JSON pattern parsing, fallback responses | Silent by design |
| Safety Coach (future `gemini_safety_service.dart`) | User-centric safety strategies | Replace legacy direct ChatGPT user voice |
| `VoiceSessionController` | Manage session states (Idle, Listening, Processing, Responding, Cooldown) | Debounce triggers; escalate emergencies |
| `SystemHealthCard` | Display status bar, protected ping indicator, drowsiness warnings | Already flag-gated |
| `AudioFocusManager` | Avoid dual audio (Phone AI vs TTS) | Only grants app TTS when OS assistant released focus |
| Telemetry Layer | Event logging, structured metrics for adoption | Redact user free-form speech before external AI |

## 7. Voice Session State Machine
States: `Idle → Listening → Processing → Responding (Optional) → Cooldown → Idle`
Transitions:
- Idle→Listening: Phone assistant wake or manual mic button.
- Listening→Processing: STT final result or intent payload delivered.
- Processing→Responding: Safety intervention chosen AND `enableCompanionAI=true`.
- Processing→Cooldown: Silent guidance; update UI only.
- Responding→Cooldown: Speech complete; schedule cooldown timer.
- Cooldown→Idle: Timer elapsed OR user starts new interaction.
Failure Paths: If STT error: revert to Idle + toast; If intent classification fails: fallback to heuristic classification.

## 8. UI Alignment
| UI Element | Source | Behavior |
|------------|--------|----------|
| Status Bar (Protected Ping) | `SystemHealthCard` | Visual health/latency; animations only when `showBarIndicator=true` |
| Drowsiness Alert Card | Safety Coach | Appears with actionable steps; dismissible; shows escalation timer if emergency risk |
| Voice HUD (Mic waveform) | Phone AI Integration | Only visible during `Listening` state; uses OS-provided transcript lines |
| Intervention Overlay | Safety Coach | Step-by-step technique instructions (breathing, fresh air) |
| Silent Mode Badge | App Shell | Displayed when voice output suppressed (`enableCompanionAI=false`) |
| Emergency Countdown | Safety Coach / SAR | Voice or visual countdown; audio only if permitted |

Design Guidelines:
- Avoid duplicating OS assistant styling; use minimal neutral HUD.
- Distinguish System AI usage (never visible) from Safety AI voice (distinct brand colors).
- Provide a toggled advanced metrics panel for debugging (latency, classification results) restricted to dev builds.

## 9. Platform Integration Details
### Android
- Use App Actions / `intent-filter` for specific utterances (e.g., drowsiness, hazard report).
- Foreground service for continuous listening NOT recommended; rely on assistant triggers.
- Audio focus: request transient focus only during TTS; abandon immediately after.
- Permissions: `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, battery optimization exclusions for safety monitoring.

### iOS
- SiriKit Intents: Custom intent definitions (e.g., `ReportDrowsinessIntent`, `StartSafetyMonitoringIntent`).
- App Shortcuts: Pre-populate common safety commands.
- Background Execution: Use BGTaskScheduler for periodic safety checks (lightweight) rather than continuous audio.
- CarPlay: Optional simplified UI (limited mental load; only essential safety prompts).

### Shared Concerns
- Platform channel method names: `phone_ai/incoming_intent`, `phone_ai/transcript_final`, `phone_ai/error`.
- All incoming payloads normalized into `VoiceIntent { type, rawText, slots, confidence }`.

## 10. Security & Privacy
| Risk | Mitigation |
|------|-----------|
| Unintended sensitive speech sent to external AI | Local classification to filter; redact PII before API call |
| Dual audio causing distraction | Central audio focus manager + single active speaking entity policy |
| Model drift / degraded classification | Versioned prompt templates; periodic evaluation set |
| API key exposure | Only via environment variables (`OPENAI_API_KEY`), never logged |
| Unauthorized voice triggers (spoofing) | OS assistant authentication layers; reject high-risk low-confidence intents |

## 11. Telemetry & Metrics
- Voice Session Metrics: start/end timestamps, latency (STT→classification), intervention chosen.
- Safety Outcomes: drowsiness events mitigated, emergency escalations averted.
- Adoption: % sessions with voice disabled, user opt-in rate for companion voice.
- Reliability: classification fallback rate, API error incidents, average response duration.

## 12. Error Handling Strategy
| Layer | Strategy | User Feedback |
|-------|----------|---------------|
| STT Fail | Retry once; fallback to manual text input prompt | Toast + subtle vibration |
| Intent Parse Fail | Use heuristic keyword scan | Silent fallback (no error shown) |
| System AI Timeout | Fallback to static rule set | "Using quick safety rules" badge |
| TTS Failure | Log + switch to visual only | Badge: "Voice temporarily unavailable" |

## 13. Implementation Phases
1. Foundations (Platform Channels, Flags, State Machine scaffold)
2. System AI Normalization (Prompt templates, classification wrapper)
3. Safety Coach Abstraction (Gemini integration stub, fallback rules)
4. UI Pass (HUD, Cards, Overlay, Status Bar polishing)
5. Audio Focus & Conflict Resolution
6. Telemetry + Privacy Redaction Filters
7. Edge Cases (Emergency flows, low connectivity fallback)
8. Performance Tuning (Latency targets <1.2s classification)
9. Beta Rollout (Internal drivers, opt-in voice)
10. Public Rollout & Continuous Evaluation

## 14. Acceptance Criteria (Key Phases)
- Phase 1: Voice session transitions logged; no crashes when flags toggled.
- Phase 3: Safety interventions chosen deterministically w/o Gemini (stub) ≤ 200ms.
- Phase 5: No overlapping audio events in 30 randomized interaction tests.
- Phase 7: Emergency countdown always completes; false positive rate < 5%.
- Phase 9: User satisfaction score > 80% (pilot survey) regarding clarity & non-intrusiveness.

## 15. Testing Matrix
| Scenario | Flags | Expected Outcome |
|----------|-------|------------------|
| Standard drowsiness utterance | SystemAI=true, Companion=false | Silent UI intervention + status bar pulse |
| Standard drowsiness utterance + companion | SystemAI=true, Companion=true | Voice intervention + UI alignment |
| Emergency phrase ("I crashed") | SystemAI=true | Emergency workflow + countdown |
| Voice disabled entirely | SystemAI=true, InAppVoiceAI=false | Classification still runs, no mic HUD |
| System AI off | SystemAI=false | Heuristic fallback classification; telemetry marks degraded mode |
| Low connectivity | SystemAI timeout | Fallback path triggers within 1.5s |
| Rapid consecutive triggers | Debounce logic | Single processed session; others ignored with log |
| TTS failure injection | Companion=true | Switch to silent mode, badge displayed |

## 16. Performance Targets
- STT transcript availability: ≤ 650ms (OS dependent).
- Classification latency (System AI): P95 ≤ 900ms.
- Fallback classification: ≤ 120ms.
- TTS start after decision: ≤ 300ms when enabled.
- Memory overhead of services: < 30MB combined.

## 17. Logging Conventions
Prefix tags:
- `[VOICE_SESSION]` State transitions
- `[INTENT]` Received normalized intent
- `[CLASSIFY]` System AI prompt/response (sanitized)
- `[SAFETY_INTERVENTION]` Selected strategy
- `[AUDIO_FOCUS]` Acquisition / release events
- `[FAILOVER]` Fallback path chosen

No raw user speech logged; only sanitized summaries.

## 18. Rollout & Adoption Strategy
- Pilot: Internal drivers with `enableCompanionAI=true` (collect feedback)
- Soft Launch: Keep companion voice off; measure silent adoption and accuracy
- Opt-In Voice: Present toggle in advanced settings (explain battery + privacy)
- Full Launch: Default remains silent unless user explicitly enables voice
- Post Launch: Quarterly evaluation of false positives, user trust metrics

## 19. Governance & Review Cadence
- Weekly: Incident triage (misclassification, emergency misses)
- Biweekly: Prompt audit (System AI drift)
- Monthly: Privacy scrub verification & PII redaction tests
- Quarterly: Model upgrade decision (Gemini / ChatGPT version alignment)

## 20. Risk Register (Top 5)
| Risk | Impact | Mitigation |
|------|--------|------------|
| Dual audio overlap | Driver distraction | AudioFocusManager strict arbitration |
| Misclassified emergency | Safety risk | Threshold tuning + multi-signal validation |
| Privacy leak in logs | Compliance breach | Sanitization layer + automated scans |
| High latency > target | UX frustration | Progressive fallback layering |
| Feature flag drift | Inconsistent behavior | Central flag schema + unit tests |

## 21. Future Enhancements
- Adaptive personalization (learn driver patterns locally; differential privacy)
- On-device lightweight classifier to reduce external LLM calls
- Multi-lingual voice support with dynamic language negotiation
- Haptic intervention patterns (smartwatch / car integration)
- Edge offline emergency protocol (store cached interventions)

## 22. Integration Checklist
- [ ] MethodChannel wiring (Android & iOS) for intents
- [ ] VoiceSessionController implementation and tests
- [ ] Feature flags recognized in bootstrap sequence
- [ ] Sanitization of free-form speech before AI send
- [ ] Fallback classification ruleset complete
- [ ] UI components (HUD, cards, overlays) responsive across form factors
- [ ] Telemetry events captured and verified in staging
- [ ] Latency benchmarks collected (P50/P95) pre-launch
- [ ] Security review of API key handling

## 23. Code Stubs (Illustrative Interfaces)
```dart
class VoiceIntent {
  final String type; // drowsiness_report, hazard_report, generic_query, emergency
  final String rawText;
  final Map<String, dynamic> slots;
  final double confidence;
  VoiceIntent(this.type, this.rawText, this.slots, this.confidence);
}

abstract class IntentRouter {
  Future<void> route(VoiceIntent intent);
}

class PhoneAIIntegrationService {
  Future<void> handleIncomingUtterance(String text) async {
    final intent = IntentClassifier.classify(text); // heuristic or System AI
    await _voiceController.onIntent(intent);
  }
}

class VoiceSessionController {
  VoiceSessionState _state = VoiceSessionState.idle;
  Future<void> onIntent(VoiceIntent intent) async {
    _transition(VoiceSessionState.processing);
    final intervention = await SafetyCoach.evaluate(intent);
    if (Env.flag<bool>('enableCompanionAI', false)) {
      await TtsOutput.speak(intervention.voiceResponse);
      _transition(VoiceSessionState.responding);
    } else {
      UIInterventions.show(intervention.visual);
      _transition(VoiceSessionState.cooldown);
    }
    _scheduleCooldown();
  }
}
```

## 24. UI Consistency Rules
- Single font scale for safety overlays.
- Color palette: status bar uses neutral safety gradient; intervention overlays use accent safety tones.
- Animations < 400ms duration to avoid distraction.
- All voice HUD elements auto-hide ≤ 2s after session end.

## 25. Decommissioning Legacy Components
- Legacy direct ChatGPT user voice flows remain disabled unless explicitly re-enabled.
- Gradual migration of heuristic safety classification to hybrid on-device + System AI summary.

---
End of Blueprint.
