import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fraud_risk_score.dart';
import '../models/user_risk_profile.dart';
import '../models/rescue_incident.dart';
import 'dart:math' as math;

/// Service for detecting and preventing Safety Fund fraud/misuse
class FraudDetectionService {
  static final FraudDetectionService _instance =
      FraudDetectionService._internal();
  static FraudDetectionService get instance => _instance;

  FraudDetectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Risk score weights (must sum to 1.0)
  static const double _frequencyWeight = 0.25;
  static const double _locationWeight = 0.20;
  static const double _sensorWeight = 0.20;
  static const double _behavioralWeight = 0.15;
  static const double _costWeight = 0.15;
  static const double _timeWeight = 0.05;

  /// Analyze SOS request for fraud risk (real-time during SOS)
  Future<FraudRiskScore> analyzeSOSRequest({
    required String sosSessionId,
    required String userId,
    required GeoPoint location,
    Map<String, dynamic>? sensorData,
  }) async {
    try {
      debugPrint('🔍 Running fraud analysis for SOS: $sosSessionId');

      // Get user risk profile
      final profile = await getUserRiskProfile(userId);

      // Run all fraud checks
      final frequencyScore = await _checkFrequencyPatterns(userId, profile);
      final locationScore = await _checkLocationAnomalies(userId, location);
      final sensorScore = _checkSensorValidation(sensorData);
      final behavioralScore = await _checkBehavioralPatterns(userId, profile);
      final timeScore = _checkTimePatterns(DateTime.now());

      // Cost score not available during SOS (no cost yet)
      const costScore = 0.0;

      // Calculate weighted total score
      final totalScore =
          (frequencyScore * _frequencyWeight) +
          (locationScore * _locationWeight) +
          (sensorScore * _sensorWeight) +
          (behavioralScore * _behavioralWeight) +
          (costScore * _costWeight) +
          (timeScore * _timeWeight);

      // Collect red flags
      final redFlags = <RedFlag>[];
      redFlags.addAll(await _getFrequencyRedFlags(userId, profile));
      redFlags.addAll(await _getLocationRedFlags(userId, location));
      redFlags.addAll(_getSensorRedFlags(sensorData));
      redFlags.addAll(_getBehavioralRedFlags(profile));
      redFlags.addAll(_getTimeRedFlags(DateTime.now()));

      // Create fraud risk score
      final score = FraudRiskScore.calculate(
        incidentId: sosSessionId,
        userId: userId,
        score: totalScore,
        redFlags: redFlags,
        calculatedAt: DateTime.now(),
        analysisData: {
          'stage': 'sos_request',
          'profile_trust_score': profile.trustScore,
          'total_claims': profile.totalClaims,
        },
        frequencyScore: frequencyScore,
        locationScore: locationScore,
        sensorScore: sensorScore,
        behavioralScore: behavioralScore,
        costScore: costScore,
        timeScore: timeScore,
      );

      // Save fraud analysis
      await _saveFraudAnalysis(sosSessionId, score);

      debugPrint(
        '✅ Fraud analysis complete: ${score.level.displayName} (${(score.score * 100).toStringAsFixed(1)}%)',
      );

      return score;
    } catch (e) {
      debugPrint('❌ Error analyzing SOS request: $e');
      rethrow;
    }
  }

