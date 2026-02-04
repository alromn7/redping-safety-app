# Firebase Setup (Phase 4)

## Strategy
- Preferred: Single Firebase project with strict collection-level scoping and RBAC via custom claims (`orgId`, `role`).
- Alternative: Dual projects (Emergency, SAR) for stronger isolation; duplicate rules and separate CI secrets.

## Required Keys / Files
- Android: `google-services.json` for Emergency and SAR apps.
- iOS: `GoogleService-Info.plist` for Emergency and SAR apps.
- CI secrets: service account for rules testing and deployment.

## Custom Claims
Set `orgId` and `role` on user tokens after verification:
- Roles: `observer`, `member`, `coordinator`, `admin`.
- Example:
```
orgId: "org-1"
role: "member"
```

## Rules Deployment
- See `firestore/firestore.rules` for org/RBAC rules.
- Validate via `npm test` in `firestore/` (uses emulator).

## Next Steps
- Wire entitlement gates (`sarParticipationEnabled`, `sarTeamManagementEnabled`) to UI actions.
- Add audit log collection and extend rules for write permissions.
- Implement consent flow in apps before first write.
