# Security Runtime Flags

Use these `--dart-define` flags to control client-side security features at build/run time.

## Flags
- `ENABLE_REQUEST_SIGNING` (bool): Enable HMAC request signing. Default: `false`.
- `ENABLE_TLS_PINNING` (bool): Enforce TLS pinning for configured hosts. Default: `false`.
- `ENABLE_PLAY_INTEGRITY_HEADER` (bool): Attach Android Play Integrity token and nonce headers on requests (best-effort). Default: `true`.
- `REQUIRE_PLAY_INTEGRITY_FOR_WRITES` (bool): ANDROID ONLY. Require a Play Integrity token for non-GET API calls; fail fast if unavailable. Default: `false`.
- `REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES` (bool): iOS ONLY. Fail fast for non-GET API calls on jailbroken devices. Default: `false`.
- `EXPECTED_ANDROID_SIG_SHA256` (string): Expected app signature digest for runtime self-checks.

## Typical Staging Run
```powershell
flutter run `
  --dart-define=BASE_URL=https://us-central1-redping-staging.cloudfunctions.net `
  --dart-define=ENABLE_REQUEST_SIGNING=true `
  --dart-define=ENABLE_TLS_PINNING=true `
  --dart-define=ENABLE_PLAY_INTEGRITY_HEADER=true `
  --dart-define=REQUIRE_PLAY_INTEGRITY_FOR_WRITES=false `
  --dart-define=REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=false `
  --dart-define=EXPECTED_ANDROID_SIG_SHA256=<YOUR_SHA256_DIGEST>
```

## Strict Production Run
```powershell
flutter run `
  --release `
  --dart-define=BASE_URL=https://us-central1-redping-prod.cloudfunctions.net `
  --dart-define=ENABLE_REQUEST_SIGNING=true `
  --dart-define=ENABLE_TLS_PINNING=true `
  --dart-define=ENABLE_PLAY_INTEGRITY_HEADER=true `
  --dart-define=REQUIRE_PLAY_INTEGRITY_FOR_WRITES=true `
  --dart-define=REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=true `
  --dart-define=EXPECTED_ANDROID_SIG_SHA256=<YOUR_SHA256_DIGEST>
```

Notes
- Server-side verification of Play Integrity remains the source of truth; client gating is an additional guardrail.
- Keep `pins.json` current using the provided extraction/validation tools before enabling TLS pin enforcement.
- iOS runtime integrity gating currently blocks jailbroken devices using the native `SecurityPlugin` check.
