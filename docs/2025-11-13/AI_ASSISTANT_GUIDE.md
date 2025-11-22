# RedPing AI Safety Assistant Guide

Last Updated: Nov 13, 2025

## Overview
The AI Safety Assistant unifies contextual safety intelligence, proactive suggestions, and voice-driven emergency actions. It now integrates real speech recognition (STT) and text-to-speech (TTS) while respecting the Ultra Battery Optimization Blueprint.

## Key Capabilities
- Contextual command processing (navigation, hazard analysis, battery/status checks)
- Direct voice actions: start/cancel SOS, hazard summary, battery level, location, system status
- Adaptive voice layer: auto-stops continuous listening when battery is critical or aggressive optimization is active
- Unified TTS output via `PhoneAIIntegrationService` used by `AIAssistantService`
- Smart Suggestions surfaced based on hazard alerts, performance data, and safety assessments

## Battery Optimization Compliance
The assistant adheres to blueprint governance rules:
- No continuous hot microphone when battery critical (voice start blocked)
- Auto-stop listening after successful command in moderate/aggressive optimization levels
- Delegated sampling logic unaffected; does not increase sensor processing rate
- Emergency override: SOS voice command escalates to full SOS countdown (sensor service handles sampling escalation per blueprint)

### Low-Power Behaviors
| Condition | Behavior |
|-----------|----------|
| Battery critical (≤10%) | Voice listening suppressed entirely |
| Moderate/Aggressive optimization (≤25%) | Auto-stop after a recognized command to avoid idle STT sessions |
| Charging | Normal voice responsiveness |

## Voice Command Mapping
| Command Key | Phrases (partial) | Direct Action |
|-------------|-------------------|---------------|
| start_sos | "start sos", "help me", "emergency" | Starts SOS countdown |
| cancel_sos | "cancel sos", "stand down", "false alarm" | Cancels active SOS |
| hazards | "check hazards", "hazard status", "alerts" | Speaks alert count |
| battery | "battery status", "battery level" | Speaks battery percent |
| location | "share location", "where am i" | Speaks lat/long |
| status | "system status", "what's my status" | Speaks optimization & battery state |

## Files Modified
- `lib/services/phone_ai_integration_service.dart`: Added STT/TTS, battery awareness, direct actions
- `lib/features/ai/presentation/pages/ai_assistant_page.dart`: Added live voice UI, recognition preview, mic controls
- `lib/services/ai_assistant_service.dart`: Delegated speech to PhoneAIIntegrationService
- `test/ai_assistant_voice_test.dart`: Basic mapping tests

## Extension Points
- Wake phrase ("Hey RedPing") passive activation (deferred; would require low-power hotword strategy)
- Ambient hazard summary injection into voice responses
- Privacy mode switch to force text-only even if battery high

## Testing
Run unit tests:
```powershell
flutter test test/ai_assistant_voice_test.dart
```
Manual validation checklist:
1. Enable voice toggle on AI Assistant page.
2. Speak "battery status" → device speaks current level.
3. Lower device battery (or mock service) → listening suppressed at ≤10%.
4. Speak "start sos" → SOS countdown initiates and voice feedback plays.
5. After command under moderate optimization (≤25%), verify auto-stop listening.

## Safety & Privacy Notes
- Microphone activation intentionally avoided under critical battery to preserve emergency capacity.
- STT sessions limited to 15s with pause window; no background indefinite recognition.
- No audio stored or transmitted; processing local only.

## Future Enhancements
- Add AI summary card showing last spoken command and battery optimization tier
- Integrate pattern learning awareness into spoken status
- Expand tests with mock battery service and SOS state assertions

---
**Compliance Reference:** Ultra Battery Optimization Blueprint Rules 1, 4, 5, 8, 10 applied; no sampling hierarchy changes; emergency override honored via SOS service.
