import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for AI voice interaction controls
class AIVoiceWidget extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const AIVoiceWidget({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  State<AIVoiceWidget> createState() => _AIVoiceWidgetState();
}

class _AIVoiceWidgetState extends State<AIVoiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AIVoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !oldWidget.isListening) {
      _waveController.repeat();
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _waveController.stop();
      _pulseController.stop();
    }

    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _getBorderColor(), width: 2),
      ),
      child: Row(
        children: [
          // Voice button
          Expanded(
            child: GestureDetector(
              onTap: widget.isListening
                  ? widget.onStopListening
                  : widget.onStartListening,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated microphone icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.isListening || widget.isSpeaking
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Icon(
                            widget.isListening
                                ? Icons.mic
                                : widget.isSpeaking
                                ? Icons.volume_up
                                : Icons.mic_none,
                            color: _getIconColor(),
                            size: 24,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // Status text
                    Expanded(
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getTextColor(),
                        ),
                      ),
                    ),

                    // Voice waves animation
                    if (widget.isListening) _buildVoiceWaves(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWaves() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_waveAnimation.value + delay) % 1.0;
            final height = 4 + (animationValue * 16);

            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (widget.isListening) {
      return AppTheme.infoBlue.withValues(alpha: 0.1);
    } else if (widget.isSpeaking) {
      return AppTheme.safeGreen.withValues(alpha: 0.1);
    } else {
      return Colors.white;
    }
  }

  Color _getBorderColor() {
    if (widget.isListening) {
      return AppTheme.infoBlue;
    } else if (widget.isSpeaking) {
      return AppTheme.safeGreen;
    } else {
      return AppTheme.neutralGray.withValues(alpha: 0.3);
    }
  }

  Color _getIconColor() {
    if (widget.isListening) {
      return AppTheme.infoBlue;
    } else if (widget.isSpeaking) {
      return AppTheme.safeGreen;
    } else {
      return AppTheme.neutralGray;
    }
  }

  Color _getTextColor() {
    if (widget.isListening) {
      return AppTheme.infoBlue;
    } else if (widget.isSpeaking) {
      return AppTheme.safeGreen;
    } else {
      return AppTheme.secondaryText;
    }
  }

  String _getStatusText() {
    if (widget.isListening) {
      return 'Listening... Tap to stop';
    } else if (widget.isSpeaking) {
      return 'AI is speaking...';
    } else {
      return 'Tap to speak or type below';
    }
  }
}
