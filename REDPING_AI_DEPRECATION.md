# System AI (ChatGPT) — Role & Configuration

This document clarifies the separation of roles between the System AI (ChatGPT) and the User Safety Assistant (Gemini) and documents the configuration used to operate both safely without conflict.

## Roles
- System AI (ChatGPT): Handles system functionality, analysis, and automations. Not user-facing for voice by default.
- Safety Assistant (Gemini): User-facing safety coach and companion. Voice/TTS as needed.

## Configuration
- Feature flags (`FEATURE_FLAGS` JSON):
  - `enableSystemAI` (default true): Enables ChatGPT-backed system functionality.
  - `enableCompanionAI` (default false): Controls RedPing companion TTS/voice to avoid conflicts.
  - `enableInAppVoiceAI` (default false): Controls phone AI voice mediation layer.
- OpenAI settings (`--dart-define`):
  - `OPENAI_API_KEY` (required)
  - `OPENAI_BASE_URL` (default `https://api.openai.com/v1`)
  - `OPENAI_MODEL` (default `gpt-4o-mini`)

## Implementation Notes
- `lib/services/redping_ai_service.dart` reads OpenAI config from `Env` and gates network calls on `enableSystemAI`.
- TTS remains gated by `enableCompanionAI` to avoid overlapping audio with phone assistant.
- No keys are hard-coded in the repository; scripts pass keys from the environment.

## Security
- Provide `OPENAI_API_KEY` via environment only. Never commit secrets.
- TLS pinning, request signing, and integrity checks remain enabled per environment.

## Operational Guidance
- For dev/staging/prod, ensure `OPENAI_API_KEY` is set in the shell before running `scripts/run_*.ps1`.
- Keep `enableCompanionAI=false` when relying on phone assistant for voice UX.

## Ownership
AI Systems & Safety Team
