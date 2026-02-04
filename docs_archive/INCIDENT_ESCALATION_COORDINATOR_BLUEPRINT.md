# 🚨 Incident Escalation Coordinator Blueprint

## Purpose
Unify crash & fall detection → AI verification → user response → fallback escalation → SOS activation into a single deterministic state machine that reduces duplication, improves reliability (especially in background), and enriches analytics & SMS context.

**✅ Current Architecture**: Emergency response uses **enhanced SMS v2.0 system** (fully automatic with smart priority selection, escalation, and two-way confirmation). Automated emergency dialing is **disabled by design** via kill switch (`EMERGENCY_CALL_ENABLED = false`). Manual call buttons remain available for conscious users.

## Scope
Covers flows triggered by:
- Sensor crash window (sustained impact + deceleration)
- Sensor fall window (free-fall + impact, ≥1m height)
- Severe impact bypass (critical crash ≥250 m/s²)
- AI verification outcomes (genuine, uncertain, false alarm, no response)
- User explicit interactions (OK / Cancel / Confirm SOS)
- Fallback timer expiry (post-verification / post-countdown)

## Goals
1. Remove duplicated heuristics between `SensorService` and `AIVerificationService` (single source for patterns: sustained impact, deceleration, free-fall, pickup cancellation).
2. Provide consistent physical magnitudes using calibrated conversion (real-world acceleration).
3. Guarantee a 2‑minute fallback escalation after no response or unresolved uncertainty.
4. Preserve battery by eliminating second sensor subscription inside AI layer.
5. Centralize timers (verification window, cancellation window, fallback window, SOS countdown) for easier tuning.
6. Create uniform analytics and SMS reason codes for every escalation path.
7. Respect contextual suppression (airplane mode, lab suppression flags) before starting escalation chains.

---
## State Machine

### States
| State | Description | Entry Trigger | Exit Trigger |
|-------|-------------|---------------|--------------|
| Idle | No active incident | App baseline | Detection start |
| CrashWindowOpening | Potential crash verifying (3s motion-resume check) | Sensor sustained impact + decel | Verified crash or cancelled |
| FallWindowOpening | Potential fall verifying (pickup cancellation 5s) | Free-fall + impact (≥1m) | Verified fall or cancelled |
| VerificationInProgress | AI asks for voice/motion response | Coordinator requests AI | AI completion or cancelled |
| AwaitUserResponse | Post-verification grace before fallback | AI outcome: noResponse OR uncertain below auto threshold | User OK / Cancel / fallback expiry |
| FallbackPending | 2‑minute timer to escalate safety | Start after AwaitUserResponse | Timer expiry or user OK / Cancel |
| SOSCountdown | Visible countdown (configurable 10s / shortened 5s for critical) | Verified genuine OR fallback expiry OR severe bypass | Countdown completion / Cancel |
| SOSActive | SOS session active (tracking, notifications) | Countdown completion or direct activation | Resolved / FalseAlarm / Cancel |
| Resolved | Session ended successfully | Resolution event | Return to Idle |
| FalseAlarm | Cancelled as non-emergency | User cancellation / AI falseAlarm | Return to Idle |
| Cancelled | User explicitly cancelled before activation | User action | Return to Idle |

### Event List
```
SensorCrashWindowStarted(impactContext)
SensorFallWindowStarted(impactContext)
CrashVerified(impactInfo)
FallVerified(impactInfo)
SevereImpactBypass(impactInfo)
AIVerificationStarted(detectionContext)
AIVerificationResult(result)
UserInteraction(type) // okConfirmed, cancelTap
FallbackTimerExpired
SOSCountdownStarted(severity)
SOSActivated(session)
SessionResolved(session)
SessionFalseAlarm(session)
SessionCancelled(session)
ContextSuppressed(reason) // airplane mode, lab suppression
```

