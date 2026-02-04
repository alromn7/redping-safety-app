import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../config/google_cloud_config.dart';
import '../../models/external_coverage.dart';

class ExternalCoverageService {
  final FirebaseFirestore _db;
  ExternalCoverageService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _db
      .collection(GoogleCloudConfig.firestoreCollectionUsers)
      .doc(userId)
      .collection('medical')
      .doc('external_coverage');

  Future<ExternalCoverageProfile> getOrCreate(String userId) async {
    if (userId.isEmpty) return ExternalCoverageProfile.initial(userId);
    try {
      final snap = await _doc(userId).get();
      if (snap.exists && snap.data() != null) {
        final data = Map<String, dynamic>.from(snap.data()!);
        data['userId'] = data['userId'] ?? userId;
        data['lastUpdated'] = _coerceNullableIsoString(data['lastUpdated']);
        return ExternalCoverageProfile.fromJson(data);
      }
      final initial = ExternalCoverageProfile.initial(userId);
      await save(initial);
      return initial;
    } catch (e) {
      debugPrint('ExternalCoverageService.getOrCreate error: $e');
      return ExternalCoverageProfile.initial(userId);
    }
  }

  Future<void> save(ExternalCoverageProfile profile) async {
    if (profile.userId.isEmpty) {
      throw ArgumentError('ExternalCoverageProfile.userId is required');
    }
    try {
      await _doc(profile.userId)
          .set(profile.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('ExternalCoverageService.save error: $e');
      rethrow;
    }
  }

  String? _coerceNullableIsoString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return null;
  }
}
