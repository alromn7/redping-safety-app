import crypto from "crypto";
import { consumeNonceFirestore, NonceReplayError } from "./nonceStore.js";
// Basic in-memory nonce cache (best-effort; replace with Redis/Firestore TTL for production)
const nonceCache = new Map();
const NONCE_TTL_MS = 5 * 60 * 1000; // 5 minutes
function cleanupNonces(now) {
    for (const [n, ts] of nonceCache.entries()) {
        if (now - ts > NONCE_TTL_MS)
            nonceCache.delete(n);
    }
}
function getSigningSecret() {
    const s = process.env.SIGNING_SECRET;
    if (!s)
        throw new Error("SIGNING_SECRET not configured");
    return s;
}
export async function verifySignatureFromRequest(req, rawBody) {
    const alg = (req.header("X-Signature-Alg") || "HMAC-SHA256").toUpperCase();
    const sig = req.header("X-Signature");
    const tsStr = req.header("X-Timestamp") || "";
    const nonce = req.header("X-Nonce") || "";
    if (!sig || !tsStr || !nonce) {
        const err = new Error("MISSING_SIGNATURE_HEADERS");
        err.status = 400;
        throw err;
    }
    const ts = Number(tsStr);
    if (!Number.isFinite(ts)) {
        const err = new Error("INVALID_TIMESTAMP");
        err.status = 400;
        throw err;
    }
    // Skew check (5 minutes)
    const now = Date.now();
    if (Math.abs(now - ts) > NONCE_TTL_MS) {
        const err = new Error("TIMESTAMP_OUT_OF_SKEW");
        err.status = 403;
        throw err;
    }
    // Replay protection
    // Attempt durable replay protection via Firestore, fallback to in-memory
    try {
        await consumeNonceFirestore(nonce, NONCE_TTL_MS);
    }
    catch (e) {
        if (e instanceof NonceReplayError) {
            const err = new Error("NONCE_REPLAY");
            err.status = 403;
            throw err;
        }
        // Firestore unavailable? Fall back to process-local cache
        cleanupNonces(now);
        if (nonceCache.has(nonce)) {
            const err = new Error("NONCE_REPLAY");
            err.status = 403;
            throw err;
        }
        nonceCache.set(nonce, now);
    }
    const method = (req.method || "").toUpperCase();
    const endpoint = req.path || "/";
    const secret = getSigningSecret();
    const baseString = `${method}\n${endpoint}\n${ts}\n${nonce}\n${rawBody}`;
    let computed;
    if (alg === "HMAC-SHA256") {
        computed = crypto.createHmac("sha256", secret).update(baseString, "utf8").digest("hex");
    }
    else {
        const err = new Error("UNSUPPORTED_ALGORITHM");
        err.status = 400;
        throw err;
    }
    if (computed !== sig) {
        const err = new Error("SIGNATURE_MISMATCH");
        err.status = 403;
        throw err;
    }
}
//# sourceMappingURL=signingUtil.js.map