/// Debug HUD for Phone AI Integration
/// Shows incoming intents, session state, and classification in real-time
library;

import 'package:flutter/material.dart';
import '../services/voice_session_controller.dart';
import '../platform/phone_ai_channel.dart';
import '../core/theme/app_theme.dart';

class PhoneAIDebugHUD extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PhoneAIDebugHUD({super.key, required this.child, this.enabled = true});

  @override
  State<PhoneAIDebugHUD> createState() => _PhoneAIDebugHUDState();
}

class _PhoneAIDebugHUDState extends State<PhoneAIDebugHUD> {
  final List<DebugEvent> _events = [];
  // Removed unused _phoneAI instance to satisfy analyzer
  final VoiceSessionController _voiceController = VoiceSessionController();
  final PhoneAIChannel _channel = PhoneAIChannel();
  bool _isExpanded = false;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _setupListeners();
    }
  }

  void _setupListeners() {
    // Listen to phone AI channel events
    _channel.onTranscriptFinal.listen((text) {
      _addEvent(
        DebugEvent(
          type: 'Transcript',
          data: text,
          timestamp: DateTime.now(),
          color: AppTheme.infoBlue,
        ),
      );
    });

    _channel.onIntent.listen((payload) {
      _addEvent(
        DebugEvent(
          type: 'Intent',
          data: payload.toString(),
          timestamp: DateTime.now(),
          color: AppTheme.warningOrange,
        ),
      );
    });
  }

  void _addEvent(DebugEvent event) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, event);
      if (_events.length > 50) {
        _events.removeLast();
      }
    });
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: _buildHUDButton(),
        ),
        if (_isExpanded) _buildDebugPanel(),
      ],
    );
  }

  static const _hudButtonPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );
  static const _hudButtonRadius = 16.0;
  static const _hudIconSize = 14.0;
  static const _hudTextSize = 11.0;

  Widget _buildHUDButton() {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          padding: _hudButtonPadding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(_hudButtonRadius),
            border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isExpanded ? Icons.bug_report : Icons.bug_report_outlined,
                color: AppTheme.infoBlue,
                size: _hudIconSize,
              ),
              const SizedBox(width: 4),
              Text(
                'AI Debug',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: _hudTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_events.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _events.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return RepaintBoundary(
      child: Positioned(
        top: MediaQuery.of(context).padding.top + 48,
        left: 8,
        right: 8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.infoBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                _buildStatusBar(),
                Expanded(child: _buildEventList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.infoBlue.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: AppTheme.infoBlue, size: 16),
          const SizedBox(width: 6),
          const Text(
            'Phone AI Debug',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildActionButton(
            icon: _autoScroll ? Icons.lock_outline : Icons.lock_open,
            label: 'Auto',
            active: _autoScroll,
            onTap: () => setState(() => _autoScroll = !_autoScroll),
          ),
          const SizedBox(width: 6),
          _buildActionButton(
            icon: Icons.clear_all,
            label: 'Clear',
            onTap: () => setState(() => _events.clear()),
          ),
          const SizedBox(width: 6),
          _buildActionButton(
            icon: Icons.close,
            label: 'Close',
            onTap: () => setState(() => _isExpanded = false),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.infoBlue.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? AppTheme.infoBlue.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white70),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final state = _voiceController.currentState;
    final stateColor = _getStateColor(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: stateColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: stateColor),
          const SizedBox(width: 6),
          Text(
            'State: ${state.name}',
            style: TextStyle(
              color: stateColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Events: ${_events.length}',
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static const _emptyStateWidget = Center(
    child: Text(
      'Waiting for AI events...',
      style: TextStyle(color: Colors.white38, fontSize: 11),
    ),
  );

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return _emptyStateWidget;
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _events.length,
      itemBuilder: (context, index) => _buildEventCard(_events[index]),
    );
  }

  Widget _buildEventCard(DebugEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: event.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.type,
                  style: TextStyle(
                    color: event.color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(event.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.data,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStateColor(VoiceSessionState state) {
    switch (state) {
      case VoiceSessionState.idle:
        return AppTheme.safeGreen;
      case VoiceSessionState.listening:
        return AppTheme.infoBlue;
      case VoiceSessionState.processing:
        return AppTheme.warningOrange;
      case VoiceSessionState.speaking:
        return AppTheme.primaryRed;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

class DebugEvent {
  final String type;
  final String data;
  final DateTime timestamp;
  final Color color;

  const DebugEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    required this.color,
  });
}
