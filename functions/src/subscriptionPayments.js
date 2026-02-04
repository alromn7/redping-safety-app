/**
 * Firebase Cloud Functions v2 for RedPing Subscription Payment Processing
 * 
 * IMPORTANT: Environment variables are configured in functions/.env
 * 
 * Required variables:
 * - STRIPE_SECRET_KEY (sk_test_... or sk_live_...)
 * - STRIPE_WEBHOOK_SECRET (whsec_...)
 * - STRIPE_PUBLISHABLE_KEY (pk_test_... or pk_live_...)
 * 
 * The .env file is automatically loaded by Firebase Functions v2.
 * Never commit .env to version control - it's in .gitignore.
 */

const {onCall, onRequest, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize Firebase Admin (use try-catch like other v2 functions)
try { admin.initializeApp(); } catch (e) { /* Already initialized */ }

const db = admin.firestore();

// Lazy Stripe initialization to avoid blocking container startup
let stripeInstance = null;
function getStripe() {
  if (!stripeInstance) {
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
      throw new Error('STRIPE_SECRET_KEY environment variable is required');
    }
    stripeInstance = require('stripe')(stripeKey);
  }
  return stripeInstance;
}

// Utility: sleep for ms
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// Decide if an error is transient and worth retrying
function isTransientStripeError(err) {
  if (!err) return false;
  // Stripe error object fields vary; use conservative matching
  const transientTypes = ['api_connection_error', 'rate_limit_error', 'idempotency_error'];
  if (transientTypes.includes(err.type)) return true;
  const transientCodes = ['lock_timeout', 'rate_limit'];
  if (transientCodes.includes(err.code)) return true;
  // 5xx from Stripe
  if (err.statusCode && err.statusCode >= 500) return true;
  return false;
}

// Create subscription with retry + idempotency
async function createSubscriptionWithRetry({customerId, items, paymentMethodId, metadata, maxAttempts = 3, requestId}) {
  let attempt = 0; let lastErr;
  while (attempt < maxAttempts) {
    attempt++;
    const idempotencyKey = `${requestId}_subcreate_${attempt}`;
    try {
      console.log(`Attempt ${attempt}/${maxAttempts} creating subscription (idempotencyKey=${idempotencyKey})`);
      const sub = await getStripe().subscriptions.create({
        customer: customerId,
        items,
        default_payment_method: paymentMethodId,
        expand: ['latest_invoice.payment_intent'],
        metadata,
      }, { idempotencyKey });
      return { subscription: sub, attempt }; 
    } catch (err) {
      lastErr = err;
      const transient = isTransientStripeError(err);
      console.warn(`Subscription create failed (attempt=${attempt}, transient=${transient}):`, err.message);
      if (!transient || attempt >= maxAttempts) break;
      await sleep(500 * attempt); // backoff
    }
  }
  throw lastErr;
}

/**
 * Subscription Price IDs (configured in Stripe Dashboard)
 * 
 * PRODUCTION DEPLOYMENT NOTES:
 * - Monthly prices are LIVE and working (price_1SVj...)
 * - Yearly prices are PLACEHOLDERS - must be created in Stripe Dashboard
 * 
 * TO CREATE YEARLY PRICES:
 * 1. Go to Stripe Dashboard → Products
 * 2. For each product (Essential+, Pro, Ultra, Family):
 *    a. Click "Add another price"
 *    b. Set billing period to "Yearly"
 *    c. Set amount: Essential+ $49.99, Pro $99.99, Ultra $299.99, Family $199.99
 *    d. Copy the new Price ID (starts with price_...)
 * 3. Update the PRICE_IDS below with real yearly price IDs
 * 4. Run: firebase deploy --only functions:processSubscriptionPayment
 */
