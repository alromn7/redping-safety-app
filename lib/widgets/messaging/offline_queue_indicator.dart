import 'package:flutter/material.dart';
import '../../services/messaging_initializer.dart';
import '../../services/messaging/transport_manager.dart';

/// Widget to display offline message queue status
class OfflineQueueIndicator extends StatelessWidget {
  final MessagingInitializer messaging;
  final VoidCallback? onTap;

  const OfflineQueueIndicator({super.key, required this.messaging, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TransportStatus>(
      stream: messaging.transportManager.statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        final count = status.outboxCount;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        // Determine color based on connection status
        final color = status.hasActiveTransport
            ? Colors
                  .green // Syncing
            : Colors.orange; // Offline, queued

        return InkWell(
          onTap: onTap ?? () => _showQueueDetails(context, status),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  status.hasActiveTransport
                      ? Icons.cloud_sync
                      : Icons.cloud_queue,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),

                // Count
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),

                // Label
                Text('queued', style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQueueDetails(BuildContext context, TransportStatus status) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          OfflineQueueDetailsSheet(messaging: messaging, status: status),
    );
  }
}

/// Bottom sheet showing detailed queue information
class OfflineQueueDetailsSheet extends StatelessWidget {
  final MessagingInitializer messaging;
  final TransportStatus status;

  const OfflineQueueDetailsSheet({
    super.key,
    required this.messaging,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                status.hasActiveTransport ? Icons.cloud_sync : Icons.cloud_off,
                color: status.hasActiveTransport ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status.hasActiveTransport
                      ? 'Syncing Messages'
                      : 'Offline Mode',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Queue count
          _buildInfoRow(
            Icons.queue,
            'Messages Queued',
            '${status.outboxCount}',
          ),
          const SizedBox(height: 12),

          // Connection status
          _buildInfoRow(
            status.internet ? Icons.wifi : Icons.wifi_off,
            'Internet',
            status.internet ? 'Connected' : 'Disconnected',
            color: status.internet ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),

          // Active transport
          if (status.activeTransport != null) ...[
            _buildInfoRow(
              Icons.router,
              'Active Transport',
              status.activeTransport!.name,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          // Last sync time
          if (status.hasActiveTransport) ...[
            _buildInfoRow(
              Icons.sync,
              'Syncing',
              'Messages being sent...',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // Manual sync button
          if (status.outboxCount > 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: status.hasActiveTransport
                    ? () async {
                        await messaging.manualSync();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Messages synced successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Info text
          Text(
            status.hasActiveTransport
                ? 'Messages will be sent automatically when online.'
                : 'Messages are queued and will be sent when connection is restored.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Compact badge version for app bar
class OfflineQueueBadge extends StatelessWidget {
  final MessagingInitializer messaging;
  final VoidCallback? onTap;

  const OfflineQueueBadge({super.key, required this.messaging, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TransportStatus>(
      stream: messaging.transportManager.statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        final count = status.outboxCount;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed:
              onTap ??
              () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => OfflineQueueDetailsSheet(
                    messaging: messaging,
                    status: status,
                  ),
                );
              },
          icon: Badge(
            label: Text('$count'),
            child: Icon(
              status.hasActiveTransport ? Icons.cloud_sync : Icons.cloud_queue,
              color: status.hasActiveTransport ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }
}
