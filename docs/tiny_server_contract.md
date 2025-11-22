# Tiny Server Contract: SOS Sessions

This contract defines the minimal, durable interface between the mobile app (client) and the backend (server) for SOS workflows. It uses Firestore as the API surface and Cloud Functions v2 as server-side automation. No HTTP endpoints are required.

## Scope
- Start/stop SOS sessions
- Stream location pings durably
- Keep a compact dashboard feed up to date
- Enforce a single active session per user

## Entities and shapes

### 1) `sos_sessions/{sessionId}` (header)
- Purpose: Single document per session used for UI and dashboard summaries.
- Ownership: Created/updated by client; additional fields maintained by server.
- Shape (canonical):
```json
{
  "userId": "<uid>",
  "userName": "<display name>",
  "type": "manual | crash | fall | ...",
  "status": "active | countdown | assigned | inProgress | false_alarm | cancelled | resolved",
  "userMessage": "<optional text>",
  "updatedAt": {"__datatype__": "timestamp"},
  "lastLocation": {
    "lat": 0,
    "lng": 0,
    "accuracy": 0,
    "address": "<optional>",
    "ts": {"__datatype__": "timestamp"}
  }
}
```

Client writes:
- Create header on SOS start
- Update `status` on cancel/resolve only

Server writes:
- Mirrors latest ping into `lastLocation`
- Updates `updatedAt` on changes

### 2) `sos_sessions/{sessionId}/locations/{ts}` (append-only pings)
- Purpose: High-frequency location updates without hot-header contention.
- Ownership: Written by client only.
- Document ID: client timestamp (ms) or server timestamp string.
- Shape:
```json
{
  "lat": 0,
  "lng": 0,
  "accuracy": 0,
  "address": "<optional>",
  "source": "gps|network|fused",
  "createdAt": {"__datatype__": "timestamp"}
}
```

Server behavior:
- Trigger mirrors the latest ping into the header and bumps `updatedAt`.

### 3) `sos_sessions/{sessionId}/events/{id}` (audit)
- Purpose: Optional append-only audit log (assignments, notes, status changes).
- Ownership: Client and coordinators may add events; server may append derived events.

### 4) `sos_pings/{sessionId}` (derived dashboard feed)
- Purpose: Compact document for SAR dashboard.
- Ownership: Server only.
- Shape (derived):
```json
{
  "sessionId": "<id>",
  "userId": "<uid>",
  "userName": "<name>",
  "type": "manual|crash|...",
  "status": "active|...",
  "priority": "low|medium|high|critical",
  "riskLevel": "low|medium|high",
  "userMessage": "",
  "location": {"latitude":0, "longitude":0, "accuracy":0, "address":""},
  "lastUpdate": "<ISO string>"
}
```

## Server responsibilities (Cloud Functions v2)
- `onSosSessionCreated`: Enforce single active session per user via `users/{uid}/meta/state.activeSessionId`.
- `onLocationPingCreated`: Mirror latest ping into the session header (`lastLocation`, `updatedAt`).
- `onSosSessionWritten`: Maintain/upsert `sos_pings/{sessionId}` for dashboard.

Region options (current: australia-southeast1 for all functions):
- Deploy-time selectable region via environment var `FUNCTION_REGION` (default `us-central1`).
- Current deployment: Firestore triggers and callable deployed in `australia-southeast1`.
- Example (PowerShell): `$env:FUNCTION_REGION = 'australia-southeast1' ; firebase deploy --config ..\\firebase.deploy.json --only functions --project redping-a2e37`

Optional callable (alternative to direct Firestore writes):
- `createSosSession` / `createSosSessionAU` (australia-southeast1)
- `createSosSessionEU` (europe-west1)
- `createSosSessionAF` (africa-south1)
- `createSosSessionAS` (asia-southeast1)
  - Input: `{ type?: string, userMessage?: string, location?: { lat: number, lng: number, accuracy?: number, address?: string } }`
  - Auth: required; uses `request.auth.uid` as `userId`
  - Effect: creates `sos_sessions/{sessionId}` header; returns `{ sessionId }`
  - Notes: normal server enforcement still applies (single active session, location mirroring, derived pings)

Client selection guidance:
- Prefer the closest regional function (e.g., AU for Australia/NZ, EU for EMEA, AF for Africa, AS for SE/Asia).
- Implement a simple fallback (if call fails, try next preferred region).

Flutter helper example:
```dart
import 'package:redping_14v/services/sos_callable_client.dart';

final client = SosCallableClient();
final sessionId = await client.createSession(
  preferredRegion: 'EU',
  type: 'manual',
  userMessage: 'Need assistance',
  location: {
    'lat': 51.5074,
    'lng': -0.1278,
    'accuracy': 12.5,
    'address': 'London, UK',
  },
);
```

## Security contract (high-level)
- Reader scope:
  - Owner can read their own session and subcollections.
  - Coordinators (role in `users/{uid}.roles`) can read active sessions for ops.
- Writer scope:
  - Client writes: create header, append locations, update status; cannot modify server-only fields.
  - Server writes: mirror fields, derived collections, enforcement pointers.

## Indexes
- Composite: `sos_sessions` on `status ASC, updatedAt DESC` for dashboards.

## Error modes and guarantees
- Idempotency: server upserts derived documents; client retries are safe.
- Concurrency: duplicate sessions are auto-resolved on create.
- Durability: high-frequency writes go to subcollections; headers remain cool.
- Partial outages: dashboard remains responsive via `sos_pings`, even if locations are high-churn.

## Versioning
- v1.0 (2025-10-28): Initial contract. Changes require backward-compatible additions or a new versioned path.