// LIVE price IDs (default)
const PRICE_IDS_LIVE = {
  essentialPlus: {
    monthly: 'price_1SYSJdPlurWsomXvLHqo1BQV', // LIVE RECURRING: Essential+ monthly
    yearly: 'price_1SYSKIPlurWsomXva4VUJL3b',  // LIVE RECURRING: Essential+ yearly
  },
  pro: {
    monthly: 'price_1SYSHUPlurWsomXvpIkKf7IZ', // LIVE RECURRING: Pro monthly
    yearly: 'price_1SYSI6PlurWsomXvJdn44f5k',  // LIVE RECURRING: Pro yearly
  },
  ultra: {
    monthly: 'price_1SYSAgPlurWsomXv5gYXx038', // LIVE RECURRING: Ultra monthly (base)
    yearly: 'price_1SYSDGPlurWsomXvpfBoxNmo',  // LIVE RECURRING: Ultra yearly (base)
    memberMonthly: 'REPLACE_WITH_MEMBER_PRICE_ID', // LIVE RECURRING: $5/month per member
    memberYearly: 'REPLACE_WITH_YEARLY_MEMBER_PRICE_ID', // LIVE RECURRING: $50/year per member
  },
  family: {
    monthly: 'price_1SYSEzPlurWsomXva7HWAETB', // LIVE RECURRING: Family monthly
    yearly: 'price_1SYSGBPlurWsomXvzv7yrZat',  // LIVE RECURRING: Family yearly
  },
};

// TEST price IDs (placeholders) – set via STRIPE_PRICE_IDS_JSON in .env for real IDs
const PRICE_IDS_TEST = {
  essentialPlus: { monthly: 'price_test_essential_monthly', yearly: 'price_test_essential_yearly' },
  pro: { monthly: 'price_test_pro_monthly', yearly: 'price_test_pro_yearly' },
  ultra: { monthly: 'price_test_ultra_monthly', yearly: 'price_test_ultra_yearly', memberMonthly: 'price_test_ultra_member_monthly', memberYearly: 'price_test_ultra_member_yearly' },
  family: { monthly: 'price_test_family_monthly', yearly: 'price_test_family_yearly' },
};

function getConfiguredPriceIds() {
  // Highest priority: explicit JSON override from environment
  if (process.env.STRIPE_PRICE_IDS_JSON) {
    try {
      const parsed = JSON.parse(process.env.STRIPE_PRICE_IDS_JSON);
      return parsed;
    } catch (e) {
      console.warn('Invalid STRIPE_PRICE_IDS_JSON; falling back to defaults:', e.message);
    }
  }
  const sk = process.env.STRIPE_SECRET_KEY || '';
  const isTest = sk.startsWith('sk_test_');
  return isTest ? PRICE_IDS_TEST : PRICE_IDS_LIVE;
}

/**
 * Get or create Stripe customer for user
 */
async function getOrCreateStripeCustomer(userId, email, name) {
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  // Check if customer already exists
  if (userData?.stripeCustomerId) {
    return await getStripe().customers.retrieve(userData.stripeCustomerId);
  }

  // Create new customer
  const customer = await getStripe().customers.create({
    email: email,
    name: name,
    metadata: {
      firebaseUserId: userId,
    },
  });

  // Save customer ID to Firestore
  await db.collection('users').doc(userId).set({
    stripeCustomerId: customer.id,
  }, { merge: true });

  return customer;
}

/**
 * Get Stripe Price ID for tier and billing period
 */
function getPriceId(tier, isYearly) {
  const billingPeriod = isYearly ? 'yearly' : 'monthly';
  const ids = getConfiguredPriceIds();
  return ids[tier]?.[billingPeriod];
}

// Feature catalog (client entitlement IDs)
const FEATURES = {
  sosCall: 'feature_sos_call',
  hazardAlerts: 'feature_hazard_alerts',
  aiAssistant: 'feature_ai_assistant',
  gadgets: 'feature_gadgets',
  redpingMode: 'feature_redping_mode',
  familyCheckIn: 'feature_family_check_in',
  findMyGadget: 'feature_find_my_gadget',
  sarBasic: 'feature_sar_basic',
  sarAdvanced: 'feature_sar_advanced',
  familyDashboard: 'feature_family_dashboard',
};

