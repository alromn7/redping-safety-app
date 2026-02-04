# Firebase Staging Deploy Plan (Single Project)

## Goal
Deploy updated Firestore rules with SAR org-scoped RBAC safely to staging, validate, then promote to production.

## Steps
1. Create staging Firebase environment (or use an existing staging project alias)
2. Add SAR collections for testing:
   - `sar_organizations/{orgId}` with `members`, `teams`, `incidents`, `incidents/{id}/messages`, `audit_logs`
3. Deploy rules to staging:
```bash
# Planning-only example (do not run yet)
firebase deploy --only firestore:rules --project <staging-alias>
```
4. Validation tests (manual or scripted):
   - Non-member cannot read/write org data
   - Member can read incidents/messages; can send messages
   - Coordinator/admin can create/update incidents/teams; manage members
   - Audit logs writable by admin/coordinator; readable by admin only
5. Log and review:
   - Capture test results and any failures; adjust rules accordingly
6. Promote to production:
```bash
# Planning-only example (do not run yet)
firebase deploy --only firestore:rules --project <prod-alias>
```

## Notes
- Keep consumer collections unchanged; SAR rules isolated under `sar_organizations/*`
- Consider staging data retention and user claims setup for role testing
