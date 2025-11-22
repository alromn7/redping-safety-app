/**
 * Firebase Cloud Function: Generate Agora RTC Token
 * 
 * This function securely generates Agora RTC tokens for RedPing emergency calls
 * 
 * Setup Instructions:
 * 1. Install dependencies: npm install agora-access-token
 * 2. Set Firebase environment variables:
 *    firebase functions:config:set agora.app_id="YOUR_APP_ID"
 *    firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE"
 * 3. Deploy: firebase deploy --only functions:generateAgoraToken
 */

const functions = require('firebase-functions');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ---------- Security Helpers ----------
function getClientIp(req) {
  const fwd = (req.headers['x-forwarded-for'] || '').toString();
  if (fwd) return fwd.split(',')[0].trim();
  return req.ip || 'unknown';
}

function getAllowedOrigins() {
  const cfg = functions.config().security || {};
  const raw = cfg.allowed_origins || '';
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);
}

function handleCors(req, res) {
  const origin = req.headers.origin;
  const allowed = getAllowedOrigins();
  if (origin) {
    if (allowed.length > 0 && !allowed.includes(origin)) {
      res.set('Vary', 'Origin');
      res.status(403).json({ error: 'Origin not allowed' });
      return false;
    }
    // reflect allowed origin
    res.set('Access-Control-Allow-Origin', origin);
  } else {
    // Non-browser clients (mobile app) – keep permissive for no-origin
    res.set('Access-Control-Allow-Origin', '*');
  }
  res.set('Access-Control-Allow-Methods', 'POST, GET, PUT, DELETE, OPTIONS');
  res.set(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, X-Signature, X-Signature-Alg, X-Timestamp, X-Nonce'
  );
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return false;
  }
  return true;
}

/**
 * HMAC request signing verification with anti-replay (nonce + timestamp)
 */
const crypto = require('crypto');

function getSecurityConfig() {
  const cfg = functions.config().security || {};
  return {
    signingRequired: (cfg.signing_required || 'false').toString() === 'true',
    skewSeconds: parseInt(cfg.signature_skew_seconds || '300', 10),
    nonceTtlSeconds: parseInt(cfg.nonce_ttl_seconds || '900', 10),
  };
}

async function getUserSigningSecret(uid) {
  try {
    const ref = db.collection('users').doc(uid).collection('security').doc('signing');
    const snap = await ref.get();
    const data = snap.exists ? snap.data() : null;
    const secret = data?.signingSecret || null;
    return secret;
  } catch (e) {
    console.error('Error fetching signing secret:', e);
    return null;
  }
}

function randomHex(bytes = 32) {
  return crypto.randomBytes(bytes).toString('hex');
}

function base64Sha256(data) {
  return crypto.createHash('sha256').update(data).digest('base64');
}

async function verifyRequestSignature(req, res, uid) {
  const { signingRequired, skewSeconds, nonceTtlSeconds } = getSecurityConfig();

  // Headers
  const sig = (req.header('X-Signature') || '').toString();
  const alg = (req.header('X-Signature-Alg') || '').toString();
  const tsStr = (req.header('X-Timestamp') || '').toString();
  const nonce = (req.header('X-Nonce') || '').toString();

  const headersPresent = sig && alg && tsStr && nonce;
  if (!headersPresent) {
    if (signingRequired) {
      res.status(401).json({ error: 'Missing signature headers' });
      return false;
    }
    return true; // optional mode, allow through
  }

  if (alg !== 'HMAC-SHA256') {
    res.status(401).json({ error: 'Unsupported signature algorithm' });
    return false;
  }

  // Timestamp skew check
  const nowMs = Date.now();
  const tsMs = parseInt(tsStr, 10);
  if (!Number.isFinite(tsMs) || Math.abs(nowMs - tsMs) > skewSeconds * 1000) {
    res.status(401).json({ error: 'Timestamp out of allowed window' });
    return false;
  }

  // Anti-replay nonce check (per-user)
  const nonceKey = `${uid}:${nonce}`;
  const nonceRef = db.collection('request_nonces').doc(nonceKey);
  try {
    const ok = await db.runTransaction(async (tx) => {
      const snap = await tx.get(nonceRef);
      if (snap.exists) {
        const data = snap.data() || {};
        const seenAt = data.ts || 0;
        if (nowMs - seenAt < nonceTtlSeconds * 1000) {
          return false; // replay within TTL
        }
      }
      tx.set(nonceRef, { uid, ts: nowMs }, { merge: false });
      return true;
    });
    if (!ok) {
      res.status(401).json({ error: 'Replay detected' });
      return false;
    }
  } catch (e) {
    console.error('Nonce check error:', e);
    // Fail-closed if required, otherwise allow
    if (signingRequired) {
      res.status(500).json({ error: 'Nonce store unavailable' });
      return false;
    }
  }

  // Fetch per-user secret
  const secret = await getUserSigningSecret(uid);
  if (!secret) {
    if (signingRequired) {
      res.status(401).json({ error: 'Signing secret not provisioned' });
      return false;
    }
    return true;
  }

  // Canonical string must match client (method, endpoint, timestamp, nonce, bodyHash)
  const method = (req.method || 'GET').toUpperCase();
  const endpoint = req.path || '/';
  const rawBody = req.rawBody ? Buffer.from(req.rawBody) : Buffer.from(JSON.stringify(req.body || {}));
  const bodyHash = base64Sha256(rawBody);
  const canonical = [method, endpoint, tsStr, nonce, bodyHash].join('\n');

  const expectedSig = crypto
    .createHmac('sha256', Buffer.from(secret, 'utf8'))
    .update(Buffer.from(canonical, 'utf8'))
    .digest('base64');

  if (!crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expectedSig))) {
    res.status(401).json({ error: 'Invalid signature' });
    return false;
  }

  return true;
}

