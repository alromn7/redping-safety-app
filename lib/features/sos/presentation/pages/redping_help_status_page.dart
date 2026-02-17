import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/emergency_message.dart';
import '../../../../models/sos_ping.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/auth_service.dart';

class RedpingHelpStatusPage extends StatefulWidget {
  final String? pingId;

  const RedpingHelpStatusPage({super.key, this.pingId});

  @override
  State<RedpingHelpStatusPage> createState() => _RedpingHelpStatusPageState();
}

class _RedpingHelpStatusPageState extends State<RedpingHelpStatusPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final AuthService _authService = AuthService.instance;

  Timer? _refreshTimer;
  final TextEditingController _updateController = TextEditingController();
  bool _isSendingUpdate = false;
  bool _isClosingRequest = false;
  String? _lastHelpPingId;
  String? _lastHelpOwnerId;

  bool _isTerminalStatus(SOSPingStatus status) {
    switch (status) {
      case SOSPingStatus.resolved:
      case SOSPingStatus.cancelled:
      case SOSPingStatus.expired:
        return true;
      case SOSPingStatus.active:
      case SOSPingStatus.assigned:
      case SOSPingStatus.inProgress:
        return false;
    }
  }

  DateTime? _tryParseIsoDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_prime());
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _prime() async {
    // 1) Load ownership hints so "Close Request" works offline/no-auth.
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastHelpPingId = prefs.getString('last_redping_help_ping_id');
      _lastHelpOwnerId = prefs.getString('last_redping_help_owner_id');
    } catch (_) {}

    // 2) Ensure ping + conversation services are ready.
    try {
      if (!_serviceManager.sosPingService.isInitialized) {
        await _serviceManager.sosPingService.initialize();
      }
    } catch (_) {
      // best-effort; UI will show "not available yet" until it comes online
    }

    try {
      if (!_serviceManager.messagingIntegrationService.isInitialized) {
        await _serviceManager.messagingIntegrationService.initialize();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _updateController.dispose();
    super.dispose();
  }

  Future<void> _sendUpdate({required String pingId}) async {
    if (_isSendingUpdate) return;
    final text = _updateController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingUpdate = true);
    try {
      if (!_serviceManager.messagingIntegrationService.isInitialized) {
        await _serviceManager.messagingIntegrationService.initialize();
      }

      await _serviceManager.messagingIntegrationService.sendREDPINGHelpMessage(
        pingId: pingId,
        content: text,
      );

      // Ensure SAR dashboards reflect the latest details even if they primarily
      // render from `help_requests`.
      try {
        await _serviceManager.sosPingService.publishHelpRequestUpdate(
          pingId: pingId,
          updateText: text,
        );
      } catch (_) {
        // best-effort only
      }

      if (!mounted) return;
      _updateController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Update sent'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send update: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingUpdate = false);
    }
  }

  Future<void> _closeRequest({
    required String pingId,
    required SOSPing ping,
    required bool isOwner,
  }) async {
    if (_isClosingRequest) return;
    if (_isTerminalStatus(ping.status)) return;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only close your own help request.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text(
            'Close help request?',
            style: TextStyle(color: AppTheme.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will mark your request as closed/resolved and it will be counted under SAR resolved cases.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: InputDecoration(
                  hintText: 'Optional closure note (e.g., Safe now)',
                  hintStyle: const TextStyle(color: AppTheme.secondaryText),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.infoBlue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeGreen,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    final note = noteController.text.trim();
    noteController.dispose();

    if (confirmed != true) return;

    setState(() => _isClosingRequest = true);
    try {
      // Best-effort: send a final update before closing.
      try {
        if (!_serviceManager.messagingIntegrationService.isInitialized) {
          await _serviceManager.messagingIntegrationService.initialize();
        }
        await _serviceManager.messagingIntegrationService
            .sendREDPINGHelpMessage(
              pingId: pingId,
              content: note.isNotEmpty
                  ? 'User closed request: $note'
                  : 'User closed request (resolved).',
            );
      } catch (_) {}

      await _serviceManager.sosPingService.closeHelpRequest(
        pingId: pingId,
        closureNote: note.isNotEmpty ? note : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Help request closed'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to close request: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClosingRequest = false);
    }
  }

  SOSPing? _getPing() {
    final pingId = widget.pingId;
    if (pingId == null || pingId.isEmpty) return null;
    return _serviceManager.sosPingService.getPingById(pingId);
  }

  List<EmergencyMessage> _getMessages() {
    final pingId = widget.pingId;
    if (pingId == null || pingId.isEmpty) return const [];
    if (!_serviceManager.messagingIntegrationService.isInitialized) {
      return const [];
    }
    return _serviceManager.messagingIntegrationService.getConversationForPing(
      pingId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ping = _getPing();
    final messages = _getMessages();
    final firebaseUid =
        firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    final authUserId = _authService.currentUser.id;
    final profileUserId =
        _serviceManager.profileService.currentProfile?.id ?? '';
    final effectiveUserId = firebaseUid.isNotEmpty
        ? firebaseUid
        : (authUserId.isNotEmpty
              ? authUserId
              : (profileUserId.isNotEmpty
                    ? profileUserId
                    : (_lastHelpOwnerId ?? '')));
    final pingId = widget.pingId;

    final isOwner =
        ping != null &&
        ((effectiveUserId.isNotEmpty && ping.userId == effectiveUserId) ||
            (_lastHelpPingId != null && _lastHelpPingId == ping.id));
    final isClosed = ping != null && _isTerminalStatus(ping.status);
    final canInteract =
        pingId != null && pingId.isNotEmpty && ping != null && !isClosed;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('REDP!NG Help Status'),
        leading: IconButton(
          tooltip: 'Back to Main',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRouter.main);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Back to Main',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(AppRouter.main),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _HeaderCard(
            pingId: widget.pingId,
            ping: ping,
            currentUserId: effectiveUserId,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRouter.main),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Main'),
            ),
          ),
          if (ping != null && isClosed) ...[
            const SizedBox(height: 12),
            _ClosedBanner(
              ping: ping,
              closedAt: _tryParseIsoDateTime(ping.metadata['closedAt']),
              closedByName: (ping.metadata['closedByName'] ?? '').toString(),
              closureNote: (ping.metadata['closureNote'] ?? '').toString(),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Update / Close',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (ping != null)
                      Text(
                        ping.status.name,
                        style: TextStyle(
                          color: isClosed
                              ? (ping.status == SOSPingStatus.resolved
                                    ? AppTheme.safeGreen
                                    : AppTheme.warningOrange)
                              : AppTheme.infoBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _updateController,
                  enabled:
                      canInteract && !_isSendingUpdate && !_isClosingRequest,
                  style: const TextStyle(color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    hintText: canInteract
                        ? 'Send an update to SAR…'
                        : (isClosed
                              ? 'Request is closed'
                              : 'Request not available yet'),
                    hintStyle: const TextStyle(color: AppTheme.secondaryText),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.infoBlue),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (pingId == null) return;
                    _sendUpdate(pingId: pingId);
                  },
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 420;

                    final sendButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoBlue,
                      ),
                      onPressed: (canInteract && !_isSendingUpdate)
                          ? () => _sendUpdate(pingId: pingId)
                          : null,
                      icon: _isSendingUpdate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: const Text('Send Update'),
                    );

                    final closeButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.safeGreen,
                      ),
                      onPressed: (canInteract && isOwner && !_isClosingRequest)
                          ? () => _closeRequest(
                              pingId: pingId,
                              ping: ping,
                              isOwner: isOwner,
                            )
                          : null,
                      icon: _isClosingRequest
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 18),
                      label: const Text('Close Request'),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          sendButton,
                          const SizedBox(height: 10),
                          closeButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: sendButton),
                        const SizedBox(width: 10),
                        Expanded(child: closeButton),
                      ],
                    );
                  },
                ),
                if (!isOwner && ping != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Only the sender can close this request.',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _MessagesCard(messages: messages),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String? pingId;
  final SOSPing? ping;
  final String currentUserId;

  const _HeaderCard({
    required this.pingId,
    required this.ping,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePingId = pingId ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _kv('Ping ID', effectivePingId),
          if (ping == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Status not available yet. If you just sent a request, wait a moment and this screen will update automatically.',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ] else ...[
            _kv('Type', ping!.type.name),
            _kv('Priority', ping!.priority.name),
            _kv('Created', ping!.timestamp.toLocal().toString()),
            _kv(
              'Location',
              (ping!.location.address ?? '').trim().isNotEmpty
                  ? ping!.location.address!
                  : 'Unknown',
            ),
            _kv(
              'Coords',
              '${ping!.location.latitude.toStringAsFixed(5)}, ${ping!.location.longitude.toStringAsFixed(5)}',
            ),
            _kv('Status', ping!.status.name),
            if ((ping!.userMessage ?? '').isNotEmpty)
              _kv('Message', ping!.userMessage!),
            if (ping!.userId != currentUserId && currentUserId.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Note: this ping does not belong to the current signed-in user.',
                  style: TextStyle(color: AppTheme.warningOrange),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(color: AppTheme.primaryText)),
          ),
        ],
      ),
    );
  }
}

