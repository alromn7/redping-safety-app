import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// EntitlementService reads the user's feature entitlements from Firestore
/// and exposes a simple `hasFeature` gate.
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  // Entitlement/subscription gating is disabled in this app build.
  // Keep the service for future re-enablement without deleting code.
  static const bool enforceEntitlements = false;

  final _featuresController = StreamController<Set<String>>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// Current feature IDs
  Set<String> _features = const {};

  /// Start listening to entitlements for the given user id.
  void start(String userId) {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          final data = doc.data();
          final List<dynamic>? list =
              data?['entitlements']?['features'] as List<dynamic>?;
          _features = list == null
              ? const {}
              : list.whereType<String>().toSet();
          _featuresController.add(_features);
        });
  }

  /// Stop listening.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Stream of current features.
  Stream<Set<String>> get featuresStream => _featuresController.stream;

  /// Synchronous check for a feature id.
  bool hasFeature(String featureId) {
    if (!enforceEntitlements) return true;
    return _features.contains(featureId);
  }
}
