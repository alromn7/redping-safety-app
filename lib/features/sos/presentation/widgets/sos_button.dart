import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Main SOS button with visual feedback and animations
class SOSButton extends StatefulWidget {
  final bool isActive;
  final bool isCountdown;
  final int countdownSeconds;
  final VoidCallback onPressed;

  const SOSButton({
    super.key,
    required this.isActive,
    required this.isCountdown,
    required this.countdownSeconds,
    required this.onPressed,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late Animation<double> _pressAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SOSButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle pulse animation for active state
    if (widget.isActive && !oldWidget.isActive) {
      // Start pulse animation when SOS becomes active
      if (!_pulseController.isAnimating && mounted) {
        _pulseController.repeat(reverse: true);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      // Stop pulse animation when SOS becomes inactive
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Handle countdown state changes
    if (widget.isCountdown && !oldWidget.isCountdown) {
      // Start countdown pulse if not already running
      if (!_pulseController.isAnimating && mounted) {
        _pulseController.repeat(reverse: true);
      }
    } else if (!widget.isCountdown && oldWidget.isCountdown) {
      // Stop countdown pulse if not active
      if (!widget.isActive && mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
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
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  Color _getButtonColor() {
    if (widget.isActive) {
      return AppTheme.primaryRed;
    } else if (widget.isCountdown) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.primaryRed;
    }
  }

  String _getButtonText() {
    if (widget.isActive) {
      return 'SOS\nACTIVE';
    } else if (widget.isCountdown) {
      return '${widget.countdownSeconds}';
    } else {
      return 'SOS';
    }
  }

  double _calculateRippleOpacity() {
    double pulseValue = _pulseAnimation.value;

    // Validate pulse animation value
    if (!pulseValue.isFinite || pulseValue.isNaN) {
      return 0.0;
    }

    // Calculate opacity with bounds checking
    double opacity = 0.5 * (1 - pulseValue);

    // Ensure opacity is within valid range
    return opacity.clamp(0.0, 1.0);
  }

  double _getSafeBlurRadius() {
    // Use smaller, safer blur radius values
    return widget.isActive ? 20.0 : 12.0;
  }

  double _getSafeSpreadRadius() {
    // Use smaller, safer spread radius values
    return widget.isActive ? 6.0 : 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressAnimation, _pulseAnimation]),
        builder: (context, child) {
          // Wrap in try-catch to prevent painting errors
          try {
            // Calculate base scale from press animation with validation
            double scale = _pressAnimation.value;

            // Validate animation values to prevent painting errors
            if (!scale.isFinite || scale.isNaN) {
              scale = 1.0;
            }

            // Add pulse effect for active or countdown states
            if (widget.isActive || widget.isCountdown) {
              // Get pulse scale with validation
              double pulseScale = _pulseAnimation.value;
              if (!pulseScale.isFinite || pulseScale.isNaN) {
                pulseScale = 1.0;
              }

              // Clamp pulse animation to prevent excessive scaling
              pulseScale = pulseScale.clamp(0.95, 1.05);
              scale *= pulseScale;
            }

            // Final validation and clamping to prevent painting issues
            if (!scale.isFinite || scale.isNaN) {
              scale = 1.0;
            }
            scale = scale.clamp(0.9, 1.1);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: AppConstants.sosButtonSize.clamp(100.0, 300.0),
                height: AppConstants.sosButtonSize.clamp(100.0, 300.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getButtonColor(),
                      _getButtonColor().withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getButtonColor().withValues(alpha: 0.4),
                      blurRadius: _getSafeBlurRadius(),
                      spreadRadius: _getSafeSpreadRadius(),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple effect for countdown
                    if (widget.isCountdown)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: _calculateRippleOpacity(),
                                  ),
                                  width: 3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Button content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isCountdown) ...[
                          Text(
                            _getButtonText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ] else ...[
                          Text(
                            _getButtonText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        if (!widget.isCountdown && !widget.isActive) ...[
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ],
                    ),

                    // Press indicator
                    if (_isPressed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } catch (e) {
            // If any painting error occurs, return a safe fallback
            debugPrint('SOSButton: Painting error caught - $e');
            return Container(
              width: AppConstants.sosButtonSize.clamp(100.0, 300.0),
              height: AppConstants.sosButtonSize.clamp(100.0, 300.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryRed,
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
