import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/user_activity.dart';

/// My Activities card for the main dashboard
class MyActivitiesCard extends StatefulWidget {
  const MyActivitiesCard({super.key});

  @override
  State<MyActivitiesCard> createState() => _MyActivitiesCardState();
}

class _MyActivitiesCardState extends State<MyActivitiesCard>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  UserActivity? _currentActivity;
  List<UserActivity> _recentActivities = [];
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _loadActivityData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);

    try {
      await _serviceManager.activityService.initialize();

      // Set up callbacks
      _serviceManager.activityService.setActivityStartedCallback(
        _onActivityStarted,
      );
      _serviceManager.activityService.setActivityUpdatedCallback(
        _onActivityUpdated,
      );
      _serviceManager.activityService.setActivityEndedCallback(
        _onActivityEnded,
      );

      // Load current data
      _currentActivity = _serviceManager.activityService.currentActivity;
      _recentActivities = _serviceManager.activityService.getRecentActivities(
        limit: 3,
      );
    } catch (e) {
      debugPrint('MyActivitiesCard: Error loading data - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onActivityStarted(UserActivity activity) {
    setState(() {
      _currentActivity = activity;
      _recentActivities = _serviceManager.activityService.getRecentActivities(
        limit: 3,
      );
    });
  }

  void _onActivityUpdated(UserActivity activity) {
    setState(() {
      if (_currentActivity?.id == activity.id) {
        _currentActivity = activity;
      }
      _recentActivities = _serviceManager.activityService.getRecentActivities(
        limit: 3,
      );
    });
  }

  void _onActivityEnded(UserActivity activity) {
    setState(() {
      _currentActivity = null;
      _recentActivities = _serviceManager.activityService.getRecentActivities(
        limit: 3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/activities'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _currentActivity != null
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentActivity != null
                                ? _getActivityColor(
                                    _currentActivity!.type,
                                  ).withValues(alpha: 0.2)
                                : AppTheme.infoBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _currentActivity != null
                                ? _getActivityIcon(_currentActivity!.type)
                                : Icons.directions_run,
                            color: _currentActivity != null
                                ? _getActivityColor(_currentActivity!.type)
                                : AppTheme.infoBlue,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Activities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        Text(
                          _currentActivity != null
                              ? 'Currently: ${_currentActivity!.title}'
                              : 'Track your adventures safely',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentActivity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRiskLevelColor(_currentActivity!.riskLevel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRiskLevelText(_currentActivity!.riskLevel),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content based on activity state
              if (_currentActivity != null)
                _buildCurrentActivityView()
              else
                _buildNoActivityView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentActivityView() {
    if (_currentActivity == null) return const SizedBox.shrink();

    final activity = _currentActivity!;
    final duration = activity.startTime != null
        ? DateTime.now().difference(activity.startTime!)
        : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current activity status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getActivityColor(activity.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getActivityColor(activity.type).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getActivityIcon(activity.type),
                    color: _getActivityColor(activity.type),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getActivityColor(activity.type),
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
              if (activity.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  activity.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick actions
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Check In',
                Icons.check_circle_outline,
                AppTheme.safeGreen,
                () => _performCheckIn(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                'End Activity',
                Icons.stop,
                AppTheme.criticalRed,
                () => _endCurrentActivity(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoActivityView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent activities or getting started
        if (_recentActivities.isNotEmpty) ...[
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),

          ..._recentActivities
              .take(2)
              .map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getActivityIcon(activity.type),
                        color: _getActivityColor(activity.type),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(activity.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.infoBlue,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Start Your First Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoBlue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your adventures safely',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Quick start activities
        const Text(
          'Quick Start',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildQuickStartActivity(
                ActivityType.hiking,
                'Hiking',
                Icons.hiking,
                AppTheme.safeGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStartActivity(
                ActivityType.driving,
                'Driving',
                Icons.directions_car,
                AppTheme.infoBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStartActivity(
                ActivityType.custom,
                'Custom',
                Icons.add,
                AppTheme.neutralGray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildQuickStartActivity(
    ActivityType type,
    String name,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _quickStartActivity(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _quickStartActivity(ActivityType type) {
    if (type == ActivityType.custom) {
      context.push('/activities/create');
    } else {
      context.push('/activities/start?type=${type.name}');
    }
  }

  void _performCheckIn() {
    _serviceManager.activityService.performCheckIn(
      message: 'Manual check-in from dashboard',
      status: 'safe',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Check-in completed'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _endCurrentActivity() {
    if (_currentActivity == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Activity'),
        content: Text(
          'Are you sure you want to end "${_currentActivity!.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _serviceManager.activityService.endActivity(
                _currentActivity!.id,
                ActivityStatus.completed,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('End Activity'),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.fishing:
        return Icons.phishing;
      case ActivityType.kayaking:
        return Icons.kayaking;
      case ActivityType.driving:
        return Icons.directions_car;
      case ActivityType.fourWD:
        return Icons.terrain;
      case ActivityType.surfing:
        return Icons.surfing;
      case ActivityType.skydiving:
        return Icons.flight;
      case ActivityType.remoteWork:
        return Icons.laptop;
      case ActivityType.exploring:
        return Icons.explore;
      case ActivityType.scubaDiving:
        return Icons.scuba_diving;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.camping:
        return Icons.cabin;
      case ActivityType.climbing:
        return Icons.landscape;
      case ActivityType.skiing:
        return Icons.downhill_skiing;
      case ActivityType.snowboarding:
        return Icons.snowboarding;
      case ActivityType.sailing:
        return Icons.sailing;
      case ActivityType.hunting:
        return Icons.my_location;
      case ActivityType.photography:
        return Icons.camera_alt;
      case ActivityType.geocaching:
        return Icons.search;
      case ActivityType.backpacking:
        return Icons.backpack;
      case ActivityType.custom:
        return Icons.star;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.hiking:
      case ActivityType.exploring:
      case ActivityType.backpacking:
        return AppTheme.safeGreen;
      case ActivityType.fishing:
      case ActivityType.swimming:
      case ActivityType.kayaking:
      case ActivityType.sailing:
      case ActivityType.scubaDiving:
        return AppTheme.infoBlue;
      case ActivityType.driving:
      case ActivityType.remoteWork:
        return AppTheme.neutralGray;
      case ActivityType.fourWD:
      case ActivityType.climbing:
        return AppTheme.warningOrange;
      case ActivityType.skydiving:
      case ActivityType.hunting:
        return AppTheme.criticalRed;
      case ActivityType.surfing:
      case ActivityType.skiing:
      case ActivityType.snowboarding:
        return AppTheme.infoBlue;
      default:
        return AppTheme.primaryText;
    }
  }

  Color _getRiskLevelColor(ActivityRiskLevel level) {
    switch (level) {
      case ActivityRiskLevel.low:
        return AppTheme.safeGreen;
      case ActivityRiskLevel.moderate:
        return AppTheme.warningOrange;
      case ActivityRiskLevel.high:
        return AppTheme.criticalRed;
      case ActivityRiskLevel.extreme:
        return AppTheme.primaryRed;
    }
  }

  String _getRiskLevelText(ActivityRiskLevel level) {
    switch (level) {
      case ActivityRiskLevel.low:
        return 'LOW';
      case ActivityRiskLevel.moderate:
        return 'MOD';
      case ActivityRiskLevel.high:
        return 'HIGH';
      case ActivityRiskLevel.extreme:
        return 'EXTREME';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
