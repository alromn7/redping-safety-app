/**
 * Fix SAR Entitlement for Pro User
 * 
 * This script manually adds feature_sar_basic to the Pro user's entitlements
 * Run: node fix_sar_entitlement.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials
// Run: $env:GOOGLE_APPLICATION_CREDENTIALS="path\to\serviceAccountKey.json" first
admin.initializeApp();

const db = admin.firestore();

const USER_ID = 'l9NlaE1c66MueSvPd2Fj4QhBUNs2';

async function fixSAREntitlement() {
  console.log('🔧 SAR Entitlement Fix Tool');
  console.log('===========================\n');

  try {
    // Get user document
    const userRef = db.collection('users').doc(USER_ID);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error('❌ User document not found!');
      process.exit(1);
    }

    const data = userDoc.data();
    console.log('✅ User document found');
    console.log(`   Tier: ${data.subscription?.tier || 'NULL'}`);
    console.log(`   Status: ${data.subscription?.status || 'NULL'}\n`);

    // Check current entitlements
    const currentFeatures = data.entitlements?.features || [];
    console.log('📦 Current Features:');
    currentFeatures.forEach(f => console.log(`   • ${f}`));
    console.log('');

    // Pro tier should have these features
    const proFeatures = [
      'feature_sos_call',
      'feature_hazard_alerts',
      'feature_ai_assistant',
      'feature_gadgets',
      'feature_redping_mode',
      'feature_sar_basic'
    ];

    // Check if feature_sar_basic is missing
    if (currentFeatures.includes('feature_sar_basic')) {
      console.log('✅ feature_sar_basic already present!');
      console.log('   SAR dashboard should be accessible.');
      console.log('   If not, restart the app to reload entitlements.');
      process.exit(0);
    }

    // Add missing features
    const missingFeatures = proFeatures.filter(f => !currentFeatures.includes(f));
    
    if (missingFeatures.length === 0) {
      console.log('✅ All Pro features already present!');
      process.exit(0);
    }

    console.log('❌ Missing features detected:');
    missingFeatures.forEach(f => console.log(`   • ${f}`));
    console.log('');

    console.log('🔧 Updating entitlements...');
    
    // Merge missing features with current ones
    const updatedFeatures = [...new Set([...currentFeatures, ...proFeatures])];

    await userRef.update({
      'entitlements.features': updatedFeatures,
      'entitlements.updatedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Entitlements updated successfully!');
    console.log('');
    console.log('📦 New Features:');
    updatedFeatures.forEach(f => {
      const isNew = !currentFeatures.includes(f);
      const prefix = isNew ? '   🆕' : '   •';
      console.log(`${prefix} ${f}`);
    });
    console.log('');
    console.log('🎯 Action Required:');
    console.log('   1. Restart the RedPing app');
    console.log('   2. Navigate to SAR Dashboard');
    console.log('   3. Should now have full access!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

fixSAREntitlement();
