# Phone AI Integration Plan (Android/iOS)

Goal: Make RedPing work with the phone's built-in AI (Assistant/Siri/etc.) without conflicts, especially during severe-impact ACFD activation. Avoid "two AIs talking" while guaranteeing life-safety prompts and actions.

## Principles
- Single Controller: Only one voice controller active at a time (OS Assistant preferred). 
- Explicit Handover: Clear handoff between phone AI and RedPing prompts.
- Fail-Safe: If the OS AI is unavailable, RedPing provides minimal, focused prompts.
- Privacy First: No hotword; on-device only when possible; obtain mic permission explicitly.

## Coexistence Strategy
- Disable continuous in-app voice AI by default (feature flags).
- Allow OS Assistant to invoke RedPing actions via deep links/shortcuts/intents.
- Serialize TTS prompts to avoid overlapping speech; yield audio focus to OS.
- Keep RedPing voice to short, essential prompts (verification countdown, safety cues).

## Android Integration
- App Shortcuts (Quick Actions): Expose "Start SOS", "Cancel SOS", "Share Location".
- Deep Links + Intent Actions: Define explicit activities/receivers:
  - `com.redping.intent.ACTION_START_SOS`
  - `com.redping.intent.ACTION_CANCEL_SOS`
  - `com.redping.intent.ACTION_SHARE_LOCATION`
- Foreground Service Notification: For ACFD, show persistent, actionable notification.
- Audio Focus: Request `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` for short prompts; abandon focus immediately.
- Security: Use explicit broadcasts with package name, check calling UID when possible, or require a one-time session token in the deep link.

## iOS Integration
- Siri Shortcuts (NS/INIntent): Donate intents for "Start SOS", "Cancel SOS", "Emergency Status".
- Shortcuts App: Provide automation examples (e.g., "Crash detected → Open RedPing SOS").
- Live Activities/Dynamic Island: Show ongoing SOS status and actions.
- Audio Session Policy: Use `.duckOthers` for brief prompts and avoid overlap.

## Feature Flags (added)
- `enableInAppVoiceAI` (default false): Gates continuous in-app voice commands and TTS in `PhoneAIIntegrationService`.
- `enableCompanionAI` (default false): Gates RedPing companion AI TTS (entertaining persona) to avoid conflicts.

## Implementation Phases
1) Compatibility Hardening (Done in this PR):
- Gate in-app voice AI and companion TTS via flags (`Env.flag`).
- Scripts updated to set both to false by default (dev/stage/prod).

2) OS Assistant Invocation (Next)
- Android: Add shortcuts.xml and intent filters; implement a `SafetyIntentReceiver` that routes to SOS flows.
- iOS: Add Siri Intents via native extension; donate intents from key flows.

3) Audio Focus & TTS Arbitration
- Introduce a lightweight `AudioFocusCoordinator` in Flutter: queue speech, yield when OS assistant active.
- Unify all TTS calls through this coordinator.

4) Session Handover Protocol
- Define an ephemeral session token passed via deep links.
- RedPing reads token, attaches to current SOS session, and returns status via a small content provider (Android) / `NSUserActivity` (iOS) update.

5) Safety QA
- Device tests: ACFD → OS assistant announces → RedPing verification prompt does not overlap; commands via assistant open RedPing flows.
- Battery: verify no continuous mic when disabled; verify background limits respected.

## Minimal API Contract (Android)
- Intent Actions: `ACTION_START_SOS`, `ACTION_CANCEL_SOS`, extras: `source`, `sessionToken`.
- Deep Link: `redping://sos?action=start&token=...`.

## Rollout
- Dev: keep OS-first; optionally enable in-app voice per tester.
- Staging/Prod: OS-first always; enable companion voice only for trials.

---
This plan ensures OS assistant remains the primary voice controller while RedPing provides focused, non-conflicting prompts and safety actions.