### Timers
| Timer | Duration | Purpose | Cancel Conditions |
|-------|----------|---------|-------------------|
| crashVerificationWindow | 3s | Confirm vehicle stopped | Motion resumed / severe bypass |
| fallCancellationWindow | 5s | Allow user pickup to cancel | Pickup movement detected |
| aiVerificationWindow | 30s | Wait for voice/motion response | User OK / Cancel |
| fallbackWindow | 120s | Post no-response safety escalation | User OK / Cancel / falseAlarm |
| sosCountdown | 5s (critical) / 10s normal | Final user chance to cancel | User Cancel / direct activation |

---
## Data Contracts

### ImpactDetection
```dart
class ImpactDetection {
  final DetectionType type; // crash | fall
  final DateTime firstDetected;
  final double maxRealWorldAcceleration; // calibrated
  final bool sustainedImpactPattern; // crash
  final bool decelerationPattern; // crash
  final bool freeFallPattern; // fall
  final double? estimatedFallHeight; // meters
  final ImpactSeverity provisionalSeverity; // low|medium|high|critical
  final LocationInfo? location;
}
```

### VerificationOutcomeEnvelope
Extends `VerificationResult` with coordinator metadata.
```dart
class VerificationOutcomeEnvelope {
  final VerificationResult result; // existing model
  final Duration verificationLatency; // detection → completion
  final bool autoEscalated; // genuine or uncertain high confidence
  final bool requiresFallback; // noResponse OR uncertain below threshold
}
```

### EscalationContext
```dart
class EscalationContext {
  final ImpactDetection detection;
  final VerificationOutcomeEnvelope? verification;
  final bool fallbackTriggered;
  final String escalationPathCode; // e.g. DIRECT_SEVERE, VERIFIED_GENUINE, VERIFIED_UNCERTAIN, FALLBACK_NO_RESPONSE, FALLBACK_UNCERTAIN
}
```

---
## Fallback Policy
| Condition | Path | Action |
|-----------|------|--------|
| SevereImpactBypass (critical ≥250 m/s² sustained) | DIRECT_SEVERE | Immediate SOSCountdown (5s) |
| AI outcome genuineIncident | VERIFIED_GENUINE | Start normal SOSCountdown (10s) |
| AI outcome uncertainIncident & confidence ≥0.6 | VERIFIED_UNCERTAIN | Start normal SOSCountdown |
| AI outcome noResponse | FALLBACK_NO_RESPONSE | Start 120s fallbackWindow → then SOSCountdown |
| AI outcome uncertainIncident & confidence <0.6 | FALLBACK_UNCERTAIN | Start 120s fallbackWindow → severity gate: high/critical shorten countdown |
| User confirms OK at any pre-SOS state | USER_OK | Cancel chain (FalseAlarm if detection) |
| User cancels or picks up in fall window | FALSE_ALARM | Log & abort |

Severity-based countdown shortening rules:
```
critical: 5s countdown
high:    8s countdown
medium: 10s countdown
low:     fallback may choose to send silent check SMS only (future extension)
```

---
## Integration Points (Code Wiring Plan)

1. SensorService ⇒ Coordinator:
   - On potential crash start: `SensorCrashWindowStarted`
   - On crash verified: `CrashVerified(impactInfo)`
   - On potential fall start: `SensorFallWindowStarted`
   - On fall verified: `FallVerified(impactInfo)`
   - On severe sustained impact: `SevereImpactBypass`
2. AIVerificationService ⇒ Coordinator:
   - Start: `AIVerificationStarted`
   - Completion: `AIVerificationResult(result)` → compute fallback need
3. Coordinator ⇒ SOSService:
   - `startSOSCountdown(severity, reasonCode)`
   - Or direct `activateSOSImmediately` for severe critical when configured
4. Coordinator ⇒ SMSService:
   - Provide `escalationPathCode`, `verificationOutcome`, `reasonCode` for message templating.
5. Coordinator ⇒ Analytics:
   - One log per state transition with timestamps; compute latencies
