import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/theme/app_theme.dart';

class SosCountdownDialog extends StatefulWidget {
  final ValueListenable<int> countdown;
  final VoidCallback onCancel;
  final void Function(String transcription)? onDistressActivate;
  final bool enableVoiceCancel;

  const SosCountdownDialog({
    super.key,
    required this.countdown,
    required this.onCancel,
    this.onDistressActivate,
    required this.enableVoiceCancel,
  });

  @override
  State<SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<SosCountdownDialog> {
  final FlutterTts _tts = FlutterTts();
  int? _lastAnnouncedSecond;
  bool _keepFinalAnnouncementAlive = false;
  Timer? _initialAnnouncementTimer;
  Timer? _initialAnnouncementRetryTimer;
  bool _initialPromptStarted = false;

  @override
  void initState() {
    super.initState();
    widget.countdown.addListener(_onCountdownChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialAnnouncementTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        unawaited(_announceCountdownMode());
      });
    });
  }

  @override
  void dispose() {
    widget.countdown.removeListener(_onCountdownChanged);
    _initialAnnouncementTimer?.cancel();
    _initialAnnouncementRetryTimer?.cancel();
    if (!_keepFinalAnnouncementAlive) {
      try {
        _tts.stop();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _announceCountdownMode() async {
    await _configureTts();
    await _speak('Crash detected. Tap the on-screen button if you are okay.');

    // Cold-start fallback: some devices bind the TTS engine late and the
    // first utterance may be dropped silently. Retry once only if speech
    // still did not start and countdown is still in the opening window.
    _initialAnnouncementRetryTimer?.cancel();
    _initialAnnouncementRetryTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (!mounted) return;
        if (_initialPromptStarted) return;
        if (widget.countdown.value < 24) return;
        unawaited(
          _speak(
            'Crash detected. Tap the on-screen button if you are okay.',
            interruptCurrent: false,
          ),
        );
      },
    );

    _onCountdownChanged();
  }

  void _onCountdownChanged() {
    final seconds = widget.countdown.value;
    if (_lastAnnouncedSecond == seconds) return;
    _lastAnnouncedSecond = seconds;

    if (seconds <= 5 && seconds >= 1) {
      unawaited(SystemSound.play(SystemSoundType.alert));
      unawaited(_speak('$seconds'));
    } else if (seconds == 0) {
      _keepFinalAnnouncementAlive = true;
      unawaited(_speak('SOS activated.', interruptCurrent: true));
    }
  }

  Future<void> _configureTts() async {
    try {
      _tts.setStartHandler(() {
        _initialPromptStarted = true;
      });
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String text, {bool interruptCurrent = true}) async {
    if (interruptCurrent) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppTheme.warningOrange,
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsAlignment: MainAxisAlignment.center,
      title: const Text(
        '⚠️ CRASH DETECTED',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.car_crash, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Are you OK?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: widget.countdown,
            builder: (context, value, _) => Text(
              'SOS will activate in $value seconds',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<int>(
            valueListenable: widget.countdown,
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap "I\'m OK" to cancel before countdown ends.',
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.enableVoiceCancel ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.enableVoiceCancel
                    ? 'Voice verification: ON'
                    : 'Voice verification: OFF',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onCancel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text(
              "I'm OK",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
