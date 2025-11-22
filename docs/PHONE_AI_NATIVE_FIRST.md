# Native Phone AI First Strategy

Date: 2025-11-18
Owner: AI Systems & Safety Team

## Rationale
Each device ships with its own OS assistant (Siri, Google Assistant, etc.). RedPing aligns with the native assistant for voice capture, invocation, and intents. External LLM services (e.g., OpenAI) are not required and remain disabled by default.

## Policy
- `enableSystemAI=false` (default): No external LLM calls.
- `enableInAppVoiceAI=false` (default): Rely on OS assistant for voice session lifecycle.
- `enableCompanionAI=false` (default): No app-spoken voice unless user explicitly enables.
- All safety classification must succeed using OS-intents and/or local heuristics.

## Architecture
- OS Assistant → Platform Channel → `PhoneAIIntegrationService` → `VoiceSessionController` → Safety Coach.
- Classification:
  1. Use OS-provided intent/slots when available.
  2. Else, run local heuristic rules (no network).

## Implementation Notes
- `lib/services/redping_ai_service.dart`: Uses heuristic classification when `enableSystemAI=false`.
- Scripts (`scripts/run_*.ps1`): Do not pass `OPENAI_*` defines; set `enableSystemAI=false`.
- Privacy: Do not log raw speech; sanitize summaries only.

## Acceptance
- No crashes when OS assistant unavailable (app falls back to heuristics). 
- No network to external LLM providers when flags are at defaults.
- Single speaker policy enforced via audio focus manager.

## Next Steps
- Implement platform channels for Android/iOS intents.
- Add unit tests for heuristic classification.
- Ship opt-in voice output UI toggle guarded by safety notice.
