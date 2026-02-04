/**
 * Scheduled pruning of old subscription correlation and failed transaction logs.
 * Runs daily. Retention: subscriptionRequests > 14 days, failed transactions > 30 days.
 */
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
try { admin.app(); } catch { admin.initializeApp(); }
const db = admin.firestore();

const REQUEST_RETENTION_DAYS = parseInt(process.env.SUB_REQ_RETENTION_DAYS || '14', 10);
const FAILED_TX_RETENTION_DAYS = parseInt(process.env.FAILED_TX_RETENTION_DAYS || '30', 10);

function cutoffTimestamp(days) {
  const d = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  return admin.firestore.Timestamp.fromDate(d);
}

exports.pruneSubscriptionLogs = onSchedule({ schedule: '0 3 * * *', timeZone: 'Etc/UTC' }, async () => {
  console.log('Starting pruneSubscriptionLogs job');
  const reqCutoff = cutoffTimestamp(REQUEST_RETENTION_DAYS);
  const txCutoff = cutoffTimestamp(FAILED_TX_RETENTION_DAYS);

  let deletedRequests = 0;
  let deletedFailedTx = 0;

  // Prune subscriptionRequests via collection group
  try {
    const reqQuery = await db.collectionGroup('subscriptionRequests')
      .where('createdAt', '<', reqCutoff)
      .get();
    for (const doc of reqQuery.docs) {
      await doc.ref.delete();
      deletedRequests++;
    }
    console.log(`Pruned ${deletedRequests} subscriptionRequests older than ${REQUEST_RETENTION_DAYS}d`);
  } catch (e) {
    console.warn('Failed pruning subscriptionRequests:', e.message);
  }

  // Prune failed transactions via collection group
  try {
    const txQuery = await db.collectionGroup('transactions')
      .where('status', '==', 'failed')
      .where('createdAt', '<', txCutoff)
      .get();
    for (const doc of txQuery.docs) {
      await doc.ref.delete();
      deletedFailedTx++;
    }
    console.log(`Pruned ${deletedFailedTx} failed transactions older than ${FAILED_TX_RETENTION_DAYS}d`);
  } catch (e) {
    console.warn('Failed pruning failed transactions:', e.message);
  }

  console.log('pruneSubscriptionLogs job complete');
});
