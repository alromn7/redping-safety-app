# Firebase Client Key Replacement Runbook

This runbook covers the remaining exposed Firebase client API keys for project `redping-a2e37`.

These keys are still active because Firebase currently emits them in the generated app configuration for the existing Android, iOS, and web app registrations. Do not revoke them until replacement config has been generated, verified, and staged.

## Remaining Key Resources

- Android: `1fee3a20-a5df-4c67-9d87-4905dbb9ddf7`
- iOS: `99f5430d-f6a9-47e7-bb79-ae3c71019db2`
- Web: `865e9587-e6ab-41c3-8670-1f54d5519a6a`

## Source of Truth

- `firebase.json` maps the live Firebase app registrations used to regenerate platform config.
- `android/app/google-services.json` must be downloaded from Firebase Console for the registered Android app.
- `ios/Runner/GoogleService-Info.plist` and any flavor-specific plist must be downloaded from Firebase Console for the exact iOS bundle IDs in use.
- `lib/firebase_options.dart` must be regenerated from FlutterFire CLI or replaced from a trusted local-only source.

## Verified Live App Identifiers

- Android app `1:557287609270:android:ee97c332c47695a6832717` is `com.redping.redping` and matches the rewritten repo Android application ID.
- Verified SHA-1 hashes for Android app `1:557287609270:android:ee97c332c47695a6832717`: `df3043a5f6295bed6cf3b7b2753dc5d97626b88a`, `406fc289d379cd0a22d7329a607abc7e91733b8a`, `1296513c200bdecb695651ba416f5f68eb71d125`, `329e6b8324ae7585440ab51c7ebbbd5c04597698`, `443a5328d2ec1f0bf353e6035226f9ff76cb9950`.
- Verified SHA-256 hashes for Android app `1:557287609270:android:ee97c332c47695a6832717`: `4a6adab5cd9ad2fa5670cd0222d470a1666b821f49d5266f4b1397ad57b500a9`, `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`.
- iOS app `1:557287609270:ios:e9d9a07f62e910b7832717` is `com.romana.redping.sos` and is the active Firebase iOS app for SOS.
- iOS app `1:557287609270:ios:3d8ac6cbc0c84ebe832717` is `com.redping.sar`.
- Web app `1:557287609270:web:3bd44b87fdf7a324832717` is `redping_14v (web)`.

## Confirmed Blocker

- The approved Firebase iOS SOS app is `com.romana.redping.sos`.
- The rewritten repo has now been realigned locally to that bundle ID and Firebase iOS app ID while keeping the API key redacted.
- Do not register `com.redping.redping` as a new Firebase iOS app for this remediation path unless product requirements explicitly change.
- Do not rotate the iOS Firebase client key until a fresh local plist is downloaded from Firebase Console or `firebase apps:sdkconfig ios` and validated in a non-committed workspace.

## Safe Replacement Procedure

1. In Firebase Console, open project `redping-a2e37` and review the registered Android, iOS, and web apps.
2. Confirm the exact package IDs and bundle IDs currently used by the active SOS and SAR builds before downloading any replacement config.
3. Generate fresh platform config from trusted sources only:
   - download a fresh `android/app/google-services.json`
   - download fresh iOS plist files for each active bundle ID
   - regenerate `lib/firebase_options.dart` with FlutterFire CLI against the same project
4. Store the downloaded/generated files only in a secure local workspace. Do not commit live keys.
5. Replace local redacted placeholders with the fresh config in a temporary validation branch or uncommitted local state.
6. Run targeted validation before revocation:
   - confirm Firebase initializes successfully
   - confirm email/password auth still works
   - confirm Google Sign-In still works on Android and iOS if those flows are enabled
   - confirm web initialization succeeds if web remains supported
7. Only after the replacement config is validated, revoke the old Android, iOS, and web Firebase API key resources in Google Cloud.
8. Immediately regenerate/download config again if Firebase emits different client keys after revocation.
9. Update `docs/security/CREDENTIAL_ROTATION_LOG.md` with the final revoke or rotate timestamp and the trusted replacement source.

## Validation Notes

- The app prefers native Firebase config on mobile and uses generated Dart options where needed.
- Because of that split, replacement validation must cover both native config files and `lib/firebase_options.dart`.
- If Firebase Console still reissues the same client key after regeneration, stop and reassess before revocation; that means the replacement path has not actually changed the credential.

## Stop Conditions

Stop and do not revoke the client keys yet if any of the following is true:

- downloaded Firebase config still contains the same exposed key value
- the exact active iOS bundle IDs or Android package names are unclear
- the local iOS target bundle ID or checked-in plist has drifted away from the approved live Firebase iOS app registration
- auth or app initialization fails with the staged replacement config
- the change would require unreviewed edits to locked SOS production files
