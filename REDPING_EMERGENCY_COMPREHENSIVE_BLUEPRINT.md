# RedPing Emergency — Comprehensive Blueprint

## 1. Overview & Goals
- Deliver a lightweight consumer safety app that detects crashes/falls (ACFD), verifies the event, and escalates SOS to contacts with minimal friction and battery impact.
- Keep background footprint small, prioritize reliability, and ensure clear consent and transparency.
- Align entitlements and subscriptions so free users have manual SOS, paid users get ACFD and hazard alerts.

## 2. Personas & Use Cases
- Everyday commuter: automatic crash detection while driving; quick verification and SOS if needed.
- Elderly or fall-risk: fall detection at home/outdoors; easy cancellation for false alarms.
- Family safety: shared contacts receive SMS/location; hazard alerts for severe weather/environmental risks.

## 3. Feature Set
- Core: ACFD (Auto Crash/Fall), Manual SOS, Emergency Contacts, Location Sharing, Hazard Alerts.
- Advanced: Medical Profile attachment to SOS, Foreground Notification during verification, Offline SOS queue, Device-native maps launch.
- Settings: toggle crash/fall detection, sensitivity sliders, contact management, consent & privacy controls.

## 4. UX Flows
- Onboarding: explain ACFD, ask for permissions (location, activity/sensors, notifications, SMS where applicable), select contacts, accept consent.
- Detection → Verification: detect event → open verification dialog with countdown; options: Confirm emergency, cancel false alarm, add message.
- Escalation: if no response or confirmation → start SOS; send SMS/push; show status screen with live updates and battery/signal indicators.
- Recovery: stop SOS; summarize incident; prompt to review settings or upgrade if features used are gated.

## 5. ACFD Pipeline (Crash & Fall)
- Sensors & Signals: accelerometer, gyroscope; optional barometer if available; location (speed) for context.
- Crash Detection:
  - Inputs: high g-force spike, jerk, orientation change, speed context.
  - Thresholds: base crash threshold range (e.g., 180–220 scaled by sensitivity).
  - Heuristics: combine peak, duration, directionality; suppress when device is stationary or pocket movement likely.
- Fall Detection:
  - Inputs: free fall signature → impact → post-impact inactivity.
  - Thresholds: base fall threshold range (e.g., 140–200 scaled by sensitivity).
  - Sequence validation: require order and timing windows to reduce false positives.
- Adaptive Sampling:
  - Battery-aware sampling: lower rates when charging/idle/sleeping; raise rates during motion.
  - Sleep detection: quiet hours reduce sampling unless speed or motion spikes.
- Verification Window:
  - Countdown (e.g., 10–30s); accessible controls; TTS optional; foreground notification persists.
  - Fallback auto-escalation when no user response.
- False Alarm Handling:
  - Single-tap cancel; log reason; quick feedback; re-enable monitoring smoothly.

## 6. Entitlements & Subscriptions
- Free Tier: Manual SOS, basic location sharing; no auto ACFD.
- Essential+: ACFD (auto crash + fall), Medical Profile, Hazard Alerts, SOS SMS.
- Higher Tiers: expand SMS limits, contacts count, additional alert types.
- Gating: UI and service initialization honor `acfd` and related flags; upgrade prompts on manual SOS indicating benefits of ACFD.

## 7. Hazard Alerts
- Sources: weather emergencies, natural disasters, environmental warnings.
- Delivery: notifications with actionable recommendations; opt-in regions; throttle to avoid spam.
- Priority: non-blocking for ACFD, avoid sensor contention.

## 8. Emergency Messaging & Contacts
- Channels: SMS (where permitted), push notifications, in-app messages.
- Payloads: session type (crash/fall/manual), timestamp, location link, medical profile summary (if consented), status.
- Reliability: offline queue; retry strategies; delivery confirmations when possible.

## 9. Permissions & Foreground Policy
- Permissions: location (foreground + background), activity recognition, sensors, notifications, SMS (if applicable).
- Foreground Service: only during detection verification window and active SOS; clear, persistent notification text.
- Rationale strings: explain necessity and benefits; allow granular toggles.

## 10. Privacy, Consent, and Safety
- Consent: explicit opt-in for ACFD and hazard alerts; separate consent for SMS.
- Data Minimization: store only necessary data; redact sensitive fields when not required.
- User Controls: easy disable/enable toggles; transparent logs for incidents.

## 11. Data Model & Storage
- Entities: `EmergencyContact`, `SOSSession`, `MedicalProfile`, `HazardAlert`.
- Key Fields: session type, reason, location, battery, speed, verification outcome.
- Collections: consumer-centric; no SAR admin data; session retention policy configurable.

## 12. Performance & Battery Targets
- Idle impact: ≤ 2–5% per day with ACFD enabled.
- Verification latency: dialog shown ≤ 200 ms; notification immediately.
- Sensor sampling: adaptive rates; paused during sleep/idle.

## 13. Accessibility & Localization
- Accessible verification dialog with large actions; screen-reader labels.
- Multi-language support; localized hazard warnings and permission rationale.

## 14. Settings & Personalization
- Toggles: crash detection, fall detection, hazard alerts.
- Sensitivity sliders for crash/fall.
- Contact management, SMS enablement, consent screens, medical profile editor.

## 15. Feature Flags & Remote Config
- Flags: `acfdEnabled`, `hazardAlertsEnabled`, `verificationTTS`, `batterySaverMode`.
- Use for phased rollouts, A/B testing of thresholds, remote kill switches.

## 16. Telemetry & Observability
- Metrics: detections per day, verification outcomes, false alarm rate, SOS success rate, notification delivery time.
- Logs: privacy-aware; redact PII; device context minimal.
- Crash reports: track ACFD pipeline errors and messaging failures.

## 17. Testing Strategy
- Unit: detection algorithms, sensitivity scaling, entitlement checks.
- Integration: end-to-end ACFD → verification → SOS; hazard alerts render and opt-in.
- Device: battery measurements, permission flow robustness, foreground notification behavior.
- Edge Cases: low battery, no network, denied permissions, sensor anomalies.

## 18. CI/CD
- Pipelines: analyze, test, and build for Emergency target; artifacts per flavor/target.
- Signing: separate keys and store listings; automated versioning and changelog.
- Canary releases with feature flags; staged rollouts.

## 19. Release & Store Compliance
- Clear descriptions; accurate emergency claims; guidance on limitations.
- Privacy Policy: detail sensors, data usage, opt-in, retention.
- Foreground notifications phrased to avoid alarming users unnecessarily.

## 20. Risks & Mitigations
- False positives: verification window, tuned thresholds, activity context.
- Battery drain: adaptive sampling; sleep detection; quick-stop foreground service.
- Permission friction: progressive prompts; explain value; fallback manual SOS.
- Network outages: offline queue; SMS priority; location caching.

## 21. Acceptance Criteria
- ACFD reliably triggers for severe events; low false alarm rate in normal motion.
- Verification and SOS flows complete under poor network conditions.
- Battery impact meets targets; UI remains responsive.
- Entitlement gating consistent; upgrade prompts sensible.

## 22. Roadmap (Post‑MVP)
- Enhanced fall detection with barometer (device-dependent).
- Family sharing improvements and guardian confirmation.
- Advanced hazard sources; geo-fenced safety tips.
- Optional assistant integrations with strict collision avoidance.
