import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import express from "express";
import { verifyIntegrityFromRequest } from "./integrityUtil.js";
import { verifySignatureFromRequest } from "./signingUtil.js";
const app = express();
app.use(express.json());
// Health check
app.get("/health", (_req, res) => res.status(200).json({ ok: true }));
// Read-only endpoints (no integrity required here by default)
app.get("/sar-teams", async (_req, res) => {
    // TODO: Fetch from storage/Firestore
    return res.status(200).json({ teams: [] });
});
app.get("/subscriptions/status", async (_req, res) => {
    // TODO: Return real user subscription status
    return res.status(200).json({ status: "unknown" });
});
// Write endpoints with integrity enforcement
app.post("/sos-alerts", async (req, res) => {
    try {
        // Verify HMAC signing first, then Play Integrity
        await verifySignatureFromRequest(req, JSON.stringify(req.body ?? {}));
        await verifyIntegrityFromRequest(req);
        // TODO: Persist SOS alert
        return res.status(200).json({ ok: true });
    }
    catch (err) {
        const status = err?.status || 500;
        logger.warn("/sos-alerts blocked", { error: err?.message, status });
        return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
    }
});
app.post("/locations", async (req, res) => {
    try {
        await verifySignatureFromRequest(req, JSON.stringify(req.body ?? {}));
        await verifyIntegrityFromRequest(req);
        // TODO: Persist location update
        return res.status(200).json({ ok: true });
    }
    catch (err) {
        const status = err?.status || 500;
        logger.warn("/locations blocked", { error: err?.message, status });
        return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
    }
});
app.post("/notifications", async (req, res) => {
    try {
        await verifySignatureFromRequest(req, JSON.stringify(req.body ?? {}));
        await verifyIntegrityFromRequest(req);
        // TODO: Queue notification
        return res.status(200).json({ ok: true });
    }
    catch (err) {
        const status = err?.status || 500;
        logger.warn("/notifications blocked", { error: err?.message, status });
        return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
    }
});
app.put("/emergency-contacts", async (req, res) => {
    try {
        await verifySignatureFromRequest(req, JSON.stringify(req.body ?? {}));
        await verifyIntegrityFromRequest(req);
        // TODO: Update contacts
        return res.status(200).json({ ok: true });
    }
    catch (err) {
        const status = err?.status || 500;
        logger.warn("/emergency-contacts blocked", { error: err?.message, status });
        return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
    }
});
app.post("/gadgets", async (req, res) => {
    try {
        await verifySignatureFromRequest(req, JSON.stringify(req.body ?? {}));
        await verifyIntegrityFromRequest(req);
        // TODO: Register gadget
        return res.status(200).json({ ok: true });
    }
    catch (err) {
        const status = err?.status || 500;
        logger.warn("/gadgets blocked", { error: err?.message, status });
        return res.status(status).json({ ok: false, error: err?.message || "ERROR" });
    }
});
export const api = onRequest({ cors: true }, app);
//# sourceMappingURL=api.js.map