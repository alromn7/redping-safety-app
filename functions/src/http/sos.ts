import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Initialize admin if not already
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
} catch (e) {
  // no-op for local runtime double-init
}

// Factory for regional callable variants
function buildCreateSos(region: string) {
  return onCall({
    region,
    cors: true,
  }, async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const data = (request.data || {}) as any;
    const type = String(data.type || "manual");
    const userMessage = String(data.userMessage || "");
    const uid = auth.uid;

    const base: any = {
      userId: uid,
      type,
      status: "active",
      userMessage,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (data.location && typeof data.location.lat === "number" && typeof data.location.lng === "number") {
      base.lastLocation = {
        lat: Number(data.location.lat),
        lng: Number(data.location.lng),
        accuracy: Number(data.location.accuracy || 0),
        address: data.location.address,
        ts: admin.firestore.FieldValue.serverTimestamp(),
      };
    }

    const docRef = await admin.firestore().collection("sos_sessions").add(base);
    return { sessionId: docRef.id } as any;
  });
}

// Input shape note (for docs/reference)
// type CreateSosInput = {
//   type?: string;
//   userMessage?: string;
//   location?: {
//     lat: number;
//     lng: number;
//     accuracy?: number;
//     address?: string;
//   };
// };

// Exports: legacy AU plus regional variants
export const createSosSession = buildCreateSos("australia-southeast1");
export const createSosSessionAU = buildCreateSos("australia-southeast1");
export const createSosSessionEU = buildCreateSos("europe-west1");
export const createSosSessionAF = buildCreateSos("africa-south1");
export const createSosSessionAS = buildCreateSos("asia-southeast1");
