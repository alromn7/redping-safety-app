import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

class SosCallableClient {
  SosCallableClient();

  /// Attempts to create an SOS session by calling a regional callable.
  /// Returns the created sessionId on success.
  ///
  /// preferredRegion: 'AU' | 'EU' | 'AF' | 'AS' (defaults to 'AU')
  ///
  /// Input fields:
  /// - type: manual | crash | fall | ...
  /// - userMessage: optional user-provided text
  /// - location: { lat, lng, accuracy?, address? }
  Future<String> createSession({
    String preferredRegion = 'AU',
    String? type,
    String? userMessage,
    Map<String, dynamic>? location,
    Duration perAttemptTimeout = const Duration(seconds: 6),
  }) async {
    final attempts = _buildAttemptPlan(preferredRegion);
    final payload = <String, dynamic>{
      if (type != null) 'type': type,
      if (userMessage != null) 'userMessage': userMessage,
      if (location != null) 'location': location,
    };

    FirebaseFunctionsException? lastError;

    for (final a in attempts) {
      try {
        final functions = FirebaseFunctions.instanceFor(region: a.region);
        final callable = functions.httpsCallable(a.name);
        final result = await callable
            .call<Map<String, dynamic>>(payload)
            .timeout(perAttemptTimeout);
        final data = result.data;
        final sessionId = data['sessionId'] as String?;
        if (sessionId != null && sessionId.isNotEmpty) {
          return sessionId;
        }
        // If shape unexpected, continue to next attempt
      } on FirebaseFunctionsException catch (e) {
        lastError = e;
        // Try next
      } on TimeoutException catch (_) {
        // Try next
      } catch (_) {
        // Try next
      }
    }

    // If all attempts fail, throw last known error or a generic failure.
    if (lastError != null) {
      throw lastError;
    }
    throw Exception(
      'Failed to create SOS session via callable (all regions failed)',
    );
  }

  List<_Attempt> _buildAttemptPlan(String code) {
    // Map the user-friendly code to a prioritized list of regional functions
    switch (code.toUpperCase()) {
      case 'EU':
        return const [
          _Attempt('europe-west1', 'createSosSessionEU'),
          _Attempt('australia-southeast1', 'createSosSession'),
          _Attempt('asia-southeast1', 'createSosSessionAS'),
          _Attempt('africa-south1', 'createSosSessionAF'),
        ];
      case 'AF':
        return const [
          _Attempt('africa-south1', 'createSosSessionAF'),
          _Attempt('australia-southeast1', 'createSosSession'),
          _Attempt('europe-west1', 'createSosSessionEU'),
          _Attempt('asia-southeast1', 'createSosSessionAS'),
        ];
      case 'AS':
        return const [
          _Attempt('asia-southeast1', 'createSosSessionAS'),
          _Attempt('australia-southeast1', 'createSosSession'),
          _Attempt('europe-west1', 'createSosSessionEU'),
          _Attempt('africa-south1', 'createSosSessionAF'),
        ];
      case 'AU':
      default:
        return const [
          _Attempt('australia-southeast1', 'createSosSession'),
          _Attempt('asia-southeast1', 'createSosSessionAS'),
          _Attempt('europe-west1', 'createSosSessionEU'),
          _Attempt('africa-south1', 'createSosSessionAF'),
        ];
    }
  }
}

class _Attempt {
  final String region;
  final String name;
  const _Attempt(this.region, this.name);
}
