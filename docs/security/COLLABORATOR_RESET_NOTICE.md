# Collaborator Reset Notice

The repository history was force-rewritten to remove exposed Google API keys and a committed Firebase Admin private-key JSON.

## Required Actions

1. Stop pushing from any clone that still has the old history.
2. Prefer a fresh reclone of the repository.
3. If a reclone is not possible, fetch and hard-reset only after confirming no local work is needed:

```bash
git fetch --all --prune --tags
git checkout main
git reset --hard origin/main
```

4. Delete any old local tags or stale clones that still contain the leaked history.
5. Rotate any credentials that may have been copied before the history rewrite.

## Why This Was Necessary

- exposed Google/Firebase API keys were present in repo history
- a Firebase Admin service-account private-key JSON had been committed under `docs/`
- the Google Cloud project `redping-a2e37` was suspended, consistent with compromised credentials

## Current State

- hosted Git history has been rewritten and revalidated from a fresh clone
- the old dirty local repo was preserved as evidence and should not be used as the ongoing source of truth