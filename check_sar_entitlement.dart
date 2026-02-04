import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Check SAR entitlement for Pro subscription user
/// This script verifies if the user has feature_sar_basic in their entitlements
void main() async {
  print('🔍 SAR Entitlement Checker');
  print('==========================\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final userId = 'l9NlaE1c66MueSvPd2Fj4QhBUNs2';
  print('📋 Checking user: $userId\n');

  final firestore = FirebaseFirestore.instance;

  try {
    // Get user document
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      print('❌ User document does not exist!');
      exit(1);
    }

    final data = userDoc.data();
    print('✅ User document found\n');

    // Check subscription info
    print('📦 SUBSCRIPTION INFO:');
    final subscriptionId = data?['subscription']?['subscriptionId'];
    final tier = data?['subscription']?['tier'];
    final status = data?['subscription']?['status'];
    final planId = data?['subscription']?['planId'];

    print('  Subscription ID: ${subscriptionId ?? "NULL"}');
    print('  Tier: ${tier ?? "NULL"}');
    print('  Status: ${status ?? "NULL"}');
    print('  Plan ID: ${planId ?? "NULL"}');
    print('');

    // Check entitlements
    print('🎫 ENTITLEMENTS:');
    final entitlements = data?['entitlements'];

    if (entitlements == null) {
      print('  ❌ NO ENTITLEMENTS FOUND!');
      print(
        '  This is the problem - Cloud Function did not write entitlements',
      );
      print('');
      _printSolution();
      exit(1);
    }

    final features = entitlements['features'] as List<dynamic>?;

    if (features == null || features.isEmpty) {
      print('  ❌ Features array is empty!');
      print('');
      _printSolution();
      exit(1);
    }

    print('  Features (${features.length}):');
    for (final feature in features) {
      final isSAR = feature.toString().contains('sar');
      final prefix = isSAR ? '  🎯' : '  •';
      print('$prefix $feature');
    }
    print('');

    // Check for SAR features specifically
    final hasBasicSAR = features.contains('feature_sar_basic');
    final hasAdvancedSAR = features.contains('feature_sar_advanced');

    print('🔍 SAR FEATURE CHECK:');
    print('  feature_sar_basic: ${hasBasicSAR ? "✅ PRESENT" : "❌ MISSING"}');
    print(
      '  feature_sar_advanced: ${hasAdvancedSAR ? "✅ PRESENT" : "❌ MISSING (OK for Pro)"}',
    );
    print('');

    if (!hasBasicSAR) {
      print('❌ PROBLEM IDENTIFIED:');
      print('   Your Pro subscription does NOT have feature_sar_basic!');
      print('');
      _printSolution();
      exit(1);
    }

    print('✅ SUCCESS: SAR entitlement is properly configured!');
    print('');
    print('If SAR dashboard still not accessible, check:');
    print('  1. App restarted after subscription?');
    print('  2. EntitlementService initialized?');
    print('  3. Stripe webhook processed successfully?');
  } catch (e) {
    print('❌ Error checking entitlements: $e');
    exit(1);
  }

  exit(0);
}

void _printSolution() {
  print('💡 SOLUTION:');
  print('');
  print('Option 1: Re-process subscription payment');
  print('  The Cloud Function should write entitlements automatically');
  print('  Check Firebase logs for webhook/payment processing errors');
  print('');
  print('Option 2: Manually fix entitlements in Firestore');
  print('  Run this Firestore update:');
  print('  ```');
  print('  users/l9NlaE1c66MueSvPd2Fj4QhBUNs2');
  print('  {');
  print('    entitlements: {');
  print('      features: [');
  print('        "feature_sos_call",');
  print('        "feature_hazard_alerts",');
  print('        "feature_ai_assistant",');
  print('        "feature_gadgets",');
  print('        "feature_redping_mode",');
  print('        "feature_sar_basic"');
  print('      ]');
  print('    }');
  print('  }');
  print('  ```');
  print('');
  print('Expected Pro tier features:');
  print('  • feature_sos_call');
  print('  • feature_hazard_alerts');
  print('  • feature_ai_assistant');
  print('  • feature_gadgets');
  print('  • feature_redping_mode');
  print('  • feature_sar_basic ← MISSING');
}
