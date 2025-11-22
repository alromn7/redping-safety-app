import express, { Request as ExRequest, Response as ExResponse } from "express";
import { onRequest, Request } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import cors from "cors";
import { verifySignatureFromRequest } from "../security/signingUtil";
import { verifyIntegrityFromRequest } from "../security/integrityUtil";

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true }));

app.get("/health", (_req: ExRequest, res: ExResponse) => {
  res.status(200).json({ ok: true, status: "healthy" });
});

app.post("/protected/ping", async (req: ExRequest, res: ExResponse) => {
  try {
    const rawBody = (req as any).rawBody ? String((req as any).rawBody) : JSON.stringify(req.body ?? "");
    await verifySignatureFromRequest(req as unknown as Request, rawBody);
    await verifyIntegrityFromRequest(req as unknown as Request);
    res.status(200).json({ ok: true, pong: true });
  } catch (err: any) {
    logger.error("Protected ping failed", err);
    res.status(err?.status || 500).json({ ok: false, error: err?.message || "PROTECTED_PING_FAILED" });
  }
});

export const api = onRequest({ cors: true, region: "australia-southeast1" }, (req, res) => {
  return app(req as any, res as any);
});
