# Signing Fingerprints Archive

Maintain historical signing certificate fingerprints for auditing, rollback, and Play Console verification. Never remove old entries—append new rotations with date stamps.

## 2025-11-24 Rotation (Active)
- Alias: `redping-key`
- Distinguished Name (DN): `CN=Redping, O=Redping, L=City, ST=State, C=US`
- Key Algorithm: RSA 4096
- Validity: 3650 days (~10 years)
- SHA-256: `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`
- SHA-1: `406fc289d379cd0a22d7329a607abc7e91733b8a`

### Verification Commands
PowerShell (Windows):
```
& "C:\Users\$Env:USERNAME\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```
Expected output contains DN above and matching SHA-256.

### Usage
- Use SHA-1 when registering with Google Play Console or API integrations needing legacy fingerprint.
- Prefer SHA-256 for modern integrity checks.

### Rotation Procedure Summary
1. Backup previous keystore (auto `.bak` timestamp file).
2. Generate new keystore & passwords (stored only in secret manager).
3. Update `key.properties` or CI env vars.
4. Tag release and verify CN + fingerprint.
5. Append new entry here.

### Rollback Notes
To rollback: restore previous `.bak` keystore, adjust `key.properties`, rebuild, and verify old fingerprints before re‑tagging.

---
(End of archive)
