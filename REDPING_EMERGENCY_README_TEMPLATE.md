# RedPing Emergency — README Template (Planning)

## Overview
Consumer safety app with ACFD, verification, and SOS escalation.

## Features
- Auto Crash/Fall Detection (ACFD)
- Manual SOS & contacts
- Hazard alerts
- Offline SOS queue

## Setup (Planning)
- App ID: `com.redping.emergency`
- Dart-define env keys (see ENV_KEYS_SETUP.md)
- Firebase config per app

## Build (later)
```bash
flutter analyze
flutter test
flutter build apk -t lib/main.dart
```

## Notes
- Foreground service only during verification/SOS.
