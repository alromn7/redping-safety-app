import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { verifyIntegrityFromRequest } from "./integrityUtil";

export const verifyIntegrity = onRequest({ cors: true, region: "australia-southeast1" }, async (req, res) => {
  try {
    const verdict = await verifyIntegrityFromRequest(req);
    res.status(200).json({ ok: true, verdict });
    return;
  } catch (err: any) {
    logger.error("Integrity verification failed", err);
    res.status(err?.status || 500).json({ ok: false, error: err?.message || "INTEGRITY_VERIFICATION_ERROR" });
    return;
  }
});
