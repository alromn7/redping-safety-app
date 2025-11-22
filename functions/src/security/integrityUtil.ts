import { GoogleAuth } from "google-auth-library";
import { Request } from "firebase-functions/v2/https";

const PACKAGE_NAME = "applications/com.redping.redping";
const RELEASE_CERT_DIGESTS = new Set<string>([
  // Provided SHA-256 (uppercase hex, no colons)
  "4A6ADAB5CD9AD2FA5670CD0222D470A1666B821F49D5266F4B1397AD57B500A9",
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

export type IntegrityVerdict = {
  packageName: string;
  deviceVerdicts: string[];
  timestampMillis: number;
  raw: any;
};

export async function verifyIntegrityFromRequest(req: Request): Promise<IntegrityVerdict> {
  const token = req.header("X-Play-Integrity");
  const nonce = req.header("X-Play-Nonce");
  if (!token || !nonce) {
    const err: any = new Error("MISSING_INTEGRITY_HEADERS");
    err.status = 400;
    throw err;
  }

  const payload = await decodeIntegrityToken(token);
  const { requestDetails, appIntegrity, deviceIntegrity, accountDetails, timestampMillis } = payload || {};

  if (!requestDetails || !appIntegrity || !deviceIntegrity || !timestampMillis) {
    const err: any = new Error("INTEGRITY_PAYLOAD_INVALID");
    err.status = 403;
    throw err;
  }

  if (requestDetails.nonce !== nonce) {
    const err: any = new Error("NONCE_MISMATCH");
    err.status = 403;
    throw err;
  }

  if (!withinSkew(Number(timestampMillis))) {
    const err: any = new Error("TIMESTAMP_OUT_OF_SKEW");
    err.status = 403;
    throw err;
  }

  const packageName = (appIntegrity.packageName as string) || "";
  if (!packageName || !PACKAGE_NAME.endsWith(packageName)) {
    const err: any = new Error("PACKAGE_MISMATCH");
    err.status = 403;
    throw err;
  }

  if (appIntegrity.appRecognitionVerdict !== "PLAY_RECOGNIZED") {
    const err: any = new Error("APP_NOT_RECOGNIZED");
    err.status = 403;
    throw err;
  }

  const digests: string[] = appIntegrity.certificateSha256Digest || [];
  const hasKnownCert = digests.some((d) => RELEASE_CERT_DIGESTS.has(d.toUpperCase()));
  if (!hasKnownCert) {
    const err: any = new Error("CERT_DIGEST_MISMATCH");
    err.status = 403;
    throw err;
  }

  const deviceVerdicts: string[] = deviceIntegrity.deviceRecognitionVerdict || [];
  if (!deviceVerdicts.includes("MEETS_DEVICE_INTEGRITY")) {
    const err: any = new Error("DEVICE_INTEGRITY_FAILED");
    err.status = 403;
    throw err;
  }

  if (accountDetails?.appLicensingVerdict && accountDetails.appLicensingVerdict !== "LICENSED") {
    const err: any = new Error("UNLICENSED_APP");
    err.status = 403;
    throw err;
  }

  return { packageName, deviceVerdicts, timestampMillis: Number(timestampMillis), raw: payload };
}
