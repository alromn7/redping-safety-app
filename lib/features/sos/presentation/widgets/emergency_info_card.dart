import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Emergency information card with important safety tips and info
class EmergencyInfoCard extends StatelessWidget {
  const EmergencyInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.infoBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.infoBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.phone,
              title: 'Emergency Services',
              subtitle: 'Call 911 for immediate help',
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.timer,
              title: 'SOS Countdown',
              subtitle: '10 seconds to cancel automatic alert',
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Location Sharing',
              subtitle: 'Your location will be shared with contacts',
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.mic,
              title: 'Voice Verification',
              subtitle: 'Speak clearly to confirm or cancel SOS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.secondaryText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
