import 'package:flutter/material.dart';
import '../../../../models/extreme_activity.dart';
import 'dart:async';

/// Card widget for active session tracking
class ActivitySessionCard extends StatefulWidget {
  final ExtremeActivitySession session;
  final VoidCallback onEnd;
  final Function(double? distance, double? maxSpeed, double? altitude) onUpdate;

  const ActivitySessionCard({
    super.key,
    required this.session,
    required this.onEnd,
    required this.onUpdate,
  });

  @override
  State<ActivitySessionCard> createState() => _ActivitySessionCardState();
}

class _ActivitySessionCardState extends State<ActivitySessionCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.session.actualDuration;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.session.startTime);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Session',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _formatActivityType(widget.session.activityType),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Elapsed time
                Center(
                  child: Text(
                    _formatDuration(_elapsed),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Metrics grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            if (widget.session.distance != null)
              _buildMetricCard(
                'Distance',
                '${widget.session.distance!.toStringAsFixed(2)} km',
                Icons.route,
                colorScheme,
              ),
            if (widget.session.maxSpeed != null)
              _buildMetricCard(
                'Max Speed',
                '${widget.session.maxSpeed!.toStringAsFixed(1)} km/h',
                Icons.speed,
                colorScheme,
              ),
            if (widget.session.maxAltitude != null)
              _buildMetricCard(
                'Max Altitude',
                '${widget.session.maxAltitude!.toStringAsFixed(0)} m',
                Icons.terrain,
                colorScheme,
              ),
            if (widget.session.averageSpeed != null)
              _buildMetricCard(
                'Avg Speed',
                '${widget.session.averageSpeed!.toStringAsFixed(1)} km/h',
                Icons.speed,
                colorScheme,
              ),
            if (widget.session.altitudeGain != null)
              _buildMetricCard(
                'Climb',
                '${widget.session.altitudeGain!.toStringAsFixed(0)} m',
                Icons.arrow_upward,
                colorScheme,
              ),
            if (widget.session.altitudeLoss != null)
              _buildMetricCard(
                'Descent',
                '${widget.session.altitudeLoss!.toStringAsFixed(0)} m',
                Icons.arrow_downward,
                colorScheme,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Session details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.session.location != null)
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    widget.session.location!,
                  ),

                _buildDetailRow(
                  Icons.access_time,
                  'Started',
                  _formatTime(widget.session.startTime),
                ),

                if (widget.session.buddies.isNotEmpty)
                  _buildDetailRow(
                    Icons.people,
                    'Buddies',
                    '${widget.session.buddies.length} people',
                  ),

                if (widget.session.equipmentUsed.isNotEmpty)
                  _buildDetailRow(
                    Icons.fitness_center,
                    'Equipment',
                    '${widget.session.equipmentUsed.length} items',
                  ),

                if (widget.session.incidents.isNotEmpty)
                  _buildDetailRow(
                    Icons.warning,
                    'Incidents',
                    '${widget.session.incidents.length}',
                    color: Colors.orange,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weather conditions
        if (widget.session.conditions != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Conditions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeatherRow(
                    Icons.thermostat,
                    'Temperature',
                    '${widget.session.conditions!.temperature}°C',
                  ),
                  if (widget.session.conditions!.windSpeed != null)
                    _buildWeatherRow(
                      Icons.air,
                      'Wind',
                      '${widget.session.conditions!.windSpeed} km/h',
                    ),
                  if (widget.session.conditions!.visibility != null)
                    _buildWeatherRow(
                      Icons.visibility,
                      'Visibility',
                      '${widget.session.conditions!.visibility} km',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddIncidentDialog(context),
                icon: const Icon(Icons.warning),
                label: const Text('Report Incident'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onEnd,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showAddIncidentDialog(BuildContext context) async {
    String incident = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Incident'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Describe the incident',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => incident = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (incident.isNotEmpty) {
                // Add incident logic would go here
                Navigator.pop(context);
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatActivityType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
