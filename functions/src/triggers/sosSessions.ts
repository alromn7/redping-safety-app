import { onDocumentWritten, onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize admin if not already
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
} catch (e) {
  // no-op for local runtime double-init
}

// Allow region to be selected at deploy time. Default to us-central1.
const REGION: string = process.env.FUNCTION_REGION || "australia-southeast1";

/**
 * Derive/maintain a compact sos_pings document for SAR dashboard
 * whenever a document in sos_sessions changes.
 * Idempotent: uses set with merge to update.
 */
export const onSosSessionWritten = onDocumentWritten(
  { document: "sos_sessions/{sessionId}", region: REGION },
  async (event: any) => {
    const after = event.data?.after.data() as any | undefined;
    const sessionId = event.params.sessionId as string;

    if (!after) {
      // Session deleted: mark derived ping as resolved/cancelled or delete
      try {
        await admin.firestore().collection("sos_pings").doc(sessionId).set(
          { status: "resolved", lastUpdate: new Date().toISOString() },
          { merge: true }
        );
        logger.info("sos_pings updated on delete", { sessionId });
      } catch (e) {
        logger.warn("sos_pings update failed on delete", { sessionId, error: String(e) });
      }
      return;
    }

    // Map/normalize fields for dashboard
    const status = normalizeStatus(after.status);
    const type = String(after.type || "manual");
    const priority = computePriority(after);
    const riskLevel = computeRisk(after);
    const location = after.location || {};
    const userMessage = after.userMessage || "";
    const userId = after.userId || "";
    const userName = after.userName || after.user_id || after.user || ""; // best-effort

    const derived = {
      id: sessionId,
      sessionId,
      userId,
      userName,
      type,
      status,
      priority,
      riskLevel,
      userMessage,
      location: {
        latitude: safeNumber(location.latitude),
        longitude: safeNumber(location.longitude),
        accuracy: safeNumber(location.accuracy),
        address: location.address,
      },
      lastUpdate: new Date().toISOString(),
    };

    try {
      await admin.firestore().collection("sos_pings").doc(sessionId).set(derived, { merge: true });
      logger.info("sos_pings upserted", { sessionId, status, priority, riskLevel });
    } catch (e) {
      logger.error("sos_pings upsert failed", { sessionId, error: String(e) });
    }
  }
);

/**
 * Ensure only one active session per user by storing a pointer under users/{uid}/meta/state.
 * If an active session pointer already exists, resolve/cancel the newly created duplicate.
 */
export const onSosSessionCreated = onDocumentCreated(
  { document: "sos_sessions/{sessionId}", region: REGION },
  async (event: any) => {
    const data = event.data?.data() as any;
    const sessionId = event.params.sessionId as string;
    if (!data) return;

    const uid = data.userId as string | undefined;
    const status = String(data.status || "active");
    if (!uid) return;

    const stateRef = admin.firestore().doc(`users/${uid}/meta/state`);
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(stateRef);
      const current = snap.exists ? snap.data() : undefined;
      const activeSessionId = current?.activeSessionId as string | undefined;

      if (!activeSessionId && status !== "resolved" && status !== "cancelled") {
        tx.set(stateRef, { activeSessionId: sessionId }, { merge: true });
        return;
      }
      if (activeSessionId && activeSessionId !== sessionId) {
        // Duplicate created while another is active: resolve this duplicate silently
        const sessionRef = admin.firestore().doc(`sos_sessions/${sessionId}`);
        tx.set(
          sessionRef,
          { status: "resolved", updatedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true }
        );
      }
    });
  }
);

/**
 * Mirror latest location ping into the session header for quick dashboard display.
 */
export const onLocationPingCreated = onDocumentCreated(
  { document: "sos_sessions/{sessionId}/locations/{ts}", region: REGION },
  async (event: any) => {
    const { sessionId } = event.params as { sessionId: string };
    const loc = event.data?.data() as any;
    if (!loc) return;
    try {
      await admin.firestore().doc(`sos_sessions/${sessionId}`).set(
        {
          lastLocation: {
            lat: safeNumber(loc.lat),
            lng: safeNumber(loc.lng),
            accuracy: safeNumber(loc.accuracy),
            address: loc.address,
            ts: admin.firestore.FieldValue.serverTimestamp(),
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } catch (e) {
      logger.warn("mirror latest location failed", { sessionId, error: String(e) });
    }
  }
);

function normalizeStatus(input: any): string {
  const s = String(input || "active").toLowerCase();
  // Map variants into a canonical set
  if (s === "responder_assigned" || s === "assigned") return "assigned";
  if (s === "responding" || s === "inprogress" || s === "in_progress") return "inProgress";
  if (s === "false_alarm" || s === "falsealarm") return "false_alarm";
  if (s === "cancelled" || s === "canceled") return "cancelled";
  if (s === "resolved") return "resolved";
  if (s === "countdown") return "countdown";
  return "active";
}

function computePriority(session: any): "low" | "medium" | "high" | "critical" {
  const impact = session.impactInfo || {};
  const severity = String(impact.severity || "medium").toLowerCase();
  if (severity === "critical") return "critical";
  if (severity === "high") return "high";
  if (severity === "low") return "low";
  return "medium";
}

function computeRisk(session: any): "low" | "medium" | "high" {
  const type = String(session.type || "manual").toLowerCase();
  if (type === "crash" || type === "fall") return "high";
  return "medium";
}

function safeNumber(v: any): number {
  const n = Number(v);
  if (!isFinite(n) || isNaN(n)) return 0;
  return n;
}

