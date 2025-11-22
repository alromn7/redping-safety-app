import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sos_session.dart';
import '../models/verification_result.dart';
import 'sos_service.dart';
import 'sos_analytics_service.dart';

/// Coordinator to unify incident escalation flows across detection and verification.
/// Phase 1: Focus on post-verification fallback (2-minute) for no-response/uncertain outcomes.
class IncidentEscalationCoordinator {
  IncidentEscalationCoordinator._internal();
  static final IncidentEscalationCoordinator instance =
      IncidentEscalationCoordinator._internal();

  // Dependencies
  SOSService _sosService = SOSService();

  // State
  CoordinatorState _state = CoordinatorState.idle;
  Timer? _fallbackTimer;
  VerificationResult? _lastResult;
  DetectionContext? _lastDetectionContext;

  // Config
  static const Duration fallbackWindow = Duration(minutes: 2);
  Duration _fallbackWindow = fallbackWindow; // Overridable for tests

  // Optional override for starting SOS (testing hook)
  Future<void> Function({
    required SOSType type,
    required bool bringToSOSPage,
    String? escalationReasonCode,
  })?
  startSOSOverride;

  // Callbacks (optional UI/analytics hooks)
  void Function(CoordinatorState state)? onStateChanged;
  void Function(String reasonCode)? onFallbackStarted;
  void Function()? onFallbackCancelled;

  CoordinatorState get state => _state;

  void reset() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _lastResult = null;
    _lastDetectionContext = null;
    _updateState(CoordinatorState.idle);
  }

  /// Notify coordinator that a detection window has started (pre-verification).
  /// This enables UI/analytics to reflect the detection phase before AI completes.
  void detectionWindowStarted(DetectionContext context) {
    _lastDetectionContext = context;
    _updateState(CoordinatorState.detectionWindow);
    debugPrint(
      'Coordinator: Detection window started → ${context.type} (${context.reason})',
    );
  }

  /// Notify coordinator that a verification result has been produced.
  /// Only acts on fallback‑eligible outcomes to avoid duplicating existing SOS triggers.
  void handleVerificationResult(VerificationResult result) {
    _lastResult = result;

    // Analytics: verification outcome with latency from detection start
    try {
      final detTs =
          _lastDetectionContext?.timestamp ?? result.context.timestamp;
      final latency = DateTime.now().difference(detTs);
      SOSAnalyticsService.instance.logVerificationOutcomeEvent(
        type: result.context.type,
        outcome: result.outcome,
        confidence: result.confidence,
        latency: latency,
      );
    } catch (_) {}

    // If verification already requires SOS, let existing pipeline proceed (no duplication).
    if (result.requiresSOS) {
      debugPrint(
        'Coordinator: verification requires SOS - deferring to existing flow',
      );
      _updateState(CoordinatorState.sosCountdown);
      return;
    }

    // Fallback cases: noResponse or uncertain → start 2‑minute timer
    if (result.outcome == VerificationOutcome.noResponse ||
        result.outcome == VerificationOutcome.uncertainIncident) {
      _startFallbackTimer(
        reasonCode: result.outcome == VerificationOutcome.noResponse
            ? 'Fallback_NoResponse'
            : 'Fallback_Uncertain',
      );
      return;
    }

    // False alarm / user OK → ensure any pending fallback is cancelled
    if (result.outcome == VerificationOutcome.falseAlarmDetected ||
        result.outcome == VerificationOutcome.userConfirmedOK) {
      cancelFallback();
      _updateState(CoordinatorState.falseAlarm);
      return;
    }

    // Genuine incident covered above by requiresSOS
  }

  /// Cancel any pending fallback (e.g., user interaction or motion resume)
  void cancelFallback() {
    if (_fallbackTimer != null) {
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      onFallbackCancelled?.call();
      debugPrint('Coordinator: Fallback cancelled');
    }
    // Do not reset state to idle here to preserve timeline; move to falseAlarm/cancelled via handleVerificationResult
  }

  void _startFallbackTimer({required String reasonCode}) {
    // If there is an existing timer, restart it
    _fallbackTimer?.cancel();
    _updateState(CoordinatorState.fallbackPending);
    onFallbackStarted?.call(reasonCode);

    debugPrint(
      'Coordinator: Starting fallback timer (${_fallbackWindow.inSeconds}s) - $reasonCode',
    );

    // Analytics: fallback scheduled
    try {
      final dType =
          _lastResult?.context.type ??
          _lastDetectionContext?.type ??
          DetectionType.crash;
      SOSAnalyticsService.instance.logFallbackTriggered(
        type: dType,
        reasonCode: reasonCode,
        delay: _fallbackWindow,
      );
    } catch (_) {}

    _fallbackTimer = Timer(_fallbackWindow, () async {
      // If no cancellation occurred, escalate via SOS countdown
      try {
        final type = _mapType(
          _lastResult?.context.type ?? _lastDetectionContext?.type,
        );
        if (startSOSOverride != null) {
          await startSOSOverride!(
            type: type,
            bringToSOSPage: true,
            escalationReasonCode: reasonCode,
          );
        } else {
          await _sosService.startSOSCountdown(
            type: type,
            bringToSOSPage: true,
            escalationReasonCode: reasonCode,
          );
        }
        _updateState(CoordinatorState.sosCountdown);
        debugPrint('Coordinator: Fallback elapsed → SOS countdown started');
      } catch (e) {
        debugPrint(
          'Coordinator: Error starting SOS countdown on fallback - $e',
        );
      } finally {
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
      }
    });
  }

  void _updateState(CoordinatorState state) {
    if (_state == state) return;
    _state = state;
    onStateChanged?.call(_state);
  }

  /// Notify that an SOS countdown has started (from any source: fallback, severe impact, manual)
  /// Keeps coordinator timeline in sync even when it wasn't the initiator.
  void notifyCountdownStarted({SOSType? type, String? reasonCode}) {
    _updateState(CoordinatorState.sosCountdown);
    debugPrint(
      'Coordinator: Notified of SOS countdown started (type: ${type?.name ?? 'unknown'}, reason: ${reasonCode ?? 'n/a'})',
    );
  }

  SOSType _mapType(DetectionType? type) {
    switch (type) {
      case DetectionType.crash:
        return SOSType.crashDetection;
      case DetectionType.fall:
        return SOSType.fallDetection;
      default:
        return SOSType.manual;
    }
  }

  // ========== TEST HOOKS ==========
  /// Override the fallback window duration for fast unit tests.
  void setFallbackWindowForTest(Duration duration) {
    _fallbackWindow = duration;
  }

  /// Inject a custom SOS service instance (e.g., a test double).
  void setSOSServiceForTest(SOSService service) {
    _sosService = service;
  }
}

enum CoordinatorState {
  idle,
  detectionWindow,
  verification,
  awaitUserResponse,
  fallbackPending,
  sosCountdown,
  sosActive,
  resolved,
  cancelled,
  falseAlarm,
}
