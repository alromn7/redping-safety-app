# Permissions Matrix — Emergency vs SAR (Planning)

## Android
- Emergency:
  - Location (foreground + background): rationale "Provide precise location during emergencies and detection verification"
  - Activity Recognition / Sensors: "Detect severe motion patterns for crash/fall detection"
  - Notifications: "Alert you during verification and SOS"
  - SMS (if applicable): "Send alerts to selected contacts with your consent"
  - Foreground Service (limited): active only during verification/SOS windows; persistent notification text
- SAR:
  - Location (foreground): "Share location on demand in active incidents"
  - Notifications: "Incident updates, task assignments, and mentions"
  - Internet: standard
  - No background sensors; no foreground service unless OS policies require persistent connection notice

## iOS
- Emergency:
  - Location (Always/When In Use): verification + SOS location
  - Motion & Fitness: crash/fall detection
  - Notifications: verification/SOS alerts
  - Background Modes: processing limited to verification/SOS windows; explain clearly in Info.plist
- SAR:
  - Location (When In Use): on-demand sharing
  - Notifications: incident updates
  - Background Modes: avoid unless messaging requires; keep minimal

## Rationale & Store Copy (Examples)
- Emergency:
  - "RedPing uses motion and location to detect severe impacts, verify your safety, and alert your contacts when necessary."
  - "We only run a foreground notification during short verification windows or active SOS to keep you informed."
- SAR:
  - "RedPing SAR coordinates search and rescue operations. Share your location on demand and receive incident updates from your team."

## Consent & Settings
- Emergency: explicit opt-in for ACFD and SMS; toggles for crash/fall; sensitivity sliders.
- SAR: opt-in to share location per incident; role-based notification settings.

## Compliance Notes
- Avoid consumer auto-detection claims in SAR listings.
- Emergency foreground service usage must be precise and time-bounded.
- Provide privacy policy links detailing sensors, data usage, retention, and opt-out.
