import { db } from "./admin";

const COLLECTION = "request_nonces";

export class NonceReplayError extends Error {
  status: number;
  constructor(message: string, status = 403) {
    super(message);
    this.status = status;
  }
}

export async function consumeNonceFirestore(nonce: string, ttlMs = 5 * 60 * 1000) {
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
