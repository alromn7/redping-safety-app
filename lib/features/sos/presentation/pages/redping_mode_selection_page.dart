import 'package:flutter/material.dart';

import '../../../../models/redping_mode.dart';
import '../../../../services/redping_mode_service.dart';
import '../../../../core/theme/app_theme.dart';

/// RedPing Mode Selection Page
class RedPingModeSelectionPage extends StatefulWidget {
  const RedPingModeSelectionPage({super.key});

  @override
  State<RedPingModeSelectionPage> createState() =>
      _RedPingModeSelectionPageState();
}

class _RedPingModeSelectionPageState extends State<RedPingModeSelectionPage> {
  final List<RedPingMode> _modes = RedPingModeService.getPredefinedModes();
  ModeCategory _selectedCategory = ModeCategory.work;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('RedPing Mode'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final modeService = RedPingModeService();
    return Column(
      children: [
        // Active Mode Banner
        if (modeService.hasActiveMode) _buildActiveModeBar(modeService),

        // Category Selector
        _buildCategorySelector(),

        // Mode List
        Expanded(child: _buildModeList(modeService)),
      ],
    );
  }

  Widget _buildActiveModeBar(RedPingModeService modeService) {
    final mode = modeService.activeMode!;
    final session = modeService.activeSession!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mode.themeColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: mode.themeColor, width: 2)),
      ),
      child: Row(
        children: [
          Icon(mode.icon, color: mode.themeColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mode.name} Active',
                  style: TextStyle(
                    color: mode.themeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDuration(session.duration),
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirm = await _showDeactivateDialog(context);
              if (confirm == true) {
                await modeService.deactivateMode();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppTheme.cardBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: ModeCategory.values.map((category) {
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_getCategoryName(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryRed
                      : AppTheme.primaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModeList(RedPingModeService modeService) {
    final filteredModes = _modes
        .where((m) => m.category == _selectedCategory)
        .toList();

    if (filteredModes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.secondaryText),
            const SizedBox(height: 16),
            Text(
              'No modes available',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredModes.length,
      itemBuilder: (context, index) {
        return _buildModeCard(filteredModes[index], modeService);
      },
    );
  }

  Widget _buildModeCard(RedPingMode mode, RedPingModeService modeService) {
    final isActive = modeService.activeMode?.id == mode.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: mode.themeColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isActive
            ? null
            : () => _showModeDetails(context, mode, modeService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: mode.themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mode.icon, color: mode.themeColor, size: 32),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.name,
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mode.themeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: AppTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeDetails(
    BuildContext context,
    RedPingMode mode,
    RedPingModeService modeService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildModeDetails(
            context,
            mode,
            modeService,
            scrollController,
          );
        },
      ),
    );
  }

  Widget _buildModeDetails(
    BuildContext context,
    RedPingMode mode,
    RedPingModeService modeService,
    ScrollController scrollController,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: mode.themeColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Icon(mode.icon, color: mode.themeColor, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.name,
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mode.description,
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              _buildDetailSection('Sensor Configuration', Icons.sensors, [
                'Crash Detection: ${mode.sensorConfig.crashThreshold.toInt()} m/s²',
                'Fall Detection: ${mode.sensorConfig.fallThreshold.toInt()} m/s²',
                'Power Mode: ${_formatPowerMode(mode.sensorConfig.powerMode)}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Location Tracking', Icons.location_on, [
                'Breadcrumbs: Every ${mode.locationConfig.breadcrumbInterval.inSeconds}s',
                'Accuracy: ${mode.locationConfig.accuracyTargetMeters}m target',
                if (mode.locationConfig.enableOfflineMaps) '✓ Offline maps',
                if (mode.locationConfig.enableRouteTracking) '✓ Route tracking',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Emergency Response', Icons.emergency, [
                'SOS Countdown: ${mode.emergencyConfig.sosCountdown.inSeconds}s',
                'Rescue Type: ${_formatRescueType(mode.emergencyConfig.preferredRescue)}',
                if (mode.emergencyConfig.autoCallEmergency)
                  '✓ Auto-call emergency services',
              ]),
              const SizedBox(height: 16),
              if (mode.activeHazardTypes.isNotEmpty)
                _buildDetailSection(
                  'Active Hazards',
                  Icons.warning,
                  mode.activeHazardTypes
                      .map((h) => '• ${_formatHazardType(h)}')
                      .toList(),
                ),
            ],
          ),
        ),

        // Activate Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await modeService.activateMode(mode);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${mode.name} activated'),
                      backgroundColor: AppTheme.safeGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mode.themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Activate Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
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
                  color: AppTheme.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeactivateDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Mode?'),
        content: const Text(
          'This will reset all mode-specific configurations and return to default settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ModeCategory category) {
    switch (category) {
      case ModeCategory.work:
        return '💼 Work';
      case ModeCategory.travel:
        return '✈️ Travel';
      case ModeCategory.family:
        return '👨‍👩‍👧‍👦 Family';
      case ModeCategory.group:
        return '👥 Group';
      case ModeCategory.extreme:
        return '🏔️ Extreme';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatPowerMode(PowerMode mode) {
    switch (mode) {
      case PowerMode.low:
        return 'Low (3-5 days)';
      case PowerMode.balanced:
        return 'Balanced (1-2 days)';
      case PowerMode.high:
        return 'High (<1 day)';
    }
  }

  String _formatRescueType(RescueType type) {
    switch (type) {
      case RescueType.ground:
        return 'Ground (Ambulance, SAR)';
      case RescueType.aerial:
        return 'Aerial (Helicopter)';
      case RescueType.marine:
        return 'Marine (Coast Guard)';
    }
  }

  String _formatHazardType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
