import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/user_activity.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_stats_widget.dart';

/// Main activities page showing user's activities and management
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  late TabController _tabController;

  UserActivity? _currentActivity;
  List<UserActivity> _recentActivities = [];
  List<UserActivity> _plannedActivities = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await _serviceManager.activityService.initialize();
      _loadActivities();

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
    } catch (e) {
      debugPrint('ActivitiesPage: Error initializing - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadActivities() {
    _currentActivity = _serviceManager.activityService.currentActivity;
    _recentActivities = _serviceManager.activityService.getRecentActivities(
      limit: 20,
    );
    _plannedActivities = _serviceManager.activityService.getUserActivities(
      status: ActivityStatus.planned,
    );
    setState(() {});
  }

  void _onActivityStarted(UserActivity activity) {
    _loadActivities();
  }

  void _onActivityUpdated(UserActivity activity) {
    _loadActivities();
  }

  void _onActivityEnded(UserActivity activity) {
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showActivitySettings,
            tooltip: 'Activity Settings',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showActivityStats,
            tooltip: 'Activity Statistics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Current', icon: Icon(Icons.play_circle, size: 20)),
            Tab(text: 'Recent', icon: Icon(Icons.history, size: 20)),
            Tab(text: 'Planned', icon: Icon(Icons.schedule, size: 20)),
            Tab(text: 'Templates', icon: Icon(Icons.view_module, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentTab(),
          _buildRecentTab(),
          _buildPlannedTab(),
          _buildTemplatesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivityOptions,
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_currentActivity == null) {
      return _buildEmptyState(
        icon: Icons.directions_run,
        title: 'No Active Activity',
        subtitle: 'Start an activity to track your adventures safely',
        actionText: 'Start Activity',
        onAction: _showAddActivityOptions,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current activity card
          ActivityCard(
            activity: _currentActivity!,
            isExpanded: true,
            onTap: () => _showActivityDetails(_currentActivity!),
            onCheckIn: () => _performCheckIn(_currentActivity!),
            onEnd: () => _endActivity(_currentActivity!),
          ),

          const SizedBox(height: 24),

          // Activity stats
          ActivityStatsWidget(activity: _currentActivity!),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Recent Activities',
        subtitle: 'Your completed activities will appear here',
        actionText: 'Start Your First Activity',
        onAction: _showAddActivityOptions,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentActivities.length,
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActivityCard(
            activity: activity,
            onTap: () => _showActivityDetails(activity),
          ),
        );
      },
    );
  }

  Widget _buildPlannedTab() {
    if (_plannedActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No Planned Activities',
        subtitle: 'Plan your future activities for better safety preparation',
        actionText: 'Plan Activity',
        onAction: () => _showAddActivityOptions(isPlanning: true),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plannedActivities.length,
      itemBuilder: (context, index) {
        final activity = _plannedActivities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActivityCard(
            activity: activity,
            onTap: () => _showActivityDetails(activity),
            onStart: () => _startPlannedActivity(activity),
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    final templates = _serviceManager.activityService.getActivityTemplates();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTemplateColor(template.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActivityIcon(template.type),
                color: _getTemplateColor(template.type),
                size: 20,
              ),
            ),
            title: Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRiskLevelColor(template.defaultRiskLevel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRiskLevelText(template.defaultRiskLevel),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (template.requiresCheckIn)
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppTheme.secondaryText,
                      ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _startFromTemplate(template),
              tooltip: 'Start Activity',
            ),
            onTap: () => _showTemplateDetails(template),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.neutralGray),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.infoBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActivityOptions({bool isPlanning = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isPlanning ? 'Plan New Activity' : 'Start New Activity',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ),

            // Options
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children:
                    ActivityType.values
                        .where((type) => type != ActivityType.custom)
                        .map((type) {
                          return _buildActivityTypeCard(type, isPlanning);
                        })
                        .toList()
                      ..add(_buildCustomActivityCard(isPlanning)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypeCard(ActivityType type, bool isPlanning) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (isPlanning) {
            context.push('/activities/plan?type=${type.name}');
          } else {
            context.push('/activities/start?type=${type.name}');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                _getActivityColor(type).withValues(alpha: 0.1),
                _getActivityColor(type).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getActivityIcon(type),
                color: _getActivityColor(type),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                _getActivityDisplayName(type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getActivityColor(type),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomActivityCard(bool isPlanning) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.push('/activities/create');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.infoBlue.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.infoBlue,
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                'Custom\nActivity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performCheckIn(UserActivity activity) {
    _serviceManager.activityService.performCheckIn(
      message: 'Manual check-in from activities page',
      status: 'safe',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Check-in completed'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endActivity(UserActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Activity'),
        content: Text('Are you sure you want to end "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _serviceManager.activityService.endActivity(
                activity.id,
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

  void _startPlannedActivity(UserActivity activity) {
    // Convert planned activity to active
    context.push('/activities/start?activityId=${activity.id}');
  }

  void _startFromTemplate(ActivityTemplate template) {
    context.push('/activities/start?template=${template.id}');
  }

  void _showActivityDetails(UserActivity activity) {
    context.push('/activities/details/${activity.id}');
  }

  void _showTemplateDetails(ActivityTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.description),
              const SizedBox(height: 16),

              Text(
                'Risk Level: ${_getRiskLevelText(template.defaultRiskLevel)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              Text(
                'Environment: ${_getEnvironmentText(template.defaultEnvironment)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

              if (template.safetyTips.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Safety Tips:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...template.safetyTips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $tip'),
                  ),
                ),
              ],

              if (template.recommendedEquipment.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recommended Equipment:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...template.recommendedEquipment.map(
                  (equipment) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${equipment.name}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startFromTemplate(template);
            },
            child: const Text('Start Activity'),
          ),
        ],
      ),
    );
  }

  void _showActivitySettings() {
    context.push('/activities/settings');
  }

  void _showActivityStats() {
    context.push('/activities/stats');
  }

  // Duplicate methods removed - already implemented above

  // Helper methods for activity display
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
      default:
        return AppTheme.primaryText;
    }
  }

  Color _getTemplateColor(ActivityType type) => _getActivityColor(type);

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
        return 'MODERATE';
      case ActivityRiskLevel.high:
        return 'HIGH';
      case ActivityRiskLevel.extreme:
        return 'EXTREME';
    }
  }

  String _getEnvironmentText(ActivityEnvironment environment) {
    switch (environment) {
      case ActivityEnvironment.urban:
        return 'Urban';
      case ActivityEnvironment.suburban:
        return 'Suburban';
      case ActivityEnvironment.rural:
        return 'Rural';
      case ActivityEnvironment.wilderness:
        return 'Wilderness';
      case ActivityEnvironment.water:
        return 'Water';
      case ActivityEnvironment.mountain:
        return 'Mountain';
      case ActivityEnvironment.desert:
        return 'Desert';
      case ActivityEnvironment.forest:
        return 'Forest';
      case ActivityEnvironment.coastal:
        return 'Coastal';
      case ActivityEnvironment.indoor:
        return 'Indoor';
    }
  }

  String _getActivityDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.hiking:
        return 'Hiking';
      case ActivityType.fishing:
        return 'Fishing';
      case ActivityType.kayaking:
        return 'Kayaking';
      case ActivityType.driving:
        return 'Driving';
      case ActivityType.fourWD:
        return '4WD Off-Road';
      case ActivityType.surfing:
        return 'Surfing';
      case ActivityType.skydiving:
        return 'Skydiving';
      case ActivityType.remoteWork:
        return 'Remote Work';
      case ActivityType.exploring:
        return 'Exploring';
      case ActivityType.scubaDiving:
        return 'Scuba Diving';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.running:
        return 'Running';
      case ActivityType.camping:
        return 'Camping';
      case ActivityType.climbing:
        return 'Climbing';
      case ActivityType.skiing:
        return 'Skiing';
      case ActivityType.snowboarding:
        return 'Snowboarding';
      case ActivityType.sailing:
        return 'Sailing';
      case ActivityType.hunting:
        return 'Hunting';
      case ActivityType.photography:
        return 'Photography';
      case ActivityType.geocaching:
        return 'Geocaching';
      case ActivityType.backpacking:
        return 'Backpacking';
      case ActivityType.custom:
        return 'Custom';
    }
  }
}
