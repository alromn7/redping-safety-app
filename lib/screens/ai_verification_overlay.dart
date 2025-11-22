import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Full-screen safety overlay for AI emergency verification
class AIVerificationOverlay extends StatefulWidget {
  final String emergencyType;
  final String detectionType;
  final Map<String, dynamic> detectionData;
  final Function()? onCancel;
  final Function()? onConfirm;

  const AIVerificationOverlay({
    super.key,
    required this.emergencyType,
    required this.detectionType,
    required this.detectionData,
    this.onCancel,
    this.onConfirm,
  });

  @override
  State<AIVerificationOverlay> createState() => _AIVerificationOverlayState();
}

class _AIVerificationOverlayState extends State<AIVerificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _countdownSeconds = 30;
  bool _isListening = false;
  String _listeningStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCountdown();
    _startListening();
  }

  void _initializeAnimations() {
    // Pulse animation for emergency state
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Shake animation for urgency
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeController.repeat(reverse: true);
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _escalateToSOS();
        return;
      }

      setState(() {
        _countdownSeconds--;
      });

      // Haptic feedback for urgency
      if (_countdownSeconds <= 10) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _listeningStatus = 'Listening for your response...';
    });
  }

  void _cancelVerification() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  void _confirmEmergency() {
    HapticFeedback.heavyImpact();
    widget.onConfirm?.call();
    Navigator.of(context).pop();
  }

  void _escalateToSOS() {
    HapticFeedback.vibrate();
    _confirmEmergency();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppTheme.criticalRed.withValues(alpha: 0.95),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.8),
            ),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildEmergencyIcon(),
                const SizedBox(height: 40),
                _buildEmergencyMessage(),
                const SizedBox(height: 40),
                _buildCountdownDisplay(),
                const SizedBox(height: 40),
                _buildActionButtons(),
                const SizedBox(height: 40),
                _buildListeningStatus(),
                const Spacer(),
                _buildInstructions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.primaryText,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY DETECTED',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Verification Required',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.criticalRed,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.criticalRed.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              widget.emergencyType == 'CRASH'
                  ? Icons.car_crash
                  : Icons.person_off,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            widget.emergencyType == 'CRASH'
                ? 'Possible Vehicle Crash Detected'
                : 'Possible Fall Detected',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI system has detected a potential emergency. Please respond to confirm you are safe.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _countdownSeconds <= 10
              ? AppTheme.criticalRed
              : AppTheme.accentGreen,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Emergency Alert in',
            style: TextStyle(color: AppTheme.primaryText, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '$_countdownSeconds',
            style: TextStyle(
              color: _countdownSeconds <= 10
                  ? AppTheme.criticalRed
                  : AppTheme.accentGreen,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'seconds',
            style: TextStyle(color: AppTheme.primaryText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button
        ElevatedButton.icon(
          onPressed: _cancelVerification,
          icon: const Icon(Icons.check_circle, size: 24),
          label: const Text('I\'m OK', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Emergency button
        ElevatedButton.icon(
          onPressed: _confirmEmergency,
          icon: const Icon(Icons.emergency, size: 24),
          label: const Text('SOS Now', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.criticalRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isListening) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            _isListening ? _listeningStatus : 'Voice recognition active',
            style: TextStyle(
              color: _isListening
                  ? AppTheme.accentGreen
                  : AppTheme.secondaryText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Instructions:',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Say "I\'m OK" or "I\'m fine" to cancel the alert\n'
            '• Tap "I\'m OK" button to cancel\n'
            '• Tap "SOS Now" to send emergency alert immediately\n'
            '• If no response, alert will be sent automatically',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
