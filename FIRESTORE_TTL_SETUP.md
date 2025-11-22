# Firestore TTL Setup for Nonce Replay Protection

This app writes consumed nonces into `request_nonces` with an `expireAt` timestamp. Enabling TTL on that field lets Firestore delete documents automatically after the replay window.

## Enable TTL (Console)
1. Open Firestore in the Firebase Console for project `redping-a2e37`.
2. Go to Settings (gear icon) → TTL.
3. Click "Add TTL policy".
4. Collection ID: `request_nonces`
5. Field: `expireAt` (type: timestamp)
6. Save and enable the policy.

Notes:
- TTL deletions are asynchronous and may take minutes/hours depending on load.
- Existing docs will be evaluated; those past `expireAt` are queued for deletion.

## Verify behavior
- Trigger a protected write from the app to generate a nonce document.
- Check Firestore → `request_nonces` for a new doc with `createdAt` and `expireAt`.
- After the TTL window elapses, the doc should disappear without manual cleanup.

## Local field shape (written by Cloud Functions)
```
{
  createdAt: <timestamp>,
  expireAt: <timestamp> // now + 5 minutes by default
}
```

## Adjusting replay window
- The server currently uses a 5-minute window. To change it, edit:
  - `functions/src/security/signingUtil.ts` → `NONCE_TTL_MS`
  - `functions/src/security/nonceStore.ts` → `ttlMs` default
- Rebuild and redeploy functions after changes:
```
cd functions
npm run build
firebase deploy --only functions
```
