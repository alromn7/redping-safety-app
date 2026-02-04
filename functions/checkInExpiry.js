// Cloud Function to expire pending check-in requests after 7 days.
// Deploy with: firebase deploy --only functions:expireCheckInRequests

const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

try { admin.initializeApp(); } catch (e) {}

exports.expireCheckInRequests = onSchedule('every 24 hours', async (event) => {
  const db = admin.firestore();
  const now = new Date();
  const snap = await db.collection('check_in_requests')
    .where('status', '==', 'pending')
    .where('expiresAt', '<', now)
    .get();
  const batch = db.batch();
  snap.docs.forEach(doc => {
    batch.update(doc.ref, { status: 'expired' });
  });
  if (!snap.empty) await batch.commit();
  console.log(`Expired ${snap.size} check-in requests at ${now.toISOString()}`);
  return null;
});

// Purge expired check-in requests older than 30 days
exports.purgeOldCheckInRequests = onSchedule('every 24 hours', async (event) => {
  const db = admin.firestore();
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30); // 30 days ago
  
  const snap = await db.collection('check_in_requests')
    .where('status', 'in', ['expired', 'denied', 'locationShared'])
    .where('createdAt', '<', cutoff)
    .get();
  
  const batch = db.batch();
  snap.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  if (!snap.empty) await batch.commit();
  console.log(`Purged ${snap.size} old check-in requests older than 30 days at ${new Date().toISOString()}`);
  return null;
});
