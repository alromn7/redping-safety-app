import { db } from "./admin.js";
const COLLECTION = "request_nonces";
export class NonceReplayError extends Error {
    status;
    constructor(message, status = 403) {
        super(message);
        this.status = status;
    }
}
/**
 * Attempts to atomically consume a nonce using Firestore.
 * Fails if the nonce already exists (replay) and writes an expiry for TTL.
 */
export async function consumeNonceFirestore(nonce, ttlMs = 5 * 60 * 1000) {
    const store = db();
    const ref = store.collection(COLLECTION).doc(nonce);
    const now = new Date();
    const expireAt = new Date(Date.now() + ttlMs);
    const snap = await ref.get();
    if (snap.exists) {
        throw new NonceReplayError("NONCE_REPLAY", 403);
    }
    await ref.create({ createdAt: now, expireAt });
}
//# sourceMappingURL=nonceStore.js.map