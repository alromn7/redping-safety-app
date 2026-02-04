import 'package:flutter/material.dart';
import '../../services/messaging_initializer.dart';
import '../../services/messaging/sync_service.dart';

/// Manual sync button for messages
class ManualSyncButton extends StatefulWidget {
  final MessagingInitializer messaging;
  final VoidCallback? onSyncComplete;

  const ManualSyncButton({
    super.key,
    required this.messaging,
    this.onSyncComplete,
  });

  @override
  State<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends State<ManualSyncButton> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isSyncing ? null : _handleSync,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      tooltip: 'Sync messages',
    );
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await widget.messaging.manualSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Messages synced successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        widget.onSyncComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}

/// Pull-to-refresh wrapper for message lists
class MessageListRefreshWrapper extends StatelessWidget {
  final MessagingInitializer messaging;
  final Widget child;
  final VoidCallback? onRefreshComplete;

  const MessageListRefreshWrapper({
    super.key,
    required this.messaging,
    required this.child,
    this.onRefreshComplete,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _handleRefresh, child: child);
  }

  Future<void> _handleRefresh() async {
    try {
      await messaging.manualSync();
      onRefreshComplete?.call();
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }
}

/// Sync status indicator with last sync time
class SyncStatusIndicator extends StatelessWidget {
  final MessagingInitializer messaging;

  const SyncStatusIndicator({super.key, required this.messaging});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncEvent>(
      stream: messaging.syncService.syncEventsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildIdleState();
        }

        final event = snapshot.data!;

        switch (event.type) {
          case SyncEventType.started:
            return _buildSyncingState();
          case SyncEventType.completed:
            return _buildCompletedState(event);
          case SyncEventType.failed:
            return _buildFailedState(event);
          case SyncEventType.manualTrigger:
            return _buildSyncingState();
        }
      },
    );
  }

  Widget _buildIdleState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Up to date',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Syncing...',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(SyncEvent event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Synced ${_formatDuration(event.duration ?? Duration.zero)} ago',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState(SyncEvent event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            event.error ?? 'Sync failed',
            style: const TextStyle(fontSize: 12, color: Colors.red),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 1) {
      return 'just now';
    } else if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inHours}h';
    }
  }
}

/// Floating action button for manual sync
class SyncFAB extends StatefulWidget {
  final MessagingInitializer messaging;
  final VoidCallback? onSyncComplete;

  const SyncFAB({super.key, required this.messaging, this.onSyncComplete});

  @override
  State<SyncFAB> createState() => _SyncFABState();
}

class _SyncFABState extends State<SyncFAB> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.messaging.transportManager.statusStream.map(
        (status) => status.outboxCount,
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0 && !_isSyncing) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: _isSyncing ? null : _handleSync,
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.sync),
          label: Text(_isSyncing ? 'Syncing...' : 'Sync $count'),
          backgroundColor: _isSyncing ? Colors.grey : Colors.green,
        );
      },
    );
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await widget.messaging.manualSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Messages synced successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        widget.onSyncComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}
