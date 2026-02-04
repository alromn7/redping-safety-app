// Cloud Function to auto-revoke pending check-in requests when user leaves family.
// Triggers on user document update when familyId changes or is removed.
// Deployment: firebase deploy --only functions:revokeCheckInOnFamilyLeave

const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
try { admin.initializeApp(); } catch (e) {}

exports.revokeCheckInOnFamilyLeave = onDocumentUpdated('users/{userId}', async (event) => {
  const change = event.data;
  if (!change) return null;
  const before = change.before.data();
  const after = change.after.data();
  if (!before || !after) return null;

  const beforeFamilyId = before.familyId;
  const afterFamilyId = after.familyId;
  const userId = event.params.userId;

    // Only act if familyId changed (left or switched families)
    if (beforeFamilyId === afterFamilyId) return null;

    console.log(`User ${userId} family change: ${beforeFamilyId} -> ${afterFamilyId}`);

    try {
      const db = admin.firestore();
      
      // Find all pending check-in requests where this user is requester or target
      const asRequesterQuery = db.collection('check_in_requests')
        .where('requesterUserId', '==', userId)
        .where('status', '==', 'pending');
      
      const asTargetQuery = db.collection('check_in_requests')
        .where('targetUserId', '==', userId)
        .where('status', '==', 'pending');

      const [requesterSnap, targetSnap] = await Promise.all([
        asRequesterQuery.get(),
        asTargetQuery.get()
      ]);

      const batch = db.batch();
      let count = 0;

      // Expire requests where user was requester (from old family)
      requesterSnap.docs.forEach(doc => {
        if (doc.data().familyId === beforeFamilyId) {
          batch.update(doc.ref, { status: 'expired' });
          count++;
        }
      });

      // Expire requests where user was target (from old family)
      targetSnap.docs.forEach(doc => {
        if (doc.data().familyId === beforeFamilyId) {
          batch.update(doc.ref, { status: 'expired' });
          count++;
        }
      });

      if (count > 0) {
        await batch.commit();
        console.log(`Expired ${count} pending check-in requests for user ${userId}`);
      }
    } catch (e) {
      console.error('Error revoking check-in requests on family leave', e);
    }

    return null;
  });
