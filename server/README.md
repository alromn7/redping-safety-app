# Redping Cloud Functions (Server)

This folder contains a minimal Firebase Functions (Node.js/TypeScript) scaffold focused on Android Play Integrity verification.

## Structure
- `functions/src/integrity.ts`: HTTP function `verifyIntegrity` that decodes and validates Play Integrity tokens.
- `functions/src/integrityUtil.ts`: Reusable verifier utility for other endpoints/middleware.
- `functions/src/protected.ts`: Example protected endpoint that enforces Play Integrity and returns a `pong` with verdict.
- `functions/src/index.ts`: Exports functions.
- `functions/package.json`: deps + scripts.
- `functions/tsconfig.json`: TS config.

## Prereqs
- Node.js 18+
- Firebase CLI (`npm i -g firebase-tools`)
- GCP project with Play Integrity API enabled

## Setup
```powershell
cd server/functions
npm install
```

Set an HMAC signing secret used by the API to verify client requests:

```powershell
$env:SIGNING_SECRET = "<STRONG_RANDOM_SECRET>"
```

Set your package name and release cert digest(s) in `src/integrity.ts`:
```ts
const PACKAGE_NAME = "applications/com.redping.redping"; // update if needed
const RELEASE_CERT_DIGESTS = new Set<string>([
  "<YOUR_RELEASE_CERT_SHA256_HEX>"
]);
```

## Local emulators
```powershell
npm run build
firebase emulators:start --only functions
```

Now test the protected endpoint locally (port may vary):
```powershell
curl -i http://127.0.0.1:5001/<YOUR_PROJECT_ID>/us-central1/protectedPing
```
Expect 400/403 without valid headers; 200 only from the Android client sending `X-Play-Integrity` and `X-Play-Nonce`.

## Request signing
- Client must include:
  - `X-Signature-Alg: HMAC-SHA256`
  - `X-Signature: <hex>` where hex = HMAC_SHA256(secret, `${method}\n${endpoint}\n${timestamp}\n${nonce}\n${body}`)
  - `X-Timestamp: <epoch_ms>` within ±5 minutes
  - `X-Nonce: <random>` not previously used within 5 minutes
- Server verifies via `signingUtil.ts` and blocks on mismatch or replay.

## Firestore TTL for Nonce Replay Protection
To enable durable replay protection across instances, configure a TTL policy on the `request_nonces` collection:

1. Ensure `server/functions/src/nonceStore.ts` writes `expireAt` on each nonce document.
2. In Firestore TTL settings, add a policy on `request_nonces` using field `expireAt`.
3. Choose a retention window ≥ 5 minutes (to match server skew window) or adjust `ttlMs` in code.

If Firestore is unavailable (emulator/offline), the server falls back to an in-memory nonce cache.

## Deploy to Firebase
```powershell
npm run deploy
```

## Client runtime flags
See `SECURITY_RUNTIME_FLAGS.md` for recommended `--dart-define` settings when enabling integrity gating.

## Base URL configuration
Set the client's `BASE_URL` to the Cloud Functions host and include the function name `api` so routes resolve as expected:

```powershell
--dart-define=BASE_URL=https://us-central1-<PROJECT_ID>.cloudfunctions.net/api
```

Then client calls like `GET /sar-teams` or `POST /sos-alerts` will hit `.../api/sar-teams` and `.../api/sos-alerts` respectively.
