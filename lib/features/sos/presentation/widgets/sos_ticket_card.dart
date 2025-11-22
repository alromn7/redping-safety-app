import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';

/// Enhanced SOS Ticket Card with status management buttons
/// Allows SAR responders to update rescue status and users to see real-time updates
class SOSTicketCard extends StatefulWidget {
  final RescueTeamResponse response;
  final String sessionId;
  final bool
  isSARView; // true if viewed by SAR responder, false if viewed by user
  final VoidCallback? onStatusUpdated;

  const SOSTicketCard({
    super.key,
    required this.response,
    required this.sessionId,
    this.isSARView = false,
    this.onStatusUpdated,
  });

  @override
  State<SOSTicketCard> createState() => _SOSTicketCardState();
}

class _SOSTicketCardState extends State<SOSTicketCard> {
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.response.status).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(widget.response.status).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(
              widget.response.status,
            ).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with team info and current status
          _buildHeader(),

          const SizedBox(height: 12),

          // Team details
          _buildTeamDetails(),

          if (widget.response.message != null) ...[
            const SizedBox(height: 12),
            _buildMessage(),
          ],

          if (widget.response.estimatedArrival != null) ...[
            const SizedBox(height: 12),
            _buildETA(),
          ],

          if (widget.response.assignedMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTeamMembers(),
          ],

          // Organization and Personnel Details Buttons (always visible)
          const SizedBox(height: 12),
          _buildDetailsButtons(),

          // Status action buttons (only for SAR view)
          if (widget.isSARView) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildStatusButtons(),
          ],

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(),
          ],

          // Timeline/History
          const SizedBox(height: 12),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Team icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor(
              widget.response.status,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getTeamIcon(widget.response.teamType),
            color: _getStatusColor(widget.response.status),
            size: 24,
          ),
        ),

        const SizedBox(width: 12),

        // Team name and type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.response.teamName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getTeamTypeLabel(widget.response.teamType),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Current status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(widget.response.status),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(
                  widget.response.status,
                ).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(widget.response.status),
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _getStatusLabel(widget.response.status),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamDetails() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: AppTheme.secondaryText),
        const SizedBox(width: 6),
        Text(
          'Responded ${_formatResponseTime(widget.response.responseTime)}',
          style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
        ),
        if (widget.response.currentLocation != null) ...[
          const SizedBox(width: 16),
          Icon(Icons.location_on, size: 16, color: AppTheme.infoBlue),
          const SizedBox(width: 4),
          Text(
            'Tracking',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.infoBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.message, size: 16, color: AppTheme.infoBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.response.message!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETA() {
    final eta = widget.response.estimatedArrival!;
    final now = DateTime.now();
    final isOverdue = eta.isBefore(now);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.criticalRed.withValues(alpha: 0.1)
            : AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.directions_run,
            size: 18,
            color: isOverdue ? AppTheme.criticalRed : AppTheme.warningOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'ETA Overdue' : 'Estimated Arrival',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue
                        ? AppTheme.criticalRed
                        : AppTheme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatETA(eta),
                  style: TextStyle(
                    fontSize: 14,
                    color: isOverdue
                        ? AppTheme.criticalRed
                        : AppTheme.warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Team:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.response.assignedMembers.map((member) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.infoBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 12, color: AppTheme.infoBlue),
                  const SizedBox(width: 4),
                  Text(
                    '${member.name} • ${member.role}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoButton(
            label: 'Organization',
            icon: Icons.business,
            onTap: _showOrganizationDetails,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoButton(
            label: 'Personnel',
            icon: Icons.group,
            onTap: _showPersonnelDetails,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoButton(
            label: 'Contact',
            icon: Icons.phone,
            onTap: _showContactOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.infoBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.infoBlue),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    if (_isUpdating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Status:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusButton(
              label: 'Assign',
              icon: Icons.assignment_turned_in,
              status: ResponseStatus.acknowledged,
              color: AppTheme.infoBlue,
            ),
            _buildStatusButton(
              label: 'En Route',
              icon: Icons.directions_car,
              status: ResponseStatus.enRoute,
              color: AppTheme.warningOrange,
            ),
            _buildStatusButton(
              label: 'Arrived',
              icon: Icons.location_on,
              status: ResponseStatus.onScene,
              color: AppTheme.safeGreen,
            ),
            _buildStatusButton(
              label: 'Resolved',
              icon: Icons.check_circle,
              status: ResponseStatus.completed,
              color: AppTheme.safeGreen,
            ),
            _buildStatusButton(
              label: 'Report',
              icon: Icons.description,
              status: null, // Special action
              color: AppTheme.infoBlue,
              onTap: _showReportDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required ResponseStatus? status,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isCurrentStatus = status != null && widget.response.status == status;
    final isDisabled =
        isCurrentStatus || (status != null && !_canTransitionTo(status));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : (onTap ?? () => _updateStatus(status!)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentStatus
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentStatus ? color : color.withValues(alpha: 0.3),
              width: isCurrentStatus ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDisabled ? AppTheme.neutralGray : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrentStatus
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: isDisabled ? AppTheme.neutralGray : color,
                ),
              ),
              if (isCurrentStatus) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.criticalRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.criticalRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: AppTheme.criticalRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 14, color: AppTheme.secondaryText),
              SizedBox(width: 6),
              Text(
                'Status Timeline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTimelineItem(
            'Response Received',
            widget.response.responseTime,
            Icons.notifications_active,
            true,
          ),
          if (widget.response.status != ResponseStatus.acknowledged)
            _buildTimelineItem(
              'Status: ${_getStatusLabel(widget.response.status)}',
              DateTime.now(), // This should be actual update time
              _getStatusIcon(widget.response.status),
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime time,
    IconData icon,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: isCompleted ? AppTheme.safeGreen : AppTheme.secondaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isCompleted
                    ? AppTheme.primaryText
                    : AppTheme.secondaryText,
              ),
            ),
          ),
          Text(
            _formatTime(time),
            style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  // Status update logic
  Future<void> _updateStatus(ResponseStatus newStatus) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Update the rescue team response status
      await firestore.collection('sos_sessions').doc(widget.sessionId).update({
        'rescueTeamResponses': FieldValue.arrayRemove([
          widget.response.toJson(),
        ]),
      });

      final updatedResponse = RescueTeamResponse(
        id: widget.response.id,
        teamId: widget.response.teamId,
        teamName: widget.response.teamName,
        teamType: widget.response.teamType,
        status: newStatus,
        responseTime: widget.response.responseTime,
        estimatedArrival: widget.response.estimatedArrival,
        currentLocation: widget.response.currentLocation,
        message: widget.response.message,
        assignedMembers: widget.response.assignedMembers,
        equipment: widget.response.equipment,
      );

      await firestore.collection('sos_sessions').doc(widget.sessionId).update({
        'rescueTeamResponses': FieldValue.arrayUnion([
          updatedResponse.toJson(),
        ]),
      });

      // Add status update notification
      await firestore
          .collection('sos_sessions')
          .doc(widget.sessionId)
          .collection('notifications')
          .add({
            'type': 'status_update',
            'teamId': widget.response.teamId,
            'teamName': widget.response.teamName,
            'oldStatus': widget.response.status.toString(),
            'newStatus': newStatus.toString(),
            'timestamp': FieldValue.serverTimestamp(),
            'message':
                '${widget.response.teamName} is now ${_getStatusLabel(newStatus)}',
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: AppTheme.safeGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onStatusUpdated?.call();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update status: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  bool _canTransitionTo(ResponseStatus newStatus) {
    final currentStatus = widget.response.status;

    // Define allowed status transitions
    switch (currentStatus) {
      case ResponseStatus.acknowledged:
        return newStatus == ResponseStatus.enRoute ||
            newStatus == ResponseStatus.unableToRespond ||
            newStatus == ResponseStatus.cancelled;

      case ResponseStatus.enRoute:
        return newStatus == ResponseStatus.onScene ||
            newStatus == ResponseStatus.unableToRespond;

      case ResponseStatus.onScene:
        return newStatus == ResponseStatus.completed;

      case ResponseStatus.completed:
      case ResponseStatus.cancelled:
      case ResponseStatus.unableToRespond:
        return false; // Terminal states
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text(
          'Generate a detailed report for this rescue operation?\n\n'
          'This will include timeline, actions taken, and outcome details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateReport();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoBlue),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    // TODO: Implement report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report generation feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOrganizationDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    widget.response.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: _getStatusColor(widget.response.status),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Organization Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.response.teamName,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(widget.response.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppTheme.secondaryText,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        'Team Type',
                        _getTeamTypeLabel(widget.response.teamType),
                        Icons.category,
                      ),
                      _buildDetailItem(
                        'Team ID',
                        widget.response.teamId,
                        Icons.badge,
                      ),
                      _buildDetailItem(
                        'Response Status',
                        _getStatusLabel(widget.response.status),
                        _getStatusIcon(widget.response.status),
                      ),
                      _buildDetailItem(
                        'Response Time',
                        _formatResponseTime(widget.response.responseTime),
                        Icons.schedule,
                      ),
                      if (widget.response.estimatedArrival != null)
                        _buildDetailItem(
                          'Estimated Arrival',
                          _formatETA(widget.response.estimatedArrival!),
                          Icons.access_time,
                        ),

                      if (widget.response.equipment.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Equipment & Resources:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.response.equipment.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppTheme.safeGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.infoBlue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This team is certified and verified by local authorities.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonnelDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group,
                      color: AppTheme.safeGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Personnel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Response Team Members',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppTheme.secondaryText,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: widget.response.assignedMembers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppTheme.neutralGray,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No personnel assigned yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.secondaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: widget.response.assignedMembers.length,
                        itemBuilder: (context, index) {
                          final member = widget.response.assignedMembers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.safeGreen.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.safeGreen
                                          .withValues(alpha: 0.2),
                                      radius: 20,
                                      child: Text(
                                        member.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.safeGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.role,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.safeGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (member.specialization != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: AppTheme.infoBlue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Specialization: ${member.specialization}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.infoBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.badge,
                                      size: 14,
                                      color: AppTheme.secondaryText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ID: ${member.id}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactOptions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, color: AppTheme.infoBlue, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contact Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildContactButton(
                'Voice Call',
                Icons.phone,
                AppTheme.safeGreen,
                () {
                  Navigator.pop(context);
                  _initiateVoiceCall();
                },
              ),

              const SizedBox(height: 12),

              _buildContactButton(
                'Send Message',
                Icons.message,
                AppTheme.infoBlue,
                () {
                  Navigator.pop(context);
                  _openMessaging();
                },
              ),

              const SizedBox(height: 12),

              _buildContactButton(
                'Share Location',
                Icons.location_on,
                AppTheme.warningOrange,
                () {
                  Navigator.pop(context);
                  _shareLocation();
                },
              ),

              const SizedBox(height: 12),

              _buildContactButton(
                'Video Call',
                Icons.videocam,
                AppTheme.primaryRed,
                () {
                  Navigator.pop(context);
                  _initiateVideoCall();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.infoBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initiateVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Initiating voice call with ${widget.response.teamName}...',
        ),
        backgroundColor: AppTheme.safeGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement voice call functionality
  }

  void _openMessaging() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening messaging interface...'),
        backgroundColor: AppTheme.infoBlue,
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to messaging interface
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing live location with rescue team...'),
        backgroundColor: AppTheme.warningOrange,
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement location sharing
  }

  void _initiateVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Initiating video call with ${widget.response.teamName}...',
        ),
        backgroundColor: AppTheme.primaryRed,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement video call functionality
  }

  // Helper methods
  Color _getStatusColor(ResponseStatus status) {
    switch (status) {
      case ResponseStatus.acknowledged:
        return AppTheme.infoBlue;
      case ResponseStatus.enRoute:
        return AppTheme.warningOrange;
      case ResponseStatus.onScene:
        return AppTheme.safeGreen;
      case ResponseStatus.completed:
        return AppTheme.safeGreen;
      case ResponseStatus.unableToRespond:
        return AppTheme.criticalRed;
      case ResponseStatus.cancelled:
        return AppTheme.neutralGray;
    }
  }

  IconData _getStatusIcon(ResponseStatus status) {
    switch (status) {
      case ResponseStatus.acknowledged:
        return Icons.assignment_turned_in;
      case ResponseStatus.enRoute:
        return Icons.directions_car;
      case ResponseStatus.onScene:
        return Icons.location_on;
      case ResponseStatus.completed:
        return Icons.check_circle;
      case ResponseStatus.unableToRespond:
        return Icons.cancel;
      case ResponseStatus.cancelled:
        return Icons.block;
    }
  }

  String _getStatusLabel(ResponseStatus status) {
    switch (status) {
      case ResponseStatus.acknowledged:
        return 'ASSIGNED';
      case ResponseStatus.enRoute:
        return 'EN ROUTE';
      case ResponseStatus.onScene:
        return 'ARRIVED';
      case ResponseStatus.completed:
        return 'RESOLVED';
      case ResponseStatus.unableToRespond:
        return 'UNABLE';
      case ResponseStatus.cancelled:
        return 'CANCELLED';
    }
  }

  IconData _getTeamIcon(RescueTeamType type) {
    switch (type) {
      case RescueTeamType.paramedic:
        return Icons.local_hospital;
      case RescueTeamType.fireDepartment:
        return Icons.local_fire_department;
      case RescueTeamType.police:
        return Icons.local_police;
      case RescueTeamType.sarTeam:
        return Icons.search;
      case RescueTeamType.helicopter:
        return Icons.flight;
      case RescueTeamType.coastGuard:
        return Icons.directions_boat;
    }
  }

  String _getTeamTypeLabel(RescueTeamType type) {
    switch (type) {
      case RescueTeamType.paramedic:
        return 'Emergency Medical Services';
      case RescueTeamType.fireDepartment:
        return 'Fire Department';
      case RescueTeamType.police:
        return 'Police Department';
      case RescueTeamType.sarTeam:
        return 'Search & Rescue Team';
      case RescueTeamType.helicopter:
        return 'Air Rescue';
      case RescueTeamType.coastGuard:
        return 'Coast Guard';
    }
  }

  String _formatResponseTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final diff = eta.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inMinutes < 1) return 'Overdue (just now)';
      if (absDiff.inMinutes < 60) return 'Overdue (${absDiff.inMinutes} min)';
      return 'Overdue (${absDiff.inHours}h)';
    }

    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