6. UI Layer:
   - Subscribe to `CoordinatorStateStream` to show proper panel (e.g., verification banner, fallback timer gauge, countdown bar)

---
## Public API (Draft)
```dart
class IncidentEscalationCoordinator {
  Stream<CoordinatorState> get state$; // emits on each transition
  void onSensorCrashWindow(ImpactDetection d);
  void onSensorFallWindow(ImpactDetection d);
  void onCrashVerified(ImpactInfo info);
  void onFallVerified(ImpactInfo info);
  void onSevereImpactBypass(ImpactInfo info);
  void onAIVerificationStarted(DetectionContext ctx);
  void onAIVerificationResult(VerificationResult result);
  void onUserInteraction(InteractionType type);
  void onSessionResolved(SOSSession s);
  void onSessionCancelled(SOSSession s);
  void dispose();
}
```

### CoordinatorState
```dart
enum CoordinatorPhase {
  idle,
  crashWindow,
  fallWindow,
  verification,
  awaitUserResponse,
  fallbackPending,
  sosCountdown,
  sosActive,
  resolved,
  falseAlarm,
  cancelled,
}

class CoordinatorState {
  final CoordinatorPhase phase;
  final EscalationContext? context;
  final Duration? remainingTimer; // for countdown/fallback
  final ImpactSeverity? severity;
}
```

---
## UI Alignment
| Phase | UI Element | Behavior |
|-------|------------|----------|
| crashWindow | Small banner: "Verifying impact…" ripple animation | Show 3s progress bar |
| fallWindow | Banner: "Possible fall detected – pick up phone to cancel" | Show cancellation countdown |
| verification | Overlay card with voice prompt + motion icons | Accept cancel/OK interactions |
| awaitUserResponse | Subtle bar with: "No response yet – safety escalation in 2:00" | Live timer; Cancel / I'm OK |
| fallbackPending | Same bar; color shift from neutral→warning | At ≤30s turn amber, ≤10s turn red |
| sosCountdown | Full-width countdown bar (severity color) | Cancel button prominent |
| sosActive | Existing SOS page + new badge showing path code | Badge: e.g. "Fallback (No Response)" |
| resolved/falseAlarm/cancelled | Snackbar + history log entry | Provide feedback to analytics module |

Color Recommendations:
- Verification: Indigo
- AwaitUserResponse: Blue → Amber → Red gradient by remaining time
- FallbackPending: Amber
- Critical Countdown: Red
- High: Orange
- Medium: Yellow
- FalseAlarm: Green accent

Accessibility:
- All timers announced via TTS (optional): "Safety escalation in 2 minutes", "30 seconds remaining", "Escalating now".
- Haptics: long pulse entering countdown, short pulse each final 5 seconds.

---
## Analytics Fields
```
detection_type
impact_severity
crash_sustained_pattern (bool)
deceleration_pattern (bool)
fall_height_meters
verification_outcome
verification_confidence
verification_latency_ms
fallback_triggered (bool)
fallback_delay_ms
escalation_path_code
countdown_duration_ms
user_interaction_type (if any)
resolution_status
resolution_latency_ms (detection→resolved)
```

---
## SMS & Reason Codes
Add `reasonCode` to escalation messages:
| Code | When | SMS Line Addition |
|------|------|-------------------|
| DIRECT_SEVERE | Severe bypass | "Severe impact detected – immediate enhanced SMS alert sent to priority contacts." |
| VERIFIED_GENUINE | Genuine AI verification | "AI confirmed serious incident. Enhanced SMS v2.0 alerts active with smart escalation." |
| VERIFIED_UNCERTAIN | Uncertain high confidence | "Incident risk high – SMS alerts sent to priority emergency contacts with auto-escalation." |
| FALLBACK_NO_RESPONSE | No user response | "No user response after safety prompts – SMS escalating to secondary contacts." |
| FALLBACK_UNCERTAIN | Continued uncertainty | "Unresolved incident risk – SMS continuing with two-way confirmation enabled." |
| USER_CANCELLED | User cancelled | In cancellation SMS: include reason |

