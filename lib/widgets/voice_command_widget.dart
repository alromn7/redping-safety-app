import 'package:flutter/material.dart';
import '../services/phone_voice_integration_service.dart';

/// Voice Command Widget
/// Displays voice command status, available commands, and provides UI controls
class VoiceCommandWidget extends StatefulWidget {
  const VoiceCommandWidget({super.key});

  @override
  State<VoiceCommandWidget> createState() => _VoiceCommandWidgetState();
}

class _VoiceCommandWidgetState extends State<VoiceCommandWidget>
    with SingleTickerProviderStateMixin {
  final PhoneVoiceIntegrationService _phoneVoice =
      PhoneVoiceIntegrationService();

  bool _isListening = false;
  String _recognizedText = '';
  String _lastCommand = '';
  bool _showCommands = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for listening indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Setup callbacks
    _phoneVoice.setOnListeningStateChanged((isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    });

    _phoneVoice.setOnVoiceRecognized((text) {
      if (mounted) {
        setState(() {
          _recognizedText = text;
        });
      }
    });

    _phoneVoice.setOnVoiceCommand((command) {
      if (mounted) {
        setState(() {
          _lastCommand = command;
        });
      }
    });

    // Check listening status
    _isListening = _phoneVoice.isListening;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                // Microphone icon with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: _isListening ? Colors.red : Colors.grey,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Commands',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isListening
                            ? '🎤 Listening...'
                            : 'Say "Hey RedPing" to activate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle button
                Switch(
                  value: _phoneVoice.voiceCommandsEnabled,
                  onChanged: (value) async {
                    await _phoneVoice.setVoiceCommandsEnabled(value);
                    if (value && !_isListening) {
                      _phoneVoice.startVoiceListening();
                    }
                    setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recognized text display
            if (_recognizedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You said:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recognizedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Last command display
            if (_lastCommand.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Command: ${_formatCommandName(_lastCommand)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Show available commands button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCommands = !_showCommands;
                });
              },
              icon: Icon(_showCommands ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _showCommands ? 'Hide Commands' : 'Show Available Commands',
              ),
            ),

            // Available commands list
            if (_showCommands) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Available Voice Commands:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._buildCommandsList(),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening
                        ? () async {
                            _phoneVoice.stopVoiceListening();
                            setState(() {});
                          }
                        : () async {
                            if (!_phoneVoice.isInitialized) {
                              await _phoneVoice.initialize();
                            }
                            _phoneVoice.startVoiceListening();
                            setState(() {});
                          },
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop' : 'Start Listening'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _phoneVoice.speak(
                      'Voice commands are ready. Say Hey RedPing to activate.',
                    );
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Test Voice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommandsList() {
    final commands = _phoneVoice.getAvailableCommands();
    final widgets = <Widget>[];

    commands.forEach((key, patterns) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCommandIcon(key),
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCommandName(key),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: patterns
                      .map(
                        (pattern) => Chip(
                          label: Text(
                            '"$pattern"',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  String _formatCommandName(String command) {
    return command
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getCommandIcon(String command) {
    switch (command) {
      case 'activate_sos':
        return Icons.emergency;
      case 'cancel_sos':
        return Icons.cancel;
      case 'call_emergency':
        return Icons.phone;
      case 'open_sos_page':
        return Icons.open_in_new;
      case 'check_status':
        return Icons.info;
      case 'enable_crash_detection':
        return Icons.sensors;
      case 'disable_crash_detection':
        return Icons.sensors_off;
      default:
        return Icons.record_voice_over;
    }
  }
}

/// Compact voice status indicator
/// For displaying in app bar or other locations
class VoiceStatusIndicator extends StatefulWidget {
  const VoiceStatusIndicator({super.key});

  @override
  State<VoiceStatusIndicator> createState() => _VoiceStatusIndicatorState();
}

class _VoiceStatusIndicatorState extends State<VoiceStatusIndicator>
    with SingleTickerProviderStateMixin {
  final PhoneVoiceIntegrationService _phoneVoice =
      PhoneVoiceIntegrationService();
  bool _isListening = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _phoneVoice.setOnListeningStateChanged((isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    });

    _isListening = _phoneVoice.isListening;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isListening) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1 + (_animController.value * 0.2)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 
                0.3 + (_animController.value * 0.4),
              ),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 16, color: Colors.red[700]),
              const SizedBox(width: 6),
              Text(
                'Listening',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
