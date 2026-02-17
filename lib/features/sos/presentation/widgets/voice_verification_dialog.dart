import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class VoiceVerificationDialog extends StatelessWidget {
  const VoiceVerificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: const Text(
        'Voice Verification',
        style: TextStyle(
          color: AppTheme.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        'If you are safe, tap "I\'m OK" to dismiss this check. '
        'If you still need assistance, tap "Keep SOS Active".',
        style: TextStyle(
          color: AppTheme.secondaryText,
          height: 1.3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text(
            'Keep SOS Active',
            style: TextStyle(color: AppTheme.warningOrange),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.safeGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          child: const Text("I'm OK"),
        ),
      ],
    );
  }
}
