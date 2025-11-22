import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/satellite_service.dart';

/// Widget displaying satellite communication status
class SatelliteStatusWidget extends StatefulWidget {
  final SatelliteService satelliteService;
  final bool showDetails;

  const SatelliteStatusWidget({
    super.key,
    required this.satelliteService,
    this.showDetails = false,
  });

  @override
  State<SatelliteStatusWidget> createState() => _SatelliteStatusWidgetState();
}

class _SatelliteStatusWidgetState extends State<SatelliteStatusWidget> {
  bool _isConnected = false;
  double _signalStrength = 0.0;
  SatelliteConnectionType _connectionType = SatelliteConnectionType.none;
  int _queuedMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadSatelliteStatus();
    _setupCallbacks();
  }

  @override
  void dispose() {
    // Replace callbacks with no-ops so the service doesn't call into a disposed widget
    try {
      widget.satelliteService.setConnectionChangedCallback((_) {});
      widget.satelliteService.setSignalStrengthChangedCallback((_) {});
    } catch (_) {
      // ignore
    }
    super.dispose();
  }

  void _loadSatelliteStatus() {
    if (!mounted) return;

    setState(() {
      _isConnected = widget.satelliteService.isConnected;
      _signalStrength = widget.satelliteService.signalStrength;
      _connectionType = widget.satelliteService.connectionType;
      _queuedMessages = widget.satelliteService.queuedMessageCount;
    });
  }

  void _setupCallbacks() {
    widget.satelliteService.setConnectionChangedCallback((connected) {
      if (!mounted) return;
      setState(() => _isConnected = connected);
    });

    widget.satelliteService.setSignalStrengthChangedCallback((strength) {
      if (!mounted) return;
      setState(() => _signalStrength = strength);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.satelliteService.isAvailable) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getSatelliteColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.satellite_alt,
                    color: _getSatelliteColor(),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satellite Communication',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSatelliteColor(),
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildToggleSwitch(),
              ],
            ),

            // Details
            if (widget.showDetails && widget.satelliteService.isEnabled) ...[
              const SizedBox(height: 12),
              _buildSatelliteDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Switch(
      value: widget.satelliteService.isEnabled,
      onChanged: widget.satelliteService.isAvailable
          ? (enabled) {
              setState(() {
                widget.satelliteService.isEnabled = enabled;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    enabled
                        ? 'Satellite communication enabled'
                        : 'Satellite communication disabled',
                  ),
                  backgroundColor: enabled
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      activeThumbColor: AppTheme.safeGreen,
      inactiveThumbColor: AppTheme.disabledText,
    );
  }

  Widget _buildSatelliteDetails() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Signal strength
          Row(
            children: [
              const Icon(
                Icons.signal_cellular_alt,
                size: 14,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                'Signal: ${(_signalStrength * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: _signalStrength,
                  backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(_getSignalColor()),
                  minHeight: 3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Connection type and queued messages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getConnectionIcon(),
                    size: 14,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getConnectionTypeText(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
              if (_queuedMessages > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.queue,
                      size: 14,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_queuedMessages queued',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSatelliteColor() {
    if (!widget.satelliteService.isEnabled) return AppTheme.disabledText;
    if (!widget.satelliteService.isAvailable) return AppTheme.neutralGray;
    if (_isConnected) return AppTheme.safeGreen;
    return AppTheme.warningOrange;
  }

  Color _getSignalColor() {
    if (_signalStrength >= 0.7) return AppTheme.safeGreen;
    if (_signalStrength >= 0.4) return AppTheme.warningOrange;
    return AppTheme.criticalRed;
  }

  String _getStatusText() {
    if (!widget.satelliteService.isEnabled) return 'Disabled';
    if (!widget.satelliteService.isAvailable) return 'Not Available';
    if (!widget.satelliteService.hasPermission) return 'Permission Required';
    if (_isConnected) return 'Connected';
    return 'Searching...';
  }

  IconData _getConnectionIcon() {
    switch (_connectionType) {
      case SatelliteConnectionType.emergency:
        return Icons.emergency;
      case SatelliteConnectionType.messaging:
        return Icons.message;
      case SatelliteConnectionType.data:
        return Icons.data_usage;
      default:
        return Icons.signal_cellular_off;
    }
  }

  String _getConnectionTypeText() {
    switch (_connectionType) {
      case SatelliteConnectionType.emergency:
        return 'Emergency Only';
      case SatelliteConnectionType.messaging:
        return 'Messaging';
      case SatelliteConnectionType.data:
        return 'Full Data';
      default:
        return 'No Connection';
    }
  }
}
