import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/emergency_message.dart';

/// Widget for SAR members to compose and send messages to SOS users
class SARMessageComposer extends StatefulWidget {
  final String sosUserId;
  final String sosUserName;
  final Future<void> Function(EmergencyMessage) onMessageSent;

  const SARMessageComposer({
    super.key,
    required this.sosUserId,
    required this.sosUserName,
    required this.onMessageSent,
  });

  @override
  State<SARMessageComposer> createState() => _SARMessageComposerState();
}

class _SARMessageComposerState extends State<SARMessageComposer> {
  final TextEditingController _messageController = TextEditingController();
  MessagePriority _selectedPriority = MessagePriority.medium;
  MessageType _selectedType = MessageType.sarResponse;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.message, color: AppTheme.infoBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Message ${widget.sosUserName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              // Quick action buttons (compact)
              _buildCompactQuickActionButton(
                icon: Icons.location_on,
                onTap: _sendLocationUpdate,
              ),
              const SizedBox(width: 4),
              _buildCompactQuickActionButton(
                icon: Icons.schedule,
                onTap: _sendETAUpdate,
              ),
              const SizedBox(width: 4),
              _buildCompactQuickActionButton(
                icon: Icons.medical_services,
                onTap: _sendMedicalAdvice,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Message type and priority selectors
          Row(
            children: [
              Expanded(
                child: _buildDropdown<MessageType>(
                  label: 'Type',
                  value: _selectedType,
                  items: MessageType.values,
                  onChanged: (value) => setState(() => _selectedType = value!),
                  itemBuilder: (type) => Text(
                    _getMessageTypeDisplayName(type),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDropdown<MessagePriority>(
                  label: 'Priority',
                  value: _selectedPriority,
                  items: MessagePriority.values,
                  onChanged: (value) =>
                      setState(() => _selectedPriority = value!),
                  itemBuilder: (priority) => Text(
                    _getPriorityDisplayName(priority),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Message input
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your message to ${widget.sosUserName}...',
              hintStyle: const TextStyle(color: AppTheme.secondaryText),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neutralGray.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.infoBlue),
              ),
              filled: true,
              fillColor: AppTheme.darkSurface,
            ),
            style: const TextStyle(color: AppTheme.primaryText),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_isSending ? 'Sending...' : 'Send Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.infoBlue,
                    side: BorderSide(color: AppTheme.infoBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendStatusUpdate,
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Status Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.infoBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: AppTheme.infoBlue),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          isExpanded: true,
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: SizedBox(
                    width: double.infinity,
                    child: itemBuilder(item),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.infoBlue),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: AppTheme.darkSurface,
          style: const TextStyle(color: AppTheme.primaryText),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    // Capture messenger before any awaits inside try
    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Create message
      final message = EmergencyMessage(
        id: 'sar_msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'sar_member',
        senderName: 'SAR Team',
        content: content,
        recipients: [widget.sosUserId],
        timestamp: DateTime.now(),
        priority: _selectedPriority,
        type: _selectedType,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'sosUserId': widget.sosUserId,
          'sosUserName': widget.sosUserName,
        },
      );

      // Send message
      await widget.onMessageSent(message);
      _messageController.clear();
    } finally {
      setState(() => _isSending = false);
    }

    // Show success message
    messenger.showSnackBar(
      SnackBar(
        content: Text('Message sent to ${widget.sosUserName}'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendStatusUpdate() {
    _showStatusUpdateDialog();
  }

  void _sendLocationUpdate() {
    _showLocationUpdateDialog();
  }

  void _sendETAUpdate() {
    _showETAUpdateDialog();
  }

  void _sendMedicalAdvice() {
    _showMedicalAdviceDialog();
  }

  Future<void> _showStatusUpdateDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          _StatusUpdateDialog(sosUserName: widget.sosUserName),
    );

    if (result != null) {
      final message = EmergencyMessage(
        id: 'sar_status_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'sar_member',
        senderName: 'SAR Team',
        content:
            'SAR Status Update: ${result['status']}\n\n${result['additionalInfo'] ?? ''}',
        recipients: [widget.sosUserId],
        timestamp: DateTime.now(),
        priority: MessagePriority.high,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'updateType': 'status',
          'status': result['status'],
          'additionalInfo': result['additionalInfo'],
        },
      );

      widget.onMessageSent(message);
    }
  }

  Future<void> _showLocationUpdateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _LocationUpdateDialog(sosUserName: widget.sosUserName),
    );

    if (result != null) {
      final lat = result['latitude'] as double;
      final lng = result['longitude'] as double;
      final description = result['description'] as String?;

      final message = EmergencyMessage(
        id: 'sar_location_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'sar_member',
        senderName: 'SAR Team',
        content:
            'SAR Team Location Update:\n'
            'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}\n'
            '${description ?? 'SAR team is en route to your location.'}',
        recipients: [widget.sosUserId],
        timestamp: DateTime.now(),
        priority: MessagePriority.high,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'updateType': 'location',
          'latitude': lat,
          'longitude': lng,
          'description': description,
        },
      );

      widget.onMessageSent(message);
    }
  }

  Future<void> _showETAUpdateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ETAUpdateDialog(sosUserName: widget.sosUserName),
    );

