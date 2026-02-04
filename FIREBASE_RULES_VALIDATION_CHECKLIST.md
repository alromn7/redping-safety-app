# Firebase Rules Validation Checklist (Single Project, SAR + Consumer)

## Scope
Validate org-scoped SAR rules and ensure consumer collections remain isolated.

## Pre-requisites
- Staging Firebase project alias configured (no production deploy yet)
- Test users: consumer, sar_member, sar_coordinator, sar_admin
- Test org: `org_test_1` with members/teams/incidents/messages/audit_logs

## Test Data Setup (example paths)
- `sar_organizations/org_test_1/members/{uid}` with roles: member/coordinator/admin
- `sar_organizations/org_test_1/teams/teamA`
- `sar_organizations/org_test_1/incidents/inc1`
- `sar_organizations/org_test_1/incidents/inc1/messages/msg1`
- `sar_organizations/org_test_1/audit_logs/log1`
- Consumer data unchanged: `users/{uid}`, `sos_sessions/{id}`, etc.

## Core Checks
- Org isolation
  - Non-member cannot read/write any `sar_organizations/org_test_1/*`
  - Member can read incidents/messages; cannot create teams/incidents
  - Coordinator can create/update incidents/teams; manage members
  - Admin can write org-wide, read audit logs; others cannot read audit logs
- Messaging
  - Member/coordinator/admin can create incident messages; only author/coordinator/admin can delete
- Consumer collections
  - Consumer users can access their own `users/{uid}` and `sos_sessions` per existing rules
  - SAR roles do not gain extra consumer privileges beyond defined rules

## Negative Tests
- Cross‑org access: a member of another org cannot access `org_test_1`
- Elevation attempts: member attempts admin-only writes are rejected
- Message deletion: non-author non-coordinator cannot delete

## Suggested Validation Flow (Emulator preferred)
1. Start Firestore emulator (optional):
   - Ensure Firebase tools installed
2. Seed test data via admin or emulator scripts
3. Run scripted reads/writes under different auth contexts (custom claims or doc roles)
4. Verify responses (allow/deny) align with expectations above

## Staging Deploy (do not run in production yet)
- Deploy rules to staging alias and repeat checks with test accounts

## Acceptance Criteria
- All listed checks pass; no unintended access paths
- Consumer and SAR data boundaries behave as designed

## Notes
- See [firestore.rules](firestore.rules) for org-scoped helpers and SAR collections
- Keep production deploy gated until staging validation is complete