// Tier → features mapping (aligned with COMPREHENSIVE_SUBSCRIPTION_BLUEPRINT.md)
const TIER_FEATURES = {
  // Free: All core features (RedPing Help, Community, Quick Call, Map, Manual SOS)
  // No entitlements needed - these are baseline features available to all
  free: [FEATURES.sosCall],
  
  // Essential+ ($4.99): Free + Medical + ACFD + Hazard + SMS
  essentialPlus: [
    FEATURES.sosCall,
    FEATURES.hazardAlerts,
    // Medical Profile, ACFD, SOS SMS are controlled via subscription limits, not entitlements
  ],
  
  // Pro ($9.99): Essential+ + RedPing Mode + AI + Gadgets + SAR Dashboard
  pro: [
    FEATURES.sosCall,
    FEATURES.hazardAlerts,
    FEATURES.aiAssistant,
    FEATURES.gadgets,
    FEATURES.redpingMode,
    FEATURES.sarBasic,  // Full SAR Dashboard Access
  ],
  
  // Ultra ($29.99 + $5/member): Pro + SAR Admin Management
  ultra: [
    FEATURES.sosCall,
    FEATURES.hazardAlerts,
    FEATURES.aiAssistant,
    FEATURES.gadgets,
    FEATURES.redpingMode,
    FEATURES.sarBasic,
    FEATURES.sarAdvanced,  // SAR Admin Management
  ],
  
  // Family ($19.99): 1 Pro account + 3 Essential+ accounts
  // Pro account gets Pro features, Essential+ accounts get Essential+ features
  family: [
    FEATURES.sosCall,
    FEATURES.hazardAlerts,
    FEATURES.aiAssistant,  // Pro account only
    FEATURES.gadgets,  // Pro account only
    FEATURES.redpingMode,  // Pro account only
    FEATURES.sarBasic,  // Pro account only
    FEATURES.familyCheckIn,
    FEATURES.findMyGadget,
    FEATURES.familyDashboard,
  ],
};

function getFeaturesForTier(tier) {
  return TIER_FEATURES[tier] || [];
}

/**
 * Process Subscription Payment
 * Creates or updates a Stripe subscription
 */
