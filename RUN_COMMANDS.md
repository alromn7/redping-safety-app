# Run Commands (SOS vs SAR)

This repo has two Flutter entrypoints:
- SOS: `lib/main_sos.dart`
- SAR: `lib/main_sar.dart`

Android uses product flavors:
- `sos`
- `sar`

## Quick Run (recommended)

### SAR
PowerShell:
- `./run_sar.ps1`

CMD/BAT:
- `run_sar.bat`

### SOS
PowerShell:
- `./run_sos.ps1`

CMD/BAT:
- `run_sos.bat`

## Full Flutter Commands (copy/paste)

### Run SAR
- `flutter run --flavor sar -t lib/main_sar.dart`

### Run SOS
- `flutter run --flavor sos -t lib/main_sos.dart`

### Pick a device
1) List devices:
- `flutter devices`

2) Run on a specific device:
- `flutter run -d <deviceId> --flavor sar -t lib/main_sar.dart`
- `flutter run -d <deviceId> --flavor sos -t lib/main_sos.dart`

## Hot Reload / Hot Restart

Hot reload is available by default in **debug** mode when you run `flutter run`.

While the app is running in the terminal:
- Press `r` = hot reload
- Press `R` = hot restart
- Press `q` = quit

Note: There is **no** `--hot` flag for `flutter run`.

## Why `--flavor sar` sometimes opens SOS

`--flavor sar` only selects the **Android build flavor**.
If you don’t pass `-t lib/main_sar.dart`, Flutter runs the default entrypoint in `lib/main.dart` (SOS).

## PowerShell script policy (if blocked)

If PowerShell blocks running `.ps1` scripts, run this once:
- `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

## Feature Flags (SOS)

### AI Assistant (hidden by default)

The SOS app currently hides the **AI Assistant** UI/routes by default.
This does **not** disable ACFD/system AI.

To enable the AI Assistant for a dev run, pass:
- `--dart-define=FEATURE_FLAGS={"enableAIAssistant":true}`
