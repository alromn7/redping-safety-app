import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_session.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/app/app_launch_config.dart';

/// Page displaying SAR mission history and analytics
class SARHistoryPage extends StatefulWidget {
  const SARHistoryPage({super.key});

  @override
  State<SARHistoryPage> createState() => _SARHistoryPageState();
}

class _SARHistoryPageState extends State<SARHistoryPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  List<SARSession> _sessionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      setState(() {
        _sessionHistory = _serviceManager.sarService.sessionHistory;
      });
    } catch (e) {
      _showError('Failed to load SAR history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // When this page was reached via context.go(), there's nothing to pop.
          // Route safely back to the main shell route instead of underflowing the stack.
          context.go(AppLaunchConfig.homeRoute);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SAR Mission History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(AppLaunchConfig.homeRoute);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sessionHistory.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics Summary
                    _buildAnalyticsSummary(),

                    const SizedBox(height: 24),

                    // Mission History List
                    _buildMissionHistoryList(),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppRouter.sar);
            }
          },
          backgroundColor: AppTheme.warningOrange,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.search),
          label: const Text('Back to SAR'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.neutralGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No SAR Missions Yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed SAR missions will appear here',
            style: TextStyle(color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/sar'),
            icon: const Icon(Icons.search),
            label: const Text('Start First Mission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    final totalMissions = _sessionHistory.length;
    final successfulMissions = _sessionHistory
        .where(
          (s) =>
              s.completion?.outcome == SAROutcome.successfulRescue ||
              s.completion?.outcome == SAROutcome.personsFoundSafe,
        )
        .length;
    final avgDuration = _calculateAverageDuration();
    final avgSuccessRating = _calculateAverageSuccessRating();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.infoBlue),
                SizedBox(width: 8),
                Text(
                  'Mission Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Total Missions',
                    totalMissions.toString(),
                    AppTheme.infoBlue,
                    Icons.assignment,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Successful',
                    successfulMissions.toString(),
                    AppTheme.safeGreen,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Avg Duration',
                    _formatDuration(avgDuration),
                    AppTheme.warningOrange,
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Success Rate',
                    '${(avgSuccessRating * 100).round()}%',
                    _getSuccessRatingColor(avgSuccessRating),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        ..._sessionHistory.map((session) => _buildMissionCard(session)),
      ],
    );
  }

  Widget _buildMissionCard(SARSession session) {
    final completion = session.completion;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(session.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(session.type),
                    color: _getTypeColor(session.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeDisplayName(session.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        _formatDate(session.startTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getOutcomeColor(completion.outcome),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getOutcomeShortName(completion.outcome),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Mission Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Duration',
                    _formatDuration(session.duration),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Priority',
                    session.priority.name.toUpperCase(),
                  ),
                ),
                if (completion?.successRating != null)
                  Expanded(
                    child: _buildDetailItem(
                      'Success',
                      '${(completion!.successRating * 100).round()}%',
                    ),
                  ),
              ],
            ),

            // Summary
            if (completion?.summary != null) ...[
              const SizedBox(height: 12),
              Text(
                completion!.summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Statistics
            if (completion != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (completion.survivorsCount != null)
                    _buildStatChip(
                      'Survivors: ${completion.survivorsCount}',
                      AppTheme.safeGreen,
                    ),
                  if (completion.casualtiesCount != null) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Casualties: ${completion.casualtiesCount}',
                      AppTheme.criticalRed,
                    ),
                  ],
                  if (session.mediaFiles.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Media: ${session.mediaFiles.length}',
                      AppTheme.infoBlue,
                    ),
                  ],
                ],
              ),
            ],

            // View Details Button
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showMissionDetails(session),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showMissionDetails(SARSession session) {
    showDialog(
      context: context,
      builder: (context) => _MissionDetailsDialog(session: session),
    );
  }

  Duration _calculateAverageDuration() {
    if (_sessionHistory.isEmpty) return Duration.zero;

    final totalSeconds = _sessionHistory
        .map((s) => s.duration.inSeconds)
        .reduce((a, b) => a + b);

    return Duration(seconds: totalSeconds ~/ _sessionHistory.length);
  }

  double _calculateAverageSuccessRating() {
    final completedMissions = _sessionHistory
        .where((s) => s.completion?.successRating != null)
        .toList();

    if (completedMissions.isEmpty) return 0.0;

    final totalRating = completedMissions
        .map((s) => s.completion!.successRating)
        .reduce((a, b) => a + b);

    return totalRating / completedMissions.length;
  }

  Color _getTypeColor(SARType type) {
    switch (type) {
      case SARType.missingPerson:
        return AppTheme.warningOrange;
      case SARType.medicalEmergency:
        return AppTheme.criticalRed;
      case SARType.vehicleAccident:
        return AppTheme.primaryRed;
      case SARType.wildernessRescue:
      case SARType.mountainRescue:
        return AppTheme.safeGreen;
      case SARType.waterRescue:
        return AppTheme.infoBlue;
      default:
        return AppTheme.neutralGray;
    }
  }

  IconData _getTypeIcon(SARType type) {
    switch (type) {
      case SARType.missingPerson:
        return Icons.person_search;
      case SARType.medicalEmergency:
        return Icons.medical_services;
      case SARType.vehicleAccident:
        return Icons.car_crash;
      case SARType.wildernessRescue:
      case SARType.mountainRescue:
        return Icons.landscape;
      case SARType.waterRescue:
        return Icons.waves;
      case SARType.urbanSearch:
        return Icons.location_city;
      case SARType.disasterResponse:
        return Icons.warning;
      case SARType.overdueParty:
        return Icons.group;
      case SARType.equipmentFailure:
        return Icons.build;
    }
  }

  Color _getOutcomeColor(SAROutcome outcome) {
    switch (outcome) {
      case SAROutcome.successfulRescue:
      case SAROutcome.personsFoundSafe:
        return AppTheme.safeGreen;
      case SAROutcome.personsFoundInjured:
        return AppTheme.warningOrange;
      case SAROutcome.personsFoundDeceased:
      case SAROutcome.personsNotFound:
        return AppTheme.criticalRed;
      case SAROutcome.falseAlarm:
        return AppTheme.infoBlue;
      default:
        return AppTheme.neutralGray;
    }
  }

  String _getOutcomeShortName(SAROutcome outcome) {
    switch (outcome) {
      case SAROutcome.successfulRescue:
        return 'RESCUED';
      case SAROutcome.personsFoundSafe:
        return 'SAFE';
      case SAROutcome.personsFoundInjured:
        return 'INJURED';
      case SAROutcome.personsFoundDeceased:
        return 'DECEASED';
      case SAROutcome.personsNotFound:
        return 'NOT FOUND';
      case SAROutcome.falseAlarm:
        return 'FALSE ALARM';
      case SAROutcome.operationSuspended:
        return 'SUSPENDED';
      case SAROutcome.operationCancelled:
        return 'CANCELLED';
      case SAROutcome.transferredToAuthorities:
        return 'TRANSFERRED';
    }
  }

  Color _getSuccessRatingColor(double rating) {
    if (rating >= 0.8) return AppTheme.safeGreen;
    if (rating >= 0.6) return AppTheme.infoBlue;
    if (rating >= 0.4) return AppTheme.warningOrange;
    return AppTheme.criticalRed;
  }

  String _getTypeDisplayName(SARType type) {
    switch (type) {
      case SARType.missingPerson:
        return 'Missing Person';
      case SARType.medicalEmergency:
        return 'Medical Emergency';
      case SARType.vehicleAccident:
        return 'Vehicle Accident';
      case SARType.wildernessRescue:
        return 'Wilderness Rescue';
      case SARType.waterRescue:
        return 'Water Rescue';
      case SARType.mountainRescue:
        return 'Mountain Rescue';
      case SARType.urbanSearch:
        return 'Urban Search';
      case SARType.disasterResponse:
        return 'Disaster Response';
      case SARType.overdueParty:
        return 'Overdue Party';
      case SARType.equipmentFailure:
        return 'Equipment Failure';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
}

/// Dialog showing detailed mission information
class _MissionDetailsDialog extends StatelessWidget {
  final SARSession session;

  const _MissionDetailsDialog({required this.session});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mission Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mission Overview
              _buildMissionOverview(),

              const SizedBox(height: 24),

              // Completion Report
              if (session.completion != null) ...[
                _buildCompletionReport(),
                const SizedBox(height: 24),
              ],

              // Media Files
              if (session.mediaFiles.isNotEmpty) ...[
                _buildMediaSection(),
                const SizedBox(height: 24),
              ],

              // Mission Updates
              _buildUpdatesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Session ID', session.id),
            _buildDetailRow('Type', _getTypeDisplayName(session.type)),
            _buildDetailRow('Priority', session.priority.name.toUpperCase()),
            _buildDetailRow('Start Time', _formatDateTime(session.startTime)),
            if (session.endTime != null)
              _buildDetailRow('End Time', _formatDateTime(session.endTime!)),
            _buildDetailRow('Duration', _formatDuration(session.duration)),
            _buildDetailRow(
              'Teams Deployed',
              '${session.rescueTeamIds.length}',
            ),
            if (session.description?.isNotEmpty == true)
              _buildDetailRow('Description', session.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionReport() {
    final completion = session.completion!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Outcome',
              _getOutcomeDisplayName(completion.outcome),
            ),
            _buildDetailRow(
              'Success Rating',
              '${(completion.successRating * 100).round()}%',
            ),
            _buildDetailRow(
              'Difficulty',
              completion.difficulty.name.toUpperCase(),
            ),
            if (completion.survivorsCount != null)
              _buildDetailRow('Survivors', '${completion.survivorsCount}'),
            if (completion.casualtiesCount != null)
              _buildDetailRow('Casualties', '${completion.casualtiesCount}'),
            if (completion.hospitalDestination != null)
              _buildDetailRow('Hospital', completion.hospitalDestination!),
            _buildDetailRow('Completed By', completion.completedBy),

            const SizedBox(height: 16),

            const Text(
              'Summary:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              completion.summary,
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),

            if (completion.detailedReport?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text(
                'Detailed Report:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                completion.detailedReport!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media Documentation (${session.mediaFiles.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...session.mediaFiles.map((media) => _buildMediaItem(media)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(SARMedia media) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getMediaTypeIcon(media.type),
            color: _getMediaTypeColor(media.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.description ?? 'Untitled ${media.type.name}',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(media.timestamp),
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (media.isEvidence)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EVIDENCE',
                style: TextStyle(
                  color: AppTheme.criticalRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mission Updates (${session.updates.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...session.updates
                .take(10)
                .map((update) => _buildUpdateItem(update)),
            if (session.updates.length > 10)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '... and more updates',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem(SARUpdate update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(width: 3, color: _getUpdateTypeColor(update.type)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getUpdateTypeIcon(update.type),
                size: 16,
                color: _getUpdateTypeColor(update.type),
              ),
              const SizedBox(width: 8),
              Text(
                update.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getUpdateTypeColor(update.type),
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(update.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            update.message,
            style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods (similar to other files)
  Color _getUpdateTypeColor(SARUpdateType type) {
    switch (type) {
      case SARUpdateType.statusUpdate:
        return AppTheme.infoBlue;
      case SARUpdateType.locationUpdate:
        return AppTheme.safeGreen;
      case SARUpdateType.teamDispatch:
        return AppTheme.warningOrange;
      case SARUpdateType.resourceRequest:
        return AppTheme.criticalRed;
      case SARUpdateType.rescueComplete:
        return AppTheme.safeGreen;
      default:
        return AppTheme.neutralGray;
    }
  }

  IconData _getUpdateTypeIcon(SARUpdateType type) {
    switch (type) {
      case SARUpdateType.statusUpdate:
        return Icons.info;
      case SARUpdateType.locationUpdate:
        return Icons.location_on;
      case SARUpdateType.teamDispatch:
        return Icons.send;
      case SARUpdateType.resourceRequest:
        return Icons.support_agent;
      case SARUpdateType.rescueComplete:
        return Icons.check_circle;
      default:
        return Icons.update;
    }
  }

  Color _getMediaTypeColor(SARMediaType type) {
    switch (type) {
      case SARMediaType.photo:
        return AppTheme.infoBlue;
      case SARMediaType.video:
        return AppTheme.warningOrange;
      case SARMediaType.audio:
        return AppTheme.safeGreen;
      case SARMediaType.document:
        return AppTheme.neutralGray;
      case SARMediaType.map:
        return AppTheme.primaryRed;
      case SARMediaType.evidence:
        return AppTheme.criticalRed;
    }
  }

  IconData _getMediaTypeIcon(SARMediaType type) {
    switch (type) {
      case SARMediaType.photo:
        return Icons.photo;
      case SARMediaType.video:
        return Icons.videocam;
      case SARMediaType.audio:
        return Icons.mic;
      case SARMediaType.document:
        return Icons.description;
      case SARMediaType.map:
        return Icons.map;
      case SARMediaType.evidence:
        return Icons.gavel;
    }
  }

  String _getOutcomeDisplayName(SAROutcome outcome) {
    switch (outcome) {
      case SAROutcome.successfulRescue:
        return 'Successful Rescue';
      case SAROutcome.personsFoundSafe:
        return 'Persons Found Safe';
      case SAROutcome.personsFoundInjured:
        return 'Persons Found Injured';
      case SAROutcome.personsFoundDeceased:
        return 'Persons Found Deceased';
      case SAROutcome.personsNotFound:
        return 'Persons Not Found';
      case SAROutcome.falseAlarm:
        return 'False Alarm';
      case SAROutcome.operationSuspended:
        return 'Operation Suspended';
      case SAROutcome.operationCancelled:
        return 'Operation Cancelled';
      case SAROutcome.transferredToAuthorities:
        return 'Transferred to Authorities';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getTypeDisplayName(SARType type) {
    switch (type) {
      case SARType.missingPerson:
        return 'Missing Person';
      case SARType.medicalEmergency:
        return 'Medical Emergency';
      case SARType.vehicleAccident:
        return 'Vehicle Accident';
      case SARType.wildernessRescue:
        return 'Wilderness Rescue';
      case SARType.waterRescue:
        return 'Water Rescue';
      case SARType.mountainRescue:
        return 'Mountain Rescue';
      case SARType.urbanSearch:
        return 'Urban Search';
      case SARType.disasterResponse:
        return 'Disaster Response';
      case SARType.overdueParty:
        return 'Overdue Party';
      case SARType.equipmentFailure:
        return 'Equipment Failure';
    }
  }
}