exports.processSubscriptionPayment = onCall({ region: 'us-central1' }, async (request) => {
  // Verify authentication
  console.log('Auth context:', request.auth ? 'Present' : 'MISSING');
  console.log('Auth UID:', request.auth?.uid);
  console.log('Request data:', JSON.stringify(request.data));
  const sk = process.env.STRIPE_SECRET_KEY || '';
  console.log('Stripe mode:', sk.startsWith('sk_test_') ? 'TEST' : 'LIVE');
  console.log('Using PRICE IDS:', JSON.stringify(getConfiguredPriceIds()));
  // Correlation / tracing ID for this subscription request
  const requestId = `subreq_${Date.now()}_${Math.random().toString(36).slice(2,8)}`;
  console.log('Correlation RequestId:', requestId);
  
  if (!request.auth) {
    console.error('Authentication failed - no auth context');
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, tier, isYearly, isYearlyBilling, paymentMethodId, savePaymentMethod, additionalMembers } = request.data;
  // Handle both parameter names (app sends isYearlyBilling, but we also support isYearly)
  // Default to false if both are undefined to prevent Firestore errors
  const isYearlyParam = isYearly !== undefined ? isYearly : (isYearlyBilling !== undefined ? isYearlyBilling : false);

  // Persist an initial correlation record before Stripe operations begin
  try {
    await db.collection('users').doc(userId).collection('subscriptionRequests').add({
      requestId,
      stage: 'received',
      tier,
      isYearly: isYearlyParam,
      additionalMembers: additionalMembers || 0,
      createdAt: admin.firestore.Timestamp.now(),
      authUid: request.auth.uid,
    });
  } catch (logErr) {
    console.warn('WARN: Failed to log initial subscription request record:', logErr.message);
  }

  try {
    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const email = userData.email || request.auth.token.email;
    const name = userData.displayName || request.auth.token.name;

    // Get or create Stripe customer
    const customer = await getOrCreateStripeCustomer(userId, email, name);

    // Attach payment method to customer
    await getStripe().paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });

    // Set as default payment method if requested
    if (savePaymentMethod) {
      await getStripe().customers.update(customer.id, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });
    }

    // Get price ID
    const priceId = getPriceId(tier, isYearlyParam);
    console.log(`DEBUG: tier="${tier}", isYearlyBilling=${isYearlyBilling}, isYearly=${isYearly}, resolved=${isYearlyParam}, priceId="${priceId}"`);
    console.log('DEBUG: EFFECTIVE_PRICE_IDS:', JSON.stringify(getConfiguredPriceIds(), null, 2));
    if (!priceId) {
      throw new HttpsError(
        'invalid-argument',
        'Invalid subscription tier'
      );
    }

    // Sanity check the Stripe Price object before creating subscription
    try {
      const priceObj = await getStripe().prices.retrieve(priceId);
      console.log('DEBUG: Stripe Price Lookup:', JSON.stringify({
        id: priceObj.id,
        type: priceObj.type,
        currency: priceObj.currency,
        recurring: priceObj.recurring,
        active: priceObj.active,
        nickname: priceObj.nickname,
        product: priceObj.product,
        livemode: priceObj.livemode,
      }, null, 2));

      if (priceObj.type !== 'recurring') {
        throw new HttpsError(
          'failed-precondition',
          `Configured price ${priceObj.id} is type=${priceObj.type}, expected recurring`
        );
      }
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.warn('WARN: Could not verify price object before subscription:', e.message || e);
    }

    // Check for existing subscription
    const existingSubscriptionId = userData.subscription?.stripeSubscriptionId;
    let subscription;
    
    // If there's an existing subscription, cancel it to start fresh
    // This ensures we don't have any old one-time prices causing issues
    if (existingSubscriptionId) {
      try {
        console.log('🔥 Canceling existing subscription:', existingSubscriptionId);
        await getStripe().subscriptions.cancel(existingSubscriptionId);
        console.log('✅ Old subscription canceled successfully');
      } catch (error) {
        console.warn('⚠️ Could not cancel old subscription (may not exist):', error.message);
      }
    }

    // Build subscription items array
    const subscriptionItems = [{ price: priceId }];
    
    // For Ultra tier, add additional member pricing if applicable
    if (tier === 'ultra' && additionalMembers && additionalMembers > 0) {
      const ids = getConfiguredPriceIds();
      const memberPriceId = isYearlyParam ? ids.ultra?.memberYearly : ids.ultra?.memberMonthly;
      if (memberPriceId && !memberPriceId.startsWith('REPLACE_WITH')) {
        subscriptionItems.push({
          price: memberPriceId,
          quantity: additionalMembers,
        });
        console.log(`Ultra tier: Adding ${additionalMembers} additional members using member price ${memberPriceId}`);
      } else {
        console.warn('Ultra member pricing skipped: placeholder or missing member price ID.');
      }
    }

    // Always create a fresh subscription (old one already canceled above)
    console.log('🔥 CREATING SUBSCRIPTION with items:', JSON.stringify(subscriptionItems, null, 2));
    console.log('🔥 Price IDs being sent to Stripe:', subscriptionItems.map(item => item.price).join(', '));
    const createResult = await createSubscriptionWithRetry({
      customerId: customer.id,
      items: subscriptionItems,
      paymentMethodId,
      metadata: {
        firebaseUserId: userId,
        tier: tier,
        billingPeriod: isYearlyParam ? 'yearly' : 'monthly',
        additionalMembers: additionalMembers || 0,
        requestId,
        // placeholder; will update subscriptionData with real attempts below
        retryAttempts: 0,
      },
      maxAttempts: 3,
      requestId,
    });
    subscription = createResult.subscription;
    console.log(`Subscription created after attempts: ${createResult.attempt}`);

    // Update Firestore with subscription data
    const now = admin.firestore.Timestamp.now();
    const renewalDate = admin.firestore.Timestamp.fromDate(
      new Date(subscription.current_period_end * 1000)
    );

    // Build subscription data (ensure all fields are defined - no undefined values for Firestore)
    const subscriptionData = {
      tier: tier,
      stripeSubscriptionId: subscription.id,
      stripeCustomerId: customer.id,
      status: subscription.status,
      currentPeriodStart: admin.firestore.Timestamp.fromDate(
        new Date(subscription.current_period_start * 1000)
      ),
      currentPeriodEnd: renewalDate,
      isYearlyBilling: isYearlyParam || false, // Ensure boolean, never undefined
      isActive: subscription.status === 'active',
      autoRenew: !subscription.cancel_at_period_end,
      updatedAt: now,
      requestId: requestId || '',
      retryAttempts: (createResult.attempt - 1) || 0,
    };

    // Add member count for Ultra tier
    if (tier === 'ultra') {
      subscriptionData.additionalMembers = additionalMembers || 0;
      subscriptionData.totalMembers = (additionalMembers || 0) + 1; // +1 for admin
    }

    await db.collection('users').doc(userId).set({
      subscription: subscriptionData,
      entitlements: {
        features: getFeaturesForTier(tier),
        updatedAt: now,
      },
    }, { merge: true });

    // Log transaction
    await db.collection('users').doc(userId).collection('transactions').add({
      type: 'subscription_payment',
      tier: tier,
      amount: subscription.latest_invoice?.amount_paid / 100 || 0,
      currency: 'aud',
      status: 'succeeded',
      stripeSubscriptionId: subscription.id,
      stripeInvoiceId: subscription.latest_invoice?.id,
      createdAt: now,
      requestId,
    });

    // Update correlation record with success details
    try {
      await db.collection('users').doc(userId).collection('subscriptionRequests').add({
        requestId,
        stage: 'completed',
        stripeSubscriptionId: subscription.id,
        stripeCustomerId: customer.id,
        status: subscription.status,
        completedAt: now,
      });
    } catch (logErr) {
      console.warn('WARN: Failed to log completion record:', logErr.message);
    }

    return {
      success: true,
      subscriptionId: subscription.id,
      status: subscription.status,
      currentPeriodEnd: subscription.current_period_end,
    };
  } catch (error) {
    console.error('Error processing subscription payment:', error);
    
    // Log failed transaction
    await db.collection('users').doc(userId).collection('transactions').add({
      type: 'subscription_payment',
      tier: tier,
      status: 'failed',
      error: error.message,
      createdAt: admin.firestore.Timestamp.now(),
      requestId,
    });

    // Correlation failure record
    try {
      await db.collection('users').doc(userId).collection('subscriptionRequests').add({
        requestId,
        stage: 'failed',
        error: error.message,
        failedAt: admin.firestore.Timestamp.now(),
      });
    } catch (logErr) {
      console.warn('WARN: Failed to log failure correlation record:', logErr.message);
    }

    throw new HttpsError('internal', error.message);
  }
});

