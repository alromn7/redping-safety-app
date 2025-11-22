/**
 * Firebase Cloud Functions for RedPing Subscription Payment Processing
 * 
 * IMPORTANT: Set environment variables before deploying:
 * firebase functions:config:set stripe.secret_key="sk_test_..." stripe.webhook_secret="whsec_..."
 * 
 * For production:
 * firebase functions:config:set stripe.secret_key="sk_live_..." stripe.webhook_secret="whsec_..."
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Subscription Price IDs (configured in Stripe Dashboard)
 * Replace with your actual Stripe Price IDs
 */
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_1SVjOcPlurWsomXvo3cJ8YO9',
    yearly: 'price_xxxxx_essential_yearly',
  },
  pro: {
    monthly: 'price_1SVjOIPlurWsomXvOvgWfPFK',
    yearly: 'price_xxxxx_pro_yearly',
  },
  ultra: {
    monthly: 'price_1SVjNIPlurWsomXvMAxQouxd',
    yearly: 'price_xxxxx_ultra_yearly',
  },
  family: {
    monthly: 'price_1SVjO7PlurWsomXv9CCcDrGF',
    yearly: 'price_xxxxx_family_yearly',
  },
};

/**
 * Get or create Stripe customer for user
 */
async function getOrCreateStripeCustomer(userId, email, name) {
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  // Check if customer already exists
  if (userData?.stripeCustomerId) {
    return await stripe.customers.retrieve(userData.stripeCustomerId);
  }

  // Create new customer
  const customer = await stripe.customers.create({
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
  return PRICE_IDS[tier]?.[billingPeriod];
}

/**
 * Process Subscription Payment
 * Creates or updates a Stripe subscription
 */
exports.processSubscriptionPayment = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, tier, isYearly, paymentMethodId, savePaymentMethod } = data;

  try {
    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const email = userData.email || context.auth.token.email;
    const name = userData.displayName || context.auth.token.name;

    // Get or create Stripe customer
    const customer = await getOrCreateStripeCustomer(userId, email, name);

    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });

    // Set as default payment method if requested
    if (savePaymentMethod) {
      await stripe.customers.update(customer.id, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });
    }

    // Get price ID
    const priceId = getPriceId(tier, isYearly);
    if (!priceId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid subscription tier'
      );
    }

    // Check for existing subscription
    const existingSubscriptionId = userData.subscription?.stripeSubscriptionId;
    let subscription;

    if (existingSubscriptionId) {
      // Update existing subscription
      subscription = await stripe.subscriptions.retrieve(existingSubscriptionId);
      subscription = await stripe.subscriptions.update(existingSubscriptionId, {
        items: [{
          id: subscription.items.data[0].id,
          price: priceId,
        }],
        default_payment_method: paymentMethodId,
        proration_behavior: 'create_prorations',
      });
    } else {
      // Create new subscription
      subscription = await stripe.subscriptions.create({
        customer: customer.id,
        items: [{ price: priceId }],
        default_payment_method: paymentMethodId,
        expand: ['latest_invoice.payment_intent'],
        metadata: {
          firebaseUserId: userId,
          tier: tier,
          billingPeriod: isYearly ? 'yearly' : 'monthly',
        },
      });
    }

    // Update Firestore with subscription data
    const now = admin.firestore.Timestamp.now();
    const renewalDate = admin.firestore.Timestamp.fromDate(
      new Date(subscription.current_period_end * 1000)
    );

    await db.collection('users').doc(userId).set({
      subscription: {
        tier: tier,
        stripeSubscriptionId: subscription.id,
        stripeCustomerId: customer.id,
        status: subscription.status,
        currentPeriodStart: admin.firestore.Timestamp.fromDate(
          new Date(subscription.current_period_start * 1000)
        ),
        currentPeriodEnd: renewalDate,
        isYearlyBilling: isYearly,
        isActive: subscription.status === 'active',
        autoRenew: !subscription.cancel_at_period_end,
        updatedAt: now,
      },
    }, { merge: true });

    // Log transaction
    await db.collection('users').doc(userId).collection('transactions').add({
      type: 'subscription_payment',
      tier: tier,
      amount: subscription.latest_invoice?.amount_paid / 100 || 0,
      currency: 'usd',
      status: 'succeeded',
      stripeSubscriptionId: subscription.id,
      stripeInvoiceId: subscription.latest_invoice?.id,
      createdAt: now,
    });

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
    });

    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cancel Subscription
 * Cancels subscription at period end
 */
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, subscriptionId } = data;

  try {
    // Cancel subscription at period end
    const subscription = await stripe.subscriptions.update(subscriptionId, {
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
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Update Payment Method
 * Updates default payment method for customer
 */
exports.updatePaymentMethod = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, paymentMethodId } = data;

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const customerId = userDoc.data()?.stripeCustomerId;

    if (!customerId) {
      throw new functions.https.HttpsError(
        'not-found',
        'Stripe customer not found'
      );
    }

    // Attach new payment method
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customerId,
    });

    // Set as default
    await stripe.customers.update(customerId, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating payment method:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get Subscription Status
 * Retrieves current subscription status from Stripe
 */
exports.getSubscriptionStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId } = data;

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const subscriptionId = userDoc.data()?.subscription?.stripeSubscriptionId;

    if (!subscriptionId) {
      return { hasSubscription: false };
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);

    return {
      hasSubscription: true,
      status: subscription.status,
      currentPeriodEnd: subscription.current_period_end,
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
    };
  } catch (error) {
    console.error('Error getting subscription status:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Stripe Webhook Handler
 * Handles Stripe webhook events for real-time updates
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
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
  }, { merge: true });
}
