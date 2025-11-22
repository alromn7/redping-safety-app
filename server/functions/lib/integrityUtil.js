import { GoogleAuth } from "google-auth-library";
const PACKAGE_NAME = "applications/com.redping.redping"; // ensure this matches integrity.ts
const RELEASE_CERT_DIGESTS = new Set([
// "<YOUR_RELEASE_CERT_SHA256_HEX>"
]);
async function decodeIntegrityToken(token) {
    const url = `https://playintegrity.googleapis.com/v1/${PACKAGE_NAME}:decodeIntegrityToken`;
    const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/playintegrity"] });
    const client = await auth.getClient();
    const res = await client.request({
        url,
        method: "POST",
        data: { integrityToken: token },
    });
    return res.data.tokenPayloadExternal;
}
function withinSkew(timestampMillis, skewMs = 5 * 60 * 1000) {
    const now = Date.now();
    return Math.abs(now - timestampMillis) <= skewMs;
}
export async function verifyIntegrityFromRequest(req) {
    const token = req.header("X-Play-Integrity");
    const nonce = req.header("X-Play-Nonce");
    if (!token || !nonce) {
        const err = new Error("MISSING_INTEGRITY_HEADERS");
        err.status = 400;
        throw err;
    }
    const payload = await decodeIntegrityToken(token);
    const { requestDetails, appIntegrity, deviceIntegrity, accountDetails, timestampMillis } = payload || {};
    if (!requestDetails || !appIntegrity || !deviceIntegrity || !timestampMillis) {
        const err = new Error("INTEGRITY_PAYLOAD_INVALID");
        err.status = 403;
        throw err;
    }
    if (requestDetails.nonce !== nonce) {
        const err = new Error("NONCE_MISMATCH");
        err.status = 403;
        throw err;
    }
    if (!withinSkew(Number(timestampMillis))) {
        const err = new Error("TIMESTAMP_OUT_OF_SKEW");
        err.status = 403;
        throw err;
    }
    const packageName = appIntegrity.packageName || "";
    if (!packageName || !PACKAGE_NAME.endsWith(packageName)) {
        const err = new Error("PACKAGE_MISMATCH");
        err.status = 403;
        throw err;
    }
    if (appIntegrity.appRecognitionVerdict !== "PLAY_RECOGNIZED") {
        const err = new Error("APP_NOT_RECOGNIZED");
        err.status = 403;
        throw err;
    }
    const digests = appIntegrity.certificateSha256Digest || [];
    const hasKnownCert = digests.some((d) => RELEASE_CERT_DIGESTS.has(d.toUpperCase()));
    if (!hasKnownCert) {
        const err = new Error("CERT_DIGEST_MISMATCH");
        err.status = 403;
        throw err;
    }
    const deviceVerdicts = deviceIntegrity.deviceRecognitionVerdict || [];
    if (!deviceVerdicts.includes("MEETS_DEVICE_INTEGRITY")) {
        const err = new Error("DEVICE_INTEGRITY_FAILED");
        err.status = 403;
        throw err;
    }
    if (accountDetails?.appLicensingVerdict && accountDetails.appLicensingVerdict !== "LICENSED") {
        const err = new Error("UNLICENSED_APP");
        err.status = 403;
        throw err;
    }
    return { packageName, deviceVerdicts, timestampMillis: Number(timestampMillis), raw: payload };
}
//# sourceMappingURL=integrityUtil.js.map