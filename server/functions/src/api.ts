import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import express, { Request, Response } from "express";
import { verifyIntegrityFromRequest } from "./integrityUtil.js";
import { verifySignatureFromRequest } from "./signingUtil.js";

const app = express();
app.use(express.json());

// Health check
app.get("/health", (_req: Request, res: Response) => res.status(200).json({ ok: true }));

// Read-only endpoints (no integrity required here by default)
app.get("/sar-teams", async (_req: Request, res: Response) => {
  // TODO: Fetch from storage/Firestore
  return res.status(200).json({ teams: [] });
});

app.get("/subscriptions/status", async (_req: Request, res: Response) => {
  // TODO: Return real user subscription status
  return res.status(200).json({ status: "unknown" });
});

// Write endpoints with integrity enforcement
app.post("/sos-alerts", async (req: Request, res: Response) => {
  try {
    // Verify HMAC signing first, then Play Integrity
    await verifySignatureFromRequest(req as any, JSON.stringify(req.body ?? {}));
    await verifyIntegrityFromRequest(req as any);
    // TODO: Persist SOS alert
    return res.status(200).json({ ok: true });
  } catch (err: any) {
    const status = err?.status || 500;
    logger.warn("/sos-alerts blocked", { error: err?.message, status });
    return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
  }
});

app.post("/locations", async (req: Request, res: Response) => {
  try {
    await verifySignatureFromRequest(req as any, JSON.stringify(req.body ?? {}));
    await verifyIntegrityFromRequest(req as any);
    // TODO: Persist location update
    return res.status(200).json({ ok: true });
  } catch (err: any) {
    const status = err?.status || 500;
    logger.warn("/locations blocked", { error: err?.message, status });
    return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
  }
});

app.post("/notifications", async (req: Request, res: Response) => {
  try {
    await verifySignatureFromRequest(req as any, JSON.stringify(req.body ?? {}));
    await verifyIntegrityFromRequest(req as any);
    // TODO: Queue notification
    return res.status(200).json({ ok: true });
  } catch (err: any) {
    const status = err?.status || 500;
    logger.warn("/notifications blocked", { error: err?.message, status });
    return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
  }
});

app.put("/emergency-contacts", async (req: Request, res: Response) => {
  try {
    await verifySignatureFromRequest(req as any, JSON.stringify(req.body ?? {}));
    await verifyIntegrityFromRequest(req as any);
    // TODO: Update contacts
    return res.status(200).json({ ok: true });
  } catch (err: any) {
    const status = err?.status || 500;
    logger.warn("/emergency-contacts blocked", { error: err?.message, status });
    return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
  }
});

app.post("/gadgets", async (req: Request, res: Response) => {
  try {
    await verifySignatureFromRequest(req as any, JSON.stringify(req.body ?? {}));
    await verifyIntegrityFromRequest(req as any);
    // TODO: Register gadget
    return res.status(200).json({ ok: true });
  } catch (err: any) {
    const status = err?.status || 500;
    logger.warn("/gadgets blocked", { error: err?.message, status });
    return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
  }
});

export const api = onRequest({ cors: true }, app);
