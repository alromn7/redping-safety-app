import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_ping.dart';

/// Dialog for filtering SOS pings
class PingFilterDialog extends StatefulWidget {
  final double maxDistance;
  final List<SOSPriority> selectedPriorities;
  final List<RiskLevel> selectedRiskLevels;
  final Function(double, List<SOSPriority>, List<RiskLevel>) onFiltersChanged;

  const PingFilterDialog({
    super.key,
    required this.maxDistance,
    required this.selectedPriorities,
    required this.selectedRiskLevels,
    required this.onFiltersChanged,
  });

  @override
  State<PingFilterDialog> createState() => _PingFilterDialogState();
}

class _PingFilterDialogState extends State<PingFilterDialog> {
  late double _maxDistance;
  late List<SOSPriority> _selectedPriorities;
  late List<RiskLevel> _selectedRiskLevels;

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.maxDistance;
    _selectedPriorities = List.from(widget.selectedPriorities);
    _selectedRiskLevels = List.from(widget.selectedRiskLevels);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter SOS Pings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance filter
            const Text(
              'Maximum Distance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxDistance,
                    min: 1.0,
                    max: 200.0,
                    divisions: 199,
                    label: '${_maxDistance.toInt()} km',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${_maxDistance.toInt()} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Priority filter
            const Text(
              'Priority Levels',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...SOSPriority.values.map((priority) {
              return CheckboxListTile(
                title: Text(
                  _getPriorityDisplayName(priority),
                  style: TextStyle(color: _getPriorityColor(priority)),
                ),
                subtitle: Text(_getPriorityDescription(priority)),
                value: _selectedPriorities.contains(priority),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedPriorities.add(priority);
                    } else {
                      _selectedPriorities.remove(priority);
                    }
                  });
                },
                activeColor: _getPriorityColor(priority),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 16),

            // Risk level filter
            const Text(
              'Risk Levels',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...RiskLevel.values.map((risk) {
              return CheckboxListTile(
                title: Text(
                  _getRiskDisplayName(risk),
                  style: TextStyle(color: _getRiskColor(risk)),
                ),
                subtitle: Text(_getRiskDescription(risk)),
                value: _selectedRiskLevels.contains(risk),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedRiskLevels.add(risk);
                    } else {
                      _selectedRiskLevels.remove(risk);
                    }
                  });
                },
                activeColor: _getRiskColor(risk),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset to defaults
            setState(() {
              _maxDistance = 50.0;
              _selectedPriorities = List.from(SOSPriority.values);
              _selectedRiskLevels = List.from(RiskLevel.values);
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFiltersChanged(
              _maxDistance,
              _selectedPriorities,
              _selectedRiskLevels,
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
          child: const Text('Apply'),
        ),
      ],
    );
  }

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

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return AppTheme.safeGreen;
      case RiskLevel.medium:
        return AppTheme.warningOrange;
      case RiskLevel.high:
        return AppTheme.primaryRed;
      case RiskLevel.critical:
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

  String _getPriorityDescription(SOSPriority priority) {
    switch (priority) {
      case SOSPriority.low:
        return 'Non-urgent situations';
      case SOSPriority.medium:
        return 'Standard emergency response';
      case SOSPriority.high:
        return 'Urgent medical attention needed';
      case SOSPriority.critical:
        return 'Life-threatening emergency';
    }
  }

  String _getRiskDescription(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return 'Minimal danger to rescuer';
      case RiskLevel.medium:
        return 'Standard rescue precautions';
      case RiskLevel.high:
        return 'Elevated danger, extra caution';
      case RiskLevel.critical:
        return 'Extreme danger, specialized team';
    }
  }
}



