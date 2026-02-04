# RedPing SAR — README Template (Planning)

## Overview
Professional SAR operations app for team coordination and messaging.

## Features
- SAR identity & verification
- Org/team management
- Incident lifecycle & messaging
- On-demand location sharing

## Setup (Planning)
- App ID: `com.redping.sar`
- Dart-define env keys (see ENV_KEYS_SETUP.md)
- Firebase project or SAR collections

## Build (later)
```bash
flutter analyze
flutter test
flutter build apk -t lib/main.dart
```

## Notes
- No continuous sensors; minimal background footprint.
