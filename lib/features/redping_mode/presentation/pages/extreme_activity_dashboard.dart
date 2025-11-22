import 'package:flutter/material.dart';
import '../../../../models/extreme_activity.dart';
import '../../../../services/extreme_activity_service.dart';
import '../widgets/equipment_item_card.dart';
import '../widgets/safety_checklist_card.dart';
import '../widgets/activity_session_card.dart';

/// Dashboard for managing extreme activity equipment, sessions, and safety
class ExtremeActivityDashboard extends StatefulWidget {
  final String? activityType; // Optional: filter by activity type

  const ExtremeActivityDashboard({super.key, this.activityType});

  @override
  State<ExtremeActivityDashboard> createState() =>
      _ExtremeActivityDashboardState();
}

class _ExtremeActivityDashboardState extends State<ExtremeActivityDashboard>
    with SingleTickerProviderStateMixin {
  final _service = ExtremeActivityService.instance;
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_service.isInitialized) {
      await _service.initialize();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extreme Activity Manager')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activityType != null
              ? '${_formatActivityType(widget.activityType!)} Manager'
              : 'Extreme Activity Manager',
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Equipment'),
            Tab(icon: Icon(Icons.checklist), text: 'Safety'),
            Tab(icon: Icon(Icons.play_circle), text: 'Session'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipmentTab(),
          _buildSafetyTab(),
          _buildSessionTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ====== EQUIPMENT TAB ======

  Widget _buildEquipmentTab() {
    return StreamBuilder<List<EquipmentItem>>(
      stream: _service.equipmentStream,
      initialData: _service.equipment,
      builder: (context, snapshot) {
        final allEquipment = snapshot.data ?? [];
        final equipment = widget.activityType != null
            ? allEquipment
                  .where((e) => e.activityTypes.contains(widget.activityType))
                  .toList()
            : allEquipment;

        final needsInspection = equipment
            .where((e) => e.needsInspection)
            .length;
        final expired = equipment.where((e) => e.isExpired).length;

        return Column(
          children: [
            // Alert banner
            if (needsInspection > 0 || expired > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (expired > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$expired item(s) expired',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    if (needsInspection > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.info,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$needsInspection item(s) need inspection',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            // Equipment list
            Expanded(
              child: equipment.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No equipment added yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddEquipmentDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Equipment'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: equipment.length,
                      itemBuilder: (context, index) {
                        return EquipmentItemCard(
                          item: equipment[index],
                          onTap: () => _showEquipmentDetails(equipment[index]),
                          onInspect: () => _markInspected(equipment[index]),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ====== SAFETY TAB ======

  Widget _buildSafetyTab() {
    if (widget.activityType == null) {
      return const Center(
        child: Text('Select an activity type to view safety checklist'),
      );
    }

    final checklist = _service.getChecklistForActivity(widget.activityType!);
    final completed = _service.getTodaysSafetyChecks(widget.activityType!);
    final completedIds = completed.map((c) => c.checklistItemId).toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Checklist Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: checklist.isEmpty
                      ? 0
                      : completedIds.length / checklist.length,
                ),
                const SizedBox(height: 8),
                Text('${completedIds.length} of ${checklist.length} completed'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Checklist items grouped by category
        ...ChecklistCategory.values.map((category) {
          final items = checklist
              .where((item) => item.category == category)
              .toList();
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatCategory(category),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ...items.map((item) {
                final isCompleted = completedIds.contains(item.id);
                return SafetyChecklistCard(
                  item: item,
                  isCompleted: isCompleted,
                  onCheck: (passed, notes) =>
                      _completeSafetyCheck(item, passed, notes),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  // ====== SESSION TAB ======

  Widget _buildSessionTab() {
    return StreamBuilder<ExtremeActivitySession?>(
      stream: _service.activeSessionStream,
      initialData: _service.activeSession,
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null || !session.isActive) {
          return _buildStartSessionView();
        }

        return ActivitySessionCard(
          session: session,
          onEnd: () => _showEndSessionDialog(session),
          onUpdate: (distance, maxSpeed, altitude) {
            _service.updateSession(
              distance: distance,
              maxSpeed: maxSpeed,
              maxAltitude: altitude,
            );
          },
        );
      },
    );
  }

  Widget _buildStartSessionView() {
    final canStart = widget.activityType == null
        ? false
        : _service.allRequiredChecksCompleted(widget.activityType!);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No active session',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (widget.activityType != null) ...[
            if (!canStart)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Complete required safety checks before starting',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ElevatedButton.icon(
              onPressed: canStart ? () => _showStartSessionDialog() : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
            ),
          ] else
            const Text('Select an activity type first'),
        ],
      ),
    );
  }

  // ====== STATS TAB ======

  Widget _buildStatsTab() {
    if (widget.activityType == null) {
      return const Center(
        child: Text('Select an activity type to view statistics'),
      );
    }

    final stats = _service.getActivityStats(widget.activityType!);
    if (stats.isEmpty) {
      return const Center(child: Text('No activity history yet'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Sessions',
          stats['totalSessions'].toString(),
          Icons.event,
        ),
        if (stats['totalDistance'] > 0)
          _buildStatCard(
            'Total Distance',
            '${(stats['totalDistance'] as double).toStringAsFixed(1)} km',
            Icons.route,
          ),
        if (stats['totalDuration'] != Duration.zero)
          _buildStatCard(
            'Total Time',
            _formatDuration(stats['totalDuration'] as Duration),
            Icons.timer,
          ),
        if (stats['maxSpeed'] > 0)
          _buildStatCard(
            'Max Speed',
            '${(stats['maxSpeed'] as double).toStringAsFixed(1)} km/h',
            Icons.speed,
          ),
        if (stats['maxAltitude'] > 0)
          _buildStatCard(
            'Max Altitude',
            '${(stats['maxAltitude'] as double).toStringAsFixed(0)} m',
            Icons.terrain,
          ),
        if (stats['averageRating'] > 0)
          _buildStatCard(
            'Average Rating',
            '${(stats['averageRating'] as double).toStringAsFixed(1)} ⭐',
            Icons.star,
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ====== DIALOGS ======

  Future<void> _showAddEquipmentDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    EquipmentCategory category = EquipmentCategory.other;
    final selectedActivities = <String>{};
    DateTime? purchaseDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Equipment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => name = v!,
                ),
                // Category dropdown, activity selection, etc.
                // (Implementation simplified for brevity)
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final item = EquipmentItem(
                  id: 'equip_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  category: category,
                  activityTypes: selectedActivities.toList(),
                  purchaseDate: purchaseDate,
                );
                _service.addEquipment(item);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEquipmentDetails(EquipmentItem item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${_formatCategory(item.category)}'),
            if (item.manufacturer != null)
              Text('Manufacturer: ${item.manufacturer}'),
            Text('Condition: ${_formatCondition(item.condition)}'),
            if (item.lastInspection != null)
              Text('Last Inspection: ${_formatDate(item.lastInspection!)}'),
            if (item.needsInspection)
              const Text(
                'Needs Inspection',
                style: TextStyle(color: Colors.orange),
              ),
            if (item.isExpired)
              const Text(
                'EXPIRED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStartSessionDialog() async {
    // Implementation for starting session with equipment selection
    // (Simplified for brevity)
    final equipment = _service.getEquipmentForActivity(widget.activityType!);
    await _service.startSession(
      activityType: widget.activityType!,
      equipmentIds: equipment.map((e) => e.id).toList(),
    );
  }

  Future<void> _showEndSessionDialog(ExtremeActivitySession session) async {
    int? rating;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate your session:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: (rating ?? 0) > i ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => setState(() => rating = i + 1),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _service.endSession(rating: rating);
              Navigator.pop(context);
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  Future<void> _markInspected(EquipmentItem item) async {
    final updated = item.copyWith(
      lastInspection: DateTime.now(),
      nextInspection: DateTime.now().add(const Duration(days: 180)),
    );
    await _service.updateEquipment(updated);
  }

  Future<void> _completeSafetyCheck(
    SafetyChecklistItem item,
    bool passed,
    String? notes,
  ) async {
    await _service.completeSafetyCheck(
      activityType: widget.activityType!,
      checklistItemId: item.id,
      passed: passed,
      notes: notes,
    );
    setState(() {}); // Refresh UI
  }

  // ====== FORMATTING HELPERS ======

  String _formatActivityType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatCategory(dynamic category) {
    return category
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatCondition(EquipmentCondition condition) {
    return condition.toString().split('.').last[0].toUpperCase() +
        condition.toString().split('.').last.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
