import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/user_activity.dart';

/// Page for starting a new activity
class StartActivityPage extends StatefulWidget {
  final ActivityType? activityType;
  final String? templateId;
  final String? activityId;

  const StartActivityPage({
    super.key,
    this.activityType,
    this.templateId,
    this.activityId,
  });

  @override
  State<StartActivityPage> createState() => _StartActivityPageState();
}

class _StartActivityPageState extends State<StartActivityPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form state
  ActivityType? _selectedType;
  ActivityRiskLevel _selectedRiskLevel = ActivityRiskLevel.moderate;
  ActivityEnvironment _selectedEnvironment = ActivityEnvironment.urban;
  Duration _estimatedDuration = const Duration(hours: 2);
  bool _hasCheckInSchedule = false;
  Duration _checkInInterval = const Duration(hours: 1);

  bool _isSubmitting = false;
  ActivityTemplate? _template;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.activityType;
    _loadTemplate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    if (widget.templateId != null) {
      _template = _serviceManager.activityService
          .getActivityTemplates()
          .where((t) => t.id == widget.templateId)
          .firstOrNull;
    } else if (_selectedType != null) {
      _template = _serviceManager.activityService.getTemplateForActivity(
        _selectedType!,
      );
    }

    if (_template != null) {
      setState(() {
        _selectedType = _template!.type;
        _titleController.text = _template!.name;
        _descriptionController.text = _template!.description;
        _selectedRiskLevel = _template!.defaultRiskLevel;
        _selectedEnvironment = _template!.defaultEnvironment;
        _hasCheckInSchedule = _template!.requiresCheckIn;
        if (_template!.recommendedCheckInInterval != null) {
          _checkInInterval = _template!.recommendedCheckInInterval!;
        }
        if (_template!.typicalDuration != null) {
          _estimatedDuration = _template!.typicalDuration!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Activity'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Activity Type Selection
              if (_selectedType == null) _buildTypeSelection(),

              // Activity Details
              _buildActivityDetails(),

              const SizedBox(height: 20),

              // Risk and Environment
              _buildRiskAndEnvironment(),

              const SizedBox(height: 20),

              // Duration and Check-ins
              _buildDurationAndCheckIns(),

              const SizedBox(height: 32),

              // Start Button
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getActivityColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getActivityIcon(),
                  color: _getActivityColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActivityDisplayName(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (_template != null)
                      Text(
                        _template!.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Start New Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const Text(
            'Set up your activity for safe tracking and monitoring',
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ActivityType>(
          initialValue: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Select Activity Type',
            border: OutlineInputBorder(),
          ),
          items: ActivityType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getActivityIconForType(type), size: 16),
                  const SizedBox(width: 8),
                  Text(_getActivityDisplayNameForType(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
            _loadTemplate();
          },
          validator: (value) =>
              value == null ? 'Please select activity type' : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActivityDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Activity Title *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Morning Hike at Sunset Trail',
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter activity title' : null,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            border: OutlineInputBorder(),
            hintText: 'Add details about your activity...',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildRiskAndEnvironment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk & Environment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ActivityRiskLevel>(
                initialValue: _selectedRiskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                ),
                items: ActivityRiskLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(_getRiskLevelDisplayName(level)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRiskLevel = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<ActivityEnvironment>(
                initialValue: _selectedEnvironment,
                decoration: const InputDecoration(
                  labelText: 'Environment',
                  border: OutlineInputBorder(),
                ),
                items: ActivityEnvironment.values.map((env) {
                  return DropdownMenuItem(
                    value: env,
                    child: Text(_getEnvironmentDisplayName(env)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEnvironment = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationAndCheckIns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        // Estimated duration
        const Text(
          'Estimated Duration',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _estimatedDuration.inMinutes.toDouble(),
                min: 30,
                max: 720, // 12 hours
                divisions: 23,
                label: _formatDuration(_estimatedDuration),
                onChanged: (value) {
                  setState(() {
                    _estimatedDuration = Duration(minutes: value.round());
                  });
                },
              ),
            ),
            Text(
              _formatDuration(_estimatedDuration),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Check-in schedule
        SwitchListTile(
          title: const Text('Enable Check-In Schedule'),
          subtitle: const Text('Automatic safety check-ins during activity'),
          value: _hasCheckInSchedule,
          onChanged: (value) {
            setState(() {
              _hasCheckInSchedule = value;
            });
          },
        ),

        if (_hasCheckInSchedule) ...[
          const SizedBox(height: 8),
          const Text(
            'Check-In Interval',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _checkInInterval.inMinutes.toDouble(),
                  min: 15,
                  max: 240, // 4 hours
                  divisions: 15,
                  label: _formatDuration(_checkInInterval),
                  onChanged: (value) {
                    setState(() {
                      _checkInInterval = Duration(minutes: value.round());
                    });
                  },
                ),
              ),
              Text(
                _formatDuration(_checkInInterval),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _startActivity,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isSubmitting ? 'Starting...' : 'Start Activity'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getActivityColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _startActivity() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _serviceManager.activityService.startActivity(
        type: _selectedType!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        riskLevel: _selectedRiskLevel,
        environment: _selectedEnvironment,
        estimatedDuration: _estimatedDuration,
        hasCheckInSchedule: _hasCheckInSchedule,
        checkInInterval: _hasCheckInSchedule ? _checkInInterval : null,
        equipment: _template?.recommendedEquipment ?? [],
        safetyNotes: _template?.safetyTips ?? [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Started ${_titleController.text}'),
            backgroundColor: AppTheme.safeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to activities page
        context.go('/activities');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error starting activity: $e'),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Helper methods
  IconData _getActivityIcon() {
    if (_selectedType == null) return Icons.directions_run;

    switch (_selectedType!) {
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

  IconData _getActivityIconForType(ActivityType type) {
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

  Color _getActivityColor() {
    if (_selectedType == null) return AppTheme.infoBlue;

    switch (_selectedType!) {
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

  String _getActivityDisplayName() {
    if (_selectedType == null) return 'Activity';
    return _getActivityDisplayNameForType(_selectedType!);
  }

  String _getActivityDisplayNameForType(ActivityType type) {
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

  String _getRiskLevelDisplayName(ActivityRiskLevel level) {
    switch (level) {
      case ActivityRiskLevel.low:
        return 'Low Risk';
      case ActivityRiskLevel.moderate:
        return 'Moderate Risk';
      case ActivityRiskLevel.high:
        return 'High Risk';
      case ActivityRiskLevel.extreme:
        return 'Extreme Risk';
    }
  }

  String _getEnvironmentDisplayName(ActivityEnvironment environment) {
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
