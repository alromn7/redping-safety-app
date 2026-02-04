import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_ping.dart';
import '../../../../models/sos_session.dart';
import '../../../../services/auth_service.dart';
import 'emergency_messaging_widget.dart';

/// Dialog for rescue operation details and actions
class RescueOperationDialog extends StatefulWidget {
  final SOSPing ping;
  final Function(
    SOSPing,
    SARResponseType, {
    String? message,
    int? estimatedArrivalTime,
    List<String>? availableEquipment,
    List<String>? teamMembers,
    String? vehicleType,
  })
  onRespond;
  final Function(SOSPing, SARResponseStatus, {String? message}) onUpdateStatus;
  final Function(SOSPing, {String? notes}) onComplete;

  const RescueOperationDialog({
    super.key,
    required this.ping,
    required this.onRespond,
    required this.onUpdateStatus,
    required this.onComplete,
  });

  @override
  State<RescueOperationDialog> createState() => _RescueOperationDialogState();
}

class _RescueOperationDialogState extends State<RescueOperationDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _estimatedArrival = 30; // minutes
  String _selectedVehicle = 'Vehicle';
  final List<String> _selectedEquipment = [];

  final List<String> _availableEquipment = [
    'First Aid Kit',
    'AED',
    'Oxygen Tank',
    'Stretcher',
    'Neck Brace',
    'Splints',
    'Rope & Harness',
    'Search Light',
    'Radio',
    'GPS Device',
  ];

  final List<String> _vehicleTypes = [
    'Vehicle',
    'ATV',
    'Helicopter',
    'Boat',
    'Snowmobile',
    'On Foot',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Added messaging tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPriorityColor(widget.ping.priority),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ping.userName ?? 'Unknown Person',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getSOSTypeDisplayName(widget.ping.type),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Details', icon: Icon(Icons.info)),
                Tab(text: 'Respond', icon: Icon(Icons.volunteer_activism)),
                Tab(text: 'Messages', icon: Icon(Icons.message)),
                Tab(text: 'Actions', icon: Icon(Icons.settings)),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildRespondTab(),
                  _buildMessagingTab(),
                  _buildActionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency info
          _buildInfoSection('Emergency Information', Icons.emergency, [
            _buildInfoRow('Type', _getSOSTypeDisplayName(widget.ping.type)),
            _buildInfoRow(
              'Priority',
              _getPriorityDisplayName(widget.ping.priority),
            ),
            _buildInfoRow(
              'Risk Level',
              _getRiskDisplayName(widget.ping.riskLevel),
            ),
            _buildInfoRow(
              'Time Elapsed',
              _formatTimeElapsed(widget.ping.timeElapsed),
            ),
            if (widget.ping.distanceFromSAR != null)
              _buildInfoRow(
                'Distance',
                '${widget.ping.distanceFromSAR!.toStringAsFixed(1)} km',
              ),
          ]),

          const SizedBox(height: 16),

          // Location info
          _buildInfoSection('Location', Icons.location_on, [
            _buildInfoRow('Address', widget.ping.location.address ?? 'Unknown'),
            _buildInfoRow(
              'Coordinates',
              '${widget.ping.location.latitude.toStringAsFixed(6)}, ${widget.ping.location.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow(
              'Accessibility',
              _getAccessibilityDisplayName(widget.ping.accessibilityLevel),
            ),
            if (widget.ping.terrainType != null)
              _buildInfoRow('Terrain', widget.ping.terrainType!),
            if (widget.ping.weatherConditions != null)
              _buildInfoRow('Weather', widget.ping.weatherConditions!),
          ]),

          const SizedBox(height: 16),

          // Personal info
          _buildInfoSection('Personal Information', Icons.person, [
            _buildInfoRow('Name', widget.ping.userName ?? 'Unknown'),
            if (widget.ping.userPhone != null)
              _buildInfoRow('Phone', widget.ping.userPhone!),
            if (widget.ping.estimatedAge != null)
              _buildInfoRow('Age', '${widget.ping.estimatedAge} years'),
            if (widget.ping.bloodType != null)
              _buildInfoRow('Blood Type', widget.ping.bloodType!),
          ]),

          const SizedBox(height: 16),

          // Medical info
          if (widget.ping.medicalConditions.isNotEmpty ||
              widget.ping.allergies.isNotEmpty) ...[
            _buildInfoSection('Medical Information', Icons.medical_services, [
              if (widget.ping.medicalConditions.isNotEmpty)
                _buildInfoRow(
                  'Conditions',
                  widget.ping.medicalConditions.join(', '),
                ),
              if (widget.ping.allergies.isNotEmpty)
                _buildInfoRow('Allergies', widget.ping.allergies.join(', ')),
            ]),
            const SizedBox(height: 16),
          ],

          // User message
          if (widget.ping.userMessage?.isNotEmpty == true) ...[
            _buildInfoSection('User Message', Icons.message, [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.ping.userMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // Required equipment
          if (widget.ping.requiredEquipment.isNotEmpty) ...[
            _buildInfoSection('Required Equipment', Icons.build, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.ping.requiredEquipment.map((equipment) {
                  return Chip(
                    label: Text(equipment),
                    backgroundColor: AppTheme.warningOrange.withValues(
                      alpha: 0.2,
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.warningOrange,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildRespondTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Message
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message to victim',
              hintText: 'Optional message...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Estimated arrival
          Row(
            children: [
              const Text(
                'Estimated Arrival:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              Text(
                '$_estimatedArrival minutes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          Slider(
            value: _estimatedArrival.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_estimatedArrival min',
            onChanged: (value) {
              setState(() {
                _estimatedArrival = value.toInt();
              });
            },
          ),

          const SizedBox(height: 16),

          // Vehicle type
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicle,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              border: OutlineInputBorder(),
            ),
            items: _vehicleTypes.map((vehicle) {
              return DropdownMenuItem(value: vehicle, child: Text(vehicle));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedVehicle = value ?? 'Vehicle';
              });
            },
          ),

          const SizedBox(height: 16),

          // Available equipment
          const Text(
            'Available Equipment',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableEquipment.map((equipment) {
              final isSelected = _selectedEquipment.contains(equipment);
              return FilterChip(
                label: Text(equipment),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEquipment.add(equipment);
                    } else {
                      _selectedEquipment.remove(equipment);
                    }
                  });
                },
                selectedColor: AppTheme.safeGreen.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.safeGreen,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Response buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _sendResponse(SARResponseType.unavailable),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.neutralGray,
                    side: const BorderSide(color: AppTheme.neutralGray),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Mark Unavailable'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _sendResponse(SARResponseType.available),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Accept & Respond'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingTab() {
    final currentUser = AuthService.instance.currentUser;
    return EmergencyMessagingWidget(
      ping: widget.ping,
      isSARMember: true, // This dialog is for SAR members
      currentUserId: currentUser.id,
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operation Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Status update buttons
          _buildActionButton(
            'En Route',
            'Update status to en route',
            Icons.directions_car,
            AppTheme.infoBlue,
            () => _updateStatus(SARResponseStatus.enRoute),
          ),

          _buildActionButton(
            'On Scene',
            'Mark as arrived on scene',
            Icons.place,
            AppTheme.warningOrange,
            () => _updateStatus(SARResponseStatus.onScene),
          ),

          const SizedBox(height: 16),

          // Completion notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Completion Notes',
              hintText: 'Optional notes about the rescue...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 16),

          // Complete rescue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _completeRescue(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Complete Rescue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Emergency actions
          const Text(
            'Emergency Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.criticalRed,
            ),
          ),
          const SizedBox(height: 8),

          _buildActionButton(
            'Request Backup',
            'Request additional SAR teams',
            Icons.group_add,
            AppTheme.criticalRed,
            () => _requestBackup(),
          ),

          _buildActionButton(
            'Medical Emergency',
            'Escalate to emergency medical services',
            Icons.local_hospital,
            AppTheme.criticalRed,
            () => _escalateToEMS(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        tileColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _sendResponse(SARResponseType responseType) {
    widget.onRespond(
      widget.ping,
      responseType,
      message: _messageController.text.isNotEmpty
          ? _messageController.text
          : null,
      estimatedArrivalTime: responseType == SARResponseType.available
          ? _estimatedArrival
          : null,
      availableEquipment: responseType == SARResponseType.available
          ? _selectedEquipment
          : null,
      vehicleType: responseType == SARResponseType.available
          ? _selectedVehicle
          : null,
    );
    Navigator.of(context).pop();
  }

  void _updateStatus(SARResponseStatus status) {
    widget.onUpdateStatus(widget.ping, status);
    Navigator.of(context).pop();
  }

  void _completeRescue() {
    widget.onComplete(
      widget.ping,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    Navigator.of(context).pop();
  }

  void _requestBackup() {
    // Implement backup request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup request sent to nearby SAR teams'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
    Navigator.of(context).pop();
  }

  void _escalateToEMS() {
    // Implement EMS escalation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency medical services notified'),
        backgroundColor: AppTheme.criticalRed,
      ),
    );
    Navigator.of(context).pop();
  }

  // Helper methods (same as in sos_ping_card.dart)
  Color _getPriorityColor(SOSPriority priority) {
    switch (priority) {
      case SOSPriority.low:
        return AppTheme.safeGreen;
      case SOSPriority.medium:
        return AppTheme.warningOrange;
      case SOSPriority.high:
        return AppTheme.primaryRed;
      case SOSPriority.critical:
        return AppTheme.criticalRed;
    }
  }

  String _getPriorityDisplayName(SOSPriority priority) {
    switch (priority) {
      case SOSPriority.low:
        return 'Low Priority';
      case SOSPriority.medium:
        return 'Medium Priority';
      case SOSPriority.high:
        return 'High Priority';
      case SOSPriority.critical:
        return 'Critical Priority';
    }
  }

  String _getRiskDisplayName(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String _getAccessibilityDisplayName(AccessibilityLevel accessibility) {
    switch (accessibility) {
      case AccessibilityLevel.easy:
        return 'Easy Access';
      case AccessibilityLevel.moderate:
        return 'Moderate Access';
      case AccessibilityLevel.difficult:
        return 'Difficult Access';
      case AccessibilityLevel.extreme:
        return 'Extreme Access';
    }
  }

  String _getSOSTypeDisplayName(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS';
      case SOSType.crashDetection:
        return 'Crash Detected';
      case SOSType.fallDetection:
        return 'Fall Detected';
      case SOSType.panicButton:
        return 'Panic Button';
      case SOSType.voiceCommand:
        return 'Voice Emergency';
      case SOSType.externalTrigger:
        return 'External Trigger';
    }
  }

  String _formatTimeElapsed(Duration elapsed) {
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';
    } else if (elapsed.inMinutes > 0) {
      return '${elapsed.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
