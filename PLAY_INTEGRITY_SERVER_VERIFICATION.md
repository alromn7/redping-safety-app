# Play Integrity: Server Verification & Enforcement (GCF)

This guide shows how to verify Android Play Integrity tokens on the server (Google Cloud Functions) and gate sensitive APIs accordingly.

## Overview
- Client obtains a Play Integrity token via the Android SDK and sends it on each request:
  - Header `X-Play-Integrity`: integrity token string
  - Header `X-Play-Nonce`: nonce used on the client when requesting the token
- Server calls Play Integrity API `decodeIntegrityToken` using a Google service account to validate and decode the token.
- Server enforces policy using decoded fields (package name, cert digests, device integrity, licensing, nonce, timestamps, etc.).

## Prerequisites
- Enable the Play Integrity API in your Google Cloud project.
- Create a service account with permission to call Play Integrity (e.g., Project > Editor or a minimal custom role granting `playintegrity.integritytoken.decode`).
- Deploy Cloud Functions with service account credentials (default service account works when running in GCP with appropriate IAM).
- Package name (example): `applications/com.redping.redping`.
- Known SHA-256 certificate digest(s) for your release keystore.

## Policy Recommendations
- Verify `requestDetails.nonce` equals the `X-Play-Nonce` header.
- Verify `appIntegrity.packageName` equals your package.
- Verify `appIntegrity.certificateSha256Digest` contains your release cert digest.
- Verify `appIntegrity.appRecognitionVerdict` == `PLAY_RECOGNIZED`.
- Verify `deviceIntegrity.deviceRecognitionVerdict` includes `MEETS_DEVICE_INTEGRITY` (or `MEETS_STRONG_INTEGRITY` for high‑risk operations).
- Optionally verify `accountDetails.appLicensingVerdict` == `LICENSED`.
- Check `timestampMillis` within skew (e.g., 2–5 minutes).

## Node.js (TypeScript) Cloud Function Example
```ts
// functions/src/integrity.ts
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import fetch from "node-fetch"; // Node 18+ has global fetch; keep for compatibility
import { GoogleAuth } from "google-auth-library";

const PACKAGE_NAME = "applications/com.redping.redping"; // update to yours
const RELEASE_CERT_DIGESTS = new Set<string>([
  // 64-char hex (base16) SHA-256 of your release cert (uppercase)
  // Example placeholder: "ABCD...1234"
]);

async function decodeIntegrityToken(token: string) {
  const url = `https://playintegrity.googleapis.com/v1/${PACKAGE_NAME}:decodeIntegrityToken`;
  const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/playintegrity"] });
  const client = await auth.getClient();
  const res = await client.request<{ tokenPayloadExternal: any }>({
    url,
    method: "POST",
    data: { integrityToken: token },
  });
  return res.data.tokenPayloadExternal;
}

function hexDigestFromBase64Url(b64url: string): string {
  // cert digests are already hex in the decoded payload (certificateSha256Digest);
  // only needed if you compare different encodings. Keep helper for completeness.
  return b64url;
}

function withinSkew(timestampMillis: number, skewMs = 5 * 60 * 1000): boolean {
  const now = Date.now();
  return Math.abs(now - timestampMillis) <= skewMs;
}

export const verifyIntegrity = onRequest({ cors: true }, async (req, res) => {
  try {
    const token = req.header("X-Play-Integrity");
    const nonce = req.header("X-Play-Nonce");
    if (!token || !nonce) {
      return res.status(400).json({ ok: false, error: "MISSING_INTEGRITY_HEADERS" });
    }

    const payload = await decodeIntegrityToken(token);
    const {
      requestDetails,
      appIntegrity,
      deviceIntegrity,
      accountDetails,
      timestampMillis,
    } = payload || {};

    // Basic structure checks
    if (!requestDetails || !appIntegrity || !deviceIntegrity || !timestampMillis) {
      return res.status(403).json({ ok: false, error: "INTEGRITY_PAYLOAD_INVALID" });
    }

    // 1) Nonce match
    if (requestDetails.nonce !== nonce) {
      return res.status(403).json({ ok: false, error: "NONCE_MISMATCH" });
    }

    // 2) Timestamp skew
    if (!withinSkew(Number(timestampMillis))) {
      return res.status(403).json({ ok: false, error: "TIMESTAMP_OUT_OF_SKEW" });
    }

    // 3) Package name & recognition
    if (appIntegrity.packageName !== PACKAGE_NAME.replace("applications/", "")) {
      return res.status(403).json({ ok: false, error: "PACKAGE_MISMATCH" });
    }
    if (appIntegrity.appRecognitionVerdict !== "PLAY_RECOGNIZED") {
      return res.status(403).json({ ok: false, error: "APP_NOT_RECOGNIZED" });
    }

    // 4) Certificate digest
    const digests: string[] = appIntegrity.certificateSha256Digest || [];
    const hasKnownCert = digests.some((d) => RELEASE_CERT_DIGESTS.has(d.toUpperCase()));
    if (!hasKnownCert) {
      return res.status(403).json({ ok: false, error: "CERT_DIGEST_MISMATCH" });
    }

    // 5) Device integrity
    const deviceVerdicts: string[] = deviceIntegrity.deviceRecognitionVerdict || [];
    const meetsDeviceIntegrity = deviceVerdicts.includes("MEETS_DEVICE_INTEGRITY");
    if (!meetsDeviceIntegrity) {
      return res.status(403).json({ ok: false, error: "DEVICE_INTEGRITY_FAILED" });
    }

    // 6) Optional: Licensing verdict (if applicable)
    if (accountDetails?.appLicensingVerdict && accountDetails.appLicensingVerdict !== "LICENSED") {
      return res.status(403).json({ ok: false, error: "UNLICENSED_APP" });
    }

    // If all checks pass, continue. Attach structured verdict for auditing.
    return res.status(200).json({
      ok: true,
      verdict: {
        packageName: appIntegrity.packageName,
        deviceVerdicts: deviceVerdicts,
        appVerdict: appIntegrity.appRecognitionVerdict,
        timestampMillis,
      },
    });
  } catch (err: any) {
    logger.error("Integrity verification failed", err);
    return res.status(500).json({ ok: false, error: "INTEGRITY_VERIFICATION_ERROR" });
  }
});
```

## Using in Your API
- For sensitive endpoints, verify integrity first or inline within each handler.
- Example (Express/Functions):
  1. Read `X-Play-Integrity` and `X-Play-Nonce` headers.
  2. Call `decodeIntegrityToken` (or reuse a shared verifier util).
  3. Enforce policy; return 403 on failure.

## Testing
- Add `X-Play-Integrity` and `X-Play-Nonce` headers from a real Android device session.
- Expect 400 if headers missing; 403 if payload invalid; 200 when all checks pass.
- Log decoded `verdict` for observability; avoid logging raw token.

## Hardening Tips
- Rate-limit verification endpoint; tie to authenticated user ID if available.
- Cache recent valid tokens by nonce for short TTL to reduce API calls.
- Combine with your existing HMAC signing and TLS pinning (already implemented client-side).
- Roll release cert digests on key rotation and keep staging/prod digests separate.
