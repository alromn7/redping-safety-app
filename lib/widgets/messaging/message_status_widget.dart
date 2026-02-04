import 'package:flutter/material.dart';
import '../../models/messaging/message_packet.dart' as msg;

/// Widget to display message status with encryption, delivery, and transport indicators
class MessageStatusWidget extends StatelessWidget {
  final msg.MessagePacket packet;
  final VoidCallback? onRetry;
  final bool showEncryption;
  final bool showTransport;

  const MessageStatusWidget({
    super.key,
    required this.packet,
    this.onRetry,
    this.showEncryption = true,
    this.showTransport = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encryption indicator
        if (showEncryption) ...[
          Icon(
            Icons.lock,
            size: 12,
            color: Colors.green,
            semanticLabel: 'Encrypted',
          ),
          const SizedBox(width: 4),
        ],

        // Delivery status
        _buildStatusIcon(context),
        const SizedBox(width: 4),

        // Transport badge
        if (showTransport) ...[
          _buildTransportBadge(context),
          const SizedBox(width: 4),
        ],

        // Retry button for failed messages
        if (_isFailedStatus() && onRetry != null) ...[
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.refresh,
                size: 14,
                color: Colors.orange,
                semanticLabel: 'Retry',
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build delivery status icon
  Widget _buildStatusIcon(BuildContext context) {
    final status = _getMessageStatus();

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'queued':
        icon = Icons.schedule;
        color = Colors.grey;
        label = 'Queued';
        break;
      case 'sending':
        icon = Icons.sync;
        color = Colors.blue;
        label = 'Sending';
        break;
      case 'sentInternet':
      case 'sentMesh':
      case 'sentSatellite':
        icon = Icons.check;
        color = Colors.green;
        label = 'Sent';
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue;
        label = 'Read';
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = Colors.red;
        label = 'Failed';
        break;
      case 'expired':
        icon = Icons.access_time;
        color = Colors.orange;
        label = 'Expired';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        label = 'Unknown';
    }

    return Icon(icon, size: 12, color: color, semanticLabel: label);
  }

  /// Build transport type badge
  Widget _buildTransportBadge(BuildContext context) {
    final status = _getMessageStatus();
    String? transportText;
    Color? badgeColor;

    if (status == 'sentInternet') {
      transportText = 'Internet';
      badgeColor = Colors.blue;
    } else if (status == 'sentMesh') {
      transportText = 'Mesh';
      badgeColor = Colors.purple;
    } else if (status == 'sentSatellite') {
      transportText = 'Satellite';
      badgeColor = Colors.teal;
    } else if (packet.status.contains('sent')) {
      // Parse from status string if available
      if (packet.metadata.containsKey('transportUsed')) {
        transportText = packet.metadata['transportUsed'] as String?;
        badgeColor = Colors.green;
      }
    }

    if (transportText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor ?? Colors.grey, width: 0.5),
      ),
      child: Text(
        transportText,
        style: TextStyle(
          fontSize: 8,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Get message status string
  String _getMessageStatus() {
    return packet.status;
  }

  /// Check if message is in failed state
  bool _isFailedStatus() {
    final status = _getMessageStatus();
    return status == 'failed' || status == 'expired';
  }
}

/// Compact version for message bubbles
class CompactMessageStatusWidget extends StatelessWidget {
  final msg.MessagePacket packet;
  final VoidCallback? onRetry;

  const CompactMessageStatusWidget({
    super.key,
    required this.packet,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MessageStatusWidget(
      packet: packet,
      onRetry: onRetry,
      showTransport: false, // Hide transport in compact view
    );
  }
}

/// Full detailed status for message details screen
class DetailedMessageStatusWidget extends StatelessWidget {
  final msg.MessagePacket packet;
  final VoidCallback? onRetry;

  const DetailedMessageStatusWidget({
    super.key,
    required this.packet,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Row(
          children: [
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            MessageStatusWidget(packet: packet, onRetry: onRetry),
          ],
        ),
        const SizedBox(height: 8),

        // Encryption info
        Row(
          children: [
            const Icon(Icons.lock, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'End-to-end encrypted',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Timestamp
        Text(
          'Sent: ${_formatTimestamp(packet.timestamp)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),

        // TTL
        if (packet.ttl > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Expires: ${_formatExpiry(packet.timestamp, packet.ttl)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],

        // Transport details
        if (packet.metadata.containsKey('transportUsed')) ...[
          const SizedBox(height: 4),
          Text(
            'Via: ${packet.metadata['transportUsed']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],

        // Signature verification
        if (packet.signature.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.verified, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Signature verified',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatExpiry(int timestamp, int ttl) {
    final sentDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expiryDate = sentDate.add(Duration(seconds: ttl));
    final now = DateTime.now();
    final remaining = expiryDate.difference(now);

    if (remaining.isNegative) {
      return 'Expired';
    } else if (remaining.inHours < 1) {
      return 'in ${remaining.inMinutes}m';
    } else if (remaining.inDays < 1) {
      return 'in ${remaining.inHours}h';
    } else {
      return 'in ${remaining.inDays}d';
    }
  }
}
