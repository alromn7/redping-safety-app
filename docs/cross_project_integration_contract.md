# RedPing App ↔ RedPing Website (SAR) Integration Contract

Last updated: 2025-10-09

## Scope
Defines the data model, transport, auth, and local dev workflow for wiring the Flutter mobile app (RedPing) and the Website/SAR system into a single real‑time emergency network.

## High-level architecture

```
Mobile App (Flutter)            Cloud (Firebase/GCF)                Website/SAR (Web)
┌───────────────────┐          ┌─────────────────────────────┐     ┌──────────────────────┐
│  RedPing App      │  HTTPS   │  Cloud Functions (REST)     │     │  RedPing Website/SAR │
│  (Auth User)      ├──────────►  /sos/*, /sar/* endpoints   ├────►│  (Coordinators)      │
│  Firestore client │  RT/Snap  │  Firestore (RT updates)    │  RT │  Firestore client    │
│  FCM sender       ├──────────►  FCM (notifications)        ├────►│  FCM receiver (opt)  │
└───────────────────┘          └─────────────────────────────┘     └──────────────────────┘

Legend: HTTPS = REST calls; RT/Snap = Firestore real‑time snapshots
```

## Roles & Auth
- Roles: `user`, `sar_coordinator`, `sar_responder`, `admin`
- Identity: Firebase Auth (email/password, phone, federated) for both app and website
- Authorization: Firestore Security Rules + Callable HTTPS endpoints checking custom claims

### Custom claims (example)
```
{
  "role": "sar_coordinator",
  "orgId": "org_abc123"
}
```

## Core collections (Firestore)
- `sos_sessions/{sessionId}` — one active session per incident
- `sos_sessions/{sessionId}/events/{eventId}` — timeline of events/updates
- `incidents/{incidentId}` — SAR-normalized view (optional projection)
- `sar_orgs/{orgId}` — org metadata
- `sar_orgs/{orgId}/teams/{teamId}` — teams
- `sar_orgs/{orgId}/incidents/{incidentId}` — scoped incidents for org dashboards

### sos_sessions document (minimal)
```json
{
  "sessionId": "sos_123",
  "userId": "uid_abc",
  "status": "active",                  // active|acknowledged|resolving|closed
  "startedAt": 1733782821000,
  "acknowledgedAt": 1733782850000,
  "closedAt": null,
  "severity": "high",                  // low|medium|high|critical
  "lastLocation": {
    "lat": 34.05223,
    "lng": -118.24368,
    "accuracy": 4.2,
    "timestamp": 1733782821000
  },
  "battery": 0.72,
  "device": {
    "model": "Pixel 7",
    "platform": "android",
    "capabilities": ["accelerometer","gps","sos_button"]
  },
  "orgId": "org_abc123",               // optional routing for SAR org
  "notes": "Crash detected on freeway"
}
```

### events document
```json
{
  "eventId": "evt_001",
  "type": "location_update",            // location_update|status_change|media|note
  "timestamp": 1733782842000,
  "payload": {
    "lat": 34.05280,
    "lng": -118.24410,
    "accuracy": 3.9
  },
  "author": {
    "uid": "uid_abc",
    "role": "user"
  }
}
```

## REST API (Cloud Functions/HTTPS)
All endpoints require Firebase Auth ID token; additional coordinator/responder rights enforced via custom claims when applicable.

- POST `/sos/start`
  - body: minimal `sos_sessions` document (without server timestamps)
  - result: `{ sessionId }`
- POST `/sos/update`
  - body: `{ sessionId, event }` (writes to `events` and patches session)
- POST `/sos/end`
  - body: `{ sessionId, reason }` (closes session)
- POST `/sar/acknowledge`
  - role: `sar_coordinator`
  - body: `{ sessionId, teamId }` (sets status=acknowledged, writes event)
- POST `/sar/dispatch`
  - role: `sar_coordinator`
  - body: `{ sessionId, teamId, eta, notes }` (writes event)
- POST `/sar/resolve`
  - role: `sar_coordinator|sar_responder`
  - body: `{ sessionId, outcome, notes }` (status=resolving/closed)