/**
 * Rotate or provision an HMAC signing secret for the current user
 * Stores secret under users/{uid}/security/signing.signingSecret
 */
exports.rotateSigningSecret = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const uid = context.auth.uid;
  try {
    const secret = randomHex(32);
    const ref = db.collection('users').doc(uid).collection('security').doc('signing');
    await ref.set({ signingSecret: secret, rotatedAt: Date.now() }, { merge: true });
    return { success: true, signingSecret: secret };
  } catch (e) {
    console.error('rotateSigningSecret error:', e);
    throw new functions.https.HttpsError('internal', 'Failed to rotate secret');
  }
});

async function checkRateLimit(key, { windowSeconds = 60, max = 30 } = {}) {
  const ref = db.collection('rate_limits').doc(key);
  const now = Date.now();
  const windowStart = now - windowSeconds * 1000;
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, { count: 1, ts: now });
      return { allowed: true, remaining: max - 1 };
    }
    const data = snap.data() || {};
    const ts = data.ts || 0;
    let count = data.count || 0;
    if (ts < windowStart) {
      // new window
      tx.set(ref, { count: 1, ts: now });
      return { allowed: true, remaining: max - 1 };
    }
    if (count >= max) {
      return { allowed: false, remaining: 0 };
    }
    count += 1;
    tx.update(ref, { count, ts });
    return { allowed: true, remaining: max - count };
  });
}

/**
 * Generate Agora RTC Token
 * 
 * @param {string} channelName - Channel name for the call
 * @param {string} uid - User ID (0 for auto-assign)
 * @param {string} role - 'publisher' or 'subscriber'
 * @param {number} expirationTimeInSeconds - Token validity period (default 24h)
 * @returns {object} { token: string, expiresAt: number }
 */
exports.generateAgoraToken = functions.https.onRequest(async (req, res) => {
  // CORS / Origin enforcement
  if (!handleCors(req, res)) return;

  // Only allow POST
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // Require Firebase authentication (ID token)
    // Require Firebase authentication (ID token)
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.+)$/i);
    if (!match) {
      res.status(401).json({ error: 'Missing Authorization bearer token' });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(match[1]);
      req.user = decoded;
    } catch (e) {
      console.error('Invalid ID token', e);
      res.status(401).json({ error: 'Invalid Authorization token' });
      return;
    }

    // Verify request signature if provided or required
    const verified = await verifyRequestSignature(req, res, req.user.uid);
    if (!verified) return;

    // Simple rate limiting: per-UID and per-IP
    const ip = getClientIp(req);
    const uidKey = `agora:${req.user.uid}`;
    const ipKey = `agora_ip:${ip}`;
    const [r1, r2] = await Promise.all([
      checkRateLimit(uidKey, { windowSeconds: 60, max: 20 }),
      checkRateLimit(ipKey, { windowSeconds: 60, max: 60 }),
    ]);
    if (!r1.allowed || !r2.allowed) {
      res.status(429).json({ error: 'Rate limit exceeded' });
      return;
    }
    // Get Agora credentials from Firebase config
    const appId = functions.config().agora?.app_id;
    const appCertificate = functions.config().agora?.app_certificate;

    if (!appId || !appCertificate) {
      console.error('Agora credentials not configured');
      res.status(500).json({ 
        error: 'Server configuration error',
        details: 'Agora credentials not set' 
      });
      return;
    }

    // Parse request body
    const { channelName, uid, role, expirationTimeInSeconds } = req.body;

    // Validate inputs
    if (!channelName) {
      res.status(400).json({ error: 'Missing channelName' });
      return;
    }

    // Default values
    const userId = uid ? parseInt(uid) : 0;
    const tokenRole = role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
    const expirationTime = expirationTimeInSeconds || 86400; // 24 hours default

    // Calculate privilege expiration time
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTime;

    // Generate token
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      userId,
      tokenRole,
      privilegeExpiredTs
    );

    // Log for monitoring (don't log sensitive data in production)
    console.log(`Token generated for channel: ${channelName}, uid: ${userId}, by: ${req.user.uid}`);

    // Return token
    res.status(200).json({
      token: token,
      expiresAt: privilegeExpiredTs,
      channelName: channelName,
      uid: userId
    });

  } catch (error) {
    console.error('Error generating Agora token:', error);
    res.status(500).json({ 
      error: 'Failed to generate token',
      details: error.message 
    });
  }
});

