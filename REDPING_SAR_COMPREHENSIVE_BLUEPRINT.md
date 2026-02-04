# RedPing SAR — Comprehensive Blueprint

## 1. Overview & Goals
- Provide a professional/volunteer Search and Rescue (SAR) operations app for team identity, coordination, and messaging.
- Keep footprint lightweight: no consumer auto-detection or continuous sensors; focus on reliable communications and incident workflows.
- Ensure strong privacy, role-based access, and auditable actions.

## 2. Personas & Use Cases
- SAR Member: joins incidents, shares status/location, receives tasks and updates.
- SAR Coordinator: creates/manages incidents, assigns tasks, oversees teams and communications.
- Dispatcher/Observer: monitors incidents and broadcasts advisories; limited controls.

## 3. Feature Set
- Identity & Registration: member onboarding, role assignment, verification.
- Organization & Teams: org admin, team management, roles/permissions, membership lifecycle.
- Incidents & Sessions: start, update, complete, cancel; priority levels; status tracking.
- Messaging & Updates: real-time SAR messaging, incident channels, announcements.
- Location & Mapping: share location on demand; open device-native maps; route helpers.
- Notifications: incident events, task assignments, status changes.
- Audit & Logs: action logs for admin decisions and incident changes.

## 4. Workflows
- Registration: user applies → admin verifies → role assigned → joins org/team.
- Incident Lifecycle:
  - Create incident → define scope/priority → invite teams → live updates.
  - Member status: available/en route/on-scene/standby → auto reminders for stale states.
  - Completion: capture summary, involved members, outcomes, evidence links.
- Messaging:
  - Incident channels with threaded updates; coordinator broadcasts; member replies.
  - Media attachments (where permitted); rate limits and content guidelines.
- Team Management:
  - Add/remove members; assign roles; manage units and capabilities.

## 5. Entitlements & Subscriptions
- Tiers:
  - Observer: read-only participation.
  - Member: full participation in incidents and messaging.
  - Coordinator: team management + incident command.
  - Ultra/Org Admin: advanced org management, billing, analytics.
- Gates: `sarParticipation`, `sarTeamManagement`, org capacity limits.

## 6. Data Model
- `SAROrganization`: id, name, adminUserId, memberCount, billing.
- `SARMember`: id, userId, role, status, verifiedAt, orgId.
- `SARTeam`: id, orgId, name, capabilities, roster.
- `SARIncident`: id, orgId, type, priority, status, location, timestamps.
- `SARSession`: member participation in incidents; join/leave, updates.
- `SARMessaging`: incident/channel messages; author, content, attachments.
- `AuditLog`: action type, actor, target, timestamp, reason.
- Retention: configurable per org; default sensible retention and minimization.

## 7. Permissions & Background Policy
- Permissions: location (foreground), notifications, internet.
- Background: avoid continuous sensors; periodic messaging/updates via streams.
- Foreground service: generally not required; only if OS policies demand persistent connection notices.

## 8. Privacy, Security, and Compliance
- Role-Based Access Control (RBAC): coordinator/admin-only actions for team/org.
- Firestore Rules: restrict access to org-bound collections; enforce roles for write ops.
- Auditability: every admin action logged with actor and reason.
- Data Minimization: store only operationally necessary info; redact non-essential PII.
- Consent & Policy: clear member consent; org privacy policy; acceptable use guidelines.

## 9. Messaging & Reliability
- Channels per incident; optional org-wide announcements.
- Delivery guarantees: retries, exponential backoff; offline queue for outbound actions.
- Throttling: prevent floods; coordinator overrides for critical broadcasts.

## 10. Location & Mapping
- On-demand share location for incident participation.
- Open native maps with coordinates and routes; avoid persistent tracking.
- Optional checkpoints and waypoints; member opt-in.

## 11. Notifications
- Incident created/updated, task assignment, member mentions, coordinator broadcasts.
- Granular settings by role and incident.

## 12. CI/CD & Configuration
- Separate app target/build with its own bundle ID and assets.
- Environment keys and Firebase project/collections isolated from consumer app.
- Feature flags: `sarParticipationEnabled`, `sarTeamManagementEnabled`, `mediaAttachmentsEnabled`.

## 13. Telemetry & Observability
- Metrics: incident throughput, message delivery latency, member online rate, role actions.
- Logs: privacy-aware; redact sensitive; structured for audits.
- Health checks for messaging streams and Firestore connections.

## 14. Testing Strategy
- Unit: RBAC checks, rules enforcement, org/team services, messaging utils.
- Integration: registration → verification; incident create → team join → messaging → completion.
- Device: notification delivery, location share UX, offline behavior.
- Security Tests: rules coverage; attempt unauthorized writes/reads.

## 15. Performance Targets
- Incident updates visible to members ≤ 1s.
- Messaging delivery median ≤ 500ms; P95 ≤ 3s.
- Idle battery impact ≤ 1–2% per day.

## 16. Store Compliance
- App positioning: professional SAR coordination tool; no consumer auto crash/fall claims.
- Privacy policy: data usage, retention, admin visibility; consent.
- Content moderation for messaging; report/ban policies.

## 17. Risks & Mitigations
- Data leakage across orgs → strict collection scoping, tests, audits.
- Role abuse → detailed audit logs, tiered permissions, admin training.
- Message reliability → retries, offline queue, status indicators.
- Legal exposure → clear terms, privacy policies, consented participation.

## 18. Acceptance Criteria
- Members can register, be verified, and join incidents per RBAC and rules.
- Coordinator can manage teams/incidents; messaging reliable under load.
- Battery impact meets target; no continuous sensor monitoring.
- Firestore rules prevent cross-org reads/writes; audits recorded.

## 19. Roadmap (Post‑MVP)
- Media attachments with secure storage and content scanning.
- Tasking module (assignments, checklists, progress tracking).
- Incident analytics and after-action reports.
- Interoperability with regional SAR hubs (APIs, federation).
