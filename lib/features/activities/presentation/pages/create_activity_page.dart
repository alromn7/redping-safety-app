import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/user_activity.dart';

/// Page for creating custom activities
class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customNameController = TextEditingController();

  // Form state
  ActivityRiskLevel _selectedRiskLevel = ActivityRiskLevel.moderate;
  ActivityEnvironment _selectedEnvironment = ActivityEnvironment.urban;
  Duration _estimatedDuration = const Duration(hours: 2);
  bool _hasCheckInSchedule = false;
  Duration _checkInInterval = const Duration(hours: 1);

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Activity'),
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

              // Activity Details
              _buildActivityDetails(),

              const SizedBox(height: 20),

              // Risk and Environment
              _buildRiskAndEnvironment(),

              const SizedBox(height: 20),

              // Duration and Check-ins
              _buildDurationAndCheckIns(),

              const SizedBox(height: 32),

              // Create Button
              _buildCreateButton(),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_circle,
                color: AppTheme.infoBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Activity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  Text(
                    'Create your own activity type for personalized tracking',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          controller: _customNameController,
          decoration: const InputDecoration(
            labelText: 'Activity Type Name *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Rock Collecting, Bird Watching, Metal Detecting',
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter activity type name' : null,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Activity Title *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Weekend Rock Collecting at Pebble Beach',
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
            hintText: 'Add details about your custom activity...',
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
          'Risk & Environment Assessment',
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
                    child: Row(
                      children: [
                        Icon(
                          _getRiskLevelIcon(level),
                          color: _getRiskLevelColor(level),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_getRiskLevelDisplayName(level)),
                      ],
                    ),
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
                    child: Row(
                      children: [
                        Icon(
                          _getEnvironmentIcon(env),
                          color: AppTheme.infoBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_getEnvironmentDisplayName(env)),
                      ],
                    ),
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

        const SizedBox(height: 12),

        // Risk level description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRiskLevelColor(
              _selectedRiskLevel,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getRiskLevelColor(
                _selectedRiskLevel,
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Assessment: ${_getRiskLevelDisplayName(_selectedRiskLevel)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getRiskLevelColor(_selectedRiskLevel),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRiskLevelDescription(_selectedRiskLevel),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationAndCheckIns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety & Monitoring',
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
          title: const Text('Enable Safety Check-Ins'),
          subtitle: Text(
            _selectedRiskLevel == ActivityRiskLevel.high ||
                    _selectedRiskLevel == ActivityRiskLevel.extreme
                ? 'Recommended for high-risk activities'
                : 'Optional safety monitoring',
          ),
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _createActivity,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_circle),
        label: Text(_isSubmitting ? 'Creating...' : 'Create & Start Activity'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _serviceManager.activityService.startActivity(
        type: ActivityType.custom,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        customActivityName: _customNameController.text.trim(),
        riskLevel: _selectedRiskLevel,
        environment: _selectedEnvironment,
        estimatedDuration: _estimatedDuration,
        hasCheckInSchedule: _hasCheckInSchedule,
        checkInInterval: _hasCheckInSchedule ? _checkInInterval : null,
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
            content: Text('❌ Error creating activity: $e'),
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
  IconData _getRiskLevelIcon(ActivityRiskLevel level) {
    switch (level) {
      case ActivityRiskLevel.low:
        return Icons.check_circle;
      case ActivityRiskLevel.moderate:
        return Icons.warning_amber;
      case ActivityRiskLevel.high:
        return Icons.warning;
      case ActivityRiskLevel.extreme:
        return Icons.dangerous;
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

  String _getRiskLevelDescription(ActivityRiskLevel level) {
    switch (level) {
      case ActivityRiskLevel.low:
        return 'Minimal safety concerns. Basic monitoring recommended.';
      case ActivityRiskLevel.moderate:
        return 'Some safety considerations. Regular check-ins recommended.';
      case ActivityRiskLevel.high:
        return 'Significant safety risks. Frequent check-ins and emergency contacts required.';
      case ActivityRiskLevel.extreme:
        return 'High danger activity. Continuous monitoring and professional supervision recommended.';
    }
  }

  IconData _getEnvironmentIcon(ActivityEnvironment environment) {
    switch (environment) {
      case ActivityEnvironment.urban:
        return Icons.location_city;
      case ActivityEnvironment.suburban:
        return Icons.home;
      case ActivityEnvironment.rural:
        return Icons.landscape;
      case ActivityEnvironment.wilderness:
        return Icons.forest;
      case ActivityEnvironment.water:
        return Icons.waves;
      case ActivityEnvironment.mountain:
        return Icons.terrain;
      case ActivityEnvironment.desert:
        return Icons.wb_sunny;
      case ActivityEnvironment.forest:
        return Icons.park;
      case ActivityEnvironment.coastal:
        return Icons.beach_access;
      case ActivityEnvironment.indoor:
        return Icons.home_work;
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
