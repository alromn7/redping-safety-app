# Security Validation Checklist (Nov 17, 2025)

Use this checklist to validate REDP!NG's client↔server protections after deploys.

## Prerequisites
- Backend deployed in `australia-southeast1` and healthy at `/health`.
- Functions config set with a strong `signing.secret` or `SIGNING_SECRET` in dotenv.
- Android physical device for Play Integrity tests; iOS non-jailbroken device for iOS gating.

## 1) Health and Basic Reachability
- Verify health returns OK:
  - PowerShell:
    ```powershell
    $u = 'https://australia-southeast1-<PROJECT_ID>.cloudfunctions.net/api/health'
    (Invoke-WebRequest -UseBasicParsing -Uri $u -Method GET -TimeoutSec 30).Content
    ```
  - Expect: `{"ok":true,"status":"healthy"}`

## 2) Firestore Nonce TTL Policy
- Enable via Console (recommended when gcloud lacks TTL):
  - Firestore → Indexes → TTL → Add
  - Collection group: `request_nonces`
  - Field: `expireAt` (Timestamp)
- Validate:
  - Trigger protected write(s) to create nonce docs.
  - After ~5 minutes, confirm consumed nonce docs auto-delete.

## 3) Android Runtime Integrity (Play Integrity)
- Run prod build on a physical Android device:
  ```powershell
  .\scripts\run_prod.ps1
  ```
- Trigger a protected action (e.g., location update) or use in-app hidden ping (see section 5).
- Expect success only when Integrity + HMAC + nonce are present.
- Negative test: Temporarily disable Integrity header and confirm server rejects with `MISSING_INTEGRITY_HEADERS`.

## 4) iOS Runtime Parity Gate
- Ensure flag enabled for production runs:
  ```
  --dart-define=REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=true
  ```
- On non-jailbroken device: protected actions should succeed.
- On jailbroken device: client should fail fast (`IOS_JAILBROKEN_BLOCKED`).

## 5) One-Tap Protected Ping (In-App)
- On SOS page, long-press the settings icon.
- Expect green snackbar on success: "Protected ping: success (HMAC + Integrity OK)".
- Red snackbar indicates failure; check logs (`SafeLog` masks sensitive data).

## 6) Integration Test (Device)
- Android/iOS physical device only:
  ```powershell
  flutter devices
  flutter test integration_test/protected_ping_test.dart -d <DEVICE_ID>
  ```
- Expect pass on compliant devices.

## 7) Direct Protected Route Exercises (Optional)
- Generate HMAC headers for a payload using the CLI helper:
  ```powershell
  dart .\scripts\sign_request_cli.dart POST /protected/ping '{"timestamp":"2025-11-17T00:00:00Z"}'
  # Outputs: X-Signature-Alg, X-Signature, X-Timestamp, X-Nonce
  ```
- Send request (server will still require Play Integrity on Android-origin traffic, but this is useful for basic HMAC checks):
  ```powershell
  $url = 'https://australia-southeast1-<PROJECT_ID>.cloudfunctions.net/api/protected/ping'
  $body = '{"timestamp":"2025-11-17T00:00:00Z"}'
  Invoke-WebRequest -UseBasicParsing -Uri $url -Method POST `
    -Headers @{
      'Content-Type'='application/json';
      'X-Signature-Alg'='<from-cli>';
      'X-Signature'='<from-cli>';
      'X-Timestamp'='<from-cli>';
      'X-Nonce'='<from-cli>'
    } -Body $body
  ```
- Expect server to validate HMAC; Integrity may still be enforced depending on route policy.

## 8) TLS Pinning
- Enabled by default in scripts; ensure endpoints are correct and pins current.
- The client heartbeat logs a single warning if hostnames/pins mismatch, then suppresses repeats.

## 9) PII-Safe Logging
- Confirm logs do not output raw emails/phones/tokens/signatures or precise lat/lng.
- `SafeLog` should mask/scrub sensitive tokens and coarse-coordinates.

## 10) Post-Validation
- Confirm no replay accepted within the 5-minute window.
- Confirm logs avoid sensitive output under normal and failure conditions.
- Capture screenshots of in-app protected ping success and TTL auto-deletion as proof.

---

### Quick Reference Flags
- Android: `ENABLE_PLAY_INTEGRITY_HEADER=true`, `REQUIRE_PLAY_INTEGRITY_FOR_WRITES=true`.
- iOS: `REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=true` for production.
- Always: `ENABLE_REQUEST_SIGNING=true`, `ENABLE_TLS_PINNING=true`.

### Notes
- Emulators generally do not satisfy Play Integrity.
- Server-side validation (HMAC + nonce + Integrity) remains the source of truth; client gating adds UX guardrails.
