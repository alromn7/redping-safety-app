# SAR Firestore Rules Scaffold (Planning)

## Goals
- Strict org- and role-based isolation for SAR data.
- Prevent cross-org reads/writes and enforce RBAC for admin actions.

## Collections & Suggested Structure
- `sar_organizations/{orgId}`
- `sar_organizations/{orgId}/members/{memberId}`
- `sar_organizations/{orgId}/teams/{teamId}`
- `sar_organizations/{orgId}/incidents/{incidentId}`
- `sar_organizations/{orgId}/incidents/{incidentId}/messages/{messageId}`
- `sar_organizations/{orgId}/audit_logs/{logId}`

## Identity & Claims
- Client includes `orgId` and `role` in a custom claim or resolves via member document.
- Server-side functions can mint claims on verification.

## Rule Patterns (Illustrative)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isOrgMember(orgId) {
      return exists(/databases/$(database)/documents/sar_organizations/$(orgId)/members/$(request.auth.uid));
    }
    function hasRole(orgId, allowed) {
      return get(/databases/$(database)/documents/sar_organizations/$(orgId)/members/$(request.auth.uid)).data.role in allowed;
    }

    match /sar_organizations/{orgId} {
      allow read: if isOrgMember(orgId);
      allow write: if hasRole(orgId, ['admin']);

      match /members/{memberId} {
        allow read: if isOrgMember(orgId);
        allow write: if request.auth.uid == memberId || hasRole(orgId, ['admin','coordinator']);
      }

      match /teams/{teamId} {
        allow read: if isOrgMember(orgId);
        allow write: if hasRole(orgId, ['admin','coordinator']);
      }

      match /incidents/{incidentId} {
        allow read: if isOrgMember(orgId);
        allow create: if hasRole(orgId, ['admin','coordinator']);
        allow update, delete: if hasRole(orgId, ['admin','coordinator']);

        match /messages/{messageId} {
          allow read: if isOrgMember(orgId);
          allow create: if hasRole(orgId, ['member','coordinator','admin']);
          allow delete: if hasRole(orgId, ['coordinator','admin']) || request.auth.uid == resource.data.authorId;
        }
      }

      match /audit_logs/{logId} {
        allow read: if hasRole(orgId, ['admin']);
        allow write: if hasRole(orgId, ['admin','coordinator']);
      }
    }
  }
}
```

## Cross-App Isolation Options
- Single Firebase project: keep SAR under `sar_organizations/*`; consumer app reads only its own collections; rules block consumer roles.
- Dual projects: consumer app uses Project A; SAR uses Project B; simplest isolation at the cost of more setup.

## Testing Checklist
- Unauthorized reads/writes blocked:
  - User from Org A cannot access Org B.
  - Member cannot perform admin actions.
- Coordinator can manage incidents and teams.
- Message deletions limited to author/coordinator/admin.
- Audit logs writable only by admin/coordinator; readable by admin.

## Next Steps
- Confirm claims source (custom claims vs document lookups).
- Align with `FeatureAccessService` gates.
- Implement rules in production `firestore.rules` with staging tests.
