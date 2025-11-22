import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to verify Firestore TTL clean-up for request nonces.
/// Usage (after Firebase init):
///   final report = await NonceTtlVerifier.verify(
///     expiredCutoff: DateTime.now().subtract(const Duration(minutes: 10)),
///   );
///   print(report.summary);
class NonceTtlVerifier {
  /// Query recent nonces and report how many are past cutoff vs still present.
  static Future<NonceTtlReport> verify({
    required DateTime expiredCutoff,
  }) async {
    final fs = FirebaseFirestore.instance;
    final coll = fs.collection('request_nonces');
    // Fetch a window of recent docs (limit to keep cheap). Adjust as needed.
    final snapshot = await coll
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    int expiredPresent = 0;
    int validPresent = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final ts = (data['createdAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      if (ts.isBefore(expiredCutoff)) {
        expiredPresent++;
      } else {
        validPresent++;
      }
    }
    // TTL expectation: expiredPresent should trend toward 0 after TTL policy active.
    // If many expired remain > 10m, TTL likely not enabled or field mismatch.
    // We print a concise report.
    print(
      '[NonceTtlVerifier] totalSample=${snapshot.docs.length} valid=$validPresent expiredStillPresent=$expiredPresent cutoff=${expiredCutoff.toIso8601String()}',
    );
    if (expiredPresent > 0) {
      print(
        '[NonceTtlVerifier] ⚠️ Expired nonces still present. Confirm TTL enabled on field `expireAt` and documents include future expiration dates.',
      );
    } else {
      print(
        '[NonceTtlVerifier] ✅ No expired nonces found in sample. TTL cleanup appears effective.',
      );
    }
    return NonceTtlReport(
      totalSample: snapshot.docs.length,
      validPresent: validPresent,
      expiredStillPresent: expiredPresent,
      cutoff: expiredCutoff,
    );
  }
}

class NonceTtlReport {
  final int totalSample;
  final int validPresent;
  final int expiredStillPresent;
  final DateTime cutoff;

  const NonceTtlReport({
    required this.totalSample,
    required this.validPresent,
    required this.expiredStillPresent,
    required this.cutoff,
  });

  String get summary =>
      'TTL sample=$totalSample valid=$validPresent expiredStillPresent=$expiredStillPresent cutoff=${cutoff.toIso8601String()}';
}