/**
 * Cancel Subscription
 * Cancels subscription at period end
 */
exports.cancelSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, subscriptionId } = request.data;

  try {
    // Cancel subscription at period end
    const subscription = await getStripe().subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    // Update Firestore
    await db.collection('users').doc(userId).set({
      subscription: {
        autoRenew: false,
        cancelledAt: admin.firestore.Timestamp.now(),
      },
    }, { merge: true });

    return {
      success: true,
      cancelAt: subscription.cancel_at,
    };
  } catch (error) {
    console.error('Error cancelling subscription:', error);
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Update Payment Method
 * Updates default payment method for customer
 */
exports.updatePaymentMethod = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, paymentMethodId } = request.data;

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const customerId = userDoc.data()?.stripeCustomerId;

    if (!customerId) {
      throw new HttpsError(
        'not-found',
        'Stripe customer not found'
      );
    }

    // Attach new payment method
    await getStripe().paymentMethods.attach(paymentMethodId, {
      customer: customerId,
    });

    // Set as default
    await getStripe().customers.update(customerId, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating payment method:', error);
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Get Subscription Status
 * Retrieves current subscription status from Stripe
 */
exports.getSubscriptionStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId } = request.data;

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const subscriptionId = userDoc.data()?.subscription?.stripeSubscriptionId;

    if (!subscriptionId) {
      return { hasSubscription: false };
    }

    const subscription = await getStripe().subscriptions.retrieve(subscriptionId);

    return {
      hasSubscription: true,
      status: subscription.status,
      currentPeriodEnd: subscription.current_period_end,
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
    };
  } catch (error) {
    console.error('Error getting subscription status:', error);
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Stripe Webhook Handler
 * Handles Stripe webhook events for real-time updates
 */
exports.stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    throw new HttpsError('failed-precondition', 'STRIPE_WEBHOOK_SECRET not configured');
  }

  let event;

  try {
    event = getStripe().webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'invoice.payment_succeeded':
        await handleInvoicePaymentSucceeded(event.data.object);
        break;

      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).send('Webhook handler failed');
  }
});

