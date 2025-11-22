import 'dart:async';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../services/google_cloud_api_service.dart';

class SystemHealthCard extends StatefulWidget {
  const SystemHealthCard({super.key});

  @override
  State<SystemHealthCard> createState() => _SystemHealthCardState();
}

class _SystemHealthCardState extends State<SystemHealthCard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = GoogleCloudApiService().getStatus();
    final isConnected = status['isConnected'] == true;
    final lastReq = status['lastSuccessfulRequest'] as String?;
    final configValid = status['configurationValid'] == true;
    final protOk = status['protectedPingOk'];
    final protAt = status['protectedPingAt'] as String?;

    final showBar = Env.flag<bool>('showBarIndicator', true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _row(
              context,
              icon: Icons.cloud_outlined,
              label: 'API',
              value: isConnected ? 'Connected' : 'Disconnected',
              color: isConnected ? Colors.green : Colors.redAccent,
              trailing: lastReq != null ? 'Last: $lastReq' : null,
            ),
            const SizedBox(height: 8),
            _row(
              context,
              icon: Icons.verified_user_outlined,
              label: 'Security',
              value: protOk == true
                  ? 'Protected: OK'
                  : (protOk == false ? 'Protected: Failed' : 'Protected: —'),
              color: protOk == true
                  ? Colors.green
                  : (protOk == false ? Colors.redAccent : Colors.orange),
              trailing: protAt != null ? 'At: $protAt' : null,
            ),
            if (showBar) ...[
              const SizedBox(height: 8),
              _ProtectedPingStatusBar(status: protOk),
            ],
            const SizedBox(height: 8),
            _row(
              context,
              icon: Icons.settings_outlined,
              label: 'Config',
              value: configValid ? 'Valid' : 'Invalid',
              color: configValid ? Colors.green : Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    String? trailing,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Theme.of(context).iconTheme.color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: textStyle)),
        Text(value, style: textStyle?.copyWith(color: color)),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(trailing, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _ProtectedPingStatusBar extends StatelessWidget {
  final dynamic status; // true, false, or null (unknown)
  const _ProtectedPingStatusBar({required this.status});

  Color _color(BuildContext context) {
    if (status == true) return Colors.green;
    if (status == false) return Colors.redAccent;
    return Colors.orange; // unknown
  }

  String _label() {
    if (status == true) return 'OK';
    if (status == false) return 'FAILED';
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 26),
          child: Text(
            'Protected Ping: ${_label()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
