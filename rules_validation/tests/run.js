const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

(async () => {
  const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId: 'redping-staging',
    firestore: { rules }
  });

  // Seed data with rules disabled (bypass) so role docs exist
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const seedDb = context.firestore();
    await seedDb.doc('sar_organizations/org_test_1/members/member_uid').set({ role: 'member' });
    await seedDb.doc('sar_organizations/org_test_1/members/coordinator_uid').set({ role: 'coordinator' });
    await seedDb.doc('sar_organizations/org_test_1/members/admin_uid').set({ role: 'admin' });
    await seedDb.doc('sar_organizations/org_test_1/audit_logs/log1').set({ action: 'create_incident', actor: 'admin_uid' });
  });

  // Define admin context for later reads
  const adminCtx = testEnv.authenticatedContext('admin_uid', { admin: true });
  const adminDb = adminCtx.firestore();

  // Member cannot create incident
  const memberCtx = testEnv.authenticatedContext('member_uid', {});
  const memberDb = memberCtx.firestore();
  await assertFails(memberDb.doc('sar_organizations/org_test_1/incidents/inc1').set({ type: 'test', priority: 'high' }));

  // Coordinator can create incident
  const coordCtx = testEnv.authenticatedContext('coordinator_uid', {});
  const coordDb = coordCtx.firestore();
  await assertSucceeds(coordDb.doc('sar_organizations/org_test_1/incidents/inc1').set({ type: 'test', priority: 'high' }));

  // Member can create message under incident
  await assertSucceeds(memberDb.doc('sar_organizations/org_test_1/incidents/inc1/messages/m1').set({ authorId: 'member_uid', content: 'hello' }));

  // Outsider cannot read incident
  const outsiderCtx = testEnv.authenticatedContext('outsider_uid', {});
  const outsiderDb = outsiderCtx.firestore();
  await assertFails(outsiderDb.doc('sar_organizations/org_test_1/incidents/inc1').get());

  // Audit logs: admin readable, member not
  // Audit log checks
  await assertFails(memberDb.doc('sar_organizations/org_test_1/audit_logs/log1').get());
  await assertSucceeds(adminDb.doc('sar_organizations/org_test_1/audit_logs/log1').get());

  console.log('Basic SAR rules validation passed.');
  await testEnv.cleanup();
})();
