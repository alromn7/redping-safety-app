# Firestore Rules & Tests (Phase 4)

This folder contains Cloud Firestore security rules and a minimal test harness to validate organization scoping and RBAC for SAR operations.

## Files
- `firestore.rules`: Enforces org scoping and role-based access for `members`, `incidents`, and per-incident `messages` under `orgs/{orgId}`.
- `tests/rules.test.js`: Uses `@firebase/rules-unit-testing` to assert typical allow/deny scenarios.
- `package.json`: Dev dependency for rules testing.

## Run Locally
1. Install dev dependency:
```powershell
Push-Location "c:\flutterapps\redping_14v\firestore"
npm install
Pop-Location
```
2. Run tests:
```powershell
Push-Location "c:\flutterapps\redping_14v\firestore"
npm test
Pop-Location
```

## Notes
- The rules assume custom claims `orgId` and `role` on the authenticated token.
- Adjust for Emergency collections as needed (e.g., SOS sessions) and extend tests.
- For dual Firebase projects, mirror rules in each and manage CI secrets per app.