  /// Analyze rescue incident after completion
  Future<FraudRiskScore> analyzeRescueIncident({
    required String incidentId,
    required RescueIncident incident,
  }) async {
    try {
      debugPrint('🔍 Running post-rescue fraud analysis: $incidentId');

      final profile = await getUserRiskProfile(incident.userId);

      // Run all fraud checks including cost
      final frequencyScore = await _checkFrequencyPatterns(
        incident.userId,
        profile,
      );
      final locationScore = await _checkLocationAnomalies(
        incident.userId,
        GeoPoint(incident.latitude, incident.longitude),
      );
      final sensorScore = _checkSensorValidation(
        null,
      ); // Get from incident if available
      final behavioralScore = await _checkBehavioralPatterns(
        incident.userId,
        profile,
      );
      final costScore = await _checkCostAnomalies(
        incident.estimatedCost,
        incident.rescueType,
        'general', // TODO: Get region from incident
      );
      final timeScore = _checkTimePatterns(incident.initiatedAt);

      // Calculate weighted total score
      final totalScore =
          (frequencyScore * _frequencyWeight) +
          (locationScore * _locationWeight) +
          (sensorScore * _sensorWeight) +
          (behavioralScore * _behavioralWeight) +
          (costScore * _costWeight) +
          (timeScore * _timeWeight);

      // Collect red flags
      final redFlags = <RedFlag>[];
      redFlags.addAll(await _getFrequencyRedFlags(incident.userId, profile));
      redFlags.addAll(
        await _getLocationRedFlags(
          incident.userId,
          GeoPoint(incident.latitude, incident.longitude),
        ),
      );
      redFlags.addAll(_getBehavioralRedFlags(profile));
      redFlags.addAll(
        _getCostRedFlags(incident.estimatedCost, incident.rescueType),
      );
      redFlags.addAll(_getTimeRedFlags(incident.initiatedAt));

      final score = FraudRiskScore.calculate(
        incidentId: incidentId,
        userId: incident.userId,
        score: totalScore,
        redFlags: redFlags,
        calculatedAt: DateTime.now(),
        analysisData: {
          'stage': 'post_rescue',
          'rescue_type': incident.rescueType.name,
          'estimated_cost': incident.estimatedCost,
          'profile_trust_score': profile.trustScore,
        },
        frequencyScore: frequencyScore,
        locationScore: locationScore,
        sensorScore: sensorScore,
        behavioralScore: behavioralScore,
        costScore: costScore,
        timeScore: timeScore,
      );

      await _saveFraudAnalysis(incidentId, score);

      debugPrint('✅ Post-rescue analysis complete: ${score.level.displayName}');

      return score;
    } catch (e) {
      debugPrint('❌ Error analyzing rescue incident: $e');
      rethrow;
    }
  }