**Note**: Enhanced SMS v2.0 system operates fully automatically with priority selection, no-response escalation at T+5m, and two-way keyword confirmation (HELP/FALSE). Manual call buttons available for conscious users; automated dialing disabled by kill switch.
| FALSE_ALARM_PICKUP | Fall pickup cancellation | "Fall cancelled – phone movement detected." |

---
## Implementation Plan (Phased)
1. Create coordinator file & core types (Phase enum, state model, events, timers).
2. Introduce calibrated conversion public accessor in `SensorService`.
3. Refactor `AIVerificationService` to stop internal sensor subscription; accept feed or metrics from SensorService.
4. Wire sensor events to coordinator; start states & windows.
5. Wire AI verification start/completion to coordinator; compute fallback logic.
6. Implement fallback timer & severity-based countdown durations.
7. Enhance SMSService with reason codes and path code insertion.
8. Add analytics logging on each transition.
9. UI integration: build reactive widgets subscribing to `state$`.
10. Add TTS/haptics optional hooks for accessibility in countdown & fallback phases.
11. Unit tests for state transitions (crash, fall, false alarm, no response fallback).
12. Documentation updates to existing blueprint + AI docs referencing coordinator.

---
## Risk & Mitigation
| Risk | Mitigation |
|------|------------|
| Background timer reliability | Use ForegroundService/WakeLock on Android; iOS background task scheduling. |
| Double escalation (sensor + AI + fallback) | Coordinator centralizes; ignore duplicate events when state already advanced. |
| Battery increase | Remove duplicate sensor stream; keep only one high-frequency path. |
| Race condition (user cancels at same moment fallback expires) | Atomic state transition check inside coordinator before escalation. |
| Airplane/boat suppression ignored | Pass context flags into coordinator; early discard events if suppressed. |

---
## Test Matrix (Essential)
| Scenario | Expected Path | Assertions |
|----------|---------------|------------|
| Sustained crash + decel + user silent | CrashWindow→Verification→AwaitUserResponse→FallbackPending→SOSCountdown→SOSActive | Fallback timer exactly 120s; path FALLBACK_NO_RESPONSE |
| Severe critical impact | DIRECT_SEVERE→SOSCountdown(5s)→SOSActive | No verification started |
| Fall ≥1m pickup in 3s | FallWindowOpening→FalseAlarm | No verification; path FALSE_ALARM_PICKUP |
| Crash, user taps OK during verification | CrashWindow→Verification→FalseAlarm | No fallback, result userConfirmedOK |
| Uncertain low confidence | Verification→AwaitUserResponse→FallbackPending→SOSCountdown | path FALLBACK_UNCERTAIN |
| Genuine AI | Verification→SOSCountdown(10s) | path VERIFIED_GENUINE |

---
## Future Extensions
- Adaptive fallback duration based on historical responsiveness.
- Silent preliminary contact ping at 60s of fallback window.
- Multi-modal verification (watch tap, voice, movement). 
- ML severity estimator for countdown duration scaling.

---
## Update Requirements for Existing Docs
Add section to `REAL_WORLD_IMPLEMENTATION_BLUEPRINT.md` under Phase 3 linking to coordinator blueprint.
Add section to AI integration docs describing verification + fallback chain.

---
## Completion Criteria
- All paths produce consistent `escalation_path_code`.
- No duplicate sensor subscriptions.
- Fallback reliably fires in background (validated on emulator & physical device).
- Analytics dashboard shows latency metrics.
- SMS messages include reason codes.
- Unit tests pass for all matrix scenarios.
- Documentation merged and cross-linked.

---
## Versioning
Blueprint Version: 1.0.0
Date: 2025-11-13
Maintainer: Incident Response Architecture WG

---
**End of Incident Escalation Coordinator Blueprint**
