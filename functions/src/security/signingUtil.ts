import crypto from "crypto";
import { Request } from "firebase-functions/v2/https";
import { consumeNonceFirestore, NonceReplayError } from "./nonceStore";

const nonceCache = new Map<string, number>();
const NONCE_TTL_MS = 5 * 60 * 1000;

function cleanupNonces(now: number) {
  for (const [n, ts] of nonceCache.entries()) {
    if (now - ts > NONCE_TTL_MS) nonceCache.delete(n);
  }
}

function getSigningSecret(): string {
  const direct = process.env.SIGNING_SECRET;
  if (direct && direct.length > 0) return direct;
  const err: any = new Error(
    "SIGNING_SECRET not configured (set via Functions .env or Cloud Run env)"
  );
  err.status = 500;
  throw err;
}

export async function verifySignatureFromRequest(req: Request, rawBody: string) {
  const alg = (req.header("X-Signature-Alg") || "HMAC-SHA256").toUpperCase();
  const sig = req.header("X-Signature");
  const tsStr = req.header("X-Timestamp") || "";
  const nonce = req.header("X-Nonce") || "";

  if (!sig || !tsStr || !nonce) {
    const err: any = new Error("MISSING_SIGNATURE_HEADERS");
    err.status = 400;
    throw err;
  }

  const ts = Number(tsStr);
  if (!Number.isFinite(ts)) {
    const err: any = new Error("INVALID_TIMESTAMP");
    err.status = 400;
    throw err;
  }

  const now = Date.now();
  if (Math.abs(now - ts) > NONCE_TTL_MS) {
    const err: any = new Error("TIMESTAMP_OUT_OF_SKEW");
    err.status = 403;
    throw err;
  }

  try {
    await consumeNonceFirestore(nonce, NONCE_TTL_MS);
  } catch (e: any) {
    if (e instanceof NonceReplayError) {
      const err: any = new Error("NONCE_REPLAY");
      err.status = 403;
      throw err;
    }
    cleanupNonces(now);
    if (nonceCache.has(nonce)) {
      const err: any = new Error("NONCE_REPLAY");
      err.status = 403;
      throw err;
    }
    nonceCache.set(nonce, now);
  }

  const method = (req.method || "").toUpperCase();
  const endpoint = (req.path || "/");
  const secret = getSigningSecret();
  const baseString = `${method}\n${endpoint}\n${ts}\n${nonce}\n${rawBody}`;

  let computed: string;
  if (alg === "HMAC-SHA256") {
    computed = crypto.createHmac("sha256", secret).update(baseString, "utf8").digest("hex");
  } else {
    const err: any = new Error("UNSUPPORTED_ALGORITHM");
    err.status = 400;
    throw err;
  }

  if (computed !== sig) {
    const err: any = new Error("SIGNATURE_MISMATCH");
    err.status = 403;
    throw err;
  }
}
