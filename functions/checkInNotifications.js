// Cloud Functions for FCM notifications related to check-in requests.
// Assumptions:
// - Each user document may contain an array field `fcmTokens` (list of device tokens)
// - Feature flag enableCheckInPingNotifications will be read from a runtime config or can be toggled here
// - Requires: firebase-admin initialized
// Deployment: firebase deploy --only functions:checkInRequestCreated,functions:checkInRequestUpdated

const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
try { admin.initializeApp(); } catch (e) {}

function getTokens(userDoc) {
  const data = userDoc.data() || {};
  const tokens = data.fcmTokens;
  if (Array.isArray(tokens)) {
    return tokens.filter(t => typeof t === 'string' && t.length > 10);
  }
  if (typeof data.fcmToken === 'string') return [data.fcmToken];
  return [];
}

async function sendMulticast(tokens, notification, data = {}, retries = 2) {
  if (!tokens.length) return { success: 0, failure: 0 };
  
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await admin.messaging().sendEachForMulticast({ tokens, notification, data });
      console.log(`FCM multicast sent (attempt ${attempt + 1}): success=${res.successCount} failure=${res.failureCount}`);
      return { success: res.successCount, failure: res.failureCount, responses: res.responses };
    } catch (err) {
      const isTransient = err.code === 'messaging/internal-error' 
        || err.code === 'messaging/server-unavailable'
        || err.code === 'messaging/timeout';
      
      if (isTransient && attempt < retries) {
        const delay = Math.pow(2, attempt) * 1000; // exponential backoff: 1s, 2s
        console.log(`FCM transient error (${err.code}), retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      console.error('FCM send error', err);
      return { success: 0, failure: tokens.length };
    }
  }
  
  return { success: 0, failure: tokens.length };
}

async function pruneInvalidTokens(userId, responses) {
  if (!responses) return;
  const invalidTokens = [];
  responses.forEach(r => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (code === 'messaging/registration-token-not-registered') {
        invalidTokens.push(r.messageIdToken || r.token); // token field name depends on SDK version
      }
    }
  });
  // Fallback: extract token from error message if field absent
  const cleaned = invalidTokens.filter(Boolean);
  if (!cleaned.length) return;
  const userRef = admin.firestore().collection('users').doc(userId);
  await admin.firestore().runTransaction(async tx => {
    const doc = await tx.get(userRef);
    if (!doc.exists) return;
    const data = doc.data();
    let tokens = Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
    tokens = tokens.filter(t => !cleaned.includes(t));
    tx.update(userRef, { fcmTokens: tokens });
  });
  console.log(`Pruned ${cleaned.length} invalid tokens for user ${userId}`);
}

// Trigger: New check-in request created
exports.checkInRequestCreated = onDocumentCreated('check_in_requests/{requestId}', async (event) => {
  const snap = event.data;
  if (!snap) return null;
    const data = snap.data();
    if (!data) return null;
    const targetUserId = data.targetUserId;
    const requesterUserId = data.requesterUserId;
    const reason = data.reason || '';

    try {
      const targetDoc = await admin.firestore().collection('users').doc(targetUserId).get();
      const requesterDoc = await admin.firestore().collection('users').doc(requesterUserId).get();
      const requesterName = requesterDoc.exists ? (requesterDoc.data().displayName || 'Someone') : 'Someone';
      const tokens = getTokens(targetDoc);
      const title = 'Location Check-In Request';
      const body = reason
        ? `${requesterName} requests your location: ${reason}`
        : `${requesterName} requests your location.`;
      const result = await sendMulticast(tokens, { title, body }, {
        type: 'check_in_request',
        requestId: snap.id,
        requesterUserId,
        familyId: data.familyId || '',
      });
      await pruneInvalidTokens(targetUserId, result.responses);
      // Analytics event
      await admin.firestore().collection('analytics/check_in_events').add({
        type: 'request_created',
        requestId: snap.id,
        requesterUserId,
        targetUserId,
        familyId: data.familyId || '',
        reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        notificationSuccess: result.success,
        notificationFailure: result.failure,
      });
    } catch (e) {
      console.error('Error sending check-in request notification', e);
    }

    return null;
  });

// Trigger: Request status updated to locationShared
exports.checkInRequestUpdated = onDocumentUpdated('check_in_requests/{requestId}', async (event) => {
  const change = event.data;
  if (!change) return null;
  const before = change.before.data();
  const after = change.after.data();
    if (!before || !after) return null;

    // Only act on pending -> locationShared transition
    if (before.status === 'pending' && after.status === 'locationShared') {
      const requesterUserId = after.requesterUserId;
      try {
        const requesterDoc = await admin.firestore().collection('users').doc(requesterUserId).get();
        const tokens = getTokens(requesterDoc);
        const targetName = after.targetUserId;
        const title = 'Location Shared';
        const body = `Location shared by ${targetName}`;
        const result = await sendMulticast(tokens, { title, body }, {
          type: 'check_in_location_shared',
          requestId: change.after.id,
          targetUserId: after.targetUserId,
          familyId: after.familyId || '',
        });
        await pruneInvalidTokens(requesterUserId, result.responses);
        // Analytics event
        await admin.firestore().collection('analytics/check_in_events').add({
          type: 'location_shared',
          requestId: change.after.id,
          requesterUserId,
          targetUserId: after.targetUserId,
          familyId: after.familyId || '',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          notificationSuccess: result.success,
          notificationFailure: result.failure,
        });
      } catch (e) {
        console.error('Error sending location shared notification', e);
      }
    }
    return null;
  });