/**
 * Handle successful invoice payment
 */
async function handleInvoicePaymentSucceeded(invoice) {
  const customerId = invoice.customer;
  const subscriptionId = invoice.subscription;

  // Find user by customer ID
  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.error('User not found for customer:', customerId);
    return;
  }

  const userId = usersSnapshot.docs[0].id;

  // Update subscription status
  await db.collection('users').doc(userId).set({
    subscription: {
      status: 'active',
      isActive: true,
      lastPaymentDate: admin.firestore.Timestamp.now(),
    },
    entitlements: {
      features: getFeaturesForTier(userId ? (await db.collection('users').doc(userId).get()).data()?.subscription?.tier : 'free'),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  }, { merge: true });

  // Log transaction
  await db.collection('users').doc(userId).collection('transactions').add({
    type: 'payment_succeeded',
    amount: invoice.amount_paid / 100,
    currency: invoice.currency,
    stripeInvoiceId: invoice.id,
    stripeSubscriptionId: subscriptionId,
    status: 'succeeded',
    createdAt: admin.firestore.Timestamp.now(),
  });
}

/**
 * Handle failed invoice payment
 */
async function handleInvoicePaymentFailed(invoice) {
  const customerId = invoice.customer;

  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) return;

  const userId = usersSnapshot.docs[0].id;

  // Update subscription status
  await db.collection('users').doc(userId).set({
    subscription: {
      status: 'past_due',
      paymentFailedAt: admin.firestore.Timestamp.now(),
    },
  }, { merge: true });

  // Log failed transaction
  await db.collection('users').doc(userId).collection('transactions').add({
    type: 'payment_failed',
    amount: invoice.amount_due / 100,
    currency: invoice.currency,
    stripeInvoiceId: invoice.id,
    status: 'failed',
    createdAt: admin.firestore.Timestamp.now(),
  });

  // TODO: Send notification to user about failed payment
}

/**
 * Handle subscription deletion
 */
async function handleSubscriptionDeleted(subscription) {
  const customerId = subscription.customer;

  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) return;

  const userId = usersSnapshot.docs[0].id;

  // Downgrade to free tier
  await db.collection('users').doc(userId).set({
    subscription: {
      tier: 'free',
      status: 'cancelled',
      isActive: false,
      cancelledAt: admin.firestore.Timestamp.now(),
    },
    entitlements: {
      features: getFeaturesForTier('free'),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  }, { merge: true });
}

