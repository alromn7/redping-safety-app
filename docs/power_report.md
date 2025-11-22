# Redping power usage snapshot (Android batterystats)

Captured on: device Pixel (ADB over Wi‑Fi), using `dumpsys batterystats --charged` after recent app session.

## Global (device) totals
- Capacity: 4708 mAh
- Computed drain: 129 mAh; actual drain: 129 mAh
- Major components (all apps + system):
  - Screen: 42.6 mAh
  - CPU: 110 mAh (duration: 37m 37s)
  - Mobile radio: 13.5 mAh
  - GNSS: 1.80 mAh (duration: 33m 05s)
  - Wi‑Fi: 13.0 mAh
  - GPU: 22.1 mAh

## App: com.redping.redping (UID u0a357)
- Total attributed: 113 mAh
  - Foreground: 55.0 mAh (time: 25m 05s)
  - Background: 18.7 mAh
  - Cached: 0.0188 mAh (1.0s)
- Breakdown by component:
  - Screen: 39.2 mAh
  - CPU: 51.0 mAh (fg 36.6; bg 14.4; cached ~0.015)
  - GNSS: 1.22 mAh (total GNSS time ~24m 52s; fg ~21m 25s; bg ~3m 27s)
  - Wi‑Fi: 0.260 mAh (fg 0.061; bg 0.199)
  - GPU: 21.3 mAh (fg 17.4; bg 3.96)

On-battery subset (screen on):
- Screen: 22.9 mAh
- CPU: 31.5 mAh (fg 19.9; bg 11.7)
- GNSS: 0.822 mAh (~14m 10s)
- Wi‑Fi: 0.259 mAh
- GPU: 12.3 mAh

Notes:
- The large "Screen" and "GPU" components indicate the app spent ~25 minutes actively in the foreground with rendering work (animations/repaints) — expected during active testing.
- GNSS consumption is modest, but non-zero; geolocation was active for ~25 minutes total (majority in foreground), aligning with location services in use.

## Hotspots and hypotheses
- CPU (51.0 mAh): Likely driven by continuous sensor processing, Firebase listeners, and foreground Dart isolates/animations.
- GPU (21.3 mAh): UI rendering/animations during foreground presence; consider reducing unnecessary rebuilds/repaints.
- Screen (39.2 mAh): Primarily user-facing time; controlled by display brightness and screen-on duration during testing.
- GNSS (1.22 mAh): Continuous/high-rate location updates while app is foreground; background attribution is small but present.
- Wi‑Fi (0.260 mAh): Minimal network radio impact in this capture.

## Targeted optimization actions
1) Rendering/UI
- Avoid unnecessary setState()/rebuilds; place RepaintBoundary around frequently updating subtrees.
- Lower animation tick rate where fidelity allows; pause animations when offscreen or when the app is idle.
- Cache heavy images; precache where needed; prefer const widgets and const constructors.

2) Sensor/AI pipeline
- Keep lab flags off in production; ensure AI verification gate remains the only activation path (free-fall+impact or sustained+decel) to avoid extra CPU work.
- Batch or debounce sensor processing; prefer using platform sensor batching where feasible.

3) Location
- Use balanced power accuracy when continuous tracking is not critical; increase time/distance filters.
- Stop location stream promptly when not needed (e.g., after resolving a single fix or when app goes to background) and restart on demand.
- Batch reverse-geocoding and avoid rapid consecutive lookups.

4) Notifications/Messaging
- Ensure no duplicate permission prompts or redundant FCM listeners (already addressed).
- Avoid long-running wakeful operations on message receipt; move work to WorkManager with constraints when possible.

5) Foreground service discipline
- Keep foreground services truly necessary and scoped; stop them when the app is idle or work completes.

6) General
- Use power-saving toggles (e.g., internal “Low Power Mode”) to throttle intervals across sensors, location, and periodic tasks.
- Audit timers/streams for leaks; dispose listeners on lifecycle changes.

## Verification steps we ran
- Collected batterystats (charged): parsed the "Estimated power use (mAh)" section.
- Resolved com.redping.redping UID via package dump; matched to UID u0a357.
- Observed runtime POST_NOTIFICATIONS permission as granted and runtime permissions for location/record audio.

## Appendix: raw excerpts
- Estimated power use (mAh) → UID u0a357:
  - "UID u0a357: 113 fg: 55.0 (25m 5s 862ms) bg: 18.7 cached: 0.0188 (1s 16ms)"
  - "screen=39.2 cpu=51.0 ... gnss=1.22 ... wifi=0.260 ... GPU=21.3"
- On-battery subset:
  - "(on battery, screen on) screen=22.9 cpu=31.5 ... gnss=0.822 ... wifi=0.259 ... GPU=12.3"

## Next steps
- Add a configurable power profile (Normal/Low) to tune sensor and location sampling dynamically.
- Profile a background-idle scenario (screen off) to isolate baseline leakage: expect near-zero CPU/GPU/Screen mAh; verify GNSS is stopped when not in use.
- Repeat batterystats collection after changes to confirm mAh reductions.
