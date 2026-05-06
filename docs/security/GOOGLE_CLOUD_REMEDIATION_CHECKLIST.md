# Google Cloud Remediation Checklist

This checklist is for project `redping-a2e37` after Google Cloud suspended it for activity consistent with exposed credentials or API keys.

## Confirmed Incident Scope

- Git history contained exposed Google-style API keys.
- Git history also contained a committed Firebase Admin service-account private-key JSON.
- Hosted Git history has now been rewritten and revalidated from a fresh clone.
- The old dirty local repo was preserved and should not be treated as the active source of truth.

## Immediate Credential Actions

1. In Google Cloud Console, open project `redping-a2e37`.
2. In `APIs & Services -> Credentials`, review every API key and remove or rotate anything not strictly required.
3. Treat all previously exposed keys as compromised, even if they are now gone from git history.
4. In `IAM & Admin -> Service Accounts`, inspect any service account that may have had downloadable keys.
5. Revoke all active JSON keys for affected service accounts.
6. Create replacement service-account credentials only if they are still operationally required.
7. Update any local or CI secret stores with newly rotated credentials.
8. Do not restore live credentials into tracked repo files.

## RedPing-Specific Focus Areas

1. Replace Firebase client config from trusted sources only:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `ios/Runner/GoogleService-Info-SAR.plist`
   - `lib/firebase_options.dart` via FlutterFire CLI or local-only defines
2. Recreate any Firebase Admin credential usage from secret storage, not docs or repo files.
3. Verify no backup copies of credential files remain in downloads, desktop folders, or shared drives.
4. Review CI/CD secrets for stale Google credentials and rotate them if they were ever derived from the exposed material.

## Resource Review

1. Review Compute Engine, Cloud Run, App Engine, Cloud Functions, Firebase, and billing activity for resources you did not create.
2. Delete unauthorized resources immediately.
3. Review usage spikes and API activity around the suspension window.
4. Check service accounts for unusual last-used patterns or unfamiliar principals.

## Collaborator Cleanup

1. Tell collaborators to reclone or hard-reset to the rewritten repository history.
2. Remove stale local clones that still contain leaked history.
3. Invalidate cached archives, exported zips, and copied working folders that may still hold secrets.

## Appeal Status

- Appeal submitted to Google Cloud on 2026-05-06.
- Submission included the completed git history scrub and Firebase Admin service-account key removals.
- Firebase client key replacement remains pending because the current Firebase project configuration still emits those active keys.

## Appeal Draft

Use this as the basis for the Google Cloud appeal after rotation and cleanup are complete:

```text
Our project `redping-a2e37` was reviewed after your suspension notice. We confirmed that exposed Google credentials had been present in our repository history, including Google API keys and a Firebase Admin service-account private-key JSON.

We have completed the following remediation steps:
- removed the exposed credentials from reachable git history and validated the rewritten hosted repository from a fresh clone
- revoked or are revoking all previously exposed API keys and service-account credentials
- reviewed project resources for unauthorized activity and removed any unauthorized resources found
- updated our operational process so live credentials are no longer stored in tracked source files or documentation
- instructed collaborators to reset or reclone from the rewritten repository history

We request reinstatement of project `redping-a2e37`. If there are additional findings from your side, we are prepared to address them immediately.
```

## Exit Criteria

- all exposed credentials rotated or revoked
- no unauthorized resources remain
- fresh Firebase client config generated from trusted console sources
- collaborators notified to stop using old history
- appeal submitted with the completed remediation summary