# Authoritative Detection Thresholds (Production)

This page is the single source of truth for the thresholds used by the REDP!NG detection system. It mirrors the constants in `lib/services/sensor_service.dart` and should be kept in sync whenever changes are made.

Current production values:

- Crash threshold: 180.0 m/s² — Detects crashes at ≥60 km/h with sustained pattern
- Severe impact threshold: 250.0 m/s² — 80+ km/h; requires sustained pattern; used to expedite response
- Extreme impact classification: ≥300.0 m/s² — Captured and classified; escalate only if sustained/corroborated
- Fall threshold: 150.0 m/s² — Focus on 1.5m+ realistic falls; reduces vigorous-handling false alarms
- Phone drop filter: 120.0 m/s² — Filters normal handling, bench/table bumps
- Sustained pattern (crash): 3 out of 5 readings above threshold
- Deceleration pattern (vehicle): 5 out of 10 readings indicate slowing/stopping
- Motion resume auto-cancel: 3s window; ≥70% readings show continuous driving (10–50 m/s²)
- Free-fall detection (fall): <2.0 m/s² for ≥3 consecutive readings
- Fall cancellation: 5s window; cancel if 60% of readings show 10–20 m/s² normal movement

Notes:
- These are physics-informed defaults tuned for production stability. Regional or per-user adaptations can adjust within safe ranges (see REAL_WORLD_IMPLEMENTATION_BLUEPRINT.md Phase 2).
- When updating thresholds, change `sensor_service.dart` first, then update this file and cross-reference in both blueprints.
