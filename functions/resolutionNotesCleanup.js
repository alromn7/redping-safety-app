// Cloud Function stub to remove resolutionNotes after 7 days while retaining documents.
// Deploy with: firebase deploy --only functions:cleanupResolutionNotes

const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
try { admin.initializeApp(); } catch (e) {}

function olderThan(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d;
}

async function processCollection(db, collectionName) {
  const cutoff = olderThan(7);
  const snap = await db.collection(collectionName)
    .where('status', '==', 'resolved')
    .where('resolvedAt', '<', cutoff)
    .get();
  const batch = db.batch();
  snap.docs.forEach(doc => {
    if (doc.data().resolutionNotes) {
      batch.update(doc.ref, { resolutionNotes: admin.firestore.FieldValue.delete() });
    }
  });
  if (!snap.empty) {
    await batch.commit();
    console.log(`Cleaned ${snap.size} notes in ${collectionName}`);
  } else {
    console.log(`No old notes to clean in ${collectionName}`);
  }
}

exports.cleanupResolutionNotes = onSchedule('every 24 hours', async (event) => {
  const db = admin.firestore();
  await processCollection(db, 'sos_sessions');
  await processCollection(db, 'help_requests');
  return null;
});