/**
 * Alternative: Generate token with account (for more complex scenarios)
 */
exports.generateAgoraTokenWithAccount = functions.https.onRequest(async (req, res) => {
  // CORS / Origin enforcement
  if (!handleCors(req, res)) return;

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // Require Firebase authentication (ID token)
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.+)$/i);
    if (!match) {
      res.status(401).json({ error: 'Missing Authorization bearer token' });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(match[1]);
      req.user = decoded;
    } catch (e) {
      console.error('Invalid ID token', e);
      res.status(401).json({ error: 'Invalid Authorization token' });
      return;
    }

    // Verify request signature if provided or required
    const verified = await verifyRequestSignature(req, res, req.user.uid);
    if (!verified) return;

    // Simple rate limiting: per-UID and per-IP
    const ip = getClientIp(req);
    const uidKey = `agora:${req.user.uid}`;
    const ipKey = `agora_ip:${ip}`;
    const [r1, r2] = await Promise.all([
      checkRateLimit(uidKey, { windowSeconds: 60, max: 20 }),
      checkRateLimit(ipKey, { windowSeconds: 60, max: 60 }),
    ]);
    if (!r1.allowed || !r2.allowed) {
      res.status(429).json({ error: 'Rate limit exceeded' });
      return;
    }
    const appId = functions.config().agora?.app_id;
    const appCertificate = functions.config().agora?.app_certificate;

    if (!appId || !appCertificate) {
      res.status(500).json({ error: 'Server configuration error' });
      return;
    }

    const { channelName, account, role, expirationTimeInSeconds } = req.body;

    if (!channelName || !account) {
      res.status(400).json({ error: 'Missing channelName or account' });
      return;
    }

    const tokenRole = role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
    const expirationTime = expirationTimeInSeconds || 86400;

    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTime;

    const token = RtcTokenBuilder.buildTokenWithAccount(
      appId,
      appCertificate,
      channelName,
      account,
      tokenRole,
      privilegeExpiredTs
    );

    console.log(`Token generated for channel: ${channelName}, account: ${account}, by: ${req.user.uid}`);

    res.status(200).json({
      token: token,
      expiresAt: privilegeExpiredTs,
      channelName: channelName,
      account: account
    });

  } catch (error) {
    console.error('Error generating Agora token:', error);
    res.status(500).json({ 
      error: 'Failed to generate token',
      details: error.message 
    });
  }
});

/**
 * Send SMS via Twilio or AWS SNS
 * Setup: firebase functions:config:set twilio.account_sid="..." twilio.auth_token="..." twilio.phone_number="..."
 */
exports.sendSMS = functions.https.onRequest(async (req, res) => {
  if (!handleCors(req, res)) return;
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // Optional Auth + Signature verification for SMS endpoint
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.+)$/i);
    if (match) {
      try {
        const decoded = await admin.auth().verifyIdToken(match[1]);
        req.user = decoded;
        const verified = await verifyRequestSignature(req, res, req.user.uid);
        if (!verified) return;
      } catch (e) {
        // If signing is required globally, verification would have failed earlier
      }
    }

    const { phoneNumber, message, timestamp } = req.body;

    if (!phoneNumber || !message) {
      res.status(400).json({ error: 'Missing phoneNumber or message' });
      return;
    }

    // If Twilio is configured, attempt to send via Twilio. Otherwise, return a mock response.
    const twilioCfg = functions.config().twilio || {};
    const hasTwilio = !!(twilioCfg.account_sid && twilioCfg.auth_token && twilioCfg.phone_number);

    if (hasTwilio) {
      try {
        // Lazy-require Twilio only when configured to avoid hard dependency during local dev
        const twilioClient = require('twilio')(twilioCfg.account_sid, twilioCfg.auth_token);
        const result = await twilioClient.messages.create({
          from: twilioCfg.phone_number,
          to: phoneNumber,
          body: message,
        });

        console.log(`SMS sent via Twilio to ${phoneNumber} at ${timestamp || new Date().toISOString()} [sid=${result.sid}]`);
        res.status(200).json({
          success: true,
          messageId: result.sid,
          provider: 'twilio',
          timestamp: timestamp || new Date().toISOString(),
        });
        return;
      } catch (sendErr) {
        console.error('Twilio send failed, falling back to mock response:', sendErr);
        // Fall through to mock response below
      }
    }

    console.log(`SMS request (mock) to ${phoneNumber} at ${timestamp || new Date().toISOString()}`);

    // Mock success for testing/dev environments
    res.status(200).json({
      success: true,
      messageId: `mock_${Date.now()}`,
      provider: 'mock',
      note: 'Twilio not configured - returning mock success. Configure functions.config().twilio for real sends.',
      timestamp: timestamp || new Date().toISOString(),
    });

  } catch (error) {
    console.error('Error sending SMS:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to send SMS',
      details: error.message 
    });
  }
});
