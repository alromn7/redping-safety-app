import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';

/// Enhanced round SOS button with heartbeat animation and full functionality
/// Now includes 5-second activation and 5-second reset with green activated state
class EnhancedSOSButton extends StatefulWidget {
  final bool isActive;
  final bool isCountdown;
  final bool isActivated; // New: green activated state
  final int countdownSeconds;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onActivated; // New: callback for SOS activation after 5s
  final VoidCallback? onReset; // New: callback for SOS reset after 5s
  final bool enableHeartbeat;
  final double size;

  const EnhancedSOSButton({
    super.key,
    required this.isActive,
    required this.isCountdown,
    required this.isActivated,
    required this.countdownSeconds,
    required this.onPressed,
    this.onLongPress,
    this.onActivated,
    this.onReset,
    this.enableHeartbeat = true,
    this.size = 200.0,
  });

  @override
  State<EnhancedSOSButton> createState() => _EnhancedSOSButtonState();
}

class _EnhancedSOSButtonState extends State<EnhancedSOSButton>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late AnimationController _heartbeatController;
  late AnimationController _rippleController;
  late AnimationController _logoFadeController;

  // Animations
  late Animation<double> _pressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartbeatAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _logoFadeAnimation;

  // State tracking
  bool _isPressed = false;
  bool _isLongPressing = false;

  // Long press timing
  Timer? _longPressTimer;
  DateTime? _longPressStartTime;
  double _longPressProgress = 0.0;
  bool _isActivationPress = false; // 5s press for activation
  bool _isResetPress = false; // 5s press for reset

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

    // Pulse animation (for countdown/active states)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Heartbeat animation (continuous when enabled)
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Ripple animation (for activation feedback)
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo fade animation (5 seconds each direction = 10 seconds total cycle)
    _logoFadeController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Define animation curves and ranges
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Logo fade animation: fade in (0->1) then fade out (1->0) = 10 seconds total
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoFadeController, curve: Curves.easeInOut),
    );
  }

  void _startHeartbeat() {
    if (widget.enableHeartbeat && !_heartbeatController.isAnimating) {
      _heartbeatController.repeat(reverse: true);
    }
    // Start logo fade animation (repeating every 10 seconds)
    if (!_logoFadeController.isAnimating) {
      _logoFadeController.repeat(reverse: true);
      debugPrint(
        'EnhancedSOSButton: 🎬 Logo fade animation started (5s fade in + 5s fade out = 10s cycle)',
      );
    }
  }

  void _stopHeartbeat() {
    if (_heartbeatController.isAnimating) {
      _heartbeatController.stop();
      _heartbeatController.reset();
    }
    if (_logoFadeController.isAnimating) {
      _logoFadeController.stop();
      _logoFadeController.reset();
    }
  }

  @override
  void didUpdateWidget(EnhancedSOSButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle heartbeat animation based on state
    if (widget.enableHeartbeat && !oldWidget.enableHeartbeat) {
      _startHeartbeat();
    } else if (!widget.enableHeartbeat && oldWidget.enableHeartbeat) {
      _stopHeartbeat();
    }

    // Handle pulse animation for active/countdown states (not for activated state)
    if ((widget.isActive || widget.isCountdown) &&
        !(oldWidget.isActive || oldWidget.isCountdown)) {
      _pulseController.repeat(reverse: true);
    } else if (!(widget.isActive || widget.isCountdown) &&
        (oldWidget.isActive || oldWidget.isCountdown)) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Trigger ripple effect when transitioning to active or activated
    if ((widget.isActive && !oldWidget.isActive) ||
        (widget.isActivated && !oldWidget.isActivated)) {
      _rippleController.forward();
    }

    // Cancel any ongoing long press if state changes externally
    if (widget.isActivated != oldWidget.isActivated ||
        widget.isActive != oldWidget.isActive) {
      _cancelLongPress();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _pressController.dispose();
    _pulseController.dispose();
    _heartbeatController.dispose();
    _rippleController.dispose();
    _logoFadeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onTapCancel() {
    if (!mounted) return;
    _cancelLongPress();
    setState(() {
      _isPressed = false;
      _isLongPressing = false;
    });
    _pressController.reverse();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!mounted) return;

    // Determine if this is an activation press (when not activated) or reset press (when activated)
    _isActivationPress = !widget.isActivated;
    _isResetPress = widget.isActivated;

    if (_isActivationPress) {
      debugPrint('EnhancedSOSButton: 🔴 Starting 5-second ACTIVATION press');
    } else if (_isResetPress) {
      debugPrint('EnhancedSOSButton: 🔄 Starting 5-second RESET press');
    }

    setState(() {
      _isLongPressing = true;
      _longPressProgress = 0.0;
    });

    _longPressStartTime = DateTime.now();
    HapticFeedback.heavyImpact();

    // Start ripple animation for long press
    _rippleController.forward();

    // Start progress timer
    _startLongPressTimer();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!mounted) return;
    _cancelLongPress();
  }

  void _startLongPressTimer() {
    const updateInterval = Duration(milliseconds: 50);
    final requiredDuration = _isActivationPress
        ? const Duration(seconds: 5) // 5 seconds for activation
        : const Duration(seconds: 5); // 5 seconds for reset

    _longPressTimer = Timer.periodic(updateInterval, (timer) {
      if (!mounted || _longPressStartTime == null) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_longPressStartTime!);
      final progress =
          (elapsed.inMilliseconds / requiredDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

      setState(() {
        _longPressProgress = progress;
      });

      // Provide haptic feedback at progress milestones
      if (progress >= 0.25 && progress < 0.3) {
        HapticFeedback.lightImpact();
      } else if (progress >= 0.5 && progress < 0.55) {
        HapticFeedback.mediumImpact();
      } else if (progress >= 0.75 && progress < 0.8) {
        HapticFeedback.heavyImpact();
      }

      // Complete the action when progress reaches 100%
      if (progress >= 1.0) {
        timer.cancel();
        _completeLongPressAction();
      }
    });
  }

  void _completeLongPressAction() {
    if (!mounted) return;

    HapticFeedback.heavyImpact();

    if (_isActivationPress && widget.onActivated != null) {
      // Complete 5-second press - activate SOS
      debugPrint(
        'EnhancedSOSButton: ✅ 5-second activation complete - calling onActivated',
      );
      widget.onActivated!();
    } else if (_isResetPress && widget.onReset != null) {
      // Complete 5-second press - reset SOS
      debugPrint(
        'EnhancedSOSButton: ✅ 5-second reset complete - calling onReset',
      );
      widget.onReset!();
    } else {
      debugPrint(
        'EnhancedSOSButton: ⚠️ Long press completed but no callback available',
      );
    }

    _cancelLongPress();
  }

  void _cancelLongPress() {
    if (_longPressProgress > 0.1) {
      debugPrint(
        'EnhancedSOSButton: Long press cancelled at ${(_longPressProgress * 100).toStringAsFixed(0)}% progress',
      );
    }

    _longPressTimer?.cancel();
    _longPressTimer = null;
    _longPressStartTime = null;
    _rippleController.reset();

    if (mounted) {
      setState(() {
        _isLongPressing = false;
        _longPressProgress = 0.0;
        _isActivationPress = false;
        _isResetPress = false;
      });
    }
  }

  Color _getButtonColor() {
    if (widget.isActivated) {
      return Colors.green; // Green when SOS is successfully activated
    } else if (widget.isActive) {
      return AppTheme.criticalRed;
    } else if (widget.isCountdown) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.primaryRed;
    }
  }

  Color _getGlowColor() {
    final baseColor = _getButtonColor();
    return baseColor.withValues(alpha: 0.6);
  }

  String _getButtonText() {
    if (widget.isActivated) {
      if (_isLongPressing && _isResetPress) {
        // Show reset countdown
        final remaining = (5.0 * (1.0 - _longPressProgress)).ceil();
        return remaining.toString();
      }
      return 'SOS\nACTIVATED';
    } else if (widget.isActive) {
      return 'SOS\nACTIVE';
    } else if (widget.isCountdown) {
      return widget.countdownSeconds.toString();
    } else if (_isLongPressing && _isActivationPress) {
      // Show activation countdown
      final remaining = (5.0 * (1.0 - _longPressProgress)).ceil();
      return remaining.toString();
    } else {
      return 'SOS';
    }
  }

  String _getSubText() {
    if (widget.isActivated) {
      if (_isLongPressing && _isResetPress) {
        return 'Resetting...';
      }
      return 'Hold 5s to Reset';
    } else if (widget.isActive) {
      return 'Emergency Active';
    } else if (widget.isCountdown) {
      return 'Activating...';
    } else if (_isLongPressing && _isActivationPress) {
      return 'Keep Holding...';
    } else {
      return 'Hold 5s to Activate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pressAnimation,
          _pulseAnimation,
          _heartbeatAnimation,
          _rippleAnimation,
          _logoFadeAnimation,
        ]),
        builder: (context, child) {
          try {
            // Calculate combined scale
            double scale = _pressAnimation.value;

            // Add pulse effect for active/countdown
            if (widget.isActive || widget.isCountdown) {
              scale *= _pulseAnimation.value;
            }

            // Add heartbeat effect when enabled
            if (widget.enableHeartbeat &&
                !widget.isActive &&
                !widget.isCountdown) {
              scale *= _heartbeatAnimation.value;
            }

            // Ensure valid scale
            scale = scale.clamp(0.8, 1.2);

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple effect
                  if (_rippleAnimation.value > 0)
                    Transform.scale(
                      scale: 1.0 + (_rippleAnimation.value * 0.5),
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getGlowColor().withValues(
                              alpha: 0.8 * (1.0 - _rippleAnimation.value),
                            ),
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                  // Main button
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 0.85,
                      height: widget.size * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getButtonColor().withValues(alpha: 0.9),
                            _getButtonColor(),
                            _getButtonColor().withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        boxShadow: [
                          // Main glow
                          BoxShadow(
                            color: _getGlowColor(),
                            blurRadius: widget.isActive || widget.isCountdown
                                ? 25
                                : 15,
                            spreadRadius: widget.isActive || widget.isCountdown
                                ? 8
                                : 4,
                          ),
                          // Inner shadow for depth
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Button content
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Main text
                              Text(
                                _getButtonText(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      (_isLongPressing || widget.isCountdown)
                                      ? 36
                                      : 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // Sub text
                              if (!widget.isCountdown || _isLongPressing) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _getSubText(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              // Touch icon for inactive state
                              if (!widget.isActive &&
                                  !widget.isCountdown &&
                                  !widget.isActivated &&
                                  !_isLongPressing) ...[
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                              ],
                            ],
                          ),

                          // RedPing Logo with fade effect (fades in and out every 10 seconds)
                          // Test: Always show the logo to debug
                          Opacity(
                            opacity: _logoFadeAnimation.value.clamp(0.0, 1.0),
                            child: Container(
                              width: widget.size * 0.55,
                              height: widget.size * 0.55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.85),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'RP',
                                  style: TextStyle(
                                    color: _getButtonColor(),
                                    fontSize: widget.size * 0.2,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Pulse rings for countdown
                          if (widget.isCountdown)
                            ...List.generate(3, (index) {
                              return AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final delay = index * 0.3;
                                  final adjustedValue =
                                      (_pulseAnimation.value - delay).clamp(
                                        0.0,
                                        1.0,
                                      );
                                  return Transform.scale(
                                    scale: 1.0 + (adjustedValue * 0.3),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.5 * (1.0 - adjustedValue),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),

                          // Long press progress indicator
                          if (_isLongPressing)
                            SizedBox(
                              width: widget.size * 0.95,
                              height: widget.size * 0.95,
                              child: CircularProgressIndicator(
                                value: _longPressProgress,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isActivationPress
                                      ? Colors.white
                                      : Colors.red, // Red for reset progress
                                ),
                              ),
                            ),

                          // Press overlay
                          if (_isPressed || _isLongPressing)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: _isLongPressing ? 0.3 : 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } catch (e) {
            debugPrint('EnhancedSOSButton: Rendering error - $e');
            // Fallback simple button
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(),
              ),
              child: Center(
                child: Text(
                  _getButtonText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
