import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Round RedPing logo button with heartbeat animation
/// Smaller than SOS button, used for non-emergency help requests
class RedPingLogoButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enableHeartbeat;
  final double size;
  final String?
  helpRequestStatus; // Track help request status (active, acknowledged, assigned, inProgress, resolved)
  // New: long-hold-to-activate SOS
  final VoidCallback? onHoldToActivate; // Called when hold completes
  final int holdSeconds; // Seconds required to hold before activation
  // New: reflect SOS state on visuals (green border when activated)
  final bool isSosActivated;
  final bool enableDisappearEffect;

  const RedPingLogoButton({
    super.key,
    required this.onPressed,
    this.enableHeartbeat = true,
    this.size = 120.0, // Smaller than SOS button (200.0)
    this.helpRequestStatus, // null = no active request
    this.onHoldToActivate,
    this.holdSeconds = 5,
    this.isSosActivated = false,
    this.enableDisappearEffect = false,
  });

  @override
  State<RedPingLogoButton> createState() => _RedPingLogoButtonState();
}

class _RedPingLogoButtonState extends State<RedPingLogoButton>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pressController;
  late AnimationController _heartbeatController;
  late AnimationController _rippleController;
  // Hold-to-activate state
  Timer? _holdTimer;
  DateTime? _holdStart;
  double _holdProgress = 0.0; // 0..1
  bool _holdCompleted = false;

  // Animations
  late Animation<double> _pressAnimation;
  late Animation<double> _heartbeatAnimation;
  late Animation<double> _rippleAnimation;

  // State tracking - removed unused _isPressed field

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startHeartbeat();
  }

  void _initializeAnimations() {
    // Press animation (quick feedback)
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Heartbeat animation (continuous when enabled)
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Ripple animation (for tap feedback)
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Define animation curves and ranges
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _startHeartbeat() {
    if (widget.enableHeartbeat && !_heartbeatController.isAnimating) {
      _heartbeatController.repeat(reverse: true);
    }
  }

  void _stopHeartbeat() {
    if (_heartbeatController.isAnimating) {
      _heartbeatController.reset();
    }
  }

  @override
  void didUpdateWidget(RedPingLogoButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle heartbeat animation based on state
    if (widget.enableHeartbeat && !oldWidget.enableHeartbeat) {
      _startHeartbeat();
    } else if (!widget.enableHeartbeat && oldWidget.enableHeartbeat) {
      _stopHeartbeat();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _heartbeatController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!mounted) return;
    _pressController.forward();
    _rippleController.forward();
    HapticFeedback.lightImpact();
    // Start hold-to-activate timer if enabled
    if (widget.onHoldToActivate != null && widget.holdSeconds > 0) {
      _holdCompleted = false;
      _holdStart = DateTime.now();
      _holdTimer?.cancel();

      debugPrint(
        'RedPingLogoButton: Started ${widget.holdSeconds}s hold timer',
      );

      _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
        if (!mounted || _holdStart == null) {
          t.cancel();
          return;
        }
        final elapsed =
            DateTime.now().difference(_holdStart!).inMilliseconds / 1000.0;
        final progress = (elapsed / widget.holdSeconds).clamp(0.0, 1.0);

        // Provide haptic feedback at milestones
        if (progress >= 0.25 && progress < 0.26) {
          HapticFeedback.lightImpact();
        } else if (progress >= 0.5 && progress < 0.52) {
          HapticFeedback.mediumImpact();
        } else if (progress >= 0.75 && progress < 0.77) {
          HapticFeedback.heavyImpact();
        }

        if (_holdProgress != progress) {
          setState(() => _holdProgress = progress);
        }
        if (progress >= 1.0 && !_holdCompleted) {
          _holdCompleted = true;
          t.cancel();
          _finishHoldActivation();
        }
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    _pressController.reverse();
    final wasHolding = _holdProgress > 0.1;
    final progressPercent = (_holdProgress * 100).toStringAsFixed(0);
    _cancelHoldIfNeeded();
    if (wasHolding && !_holdCompleted) {
      debugPrint(
        'RedPingLogoButton: Hold cancelled at $progressPercent% progress',
      );
    }
  }

  void _onTapCancel() {
    if (!mounted) return;
    _pressController.reverse();
    final wasHolding = _holdProgress > 0.1;
    final progressPercent = (_holdProgress * 100).toStringAsFixed(0);
    _cancelHoldIfNeeded();
    if (wasHolding && !_holdCompleted) {
      debugPrint(
        'RedPingLogoButton: Hold interrupted at $progressPercent% progress',
      );
    }
  }

  void _onTap() {
    _rippleController.reset();
    // If hold already completed, don't trigger tap action
    if (_holdCompleted) {
      return;
    }
    widget.onPressed();
  }

  void _finishHoldActivation() {
    debugPrint(
      'RedPingLogoButton: ✅ Hold complete - ${widget.holdSeconds}s reached',
    );
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdStart = null;
    if (mounted) {
      setState(() {});
    }
    // Fire callback
    if (widget.onHoldToActivate != null) {
      debugPrint('RedPingLogoButton: Calling onHoldToActivate callback');
      widget.onHoldToActivate!.call();
    } else {
      debugPrint('RedPingLogoButton: ⚠️ No callback set for hold activation');
    }
  }

  void _cancelHoldIfNeeded() {
    if (_holdTimer != null && !_holdCompleted) {
      _holdTimer?.cancel();
      _holdTimer = null;
      _holdStart = null;
      if (mounted && _holdProgress > 0) {
        setState(() => _holdProgress = 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pressAnimation,
          _heartbeatAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          try {
            // Calculate combined scale
            double scale = _pressAnimation.value;

            // Add heartbeat effect when enabled
            if (widget.enableHeartbeat) {
              scale *= _heartbeatAnimation.value;
            }

            // Ensure valid scale
            scale = scale.clamp(0.8, 1.2);

            // Determine border color and glow based on status
            Color borderColor = AppTheme.primaryRed; // Default red
            Color glowColor = AppTheme.primaryRed;
            bool isActive = false;

            if (widget.isSosActivated) {
              borderColor = AppTheme.successGreen;
              glowColor = AppTheme.successGreen;
              isActive = true;
            } else if (widget.helpRequestStatus != null &&
                widget.helpRequestStatus != 'resolved') {
              // Active help request - change to green
              borderColor = AppTheme.successGreen;
              glowColor = AppTheme.successGreen;
              isActive = true;
            }

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple effect
                  if (_rippleAnimation.value > 0)
                    Transform.scale(
                      scale: 1.0 + (_rippleAnimation.value * 0.3),
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor.withValues(
                              alpha: 0.6 * (1.0 - _rippleAnimation.value),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  // Main button with status-aware border and glow
                  Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main button container
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 4),
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryRed.withValues(alpha: 0.9),
                                AppTheme.primaryRed,
                                AppTheme.criticalRed,
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.5),
                                blurRadius: isActive ? 20 : 15,
                                spreadRadius: isActive ? 5 : 3,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: widget.size * 0.63,
                              height: widget.size * 0.63,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Redpinglogo5.webp',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        'assets/images/Redpinglogo5.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error2, stackTrace2) =>
                                                const Icon(
                                                  Icons.help_outline,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Progress arc on button edge
                        if (widget.onHoldToActivate != null &&
                            _holdProgress > 0 &&
                            !_holdCompleted)
                          CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: _ProgressArcPainter(
                              progress: _holdProgress,
                              color: widget.isSosActivated
                                  ? AppTheme
                                        .criticalRed // Red for reset
                                  : AppTheme.safeGreen, // Green for activation
                              strokeWidth: 6,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Countdown text overlay (centered on button)
                  if (widget.onHoldToActivate != null &&
                      _holdProgress > 0 &&
                      !_holdCompleted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.holdSeconds - (_holdProgress * widget.holdSeconds).floor()}',
                        style: TextStyle(
                          color: widget.isSosActivated
                              ? AppTheme.criticalRed
                              : AppTheme.safeGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          } catch (e) {
            debugPrint('RedPingLogoButton build error: $e');
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryRed,
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 32,
              ),
            );
          }
        },
      ),
    );
  }
}

/// Custom painter to draw progress arc on button edge
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background arc (gray)
    final bgPaint = Paint()
      ..color = AppTheme.neutralGray.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc (green or red)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -90 * 3.14159 / 180; // Start at top (12 o'clock)
    final sweepAngle = 2 * 3.14159 * progress; // Progress in radians

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
