import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { verifyIntegrityFromRequest } from "./integrityUtil.js";

export const protectedPing = onRequest({ cors: true }, async (req, res) => {
  try {
    const verdict = await verifyIntegrityFromRequest(req);
    res.status(200).json({ ok: true, message: "pong", verdict });
    return;
  } catch (err: any) {
    logger.warn("protectedPing blocked", { error: err?.message, status: err?.status });
    const status = err?.status || 500;
    res.status(status).json({ ok: false, error: err?.message || "INTEGRITY_VERIFICATION_ERROR" });
    return;
  }
});