class _MessagesCard extends StatelessWidget {
  final List<EmergencyMessage> messages;

  const _MessagesCard({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Conversation',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          if (messages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No messages yet. SAR teams can reply here when available.',
                style: TextStyle(color: AppTheme.secondaryText),
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _MessageBubble(message: msg);
              },
            ),
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  final SOSPing ping;
  final DateTime? closedAt;
  final String closedByName;
  final String closureNote;

  const _ClosedBanner({
    required this.ping,
    required this.closedAt,
    required this.closedByName,
    required this.closureNote,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = ping.status == SOSPingStatus.resolved;
    final accent = isResolved ? AppTheme.safeGreen : AppTheme.warningOrange;

    final parts = <String>[];
    final who = closedByName.trim();
    if (who.isNotEmpty) parts.add('By $who');
    if (closedAt != null) parts.add(closedAt!.toLocal().toString());
    final subtitle = parts.join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isResolved ? Icons.verified : Icons.info_outline, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isResolved ? 'Request closed (resolved)' : 'Request closed',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                ],
                finalNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget finalNote() {
    final note = closureNote.trim();
    if (note.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Note: $note',
        style: const TextStyle(color: AppTheme.primaryText),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final EmergencyMessage message;

  const _MessageBubble({required this.message});

  String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final ts = _formatTimestamp(message.timestamp.toLocal());
    final displayName = message.senderName.trim().isNotEmpty
        ? message.senderName
        : message.senderId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ts,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.content,
            style: const TextStyle(color: AppTheme.primaryText),
          ),
        ],
      ),
    );
  }
}
