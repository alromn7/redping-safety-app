# History Scrub Migration Runbook

This runbook applies to the RedPing repository after the credential scrub incident on project `redping-a2e37`.

## Artifacts Created

Rollback and migration artifacts were created outside the repo so they do not enter source control:

- Live repo bundle: `/tmp/redping-history-scrub-artifacts/redping-live-pre-rewrite.bundle`
- Sanitized history bundle: `/tmp/redping-history-scrub-artifacts/redping-sanitized-history.bundle`
- Live worktree patch: `/tmp/redping-history-scrub-artifacts/redping-live-working-tree.patch`
- Live index patch: `/tmp/redping-history-scrub-artifacts/redping-live-index.patch`
- Live status snapshot: `/tmp/redping-history-scrub-artifacts/redping-live-status.txt`

## What Was Scrubbed

The sanitized mirror removed these leaked values from reachable history:

- `AIzaSyBVLe9v8WMxqLdP_8rOHnFQxOv8K3Qp9jI`
- `AIzaSyCBJhW4EHzPwzfxuauXSB1k30w_rTml6Po`
- `AIzaSyDVkOTdQRI0VJLRPQi-WP3LOKmcm-jvzLM`
- `AIzaSyDbfJvjgDxGZ21no8NSVLcQkXf7GTJf4ec`
- `docs/Admin private key redping-a2e37-firebase-adminsdk-fbsvc-ebd2831aac.json`

Validation on the sanitized mirror showed:

- no remaining reachable `AIza...` keys
- no remaining reachable copy of the committed Firebase Admin private-key JSON
- no remaining non-dependency private-key markers after excluding dependency examples and placeholder docs

## Remote Rewrite Script

Use the guarded script below from the repo root:

```bash
./scripts/security/push_sanitized_history.sh
```

The script refuses to push if any of these remote branches have moved since the scrub was prepared:

- `main`
- `dev/sensor-monitoring`
- `release/safety-fund-removal-prep-2026-02-16`

The script reads the hosted `origin` URL from the current repo and validates that hosted remote directly. It does not trust the mirror clone's own `origin` setting.
If the hosted repo no longer has the legacy release branch, the script skips that ref instead of recreating it.

If it fails, refresh the expected SHAs before attempting a force-push.

## Safe Local Recovery After Remote Rewrite

Do not try to `pull` the rewritten history into the old dirty worktree.

Preferred recovery sequence:

1. Keep the old repo untouched as a local evidence copy until the remote rewrite is confirmed.
2. Use this fresh clone as the new working copy.
3. Reapply only the local changes you still want from `/tmp/redping-history-scrub-artifacts/redping-live-working-tree.patch`.
4. Recreate any needed untracked files using `/tmp/redping-history-scrub-artifacts/redping-live-status.txt` as the inventory.

If the bulk patch does not apply cleanly, port only the needed changes manually from the old repo. That is safer than forcing old dirty state across a rewritten history boundary.

## Remote Cleanup Follow-Through

After the force-push succeeds:

1. Invalidate any cached archives or old local clones that still contain the leaked history.
2. Ask collaborators to reclone or hard-reset to the rewritten remote.
3. Rotate any credentials that were ever present in git history, even though the history has now been scrubbed.
4. Re-check GitHub tags, release attachments, and any external mirrors for copies of the removed secrets.

## Notes

- The old repo had a large dirty state, including tracked changes under `server/functions/node_modules`, which is why the rewrite was performed in an isolated mirror.
- The guarded push script uses explicit branch refspecs and a separate forced tag push so the rewrite is targeted and auditable.