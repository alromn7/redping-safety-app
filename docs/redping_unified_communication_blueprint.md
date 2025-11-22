# RedPing Unified Communication Blueprint

## 1. Overview

This document outlines the definitive communication workflow for the entire RedPing Safety Ecosystem. Its purpose is to establish a single, unified data flow model that ensures seamless, real-time interaction between the end-user (via the Flutter App) and the emergency responders (via the SAR Website).

## 2. Core Principle: A Single Source of Truth

The entire system is built around one central principle: **a single source of truth**. All emergency data, from initial alert to final resolution, will reside in one specific location.

**Central Hub:** The `sos_sessions` collection within the `redping-a2e37` Firebase Firestore database.

All clients—the user's mobile app and the SAR coordinator's website—will read from and write to this single collection. This eliminates data silos, prevents synchronization errors, and guarantees that all parties are viewing the exact same information in real-time.

## 3. System Components

*   **RedPing Mobile App (Flutter):** The client used by the person in distress. It is responsible for *sending* the SOS and *displaying the status* of that specific SOS back to the user.
*   **RedPing SAR Dashboard (Next.js):** The client used by the SAR coordinators. It is responsible for *viewing all active SOS alerts* and *updating their status*.
*   **Firebase Firestore:** The cloud-hosted, real-time database that serves as the central communication hub.

## 4. The Unified Workflow: End-to-End

This is the step-by-step flow of information during an emergency incident.

### Step 1: SOS Activation (User App)
1.  A user in distress triggers the SOS function in the Flutter app.
2.  The app gathers essential data: User ID, current GPS location, timestamp, and emergency type.
3.  The app writes a **new document** directly to the `sos_sessions` collection in Firestore. This document has an initial `status` of `'active'`.

### Step 2: Real-time Alert (SAR Website)
1.  The SAR Dashboard website has a persistent, real-time listener attached to the `sos_sessions` collection, specifically querying for documents where `status` is `'active'`.
2.  The new SOS document from Step 1 appears instantly on the SAR dashboard, alerting the coordinator.

### Step 3: User Confirmation (User App)
1.  Simultaneously, the user's app navigates to a "My SOS Status" screen.
2.  This screen has its own real-time listener on the `sos_sessions` collection, but it is filtered to show *only the document created by that specific user*.
3.  The user sees their own SOS details appear on their screen, providing immediate confirmation that the alert was successfully transmitted.

### Step 4: Responder Action (SAR Website)
1.  The SAR coordinator sees the new alert on the website dashboard and takes action (e.g., dispatches a team).
2.  The coordinator updates the status of the SOS document directly in Firestore, changing the `status` field from `'active'` to `'responder_assigned'`.

### Step 5: Real-time Feedback (User App)
1.  The listener on the user's "My SOS Status" screen (from Step 3) instantly detects the change to the document.
2.  The app's UI updates in real-time, informing the user: "A responder has been assigned." This provides crucial feedback and reassurance to the person in distress.

## 5. Architectural Diagram

```
                               +--------------------------+
                               |                          |
(1. Writes SOS)--------------> |  Firestore Database      | <------------(2. Reads All SOS)
                               |  (sos_sessions Collection)|
(3. Reads Own SOS) <-----------|                          | ------------>(4. Updates Status)
                               +--------------------------+
       ^                             ^            ^                             |
       |                             |            |                             |
       | (5. Receives Status Update) |            |                             |
       |                             |            |                             |
+------------------+                 |            +-------------------+
|                  |                 |            |                   |
| RedPing App      |-----------------+            | SAR Website       |
| (User)           |                              | (Coordinator)     |
|                  |                              |                   |
+------------------+                              +-------------------+
```

## 6. Durability and Scale Enhancements

This section extends the blueprint with concrete adjustments to keep Firestore realtime UX while avoiding hot-document contention, race conditions, and noisy listeners.

### 6.1 Split the write paths (Header + Subcollections)

Keep the session document as a lightweight "header," and move high-churn updates to subcollections.

- `sos_sessions/{sessionId}` (header)
       - Minimal, frequently-read fields for dashboard triage and user confirmation.
       - Example shape:

```jsonc
// sos_sessions/{sessionId}
{
       "userId": "<uid>",
       "status": "active", // 'active' | 'responder_assigned' | 'in_progress' | 'resolved'
       "type": "medical",   // emergency type/category
       "createdAt": {"__datatype__": "serverTimestamp"},
              "updatedAt": {"__datatype__": "serverTimestamp"},
       "lastLocation": { "lat": 0, "lng": 0, "accuracy": 12.3, "ts": {"__datatype__": "serverTimestamp"} },
       "assignedResponderId": null,
       "priority": 0
}
```

- `sos_sessions/{sessionId}/locations/{ts}` (append-only)
       - Example:

```jsonc
{
       "lat": 0,
       "lng": 0,
       "accuracy": 12.3,
       "source": "gps", // 'gps' | 'network'
       "ts": {"__datatype__": "serverTimestamp"}
}
```

- `sos_sessions/{sessionId}/events/{ts}` (audit log)
       - Example:

```jsonc
{
       "type": "status_change", // 'status_change' | 'note' | 'assignment'
       "actor": { "role": "coordinator", "uid": "<uid>" },
       "payload": { "from": "active", "to": "responder_assigned" },
       "ts": {"__datatype__": "serverTimestamp"}
}
```

Rationale: Dashboard listens to small header docs; mobile can stream subcollections when needed (e.g., breadcrumb map). A Cloud Function can mirror the latest location into `lastLocation` to avoid hot writes on the header.

### 6.2 Listener strategy (reduce noise, keep realtime)

- SAR Website (Next.js):
              - Listen to `sos_sessions` headers only with `where('status', '==', 'active')` and `orderBy('updatedAt', 'desc')`.
       - Render list from headers; expand into subcollections only when the operator opens a session.

- Mobile App (Flutter):
       - Listen to the user's own session header for status and confirmation.
       - Subscribe to `locations` subcollection only when showing detailed breadcrumb/history.

### 6.3 Status transitions and idempotency

Enforce via Cloud Functions or Firestore transactions:

- Valid transitions: `active -> responder_assigned -> in_progress -> resolved`.
- One active session per user:
       - On create, check if the user already has an active session; if yes, return that ID (idempotency) or block creation.
       - Maintain a user-scoped pointer (e.g., `users/{uid}/meta.activeSessionId`) for quick lookup.

Illustrative pseudocode (Cloud Functions):

```js
// onCreate sos_sessions/{sessionId}
exports.ensureSingleActiveSession = functions.firestore
       .document('sos_sessions/{sessionId}')
       .onCreate(async (snap, ctx) => {
              const data = snap.data();
              const uid = data.userId;
              const ref = admin.firestore().doc(`users/${uid}/meta/state`);
              await admin.firestore().runTransaction(async (tx) => {
                     const curr = await tx.get(ref);
                     const activeSessionId = curr.exists ? curr.data().activeSessionId : null;
                     if (activeSessionId) {
                            // Option A: mark duplicate as resolved/canceled
                            tx.update(snap.ref, { status: 'resolved', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
                            return;
                     }
                     tx.set(ref, { activeSessionId: snap.id }, { merge: true });
              });
       });

// onWrite locations -> mirror latest to header (debounced)
exports.mirrorLatestLocation = functions.firestore
       .document('sos_sessions/{sessionId}/locations/{ts}')
       .onCreate(async (snap, ctx) => {
              const { sessionId } = ctx.params;
              const loc = snap.data();
              await admin.firestore().doc(`sos_sessions/${sessionId}`).set({
                            lastLocation: { lat: loc.lat, lng: loc.lng, accuracy: loc.accuracy, ts: admin.firestore.FieldValue.serverTimestamp() },
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              }, { merge: true });
       });
```

### 6.4 Security model (roles and field ownership)

Roles:

- User: owns their session; may create/cancel; may update location.
- Coordinator: may read all sessions and update responder/status fields.

Policy outline (to be implemented in Firestore rules):