    if (result != null) {
      final etaMinutes = result['etaMinutes'] as int;
      final additionalInfo = result['additionalInfo'] as String?;

      final message = EmergencyMessage(
        id: 'sar_eta_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'sar_member',
        senderName: 'SAR Team',
        content:
            'SAR Team ETA Update:\n'
            'Estimated arrival: ${etaMinutes > 60 ? '${etaMinutes ~/ 60}h ${etaMinutes % 60}m' : '${etaMinutes}m'}\n'
            '${additionalInfo ?? 'Please remain at your current location if safe to do so.'}',
        recipients: [widget.sosUserId],
        timestamp: DateTime.now(),
        priority: MessagePriority.medium,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'updateType': 'eta',
          'etaMinutes': etaMinutes,
          'additionalInfo': additionalInfo,
        },
      );

      widget.onMessageSent(message);
    }
  }

  Future<void> _showMedicalAdviceDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          _MedicalAdviceDialog(sosUserName: widget.sosUserName),
    );

    if (result != null) {
      final message = EmergencyMessage(
        id: 'sar_medical_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'sar_member',
        senderName: 'SAR Team',
        content: 'Medical Advice from SAR Team:\n\n$result',
        recipients: [widget.sosUserId],
        timestamp: DateTime.now(),
        priority: MessagePriority.high,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {'updateType': 'medical_advice', 'advice': result},
      );

      widget.onMessageSent(message);
    }
  }

  String _getMessageTypeDisplayName(MessageType type) {
    switch (type) {
      case MessageType.emergency:
        return 'Emergency';
      case MessageType.alert:
        return 'Alert';
      case MessageType.status:
        return 'Status';
      case MessageType.response:
        return 'Response';
      case MessageType.general:
        return 'General';
      case MessageType.sarResponse:
        return 'SAR';
      case MessageType.userResponse:
        return 'User';
    }
  }

  String _getPriorityDisplayName(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.low:
        return 'Low';
      case MessagePriority.medium:
        return 'Medium';
      case MessagePriority.high:
        return 'High';
      case MessagePriority.critical:
        return 'Critical';
    }
  }
}

// Status Update Dialog
class _StatusUpdateDialog extends StatefulWidget {
  final String sosUserName;

  const _StatusUpdateDialog({required this.sosUserName});

  @override
  State<_StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<_StatusUpdateDialog> {
  final _statusController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Status Update for ${widget.sosUserName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _statusController,
            decoration: const InputDecoration(
              labelText: 'Status',
              hintText: 'e.g., "SAR team dispatched", "En route", "On scene"',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _additionalInfoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional Information',
              hintText: 'Any additional details...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_statusController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'status': _statusController.text.trim(),
                'additionalInfo': _additionalInfoController.text.trim(),
              });
            }
          },
          child: const Text('Send Update'),
        ),
      ],
    );
  }
}

// Location Update Dialog
class _LocationUpdateDialog extends StatefulWidget {
  final String sosUserName;

  const _LocationUpdateDialog({required this.sosUserName});

  @override
  State<_LocationUpdateDialog> createState() => _LocationUpdateDialogState();
}

class _LocationUpdateDialogState extends State<_LocationUpdateDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Location Update for ${widget.sosUserName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '37.8936',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '-122.5831',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., "SAR team is en route to your location"',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final lat = double.tryParse(_latController.text);
            final lng = double.tryParse(_lngController.text);
            if (lat != null && lng != null) {
              Navigator.pop(context, {
                'latitude': lat,
                'longitude': lng,
                'description': _descriptionController.text.trim(),
              });
            }
          },
          child: const Text('Send Update'),
        ),
      ],
    );
  }
}

// ETA Update Dialog
class _ETAUpdateDialog extends StatefulWidget {
  final String sosUserName;

  const _ETAUpdateDialog({required this.sosUserName});

  @override
  State<_ETAUpdateDialog> createState() => _ETAUpdateDialogState();
}

class _ETAUpdateDialogState extends State<_ETAUpdateDialog> {
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');
  final _additionalInfoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ETA Update for ${widget.sosUserName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    hintText: '30',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _additionalInfoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Additional Information',
              hintText: 'e.g., "Please remain at your current location"',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final hours = int.tryParse(_hoursController.text) ?? 0;
            final minutes = int.tryParse(_minutesController.text) ?? 0;
            final etaMinutes = hours * 60 + minutes;

            Navigator.pop(context, {
              'etaMinutes': etaMinutes,
              'additionalInfo': _additionalInfoController.text.trim(),
            });
          },
          child: const Text('Send Update'),
        ),
      ],
    );
  }
}

// Medical Advice Dialog
class _MedicalAdviceDialog extends StatefulWidget {
  final String sosUserName;

  const _MedicalAdviceDialog({required this.sosUserName});

  @override
  State<_MedicalAdviceDialog> createState() => _MedicalAdviceDialogState();
}

class _MedicalAdviceDialogState extends State<_MedicalAdviceDialog> {
  final _adviceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Medical Advice for ${widget.sosUserName}'),
      content: TextField(
        controller: _adviceController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Provide medical advice or instructions...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_adviceController.text.trim().isNotEmpty) {
              Navigator.pop(context, _adviceController.text.trim());
            }
          },
          child: const Text('Send Advice'),
        ),
      ],
    );
  }
}