### Error model
```json
{ "error": { "code": "PERMISSION_DENIED", "message": "..." } }
```

## Real‑time updates
- Both App and Website subscribe to:
  - `sos_sessions/{sessionId}` doc snapshots
  - `sos_sessions/{sessionId}/events` collection snapshots (ordered by timestamp)
- Optional: Website subscribes to `sar_orgs/{orgId}/incidents/*` for org-wide board

## Notifications (optional)
- App → Website coordinators: Use FCM Topic per-org: `org_{orgId}_alerts`
- Website → App user: Use FCM direct token for the user device for acknowledgements and instructions

## Security Rules (Firestore, sketch)
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function hasRole(r) { return request.auth.token.role == r; }
    function inOrg(orgId) { return request.auth.token.orgId == orgId; }

    match /sos_sessions/{sessionId} {
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow read, update: if isSignedIn() && (
        request.auth.uid == resource.data.userId ||
        (hasRole('sar_coordinator') && inOrg(resource.data.orgId)) ||
        (hasRole('sar_responder') && inOrg(resource.data.orgId))
      );
    }

    match /sos_sessions/{sessionId}/events/{eventId} {
      allow read: if isSignedIn() && (
        request.auth.uid == get(/databases/$(database)/documents/sos_sessions/$(sessionId)).data.userId ||
        hasRole('sar_coordinator') || hasRole('sar_responder')
      );
      allow create: if isSignedIn();
    }
  }
}
```

## Environments & config
- Single Firebase Project for dev (`redping-dev`) with:
  - Auth, Firestore, Functions, Hosting (web), Messaging
- Separate projects for staging/production (`redping-stg`, `redping-prod`)
- Client config:
  - Flutter: `firebase_options.dart` (per env)
  - Web: `.env` with Firebase web config + API base URL for functions

## Local development workflow
- Use Firebase Emulators for both app & website dev
- Services: auth, firestore, functions, hosting, pubsub (optional)

### Start emulators (example)
```
firebase emulators:start --only auth,firestore,functions,hosting
```

### App connects to emulator
- In Flutter, gate by `kDebugMode` and set:
  - Firestore: `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080)`
  - Auth: `FirebaseAuth.instance.useAuthEmulator('localhost', 9099)`
  - Functions: `FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001)`

### Website connects to emulator
- Initialize Firebase app with `useEmulator` bindings for Auth/Firestore/Functions

## DataConnect (optional, recommended)
If using Firebase Data Connect, define a shared schema and generate typed clients for Dart (app) and TypeScript (web).

### Example query (pseudo)
```graphql
query ActiveSession($sessionId: ID!) {
  sos_session(id: $sessionId) {
    sessionId
    status
    lastLocation { lat lng accuracy timestamp }
    events(orderBy: timestamp_desc, limit: 50) {
      eventId type timestamp payload
    }
  }
}
```

## Validation checklist
- [ ] Auth flows working on both clients
- [ ] App can create `/sos/start` and write Firestore session
- [ ] Website sees real‑time session + events
- [ ] Coordinator can acknowledge & dispatch via `/sar/*` endpoints
- [ ] Notifications reach intended parties (topic and direct)
- [ ] Security rules enforce role/org scoping
- [ ] Emulator parity with cloud environment

## Minimal client contracts

### App → `/sos/start`
```json
{
  "userId": "uid_abc",
  "severity": "critical",
  "orgId": "org_abc123",
  "device": {"model":"iPhone 14","platform":"ios"},
  "lastLocation": {"lat":34.05223,"lng":-118.24368,"accuracy":4.2,"timestamp":1733782821000}
}
```

### Website → `/sar/acknowledge`
```json
{
  "sessionId": "sos_123",
  "teamId": "team_01"
}
```

## Monitoring & logging
- Functions logs: Stackdriver/Cloud Logging with sessionId correlation
- Firestore writes: include `updatedBy` and `actorRole` fields
- Error alerts: Functions error reporting + Sentry (optional)

## Versioning
- Prefix API paths with `/v1/` for future compatibility
- Add `schemaVersion` to session docs when evolving structure
