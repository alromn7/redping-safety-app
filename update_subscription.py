#!/usr/bin/env python3
"""Update user subscription in Firestore - for testing only"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Find user by email
print('🔧 Updating subscription for alromn@yahoo.com...')

# Query users collection
users_ref = db.collection('users')
query = users_ref.where('email', '==', 'alromn@yahoo.com').limit(1)
results = query.get()

if not results:
    print('❌ User not found with email: alromn@yahoo.com')
    print('💡 Make sure the user has signed up in the app first')
    exit(1)

user_doc = results[0]
user_id = user_doc.id
user_data = user_doc.to_dict()
print(f"✅ Found user: {user_data.get('displayName', 'Unknown')} (ID: {user_id})")

# Update subscription to Pro tier
now = datetime.now()
trial_end = now + timedelta(days=14)
next_billing = now + timedelta(days=30)

subscription_data = {
    'subscription': {
        'tier': 'pro',
        'status': 'active',
        'startDate': firestore.SERVER_TIMESTAMP,
        'trialEndDate': trial_end,
        'nextBillingDate': next_billing,
        'billingCycle': 'monthly',
        'stripeCustomerId': f'test_customer_{user_id}',
        'stripeSubscriptionId': f'test_sub_{user_id}',
        'cancelAtPeriodEnd': False,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
}

users_ref.document(user_id).update(subscription_data)

print('✅ Successfully updated subscription!')
print('📊 New subscription details:')
print('   Tier: Pro')
print('   Status: Active')
print(f'   Trial End: {trial_end.strftime("%Y-%m-%d %H:%M:%S")}')
print(f'   Next Billing: {next_billing.strftime("%Y-%m-%d %H:%M:%S")}')
print('🎉 alromn@yahoo.com now has Pro access!')
print('💡 Restart the app to see the changes')