- allow create: authenticated users creating a session with `userId == request.auth.uid`.
- allow read: owner or coordinator.
- allow update (user): only non-privileged fields (e.g., `lastLocation`) and cannot change `userId` or elevate status.
- allow update (coordinator): only `status`, `assignedResponderId`, `priority`, `updatedAt`.

Example rule skeleton (illustrative):

```ruby
rules_version = '2';
service cloud.firestore {
       match /databases/{database}/documents {
              function isAuthenticated() { return request.auth != null; }
              // Coordinator role is derived from users/<uid>.roles array (e.g., 'SAR_LEADER' or 'ADMIN')
              function isCoordinator() {
                     return isAuthenticated() &&
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles.hasAny(['SAR_LEADER', 'ADMIN']);
              }
              function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }

              match /sos_sessions/{sessionId} {
                     allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
                     allow read: if isOwner(resource.data.userId) || isCoordinator();
                     allow update: if (
                            // user may update only non-privileged fields (e.g., lastLocation)
                            (isOwner(resource.data.userId) &&
                             request.resource.data.userId == resource.data.userId)
                            ||
                            // coordinator may update status/assignment/priority
                            (isCoordinator() && request.resource.data.userId == resource.data.userId)
                     );
                     allow delete: if isCoordinator();
              }

              // Subcollections: locations/events
              match /sos_sessions/{sessionId}/locations/{doc} {
                     allow create: if isAuthenticated() && get(/databases/$(database)/documents/sos_sessions/$(sessionId)).data.userId == request.auth.uid;
                     allow read: if isAuthenticated();
                     allow update, delete: if false; // immutable pings; admin-only cleanup can be added separately
              }
              match /sos_sessions/{sessionId}/events/{doc} {
                     allow read: if isAuthenticated();
                     allow create: if isCoordinator();
                     allow update, delete: if false;
              }
       }
}
```

Note: The rule skeleton is an example—adapt to your exact field list and introduce stricter per-field checks as needed.

### 6.5 Indexes and queries

Add a composite index for the dashboard query:

```json
{
       "indexes": [
              {
                     "collectionGroup": "sos_sessions",
                     "queryScope": "COLLECTION",
                     "fields": [
                            { "fieldPath": "status", "order": "ASCENDING" },
                            { "fieldPath": "updatedAt", "order": "DESCENDING" }
                     ]
              }
       ]
}
```

### 6.6 Write-rate control

- Mobile location pings: prefer 3–10 seconds cadence under normal conditions; go denser only when necessary.
- Mirror to header via function, not by writing header every ping.
- Consider client-side debouncing and backoff under poor connectivity.

### 6.7 Archival and retention

- On `resolved`, set `resolvedAt` and clear `users/{uid}/meta.state.activeSessionId`.
- Use a scheduled Cloud Function to archive/prune old `locations` and `events` after N days.
- Optionally leverage Firestore TTL on a timestamp field for `locations` if long-term breadcrumb storage isn’t required.

### 6.8 Notifications

- Trigger FCM to coordinators on new `active` session.
- Trigger FCM to the user on status changes (e.g., `responder_assigned`).

### 6.9 Failure modes and UX notes

- Offline-first: client writes queue locally—ensure server-side idempotency for duplicate creates.
- Race conditions: protect status transitions with transactions/functions.
- Time trust: rely on `serverTimestamp()` for created/updated fields.
- Privacy: consider redacting precise coordinates in coordinator list views, showing full precision only in detail views.

### 6.10 Success checklist

- One active session per user enforced.
- Header + subcollections pattern implemented.
- Coordinator dashboard listens to headers only; indexes in place.
- Security rules separate user vs coordinator capabilities.
- Functions mirror latest location and emit notifications.
- Archival/TTL strategy defined for breadcrumbs and events.

## Appendix: Tiny server contract

For a concise, implementation-ready interface (inputs/outputs, data shapes, error modes) that the app and server both adhere to, see `docs/tiny_server_contract.md`.

Notes:
- Region can be selected at deploy-time via `FUNCTION_REGION` (default `us-central1`).
- An optional callable `createSosSession` is available if you prefer a server-mediated session start instead of direct Firestore writes.