  /// Get or create user risk profile
  Future<UserRiskProfile> getUserRiskProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('userRiskProfiles')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Create initial profile
        final profile = UserRiskProfile.initial(userId, DateTime.now());
        await _firestore
            .collection('userRiskProfiles')
            .doc(userId)
            .set(profile.toJson());
        return profile;
      }

      return UserRiskProfile.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error getting user risk profile: $e');
      rethrow;
    }
  }

  /// Update user risk profile after incident
  Future<void> updateRiskProfile(String userId, RescueIncident incident) async {
    try {
      final profile = await getUserRiskProfile(userId);

      // Calculate new values
      final now = DateTime.now();
      final daysSinceCreation = now.difference(profile.accountCreated).inDays;
      final isLongTerm = daysSinceCreation > 365;

      // Count claims in different timeframes
      final claimsLast30Days = await _countClaimsInPeriod(userId, 30);
      final claimsLast90Days = await _countClaimsInPeriod(userId, 90);
      final claimsThisYear = await _countClaimsInYear(userId, now.year);

      // Calculate new trust score
      final newTrustScore = UserRiskProfile.calculateTrustScore(
        totalClaims: profile.totalClaims + 1,
        suspiciousIncidents: profile.suspiciousIncidents,
        consecutiveSafeMonths: 0, // Reset after claim
        verifiedIdentity: profile.verifiedIdentity,
        longTermMember: isLongTerm,
        daysActive: daysSinceCreation,
        flaggedIncidents: profile.flaggedIncidents,
      );

      // Update profile
      await _firestore.collection('userRiskProfiles').doc(userId).update({
        'totalClaims': FieldValue.increment(1),
        'trustScore': newTrustScore,
        'lastClaimDate': Timestamp.fromDate(now),
        'claimsLast30Days': claimsLast30Days,
        'claimsLast90Days': claimsLast90Days,
        'claimsThisYear': claimsThisYear,
        'longTermMember': isLongTerm,
        'daysActive': daysSinceCreation,
        'lastUpdated': Timestamp.fromDate(now),
      });

      debugPrint('✅ Updated risk profile for user: $userId');
    } catch (e) {
      debugPrint('❌ Error updating risk profile: $e');
    }
  }

  // =================================================================
  // FREQUENCY PATTERN CHECKS (Detection Only - NO Hard Limits)
  // Per Blueprint: "All users can ALWAYS request rescue service"
  // =================================================================

  Future<double> _checkFrequencyPatterns(
    String userId,
    UserRiskProfile profile,
  ) async {
    double score = 0.0;

    // Detect unusual frequency patterns (for review, NOT blocking)
    // Multiple claims in 30 days - suspicious pattern
    if (profile.claimsLast30Days >= 2) {
      score += 0.4; // Reduced from 0.5
    }

    // Unusually high claims this year - flag for review
    if (profile.claimsThisYear >= 4) {
      score += 0.3;
    }

    // Rapid succession claims - potential pattern
    if (profile.lastClaimDate != null) {
      final daysSinceLastClaim = DateTime.now()
          .difference(profile.lastClaimDate!)
          .inDays;
      if (daysSinceLastClaim < 14) {
        // Very close claims
        score += 0.4;
      }
    }

    // New user with immediate claim - verify but don't block
    if (profile.daysActive < 7 && profile.totalClaims == 0) {
      score += 0.2; // Reduced - new users may have legitimate emergencies
    }

    return score.clamp(0.0, 1.0);
  }

  Future<List<RedFlag>> _getFrequencyRedFlags(
    String userId,
    UserRiskProfile profile,
  ) async {
    final flags = <RedFlag>[];

    // Note: These are FLAGS for manual review, NOT auto-reject limits
    // Per Blueprint: No hard caps on claims - use pattern detection + manual review

    if (profile.claimsLast30Days >= 2) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.frequencyPattern,
          description:
              'Unusual frequency: ${profile.claimsLast30Days} claims within 30 days - Requires review',
          severity: 0.6, // Reduced - for review, not blocking
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (profile.claimsThisYear >= 4) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.frequencyPattern,
          description:
              'High annual frequency: ${profile.claimsThisYear} claims this year - Manual review recommended',
          severity: 0.7, // Reduced
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (profile.lastClaimDate != null) {
      final daysSince = DateTime.now()
          .difference(profile.lastClaimDate!)
          .inDays;
      if (daysSince < 14) {
        flags.add(
          RedFlag(
            category: RedFlagCategory.frequencyPattern,
            description:
                'Rapid succession: $daysSince days since last claim - Verify incident authenticity',
            severity: 0.6,
            detectedAt: DateTime.now(),
          ),
        );
      }
    }

    if (profile.daysActive < 7 && profile.totalClaims == 0) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.frequencyPattern,
          description:
              'New user claim: Account age ${profile.daysActive} days - Standard verification required',
          severity: 0.4, // Low - legitimate emergencies happen to new users
          detectedAt: DateTime.now(),
        ),
      );
    }

    return flags;
  }

  // =================================================================
  // LOCATION ANOMALY CHECKS
  // =================================================================

  Future<double> _checkLocationAnomalies(
    String userId,
    GeoPoint currentLocation,
  ) async {
    double score = 0.0;

    // Get recent incidents for user
    final recentIncidents = await _getRecentIncidents(userId, days: 90);

    if (recentIncidents.isEmpty) return 0.0;

    // Check for same location claims (within 1km)
    int sameLocationCount = 0;
    for (final incident in recentIncidents) {
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        incident['latitude'] as double,
        incident['longitude'] as double,
      );

      if (distance < 1.0) {
        // Within 1km
        sameLocationCount++;
      }
    }

    if (sameLocationCount >= 2) {
      score += 0.6;
    }

    // Check for unrealistic location jumps (teleportation)
    if (recentIncidents.isNotEmpty) {
      final lastIncident = recentIncidents.first;
      final lastTime = (lastIncident['initiatedAt'] as Timestamp).toDate();
      final timeDiffHours = DateTime.now().difference(lastTime).inHours;

      if (timeDiffHours < 24) {
        final distance = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          lastIncident['latitude'] as double,
          lastIncident['longitude'] as double,
        );

        // If distance > 500km in < 24 hours without travel time
        if (distance > 500 && timeDiffHours < 12) {
          score += 0.8;
        }
      }
    }

    return score.clamp(0.0, 1.0);
  }

  Future<List<RedFlag>> _getLocationRedFlags(
    String userId,
    GeoPoint currentLocation,
  ) async {
    final flags = <RedFlag>[];
    final recentIncidents = await _getRecentIncidents(userId, days: 90);

    // Check same location
    int sameLocationCount = 0;
    for (final incident in recentIncidents) {
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        incident['latitude'] as double,
        incident['longitude'] as double,
      );

      if (distance < 1.0) sameLocationCount++;
    }

    if (sameLocationCount >= 2) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.locationAnomaly,
          description:
              'Multiple claims at same location ($sameLocationCount claims within 1km)',
          severity: 0.7,
          detectedAt: DateTime.now(),
        ),
      );
    }

    // Check teleportation
    if (recentIncidents.isNotEmpty) {
      final lastIncident = recentIncidents.first;
      final lastTime = (lastIncident['initiatedAt'] as Timestamp).toDate();
      final timeDiffHours = DateTime.now().difference(lastTime).inHours;

      if (timeDiffHours < 24) {
        final distance = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          lastIncident['latitude'] as double,
          lastIncident['longitude'] as double,
        );

        if (distance > 500 && timeDiffHours < 12) {
          flags.add(
            RedFlag(
              category: RedFlagCategory.locationAnomaly,
              description:
                  'Unrealistic location jump (${distance.toStringAsFixed(0)}km in $timeDiffHours hours)',
              severity: 0.9,
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return flags;
  }

  // =================================================================
  // SENSOR VALIDATION CHECKS
  // =================================================================

  double _checkSensorValidation(Map<String, dynamic>? sensorData) {
    if (sensorData == null) return 0.0;

    double score = 0.0;

    // Check if crash/fall detection was active
    final crashDetected = sensorData['crashDetected'] as bool? ?? false;
    final fallDetected = sensorData['fallDetected'] as bool? ?? false;
    final manualTrigger = sensorData['manualTrigger'] as bool? ?? true;

    // If manual trigger without sensor validation, suspicious
    if (manualTrigger && !crashDetected && !fallDetected) {
      score += 0.4;
    }

    // Check accelerometer data
    final accelData = sensorData['accelerometer'] as Map<String, dynamic>?;
    if (accelData != null) {
      final magnitude = accelData['magnitude'] as double? ?? 0.0;
      // For crash: expect >180 m/s², for fall: expect >150 m/s²
      if (magnitude < 100) {
        score += 0.5; // No significant impact detected
      }
    }

    return score.clamp(0.0, 1.0);
  }

  List<RedFlag> _getSensorRedFlags(Map<String, dynamic>? sensorData) {
    final flags = <RedFlag>[];

    if (sensorData == null) return flags;

    final crashDetected = sensorData['crashDetected'] as bool? ?? false;
    final fallDetected = sensorData['fallDetected'] as bool? ?? false;
    final manualTrigger = sensorData['manualTrigger'] as bool? ?? true;

    if (manualTrigger && !crashDetected && !fallDetected) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.sensorValidation,
          description: 'Manual SOS trigger without sensor validation',
          severity: 0.5,
          detectedAt: DateTime.now(),
        ),
      );
    }

    final accelData = sensorData['accelerometer'] as Map<String, dynamic>?;
    if (accelData != null) {
      final magnitude = accelData['magnitude'] as double? ?? 0.0;
      if (magnitude < 100) {
        flags.add(
          RedFlag(
            category: RedFlagCategory.sensorValidation,
            description:
                'No significant impact detected (${magnitude.toStringAsFixed(1)} m/s²)',
            severity: 0.6,
            detectedAt: DateTime.now(),
          ),
        );
      }
    }

    return flags;
  }

  // =================================================================
  // BEHAVIORAL PATTERN CHECKS
  // =================================================================

  Future<double> _checkBehavioralPatterns(
    String userId,
    UserRiskProfile profile,
  ) async {
    double score = 0.0;

    // Low trust score
    if (profile.trustScore < 0.3) {
      score += 0.5;
    }

    // Has flagged incidents
    if (profile.flaggedIncidents > 0) {
      score += 0.4;
    }

    // Has suspicious incidents
    if (profile.suspiciousIncidents > 0) {
      score += 0.3;
    }

    // Pattern of high-cost claims
    if (profile.averageClaimAmount > 10000) {
      score += 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  List<RedFlag> _getBehavioralRedFlags(UserRiskProfile profile) {
    final flags = <RedFlag>[];

    if (profile.trustScore < 0.3) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.behavioralPattern,
          description:
              'Low trust score (${(profile.trustScore * 100).toStringAsFixed(0)}%)',
          severity: 0.7,
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (profile.flaggedIncidents > 0) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.behavioralPattern,
          description:
              'Previous flagged incidents (${profile.flaggedIncidents} incidents)',
          severity: 0.8,
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (profile.suspiciousIncidents > 0) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.behavioralPattern,
          description:
              'Suspicious incident history (${profile.suspiciousIncidents} incidents)',
          severity: 0.7,
          detectedAt: DateTime.now(),
        ),
      );
    }

    return flags;
  }

  // =================================================================
  // COST ANOMALY CHECKS
  // =================================================================

  Future<double> _checkCostAnomalies(
    double cost,
    RescueType rescueType,
    String region,
  ) async {
    double score = 0.0;

    // Get expected cost range for rescue type
    final expectedCost = rescueType.estimatedCost;
    final upperLimit = expectedCost * 2.0; // 2x expected is suspicious

    if (cost > upperLimit) {
      score += 0.6;
    }

    // Extremely high costs
    if (cost > 50000) {
      score += 0.4;
    }

    return score.clamp(0.0, 1.0);
  }

  List<RedFlag> _getCostRedFlags(double cost, RescueType rescueType) {
    final flags = <RedFlag>[];
    final expectedCost = rescueType.estimatedCost;
    final upperLimit = expectedCost * 2.0;

    if (cost > upperLimit) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.costAnomaly,
          description:
              'Cost exceeds expected range (\$${cost.toStringAsFixed(0)} vs \$${expectedCost.toStringAsFixed(0)} expected)',
          severity: 0.7,
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (cost > 50000) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.costAnomaly,
          description:
              'Extremely high rescue cost (\$${cost.toStringAsFixed(0)})',
          severity: 0.8,
          detectedAt: DateTime.now(),
        ),
      );
    }

    return flags;
  }

  // =================================================================
  // TIME PATTERN CHECKS
  // =================================================================

  double _checkTimePatterns(DateTime incidentTime) {
    double score = 0.0;

    // Weekend claims (slightly suspicious)
    if (incidentTime.weekday == DateTime.saturday ||
        incidentTime.weekday == DateTime.sunday) {
      score += 0.2;
    }

    // Holiday claims (more suspicious)
    // TODO: Check against holiday calendar

    // Late night claims (11pm - 5am)
    final hour = incidentTime.hour;
    if (hour >= 23 || hour < 5) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  List<RedFlag> _getTimeRedFlags(DateTime incidentTime) {
    final flags = <RedFlag>[];

    if (incidentTime.weekday == DateTime.saturday ||
        incidentTime.weekday == DateTime.sunday) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.timePattern,
          description: 'Weekend incident',
          severity: 0.3,
          detectedAt: DateTime.now(),
        ),
      );
    }

    final hour = incidentTime.hour;
    if (hour >= 23 || hour < 5) {
      flags.add(
        RedFlag(
          category: RedFlagCategory.timePattern,
          description: 'Late night incident (${hour}:00)',
          severity: 0.2,
          detectedAt: DateTime.now(),
        ),
      );
    }

    return flags;
  }

  // =================================================================
  // HELPER METHODS
  // =================================================================

  /// Save fraud analysis to Firestore
  Future<void> _saveFraudAnalysis(
    String incidentId,
    FraudRiskScore score,
  ) async {
    try {
      await _firestore
          .collection('fraudAnalyses')
          .doc(incidentId)
          .set(score.toJson());
    } catch (e) {
      debugPrint('❌ Error saving fraud analysis: $e');
    }
  }

  /// Get recent incidents for user
  Future<List<Map<String, dynamic>>> _getRecentIncidents(
    String userId, {
    required int days,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collectionGroup('rescueIncidents')
          .where('userId', isEqualTo: userId)
          .where('initiatedAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('initiatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error getting recent incidents: $e');
      return [];
    }
  }

  /// Count claims in period
  Future<int> _countClaimsInPeriod(String userId, int days) async {
    final incidents = await _getRecentIncidents(userId, days: days);
    return incidents.length;
  }

  /// Count claims in specific year
  Future<int> _countClaimsInYear(String userId, int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _firestore
          .collectionGroup('rescueIncidents')
          .where('userId', isEqualTo: userId)
          .where(
            'initiatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'initiatedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error counting claims in year: $e');
      return 0;
    }
  }

  /// Calculate distance between two points in km
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth's radius in km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
