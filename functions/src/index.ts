/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions/v2/options";
export { onSosSessionWritten, onSosSessionCreated, onLocationPingCreated } from "./triggers/sosSessions";
export { createSosSession, createSosSessionAU, createSosSessionEU, createSosSessionAF, createSosSessionAS } from "./http/sos";
export { api } from "./http/api";
export { verifyIntegrity } from "./security/integrity";

// Import and export check-in related functions from JavaScript modules
const checkInNotificationsFns = require('../checkInNotifications');
const checkInExpiryFns = require('../checkInExpiry');
const resolutionNotesCleanupFns = require('../resolutionNotesCleanup');
const revokeCheckInFns = require('../revokeCheckInOnFamilyLeave');

export const checkInRequestCreated = checkInNotificationsFns.checkInRequestCreated;
export const checkInRequestUpdated = checkInNotificationsFns.checkInRequestUpdated;
export const expireCheckInRequests = checkInExpiryFns.expireCheckInRequests;
export const purgeOldCheckInRequests = checkInExpiryFns.purgeOldCheckInRequests;
export const cleanupResolutionNotes = resolutionNotesCleanupFns.cleanupResolutionNotes;
export const revokeCheckInOnFamilyLeave = revokeCheckInFns.revokeCheckInOnFamilyLeave;

// Stripe Payment Functions
const subscriptionPaymentsFns = require('./subscriptionPayments');
export const processSubscriptionPayment = subscriptionPaymentsFns.processSubscriptionPayment;
export const cancelSubscription = subscriptionPaymentsFns.cancelSubscription;
export const updatePaymentMethod = subscriptionPaymentsFns.updatePaymentMethod;
export const getSubscriptionStatus = subscriptionPaymentsFns.getSubscriptionStatus;
export const stripeWebhook = subscriptionPaymentsFns.stripeWebhook;

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// Global defaults (pin region to australia-southeast1)
setGlobalOptions({ region: "australia-southeast1", maxInstances: 10 });

// Region switch marker: deploying with FUNCTION_REGION can change regions without code edits.
// Last requested region: australia-southeast1 (2025-11-17) - redeploy to pick up config updates

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
