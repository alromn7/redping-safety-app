import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/communication_tracking_service.dart';
import '../../../../core/logging/app_logger.dart';

/// Reusable widget for Call and SMS communication buttons
/// Aligned with website's call tracking functionality
class CommunicationButtons extends StatelessWidget {
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? sosId;
  final String? helpRequestId;
  final String sarMemberId;
  final String sarMemberName;
  final String? helpCategory;

  const CommunicationButtons({
    super.key,
    this.userId,
    this.userName,
    this.userPhone,
    this.sosId,
    this.helpRequestId,
    required this.sarMemberId,
    required this.sarMemberName,
    this.helpCategory,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show buttons if no phone number
    if (userPhone == null || userPhone!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Contact Information',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),

          // User Info and Communication Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userName != null && userName!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            userName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          userPhone!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (userId != null && userId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'User ID: $userId',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Communication Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Call Button
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCall(context),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // SMS Button
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSMS(context),
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle phone call
  Future<void> _handleCall(BuildContext context) async {
    try {
      // Log to Firestore
      final trackingService = CommunicationTrackingService();
      final logged = await trackingService.logCall(
        recipientPhone: userPhone!,
        recipientName: userName ?? 'Unknown',
        sosId: sosId,
        helpRequestId: helpRequestId,
        recipientId: userId,
        senderId: sarMemberId,
        senderName: sarMemberName,
        additionalMetadata: {
          if (helpCategory != null) 'helpCategory': helpCategory,
        },
      );

      if (!logged) {
        AppLogger.w(
          'Failed to log call to Firestore',
          tag: 'CommunicationButtons',
        );
      }

      // Launch phone dialer
      final uri = Uri(scheme: 'tel', path: userPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📞 Call initiated to ${userName ?? userPhone}'),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      AppLogger.e(
        'Failed to initiate call',
        tag: 'CommunicationButtons',
        error: e,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to initiate call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle SMS
  Future<void> _handleSMS(BuildContext context) async {
    try {
      // Log to Firestore
      final trackingService = CommunicationTrackingService();
      final logged = await trackingService.logSMS(
        recipientPhone: userPhone!,
        recipientName: userName ?? 'Unknown',
        sosId: sosId,
        helpRequestId: helpRequestId,
        recipientId: userId,
        senderId: sarMemberId,
        senderName: sarMemberName,
        additionalMetadata: {
          if (helpCategory != null) 'helpCategory': helpCategory,
        },
      );

      if (!logged) {
        AppLogger.w(
          'Failed to log SMS to Firestore',
          tag: 'CommunicationButtons',
        );
      }

      // Launch SMS app
      final uri = Uri(scheme: 'sms', path: userPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💬 SMS opened to ${userName ?? userPhone}'),
              backgroundColor: Colors.blue[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      AppLogger.e('Failed to open SMS', tag: 'CommunicationButtons', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to open SMS'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