/**
 * Handle subscription update
 */
async function handleSubscriptionUpdated(subscription) {
  const customerId = subscription.customer;

  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) return;

  const userId = usersSnapshot.docs[0].id;

  // Update subscription data
  await db.collection('users').doc(userId).set({
    subscription: {
      status: subscription.status,
      isActive: subscription.status === 'active',
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(
        new Date(subscription.current_period_end * 1000)
      ),
      autoRenew: !subscription.cancel_at_period_end,
    },
    entitlements: {
      features: getFeaturesForTier((await db.collection('users').doc(userId).get()).data()?.subscription?.tier || 'free'),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  }, { merge: true });
}

/**
 * Update SAR Member Count for Ultra Tier
 * Call this whenever members are added/removed
 */
exports.updateUltraMemberCount = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, memberCount } = request.data;

  // Validate user is admin/owner
  if (request.auth.uid !== userId) {
    throw new HttpsError('permission-denied', 'Not authorized');
  }

  try {
    // Get user's subscription
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const subscription = userData.subscription;

    if (!subscription || subscription.tier !== 'ultra') {
      throw new HttpsError('failed-precondition', 'User must have Ultra tier subscription');
    }

    const subscriptionId = subscription.stripeSubscriptionId;
    if (!subscriptionId) {
      throw new HttpsError('not-found', 'Subscription not found');
    }

    // Retrieve subscription from Stripe
    const stripeSubscription = await getStripe().subscriptions.retrieve(subscriptionId);
    
    // Calculate additional members (total - 1 for admin)
    const additionalMembers = Math.max(0, memberCount - 1);
    
    // Get member price ID
    const isYearly = subscription.isYearlyBilling || false;
    const ids = getConfiguredPriceIds();
    const memberPriceId = isYearly ? ids.ultra?.memberYearly : ids.ultra?.memberMonthly;

    if (!memberPriceId || memberPriceId.startsWith('REPLACE_WITH')) {
      throw new HttpsError('failed-precondition', 'Member pricing not configured');
    }

    // Find existing member item
    const memberItem = stripeSubscription.items.data.find(item => 
      item.price.id === getConfiguredPriceIds().ultra?.memberMonthly || 
      item.price.id === getConfiguredPriceIds().ultra?.memberYearly
    );

    // Update subscription items
    const itemsUpdate = [];

    if (additionalMembers > 0) {
      if (memberItem) {
        // Update existing member item quantity
        itemsUpdate.push({
          id: memberItem.id,
          quantity: additionalMembers,
        });
      } else {
        // Add new member item
        itemsUpdate.push({
          price: memberPriceId,
          quantity: additionalMembers,
        });
      }
    } else if (memberItem) {
      // Remove member item if no additional members
      itemsUpdate.push({
        id: memberItem.id,
        deleted: true,
      });
    }

    // Update Stripe subscription if changes needed
    if (itemsUpdate.length > 0) {
      await getStripe().subscriptions.update(subscriptionId, {
        items: itemsUpdate,
        proration_behavior: 'create_prorations', // Charge/credit immediately
      });

      console.log(`Updated Ultra subscription for user ${userId}: ${additionalMembers} additional members`);
    }

    // Update Firestore
    await db.collection('users').doc(userId).set({
      subscription: {
        additionalMembers: additionalMembers,
        totalMembers: memberCount,
        updatedAt: admin.firestore.Timestamp.now(),
      },
    }, { merge: true });

    return {
      success: true,
      memberCount: memberCount,
      additionalMembers: additionalMembers,
      monthlyTotal: subscription.isYearlyBilling 
        ? ((299.99 + (additionalMembers * 50)) / 12).toFixed(2)
        : (29.99 + (additionalMembers * 5)).toFixed(2),
    };
  } catch (error) {
    console.error('Error updating member count:', error);
    throw new HttpsError('internal', error.message);
  }
});
