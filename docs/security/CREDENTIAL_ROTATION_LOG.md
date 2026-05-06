# Credential Rotation Log

Use this file to record each compromised or potentially compromised credential, when it was revoked, what replaced it, and where the replacement is stored.

## Status Legend

- `pending`: identified but not yet rotated or revoked
- `revoked`: disabled without replacement
- `rotated`: replaced with a new credential
- `not-needed`: credential no longer required

## Entries

| Surface | Identifier | Exposure Source | Status | Revoked/Rotated At | Replacement Location | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Firebase client API key | Android `current_key` values | historical git exposure | pending |  |  | Replace from Firebase console or FlutterFire-generated config |
| Firebase client API key | iOS `API_KEY` values | historical git exposure | pending |  |  | Replace from Firebase console or FlutterFire-generated config |
| Firebase web API key | `lib/firebase_options.dart` web placeholder | historical git exposure | pending |  |  | Regenerate from trusted Firebase project config |
| Firebase Admin service account JSON | `docs/Admin private key redping-a2e37-firebase-adminsdk-fbsvc-ebd2831aac.json` | committed private key JSON in git history | pending |  |  | Revoke all active keys for the affected service account |

## Storage Rules

1. Do not paste replacement secrets into this file.
2. Record only the storage location, such as secret manager, local secure vault, CI secret name, or Firebase-generated config source.
3. If a credential is no longer required, mark it `not-needed` and document the removal path in Notes.

## Completion Check

- all exposed credentials moved out of `pending`
- replacement locations documented
- no replacement secrets committed to the repo