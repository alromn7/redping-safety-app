import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { GoogleAuth } from "google-auth-library";

const PACKAGE_NAME = "applications/com.redping.redping"; // TODO: update to match your app id
const RELEASE_CERT_DIGESTS = new Set<string>([
  // e.g., "ABCD...1234" (uppercase hex of SHA-256 cert digest)
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

function withinSkew(timestampMillis: number, skewMs = 5 * 60 * 1000): boolean {
  const now = Date.now();
  return Math.abs(now - timestampMillis) <= skewMs;
}

export const verifyIntegrity = onRequest({ cors: true }, async (req, res) => {
  try {
    const token = req.header("X-Play-Integrity");
    const nonce = req.header("X-Play-Nonce");
    if (!token || !nonce) {
      res.status(400).json({ ok: false, error: "MISSING_INTEGRITY_HEADERS" });
      return;
    }

    const payload = await decodeIntegrityToken(token);
    const { requestDetails, appIntegrity, deviceIntegrity, accountDetails, timestampMillis } = payload || {};

    if (!requestDetails || !appIntegrity || !deviceIntegrity || !timestampMillis) {
      res.status(403).json({ ok: false, error: "INTEGRITY_PAYLOAD_INVALID" });
      return;
    }

    if (requestDetails.nonce !== nonce) {
      res.status(403).json({ ok: false, error: "NONCE_MISMATCH" });
      return;
    }

    if (!withinSkew(Number(timestampMillis))) {
      res.status(403).json({ ok: false, error: "TIMESTAMP_OUT_OF_SKEW" });
      return;
    }

    const packageName = (appIntegrity.packageName as string) || "";
    if (!packageName || !PACKAGE_NAME.endsWith(packageName)) {
      res.status(403).json({ ok: false, error: "PACKAGE_MISMATCH" });
      return;
    }

    if (appIntegrity.appRecognitionVerdict !== "PLAY_RECOGNIZED") {
      res.status(403).json({ ok: false, error: "APP_NOT_RECOGNIZED" });
      return;
    }

    const digests: string[] = appIntegrity.certificateSha256Digest || [];
    const hasKnownCert = digests.some((d) => RELEASE_CERT_DIGESTS.has(d.toUpperCase()));
    if (!hasKnownCert) {
      res.status(403).json({ ok: false, error: "CERT_DIGEST_MISMATCH" });
      return;
    }

    const deviceVerdicts: string[] = deviceIntegrity.deviceRecognitionVerdict || [];
    if (!deviceVerdicts.includes("MEETS_DEVICE_INTEGRITY")) {
      res.status(403).json({ ok: false, error: "DEVICE_INTEGRITY_FAILED" });
      return;
    }

    if (accountDetails?.appLicensingVerdict && accountDetails.appLicensingVerdict !== "LICENSED") {
      res.status(403).json({ ok: false, error: "UNLICENSED_APP" });
      return;
    }
    res.status(200).json({ ok: true, verdict: { packageName, deviceVerdicts, timestampMillis } });
    return;
  } catch (err: any) {
    logger.error("Integrity verification failed", err);
    res.status(500).json({ ok: false, error: "INTEGRITY_VERIFICATION_ERROR" });
    return;
  }
});
