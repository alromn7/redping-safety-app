# Release Tag & Signing Verification Checklist

Certificate (current):
- SHA-256: 53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469
- SHA-1:    406fc289d379cd0a22d7329a607abc7e91733b8a
- DN:       CN=Redping, O=Redping, L=City, ST=State, C=US

## 1. Pre-tag Sanity
- [ ] Working branch is `main` and clean (`git status` has no changes).
- [ ] `flutter build apk --release --flavor sos -t lib/main_sos.dart` succeeds locally.
- [ ] `flutter build apk --release --flavor sar -t lib/main_sar.dart` succeeds locally.
- [ ] Local APK signature shows CN=Redping (no "Android Debug").
- [ ] Key passwords rotated & stored securely in secret manager.

Note: This repo builds multiple Android flavors (e.g. `sos`, `sar`). A plain
`flutter build apk --release` may succeed in Gradle but Flutter may not locate the
APK under the default `app-release.apk` name. Expected outputs:
- `build/app/outputs/flutter-apk/app-sos-release.apk`
- `build/app/outputs/flutter-apk/app-sar-release.apk`

## 2. Create Annotated Tag
```
git pull origin main
export REL_VER=v1.0.0   # adjust version
git tag -a $REL_VER -m "Release $REL_VER (Redping cert SHA256: 53b37f...)"
git push origin $REL_VER
```
(Windows PowerShell equivalent):
```
$REL_VER = "v1.0.0"
git pull origin main
git tag -a $REL_VER -m "Release $REL_VER (Redping cert SHA256: 53b37f...)"
git push origin $REL_VER
```

## 3. CI Workflow Expected Steps
- Decode base64 keystore → write `android/keystore/redping-release.jks`.
- Use `key.properties` or env vars for signing.
- Build APK/AAB.
- Verify signature step prints CN=Redping + correct SHA-256.
- Generate SHA-256 checksums artifact.

## 4. Post-build Verification
After workflow finishes:
- [ ] Download APK/AAB artifact.
- [ ] Run:
```
C:\Users\<you>\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat verify --print-certs app-release.apk
```
Ensure output SHA-256 matches `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`.
- [ ] Confirm no fallback to debug certificate (CN=Android Debug should NOT appear).

## 4a. Latest Local Verification (2026-02-04)
Tag: `v1.0.1+3`

Artifacts found under `build/app/outputs/flutter-apk/...`:
- SOS: `build/app/outputs/flutter-apk/app-sos-release.apk`
- SAR: `build/app/outputs/flutter-apk/app-sar-release.apk`

Package versions (from `aapt dump badging`):
- SOS: `com.redping.redping` versionCode `3`, versionName `1.0.1`
- SAR: `com.redping.redping.sar` versionCode `3`, versionName `1.0.1-sar`

`apksigner verify --print-certs` results (SOS + SAR):
- DN: `CN=Redping, O=Redping, L=City, ST=State, C=US`
- SHA-256: `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`
- SHA-1: `406fc289d379cd0a22d7329a607abc7e91733b8a`

## 5. Fingerprint Archival
Append/update fingerprints in `SIGNING_FINGERPRINTS.md` (create if missing):
```
## YYYY-MM-DD Rotation
Alias: redping-key
SHA-256: 53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469
SHA-1:    406fc289d379cd0a22d7329a607abc7e91733b8a
DN:       CN=Redping, O=Redping, L=City, ST=State, C=US
```
Store outside repo in secure secrets vault as well.

## 6. (Optional) Play Console Prep
- [ ] Upload AAB to internal testing track.
- [ ] Confirm Google Play reports correct SHA-1 (matches above).
- [ ] Roll out to closed/instrumented testers before production.

## 7. Roll-forward Strategy
If future rotation: keep prior fingerprints in the same doc with date stamps; never delete old entries.

## 8. Rollback Strategy
If CI artifacts show debug cert or mismatched fingerprint:
1. Stop distribution and revoke tag (`git tag -d <tag>; git push origin :refs/tags/<tag>`).
2. Re-run keystore rotation script or restore previous backup `.bak` file.
3. Rebuild and re-tag.

---
Checklist owner: Release Engineer / Security.
