import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/satellite_service.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../widgets/satellite_status_widget.dart';
import '../../../../models/sos_session.dart';

/// Page for satellite communication settings and management
class SatellitePage extends StatefulWidget {
  const SatellitePage({super.key});

  @override
  State<SatellitePage> createState() => _SatellitePageState();
}

class _SatellitePageState extends State<SatellitePage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  bool _isLoading = true;
  final List<SatelliteMessage> _messageHistory = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    // Reset callbacks to no-ops to avoid stale references after popping the page
    try {
      _serviceManager.satelliteService.setConnectionChangedCallback((_) {});
      _serviceManager.satelliteService.setMessageSentCallback((_) {});
      _serviceManager.satelliteService.setMessageReceivedCallback((_) {});
    } catch (_) {
      // best-effort cleanup; service callbacks are optional
    }
    super.dispose();
  }

  Future<void> _initializePage() async {
    setState(() => _isLoading = true);

    try {
      // Ensure satellite service is initialized
      await _serviceManager.satelliteService.initialize();
      _setupCallbacks();
    } catch (e) {
      _showError('Failed to initialize satellite service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupCallbacks() {
    _serviceManager.satelliteService.setMessageSentCallback(_onMessageSent);
    _serviceManager.satelliteService.setMessageReceivedCallback(
      _onMessageReceived,
    );
    _serviceManager.satelliteService.setConnectionChangedCallback(
      _onConnectionChanged,
    );
  }

  void _onMessageSent(SatelliteMessage message) {
    if (!mounted) return;
    setState(() {
      _messageHistory.insert(0, message);
    });
    _showSuccess('Message sent via satellite');
  }

  void _onMessageReceived(SatelliteMessage message) {
    if (!mounted) return;
    setState(() {
      _messageHistory.insert(0, message);
    });
    _showSuccess('Message received via satellite');
  }

  void _onConnectionChanged(bool connected) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              connected ? Icons.satellite_alt : Icons.satellite_alt,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(connected ? 'Satellite connected' : 'Satellite disconnected'),
          ],
        ),
        backgroundColor: connected
            ? AppTheme.safeGreen
            : AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satellite Communication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _serviceManager.satelliteService.isConnected
                  ? Icons.satellite_alt
                  : Icons.satellite_alt,
              color: _serviceManager.satelliteService.isConnected
                  ? AppTheme.safeGreen
                  : AppTheme.warningOrange,
            ),
            onPressed: () => _showConnectionInfo(),
            tooltip: 'Connection Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Satellite capability info
                  _buildCapabilityCard(),

                  const SizedBox(height: 16),

                  // Satellite status
                  SatelliteStatusWidget(
                    satelliteService: _serviceManager.satelliteService,
                    showDetails: true,
                  ),

                  const SizedBox(height: 16),

                  // Emergency satellite controls
                  _buildEmergencyControls(),

                  const SizedBox(height: 16),

                  // Message testing
                  _buildMessageTesting(),

                  const SizedBox(height: 16),

                  // Message history
                  _buildMessageHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildCapabilityCard() {
    final service = _serviceManager.satelliteService;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: service.isAvailable
                        ? AppTheme.safeGreen.withValues(alpha: 0.2)
                        : AppTheme.neutralGray.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.satellite_alt,
                    color: service.isAvailable
                        ? AppTheme.safeGreen
                        : AppTheme.neutralGray,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satellite Capability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: service.isAvailable
                              ? AppTheme.safeGreen
                              : AppTheme.neutralGray,
                        ),
                      ),
                      Text(
                        service.isAvailable
                            ? 'Emergency satellite communication available'
                            : 'Satellite communication not supported on this device',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (service.isAvailable) ...[
              const SizedBox(height: 12),
              _buildCapabilityDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityDetails() {
    final service = _serviceManager.satelliteService;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow('Device Support', service.isAvailable ? 'Yes' : 'No'),
          _buildDetailRow(
            'Permission',
            service.hasPermission ? 'Granted' : 'Required',
          ),
          _buildDetailRow(
            'Connection Type',
            _getConnectionTypeText(service.connectionType),
          ),
          _buildDetailRow('Queued Messages', '${service.queuedMessageCount}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: AppTheme.criticalRed),
                SizedBox(width: 8),
                Text(
                  'Emergency Satellite Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.criticalRed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Satellite communication provides emergency backup when cellular and WiFi are unavailable.',
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _serviceManager.satelliteService.canSendEmergency
                        ? _sendTestEmergencyMessage
                        : null,
                    icon: const Icon(Icons.emergency),
                    label: const Text('Test Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.criticalRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _serviceManager.satelliteService.isAvailable
                        ? _sendTestLocationUpdate
                        : null,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Test Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.criticalRed,
                      side: const BorderSide(color: AppTheme.criticalRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTesting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message Testing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Test Message',
                hintText: 'Enter a test message to send via satellite...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (message) => _sendCustomMessage(message),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _serviceManager.satelliteService.isAvailable
                        ? () => _sendCustomMessage('Test message from REDP!NG')
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Satellite Message History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),

            const SizedBox(height: 12),

            if (_messageHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No satellite messages yet',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                ),
              )
            else
              ...(_messageHistory
                  .take(5)
                  .map((message) => _buildMessageCard(message))),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(SatelliteMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPriorityColor(message.priority).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMessageTypeIcon(message.type),
                size: 16,
                color: _getPriorityColor(message.priority),
              ),
              const SizedBox(width: 6),
              Text(
                message.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getPriorityColor(message.priority),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.disabledText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            message.content,
            style: const TextStyle(fontSize: 13, color: AppTheme.primaryText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Icon(
                message.isTransmitted ? Icons.check_circle : Icons.schedule,
                size: 12,
                color: message.isTransmitted
                    ? AppTheme.safeGreen
                    : AppTheme.warningOrange,
              ),
              const SizedBox(width: 4),
              Text(
                message.isTransmitted ? 'Transmitted' : 'Queued',
                style: TextStyle(
                  fontSize: 11,
                  color: message.isTransmitted
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestEmergencyMessage() async {
    try {
      // Create a mock SOS session for testing
      final mockSession = SOSSession(
        id: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        type: SOSType.manual,
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: 37.4219983,
          longitude: -122.084,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          address: 'Test Location',
        ),
        isTestMode: true,
      );

      final success = await _serviceManager.satelliteService.sendEmergencySOS(
        session: mockSession,
        customMessage: 'This is a test emergency message via satellite',
      );

      _showSuccess(
        success
            ? 'Test emergency message sent via satellite'
            : 'Test emergency message queued for satellite transmission',
      );
    } catch (e) {
      _showError('Failed to send test emergency message: $e');
    }
  }

  Future<void> _sendTestLocationUpdate() async {
    try {
      final location = LocationInfo(
        latitude: 37.4219983,
        longitude: -122.084,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        address: 'Test Location Update',
      );

      final success = await _serviceManager.satelliteService.sendLocationUpdate(
        location,
      );

      _showSuccess(
        success
            ? 'Location update sent via satellite'
            : 'Location update queued for satellite transmission',
      );
    } catch (e) {
      _showError('Failed to send location update: $e');
    }
  }

  Future<void> _sendCustomMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      final success = await _serviceManager.satelliteService.sendCustomMessage(
        message: message.trim(),
        priority: SatelliteMessagePriority.normal,
      );

      _showSuccess(
        success
            ? 'Custom message sent via satellite'
            : 'Custom message queued for satellite transmission',
      );
    } catch (e) {
      _showError('Failed to send custom message: $e');
    }
  }

  void _showConnectionInfo() {
    final service = _serviceManager.satelliteService;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Satellite Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Available', service.isAvailable ? 'Yes' : 'No'),
            _buildInfoRow('Enabled', service.isEnabled ? 'Yes' : 'No'),
            _buildInfoRow(
              'Permission',
              service.hasPermission ? 'Granted' : 'Required',
            ),
            _buildInfoRow('Connected', service.isConnected ? 'Yes' : 'No'),
            _buildInfoRow(
              'Signal Strength',
              '${(service.signalStrength * 100).toInt()}%',
            ),
            _buildInfoRow(
              'Connection Type',
              _getConnectionTypeText(service.connectionType),
            ),
            _buildInfoRow('Queued Messages', '${service.queuedMessageCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(SatelliteMessagePriority priority) {
    switch (priority) {
      case SatelliteMessagePriority.low:
        return AppTheme.infoBlue;
      case SatelliteMessagePriority.normal:
        return AppTheme.neutralGray;
      case SatelliteMessagePriority.high:
        return AppTheme.warningOrange;
      case SatelliteMessagePriority.critical:
        return AppTheme.criticalRed;
    }
  }

  IconData _getMessageTypeIcon(SatelliteMessageType type) {
    switch (type) {
      case SatelliteMessageType.emergency:
        return Icons.emergency;
      case SatelliteMessageType.location:
        return Icons.location_on;
      case SatelliteMessageType.text:
        return Icons.message;
      case SatelliteMessageType.status:
        return Icons.info;
    }
  }

  String _getConnectionTypeText(SatelliteConnectionType type) {
    switch (type) {
      case SatelliteConnectionType.emergency:
        return 'Emergency Only';
      case SatelliteConnectionType.messaging:
        return 'Messaging';
      case SatelliteConnectionType.data:
        return 'Full Data';
      default:
        return 'None';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
