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
| Google AI API key | `projects/557287609270/locations/global/keys/047fd37a-f40d-4a05-96ae-e40e69453de6` | historical git exposure in archived AI docs | rotated | 2026-05-06 | Google Cloud API Keys resource `047fd37a-f40d-4a05-96ae-e40e69453de6` | Verified current key string no longer matches the leaked Gemini-era value from git history |
| Firebase client API key | Android key resource `1fee3a20-a5df-4c67-9d87-4905dbb9ddf7` | historical git exposure | pending |  | Firebase Android app config for project `redping-a2e37` | Follow `docs/security/FIREBASE_CLIENT_KEY_REPLACEMENT_RUNBOOK.md`; current Firebase config download still emits the exposed Android key |
| Firebase client API key | iOS key resource `99f5430d-f6a9-47e7-bb79-ae3c71019db2` | historical git exposure | pending |  | Firebase iOS app config for project `redping-a2e37` | Follow `docs/security/FIREBASE_CLIENT_KEY_REPLACEMENT_RUNBOOK.md`; rewritten repo iOS bundle ID `com.redping.redping` does not currently match the live Firebase iOS app registrations `com.romana.redping.sos` and `com.redping.sar` |
| Firebase web API key | Browser key resource `865e9587-e6ab-41c3-8670-1f54d5519a6a` | historical git exposure | pending |  | Firebase web app config for project `redping-a2e37` | Follow `docs/security/FIREBASE_CLIENT_KEY_REPLACEMENT_RUNBOOK.md`; current Firebase web SDK config still emits the exposed browser key |
| Firebase Admin service account JSON | User-managed keys for `firebase-adminsdk-fbsvc@redping-a2e37.iam.gserviceaccount.com` including exposed key `ebd2831aacaec5b4f3f387e8db5f18823a3e18d9` | committed private key JSON in git history | revoked | 2026-05-06 | No replacement created in repo; service account remains disabled in Google Cloud | Verified the exposed key was deleted and the two remaining user-managed keys were also deleted; no user-managed keys remain on this disabled service account |

## Storage Rules

1. Do not paste replacement secrets into this file.
2. Record only the storage location, such as secret manager, local secure vault, CI secret name, or Firebase-generated config source.
3. If a credential is no longer required, mark it `not-needed` and document the removal path in Notes.

## Completion Check

- all exposed credentials moved out of `pending`
- replacement locations documented
- no replacement secrets committed to the repo