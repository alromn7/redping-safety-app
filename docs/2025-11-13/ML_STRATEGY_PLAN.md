# RedPing ML Strategy Plan (Phase 0 → Phase 3)

## Purpose
Introduce a lightweight, privacy-preserving on‑device ML layer to complement existing heuristic crash/fall verification. Preserve deterministic safety behavior, avoid conflicts with OEM (phone) proprietary crash APIs, and reduce false alarms while guaranteeing severe events still escalate.

## Guiding Principles
- Heuristic First: Existing physics/threshold logic remains the primary gate for severe impacts (≥250 m/s² bypass) & sustained crash patterns.
- ML as Confidence Refiner: Model outputs a probability of genuine incident vs false alarm; used only when heuristics produce uncertain or moderate confidence corridors.
- Deterministic Override: High‑severity heuristic (>250 m/s²) or verified stop (3s stationary after impact) always escalates regardless of ML output.
- Battery Preservation: Feature extraction piggybacks on existing sensor buffers (SensorService canonical feed). No duplicate streams inside `AIVerificationService` once external feed mode enabled.
- Privacy & Locality: All inference on device (e.g. TFLite / Dart FFI). No raw sensor logs leave device; only aggregated, anonymized metrics if user opts in.

## Phased Roadmap
| Phase | Scope | Model | Data | Rollout | Safety Fallback |
|-------|-------|-------|------|---------|-----------------|
| 0 | Scaffold | Adapter interface, manual feature snapshot | None (stub) | Internal dev only | 100% heuristic |
| 1 | Passive Collection | Feature logging (opt-in) | Offline training (GBDT / RandomForest) -> TFLite | Limited beta (5%) | Heuristic final say |
| 2 | Assisted Inference | Calibrated probability blending | TFLite 1D CNN or LightGBM | Gradual (25%, 50%, 75%) | Escalate if model low confidence but heuristic severe |
| 3 | Adaptive & Personalization | Per-user calibration offsets | Federated (future) | Broad (90%+) | Hard overrides retained |

## Candidate Features (Grouped)
1. Impact Dynamics:
   - Peak magnitude (converted physics-adjusted)
   - Sustained high-impact count (last N readings)
   - Deceleration gradient & jerk max
   - Impact duration window (time above threshold)
2. Motion Context:
   - Pre-impact average speed (3–5s prior)
   - Post-impact residual motion (avg magnitude 1–3s after)
   - Motion resume flags (boolean)
3. Pattern Flags:
   - Free-fall low gravity ratio
   - Stationary pre-impact indicator
   - Throw pattern boolean (free-fall + impact chain)
4. Environment & Temporal:
   - Hour-of-day bucket (night vs day)
   - Device power mode (normal / low)
   - Airplane / boat mode active
5. Historical / User Profile:
   - Past 7d false alarm rate
   - Past genuine incident count
   - Typical average driving acceleration baseline

## Model Selection Rationale
- Initial: Gradient Boosted Decision Trees (fast, interpretable, small footprint).
- Later: 1D CNN for temporal sensor micro-patterns (improved subtle differentiation between pothole vs crash decel).
- Export to TFLite for cross-platform inference; fallback pure-Dart inference path for low-end devices if needed.

## Inference Contract
Input: `VerificationFeatures`
Output: Incident probability `pIncident in [0,1]`
Blend:
```
heuristicScore = contextScore(env, pattern)
if severeImpact: return 1.0  // Hard override
blended = 0.6 * heuristicScore + 0.4 * pIncident
confidenceBucket:
  >0.8 => genuineIncident
  <0.3 => falseAlarmDetected
  else => uncertainIncident
```

## Safety Overrides (Never Delegated to ML)
- Severe impact bypass (≥250 m/s² sustained)
- Verified stationary stop after impact (3s window complete)
- Direct free-fall + high impact with throw pattern (≥ fall threshold + pattern strength)
- Manual user cancel / OK (immediate)

## Data Collection (Phase 1 – Opt-In)
- Store rotating local ring buffer (e.g. last 500 events) of feature sets & heuristic outcome.
- Upload anonymized aggregates only if user explicitly opts-in. No raw sensor arrays.
- Differential privacy: noise injection for frequency counts.

## False Alarm Reduction Goals
Baseline (heuristic only): ~X (pending measurement) false alarms / 100 active detection hours.
Target Phase 2: 40% reduction without increasing missed genuine incidents (>99% recall for severe crashes & >95% for 1.5m+ falls).

## Edge Cases
- Low sensor fidelity (older devices) → fallback to heuristics.
- Intermittent location services (speed unavailable) → degrade environmental features gracefully.
- High vibration environments (boat/airplane) → mode flags reduce model weight on impact features.

## Implementation Steps (Actionable)
1. Add `verification_ml_adapter.dart` (interface + features struct) [Phase 0].
2. Inject adapter into `AIVerificationService`; use if `isModelLoaded` true.
3. Add external feed mode to remove internal sensor subscription duplication.
4. Implement feature snapshot builder using existing buffers.
5. Introduce local logging of feature vectors (opt-in flag) → secure storage.
6. Build training pipeline script (outside app) to transform feature CSV → LightGBM → export TFLite.
7. Add TFLite runtime (optional plugin) & implement adapter inference.
8. Add blending logic & confidence bucket thresholds.
9. Telemetry (anonymized) for confidence distribution & override triggers.
10. Gradual rollout gating via remote config percentage.

## Phone OEM Crash AI Compatibility
We do NOT rely on or override phone vendor proprietary crash/fall detection. Our ML:
- Operates strictly on raw sensor streams + contextual app data.
- Namespaced under `RedPing` to avoid UI confusion.
- Never claims OS-level certification or replaces emergency call functions.

## Testing Matrix (Incremental)
| Scenario | Heuristic Outcome | ML Prob | Expected Blend | Final | Override Source |
|----------|------------------|---------|----------------|-------|-----------------|
| 60 km/h crash (stop) | High | 0.85 | >0.8 | Genuine | Severity + ML |
| Pothole bump | Potential | 0.15 | <0.3 | False Alarm | ML + lack decel |
| Phone drop (1m) | Below fall thresh | 0.25 | <0.3 | False Alarm | Heuristic fail |
| Vigorous handling | ViolentHandling | 0.10 | <0.3 | False Alarm | Heuristic + ML |
| Ambiguous low-speed impact | Potential | 0.55 | ~0.55 | Uncertain | Blend only |
| Severe 80 km/h crash | Severe | Any | 1.0 | Genuine | Hard override |

## Rollback Plan
- Remote config kill switch disables ML adapter → immediate reversion to heuristic pipeline.
- Preserve identical public APIs; UI integration reads `verificationOutcome` unchanged.

## Next Immediate Actions
1. Add adapter + integrate into `_performAIAssessment`.
2. Document feature extraction & blending (this file).
3. Enable external feed mode scaffolding (no duplicate streams).
4. Provide consolidation report of duplicated logic between services.

---
Revision: 2025-11-13
Owner: AI Platform / Safety Engineering
Status: Phase 0 scaffold
