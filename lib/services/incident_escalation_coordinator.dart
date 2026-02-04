import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sos_session.dart';
import '../models/detection_context.dart';
import 'sos_service.dart';
import 'sos_analytics_service.dart';

/// Coordinator to unify incident escalation flows across detection windows and
/// heuristic-based fallback escalation.
class IncidentEscalationCoordinator {
  IncidentEscalationCoordinator._internal();
  static final IncidentEscalationCoordinator instance =
      IncidentEscalationCoordinator._internal();

  // Dependencies
  SOSService _sosService = SOSService();

  // State
  CoordinatorState _state = CoordinatorState.idle;
  Timer? _fallbackTimer;
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
    _lastDetectionContext = null;
    _updateState(CoordinatorState.idle);
  }

  /// Notify coordinator that a detection window has started (pre-verification).
  /// This enables UI/analytics to reflect the detection phase before escalation completes.
  void detectionWindowStarted(DetectionContext context) {
    _lastDetectionContext = context;
    _updateState(CoordinatorState.detectionWindow);
    debugPrint(
      'Coordinator: Detection window started → ${context.type} (${context.reason})',
    );
  }

  /// Schedule a heuristic fallback timer.
  ///
  /// Use this when a detection window begins and the app expects user response,
  /// but wants to auto-escalate if no interaction occurs within the fallback window.
  void scheduleFallback({
    required DetectionContext context,
    required String reasonCode,
  }) {
    _lastDetectionContext = context;
    _startFallbackTimer(context: context, reasonCode: reasonCode);
  }

  /// Cancel any pending fallback (e.g., user interaction or motion resume)
  void cancelFallback() {
    if (_fallbackTimer != null) {
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      onFallbackCancelled?.call();
      debugPrint('Coordinator: Fallback cancelled');
    }
    // Do not reset state to idle here to preserve timeline.
  }

  /// Mark the current timeline as a false alarm (cancels any pending fallback).
  void markFalseAlarm() {
    cancelFallback();
    _updateState(CoordinatorState.falseAlarm);
  }

  void _startFallbackTimer({
    required DetectionContext context,
    required String reasonCode,
  }) {
    // If there is an existing timer, restart it
    _fallbackTimer?.cancel();
    _updateState(CoordinatorState.fallbackPending);
    onFallbackStarted?.call(reasonCode);

    debugPrint(
      'Coordinator: Starting fallback timer (${_fallbackWindow.inSeconds}s) - $reasonCode',
    );

    // Analytics: fallback scheduled
    try {
      final dType = context.type;
      SOSAnalyticsService.instance.logFallbackTriggered(
        type: dType,
        reasonCode: reasonCode,
        delay: _fallbackWindow,
      );
    } catch (_) {}

    _fallbackTimer = Timer(_fallbackWindow, () async {
      // If no cancellation occurred, escalate via SOS countdown
      try {
        final type = _mapType(_lastDetectionContext?.type ?? context.type);
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
  fallbackPending,
  sosCountdown,
  sosActive,
  resolved,
  cancelled,
  falseAlarm,
}
