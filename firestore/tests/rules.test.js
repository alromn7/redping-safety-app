const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

let testEnv;

async function seed(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const org1Inc = db.collection('orgs').doc('org-1').collection('incidents').doc('inc-1');
    await org1Inc.set({ type: 'missing_person', status: 'open' });
    const org1MsgCol = org1Inc.collection('messages');
    await org1MsgCol.doc('m1').set({ content: 'Initial briefing', authorId: 'coord-1' });

    const org2Inc = db.collection('orgs').doc('org-2').collection('incidents').doc('inc-9');
    await org2Inc.set({ type: 'disaster', status: 'active' });
  });
}

async function run() {
  testEnv = await initializeTestEnvironment({
    projectId: 'redping-demo',
    firestore: {
      rules: fs.readFileSync(require('path').resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });

  await seed(testEnv);

  const obsCtx = testEnv.authenticatedContext('user-obs', { orgId: 'org-1', role: 'observer' });
  const memCtx = testEnv.authenticatedContext('user-mem', { orgId: 'org-1', role: 'member' });
  const coordCtx = testEnv.authenticatedContext('user-coord', { orgId: 'org-1', role: 'coordinator' });
  const adminCtx = testEnv.authenticatedContext('user-admin', { orgId: 'org-1', role: 'admin' });
  const otherOrgCtx = testEnv.authenticatedContext('user-x', { orgId: 'org-2', role: 'member' });

  // Observer can read incidents in own org
  await assertSucceeds(
    obsCtx.firestore().collection('orgs').doc('org-1').collection('incidents').doc('inc-1').get()
  );

  // Observer cannot post messages
  await assertFails(
    obsCtx.firestore().collection('orgs').doc('org-1').collection('incidents').doc('inc-1').collection('messages').add({
      content: 'hello', authorId: 'user-obs'
    })
  );

  // Member can post messages
  await assertSucceeds(
    memCtx.firestore().collection('orgs').doc('org-1').collection('incidents').doc('inc-1').collection('messages').add({
      content: 'en route', authorId: 'user-mem'
    })
  );

  // Coordinator can create incidents
  await assertSucceeds(
    coordCtx.firestore().collection('orgs').doc('org-1').collection('incidents').add({
      type: 'search', status: 'open'
    })
  );

  // Cross-org read should fail
  await assertFails(
    memCtx.firestore().collection('orgs').doc('org-2').collection('incidents').doc('inc-9').get()
  );

  // Admin can manage members
  await assertSucceeds(
    adminCtx.firestore().collection('orgs').doc('org-1').collection('members').doc('me').set({ role: 'member' })
  );

  // Coordinator can create audit log; member cannot
  await assertSucceeds(
    coordCtx.firestore().collection('orgs').doc('org-1').collection('audit_logs').add({
      action: 'incident_update', target: 'inc-1', actor: 'user-coord'
    })
  );
  await assertFails(
    memCtx.firestore().collection('orgs').doc('org-1').collection('audit_logs').add({
      action: 'something', target: 'inc-1', actor: 'user-mem'
    })
  );

  // Admin can delete audit logs
  const adminDb = adminCtx.firestore();
  const logRef = adminDb.collection('orgs').doc('org-1').collection('audit_logs').doc('log-1');
  await assertSucceeds(logRef.set({ action: 'seed', actor: 'admin' }));
  await assertSucceeds(logRef.delete());

  console.log('All rule tests completed.');
  await testEnv.cleanup();
}

run().catch((e) => { console.error(e); process.exit(1); });
