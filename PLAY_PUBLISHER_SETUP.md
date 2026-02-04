# Play Publisher Setup

Integrates Gradle Play Publisher to automate internal track uploads.

## Secrets Required
Set these GitHub repository secrets:
- `PLAY_SERVICE_ACCOUNT_JSON_BASE64`: Base64 of service account JSON downloaded from Google Cloud IAM (role: Play Developer API Access).
- `PLAY_PUBLISH`: `true` to enable publishing step, anything else or empty to skip.

## Generating Service Account JSON
1. In Google Cloud Console, create a service account (e.g. `play-publisher-redping`).
2. Grant "Google Play Android Developer" access inside Play Console (Settings > Developer account > API access).
3. Create JSON key; download.
4. Convert to base64 (PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('service-account.json'))
```
5. Store output in `PLAY_SERVICE_ACCOUNT_JSON_BASE64` secret.

## Workflow Behavior
- If `PLAY_SERVICE_ACCOUNT_JSON_BASE64` present, decodes to `android/play/service-account.json`.
- If `PLAY_PUBLISH == 'true'`, runs `./gradlew :app:publishReleaseBundle` after successful build & verification.
- Uses `track = internal` (change in `android/app/build.gradle.kts` for production).

## Changing Track
Edit in `android/app/build.gradle.kts`:
```kotlin
play { track.set("internal") }
```
Replace `internal` with `alpha`, `beta`, `production` or custom testing tracks.

## Dry Run
Temporarily set:
```kotlin
enabled.set(false)
```
or keep `PLAY_PUBLISH` unset to skip upload.

## Verification After Upload
1. Check Actions log for successful `publishReleaseBundle`.
2. In Play Console internal testing track, confirm new version code `1` (or incremented code) appears.
3. Review Pre-Launch reports & bundle explorer signature (should match archived fingerprint).

## Rotations & Updates
- On keystore rotation, no change needed for service account.
- On major version release, increment `versionCode` in `pubspec.yaml` (Flutter build will propagate) before tagging.

## Troubleshooting
| Issue | Cause | Fix |
|-------|-------|-----|
| 403 Permission Denied | Service account not linked in Play Console | Link & grant access in API access page |
| Invalid Grant | Key JSON malformed or base64 wrong | Re-base64 file, update secret |
| Track not found | Track string typo | Use valid track name (`internal`, `production`, etc.) |
| Publishing skipped | `PLAY_PUBLISH` not `true` | Set secret to `true` |

## Security Notes
- Never commit `service-account.json`.
- Limit service account to only Play publishing role.
- Rotate JSON key annually; update secret accordingly.

---
Ready for activation once secrets are added.
