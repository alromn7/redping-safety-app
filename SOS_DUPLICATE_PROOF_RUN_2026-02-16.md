# SOS Duplicate Ping Proof Run — 2026-02-16

## Scope
Auditable live verification that one SOS activation produces one SOS ping creation/publication (no duplicate ping generation).

## Environment
- Device: `ZY22LZMX9T` (moto g04s)
- SOS app: running from `flutter run -d ZY22LZMX9T --flavor sos -t lib/main_sos.dart`
- SAR app: user-confirmed running concurrently

## Procedure
1. Cleared Android logs:
   - `adb logcat -c`
2. Started focused live capture for SOS trigger + ping lifecycle lines.
3. Performed one full SOS activation (`done3`).
4. Extracted grouped counts from `adb logcat -d`:
   - create pattern: `Creating REAL SOS ping from session`
   - publish pattern: `Published SOS ping to SAR dashboard for session`

## Captured Evidence
- `02-16 23:05:09.824 ... SOSPingService: Creating REAL SOS ping from session ZWFiQW2ttTyuXQgJszQW ...`
- `02-16 23:05:10.363 ... SOSService: Published SOS ping to SAR dashboard for session ZWFiQW2ttTyuXQgJszQW`

## Deterministic Counts
- `CREATE_COUNTS`
  - `ZWFiQW2ttTyuXQgJszQW = 1`
- `PUBLISH_COUNTS`
  - `ZWFiQW2ttTyuXQgJszQW = 1`

## Result
PASS — No duplicate SOS ping creation/publication observed in this proof run.

---

## Second Auditable Run (same day)

### Scope
Repeat the proof run to confirm stable behavior across consecutive live activations.

### Procedure
1. Cleared Android logs again:
  - `adb logcat -c`
2. Started focused live capture.
3. Performed one full SOS activation (`done4`).

### Captured Evidence
- `02-16 23:10:01.046 ... SOSPingService: Creating REAL SOS ping from session GqduI26RcpMGswdpOrZP ...`
- `02-16 23:10:01.569 ... SOSService: Published SOS ping to SAR dashboard for session GqduI26RcpMGswdpOrZP`

### Deterministic Outcome (from capture)
- Session `GqduI26RcpMGswdpOrZP` observed once in create line.
- Session `GqduI26RcpMGswdpOrZP` observed once in publish line.

### Result
PASS — No duplicate SOS ping observed in second consecutive auditable run.
