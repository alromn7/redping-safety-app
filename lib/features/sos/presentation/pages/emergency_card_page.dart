import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/sos_session.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency Card Page - Displays emergency session details
/// Opened from SMS deep link: redping://sos/{sessionId}
class EmergencyCardPage extends StatefulWidget {
  final String sessionId;

  const EmergencyCardPage({super.key, required this.sessionId});

  @override
  State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}

class _EmergencyCardPageState extends State<EmergencyCardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SOSSession? _session;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final doc = await _firestore
          .collection('sos_sessions')
          .doc(widget.sessionId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Emergency session not found';
          _loading = false;
        });
        return;
      }

      final data = doc.data()!;
      setState(() {
        _session = _parseSOSSession(widget.sessionId, data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading emergency details: $e';
        _loading = false;
      });
    }
  }

  SOSSession _parseSOSSession(String sessionId, Map<String, dynamic> data) {
    final userPhone =
        data['userPhone'] as String? ??
        data['phoneNumber'] as String? ??
        data['phone'] as String? ??
        (data['metadata'] as Map<String, dynamic>?)?['userPhone'] as String? ??
        '';
    return SOSSession(
      id: sessionId,
      userId: data['userId'] as String? ?? '',
      type: _parseSOSType(data['type'] as String? ?? 'manual'),
      status: _parseSOSStatus(data['status'] as String? ?? 'active'),
      startTime:
          (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['startTime'] != null
              ? DateTime.parse(data['startTime'] as String)
              : DateTime.now()),
      location: LocationInfo(
        latitude:
            (data['latitude'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['latitude']
                as double? ??
            0.0,
        longitude:
            (data['longitude'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['longitude']
                as double? ??
            0.0,
        accuracy:
            (data['accuracy'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['accuracy']
                as double? ??
            0.0,
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        address:
            data['address'] as String? ??
            (data['location'] as Map<String, dynamic>?)?['address'] as String?,
        speed: (data['speed'] as num?)?.toDouble(),
      ),
      userMessage: data['message'] as String? ?? data['userMessage'] as String?,
      metadata: {
        'userName': data['userName'] as String? ?? '',
        'userPhone': userPhone,
        'batteryLevel':
            (data['batteryLevel'] as num?)?.toInt() ??
            (data['metadata'] as Map<String, dynamic>?)?['batteryLevel']
                as int? ??
            0,
        'assignedSARName': data['assignedSARName'] as String? ?? '',
        'assignedSARPhone': data['assignedSARPhone'] as String? ?? '',
      },
    );
  }

  SOSType _parseSOSType(String type) {
    switch (type.toLowerCase()) {
      case 'crash':
      case 'crash_detection':
        return SOSType.crashDetection;
      case 'fall':
      case 'fall_detection':
        return SOSType.fallDetection;
      case 'manual':
        return SOSType.manual;
      case 'panic':
      case 'panic_button':
        return SOSType.panicButton;
      case 'voice':
      case 'voice_command':
        return SOSType.voiceCommand;
      case 'external':
      case 'external_trigger':
        return SOSType.externalTrigger;
      default:
        return SOSType.manual;
    }
  }

  SOSStatus _parseSOSStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SOSStatus.active;
      case 'acknowledged':
        return SOSStatus.acknowledged;
      case 'assigned':
        return SOSStatus.assigned;
      case 'enroute':
      case 'en_route':
        return SOSStatus.enRoute;
      case 'resolved':
        return SOSStatus.resolved;
      case 'cancelled':
        return SOSStatus.cancelled;
      default:
        return SOSStatus.active;
    }
  }

  String _getAccidentTypeString(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS';
      case SOSType.crashDetection:
        return '🚗 Crash Detected';
      case SOSType.fallDetection:
        return '🤕 Fall Detected';
      case SOSType.panicButton:
        return '🆘 Panic Button';
      case SOSType.voiceCommand:
        return '🎤 Voice Command';
      case SOSType.externalTrigger:
        return 'External Trigger';
    }
  }

  String _getStatusString(SOSStatus status) {
    switch (status) {
      case SOSStatus.countdown:
        return '⏱️ COUNTDOWN';
      case SOSStatus.active:
        return '🚨 ACTIVE EMERGENCY';
      case SOSStatus.acknowledged:
        return '✅ ACKNOWLEDGED';
      case SOSStatus.assigned:
        return '👤 SAR ASSIGNED';
      case SOSStatus.enRoute:
        return '🚗 SAR EN ROUTE';
      case SOSStatus.onScene:
        return '🚑 SAR ON SCENE';
      case SOSStatus.inProgress:
        return '👨‍⚕️ IN PROGRESS';
      case SOSStatus.resolved:
        return '✅ RESOLVED';
      case SOSStatus.cancelled:
        return '❌ CANCELLED';
      case SOSStatus.falseAlarm:
        return '⚠️ FALSE ALARM';
    }
  }

  Color _getStatusColor(SOSStatus status) {
    switch (status) {
      case SOSStatus.countdown:
        return AppTheme.warningOrange;
      case SOSStatus.active:
        return AppTheme.criticalRed;
      case SOSStatus.acknowledged:
        return AppTheme.warningOrange;
      case SOSStatus.assigned:
        return AppTheme.infoBlue;
      case SOSStatus.enRoute:
        return AppTheme.primaryRed;
      case SOSStatus.onScene:
        return AppTheme.successGreen;
      case SOSStatus.inProgress:
        return AppTheme.infoBlue;
      case SOSStatus.resolved:
        return AppTheme.successGreen;
      case SOSStatus.cancelled:
        return AppTheme.neutralGray;
      case SOSStatus.falseAlarm:
        return AppTheme.alertYellow;
    }
  }

  Future<void> _callUser() async {
    if (_session?.userPhone == null) return;
    final uri = Uri.parse('tel:${_session!.userPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps() async {
    if (_session == null) return;
    final lat = _session!.location.latitude;
    final lng = _session!.location.longitude;
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.criticalRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.criticalRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              )
            : _buildEmergencyCard(),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    final session = _session!;
    final timestamp = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(session.startTime);
    final elapsedTime = DateTime.now().difference(session.startTime);
    final elapsedMinutes = elapsedTime.inMinutes;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(session.status),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emergency,
                    size: 48,
                    color: _getStatusColor(session.status),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RedPing Emergency',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusString(session.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Information
            _buildInfoCard(
              title: 'User Information',
              icon: Icons.person,
              children: [
                _buildInfoRow('Name', session.userName ?? 'Not available'),
                _buildInfoRow('Phone', session.userPhone ?? 'Not available'),
                _buildInfoRow(
                  'Emergency Type',
                  _getAccidentTypeString(session.type),
                ),
                _buildInfoRow('Time', timestamp),
                _buildInfoRow('Elapsed Time', '$elapsedMinutes minutes ago'),
                if (session.batteryLevel != null)
                  _buildInfoRow('Battery', '${session.batteryLevel}%'),
              ],
            ),
            const SizedBox(height: 16),

            // Location Information
            _buildInfoCard(
              title: 'Location',
              icon: Icons.location_on,
              children: [
                _buildInfoRow(
                  'Coordinates',
                  '${session.location.latitude.toStringAsFixed(6)}, ${session.location.longitude.toStringAsFixed(6)}',
                ),
                if (session.location.address != null)
                  _buildInfoRow('Address', session.location.address!),
                _buildInfoRow(
                  'Accuracy',
                  '${session.location.accuracy.toStringAsFixed(1)}m',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SAR Information (if assigned)
            if (session.assignedSARName != null)
              _buildInfoCard(
                title: 'SAR Team',
                icon: Icons.medical_services,
                children: [
                  _buildInfoRow('SAR Name', session.assignedSARName!),
                  if (session.assignedSARPhone != null)
                    _buildInfoRow('SAR Phone', session.assignedSARPhone!),
                ],
              ),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButton(
              label: 'CALL USER',
              icon: Icons.phone,
              color: AppTheme.criticalRed,
              onPressed: _callUser,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'NAVIGATE TO LOCATION',
              icon: Icons.navigation,
              color: AppTheme.primaryRed,
              onPressed: _openMaps,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'OPEN REDPING APP',
              icon: Icons.open_in_new,
              color: AppTheme.successGreen,
              onPressed: () {
                // Navigate to main app - just pop back
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                'RedPing Emergency Response System',
                style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
