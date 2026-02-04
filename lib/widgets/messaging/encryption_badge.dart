import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/messaging_initializer.dart';

/// Widget to display encryption status and details
class EncryptionBadge extends StatelessWidget {
  final String conversationId;
  final MessagingInitializer messaging;
  final bool showDetails;

  const EncryptionBadge({
    super.key,
    required this.conversationId,
    required this.messaging,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: showDetails ? () => _showEncryptionDetails(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            const Text(
              'Encrypted',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 14, color: Colors.green),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEncryptionDetails(BuildContext context) async {
    // Get conversation key fingerprint
    final conversationKey = await messaging.crypto.getConversationKey(
      conversationId,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => EncryptionDetailsDialog(
        conversationId: conversationId,
        conversationKey: conversationKey,
        messaging: messaging,
      ),
    );
  }
}

/// Dialog showing detailed encryption information
class EncryptionDetailsDialog extends StatelessWidget {
  final String conversationId;
  final String? conversationKey;
  final MessagingInitializer messaging;

  const EncryptionDetailsDialog({
    super.key,
    required this.conversationId,
    required this.conversationKey,
    required this.messaging,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, color: Colors.green),
          const SizedBox(width: 12),
          const Text('Encryption Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encryption status
            _buildInfoSection(
              icon: Icons.verified_user,
              title: 'End-to-End Encrypted',
              description:
                  'Messages are encrypted on your device and can only be read by you and the recipient.',
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // Algorithm info
            _buildInfoSection(
              icon: Icons.security,
              title: 'Encryption Algorithm',
              description:
                  'AES-GCM 256-bit encryption with X25519 key exchange and Ed25519 signatures.',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // Conversation key fingerprint
            if (conversationKey != null) ...[
              _buildInfoSection(
                icon: Icons.fingerprint,
                title: 'Conversation Key',
                description: 'Each conversation has a unique encryption key.',
                color: Colors.purple,
              ),
              const SizedBox(height: 8),
              _buildFingerprintBox(context, conversationKey!),
              const SizedBox(height: 16),
            ],

            // Signature verification
            _buildInfoSection(
              icon: Icons.verified,
              title: 'Signature Verification',
              description:
                  'All messages are digitally signed to ensure authenticity.',
              color: Colors.teal,
            ),
            const SizedBox(height: 16),

            // Security notes
            _buildSecurityNotes(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFingerprintBox(BuildContext context, String key) {
    // Generate fingerprint (first 32 chars of key)
    final fingerprint = key.length > 32 ? key.substring(0, 32) : key;
    final formatted = _formatFingerprint(fingerprint);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fingerprint));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fingerprint copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFingerprint(String fingerprint) {
    // Format as groups of 4 characters
    final buffer = StringBuffer();
    for (int i = 0; i < fingerprint.length; i += 4) {
      if (i > 0) buffer.write(' ');
      final end = (i + 4 < fingerprint.length) ? i + 4 : fingerprint.length;
      buffer.write(fingerprint.substring(i, end));
    }
    return buffer.toString();
  }

  Widget _buildSecurityNotes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Security Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
            'Messages are encrypted before leaving your device',
          ),
          _buildBulletPoint('RedPing cannot read your messages'),
          _buildBulletPoint('Each conversation uses a unique encryption key'),
          _buildBulletPoint('Keys are stored securely on your device'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact encryption indicator for message list
class CompactEncryptionIndicator extends StatelessWidget {
  final bool isEncrypted;

  const CompactEncryptionIndicator({super.key, this.isEncrypted = true});

  @override
  Widget build(BuildContext context) {
    if (!isEncrypted) {
      return const SizedBox.shrink();
    }

    return const Tooltip(
      message: 'End-to-end encrypted',
      child: Icon(Icons.lock, size: 12, color: Colors.green),
    );
  }
}
