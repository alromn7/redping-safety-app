import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../models/hazard_alert.dart';
import '../../../../models/ai_assistant.dart';
import '../../../../services/app_service_manager.dart';
import '../widgets/hazard_alert_card.dart';
import '../widgets/community_report_card.dart';
import '../widgets/hazard_report_dialog.dart';

/// Comprehensive hazard alerts page
class HazardAlertsPage extends StatefulWidget {
  final String? initialCategory;

  const HazardAlertsPage({super.key, this.initialCategory});

  @override
  State<HazardAlertsPage> createState() => _HazardAlertsPageState();
}

class _HazardAlertsPageState extends State<HazardAlertsPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  late TabController _tabController;

  List<HazardAlert> _activeAlerts = [];
  List<CommunityHazardReport> _communityReports = [];
  List<WeatherAlert> _weatherAlerts = [];
  List<AIHazardSummary> _aiHazardSummaries = [];

  bool _isLoading = true;
  bool _isReporting = false;
  bool _loadingAISummary = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial tab based on category parameter
    if (widget.initialCategory != null) {
      switch (widget.initialCategory!.toLowerCase()) {
        case 'weather':
          _tabController.index = 1; // Weather tab
          break;
        case 'community':
          _tabController.index = 2; // Community tab
          break;
        case 'emergency':
          _tabController.index = 0; // Active/Emergency tab
          break;
        default:
          _tabController.index = 0; // Default to Active tab
      }
    }

    _initializeHazardService();
    _setupCallbacks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeHazardService() async {
    setState(() => _isLoading = true);

    try {
      // Services should already be initialized by AppServiceManager
      if (!_serviceManager.hazardService.isInitialized) {
        await _serviceManager.initializeAllServices();
      }
      _loadHazardData();
    } catch (e) {
      _showError('Failed to initialize hazard service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupCallbacks() {
    _serviceManager.hazardService.setHazardAlertCallback(_onHazardAlert);
    _serviceManager.hazardService.setCommunityReportCallback(
      _onCommunityReport,
    );
    _serviceManager.hazardService.setWeatherAlertCallback(_onWeatherAlert);
    _serviceManager.hazardService.setAlertsUpdatedCallback(_onAlertsUpdated);
  }

  void _loadHazardData() {
    if (!mounted) return;

    setState(() {
      _activeAlerts = _serviceManager.hazardService.activeAlerts;
      _communityReports = _serviceManager.hazardService.communityReports;
      _weatherAlerts = _serviceManager.hazardService.weatherAlerts;
    });

    // Load AI-powered hazard summary
    _loadAIHazardSummary();
  }

  Future<void> _loadAIHazardSummary() async {
    if (!mounted || _activeAlerts.isEmpty) {
      setState(() => _aiHazardSummaries = []);
      return;
    }

    setState(() => _loadingAISummary = true);

    try {
      final summaries = await _serviceManager.aiAssistantService
          .getAIHazardSummary();
      if (mounted) {
        setState(() {
          _aiHazardSummaries = summaries;
          _loadingAISummary = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load AI hazard summary: $e');
      if (mounted) {
        setState(() {
          _aiHazardSummaries = [];
          _loadingAISummary = false;
        });
      }
    }
  }

  void _onHazardAlert(HazardAlert alert) {
    if (!mounted) return;
    setState(() {
      _activeAlerts = _serviceManager.hazardService.activeAlerts;
    });
    _showHazardSnackBar(alert);
  }

  void _onCommunityReport(CommunityHazardReport report) {
    if (!mounted) return;
    setState(() {
      _communityReports = _serviceManager.hazardService.communityReports;
    });
    _showSuccess('Hazard report submitted successfully');
  }

  void _onWeatherAlert(WeatherAlert alert) {
    if (!mounted) return;
    setState(() {
      _weatherAlerts = _serviceManager.hazardService.weatherAlerts;
    });
  }

  void _onAlertsUpdated() {
    _loadHazardData();
  }

  Future<void> _showReportHazardDialog() async {
    setState(() => _isReporting = true);

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => HazardReportDialog(
          locationService: _serviceManager.locationService,
        ),
      );

      if (result != null) {
        await _serviceManager.hazardService.reportCommunityHazard(
          type: result['type'],
          title: result['title'],
          description: result['description'],
          severity: result['severity'],
          mediaFiles: result['mediaFiles'],
          tags: result['tags'],
        );
      }
    } catch (e) {
      _showError('Failed to submit hazard report: $e');
    } finally {
      setState(() => _isReporting = false);
    }
  }

  Future<void> _refreshAlerts() async {
    try {
      if (!_serviceManager.hazardService.isInitialized) {
        await _serviceManager.initializeAllServices();
      }
      // Trigger a service-level refresh (respects battery/connectivity guards)
      await _serviceManager.hazardService.refreshWeatherAlerts();
      _loadHazardData();
      _showSuccess('Alerts refreshed');
    } catch (e) {
      _showError('Failed to refresh alerts: $e');
    }
  }

  void _showHazardSnackBar(HazardAlert alert) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(_getSeverityEmoji(alert.severity)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'New ${alert.type.name} alert: ${alert.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _getSeverityColor(alert.severity),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showAlertDetails(alert),
        ),
      ),
    );
  }

  void _showAlertDetails(HazardAlert alert) {
    showDialog(
      context: context,
      builder: (context) => _HazardAlertDetailsDialog(alert: alert),
    );
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hazard Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.main),
        ),
        actions: [
          IconButton(
            onPressed: _refreshAlerts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRouter.main),
            tooltip: 'Close',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.warning),
              text: 'Active (${_activeAlerts.length})',
            ),
            Tab(
              icon: const Icon(Icons.cloud),
              text: 'Weather (${_weatherAlerts.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Community (${_communityReports.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Alerts Tab
                _buildActiveAlertsTab(),

                // Weather Alerts Tab
                _buildWeatherAlertsTab(),

                // Community Reports Tab
                _buildCommunityReportsTab(),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _isReporting ? null : _showReportHazardDialog,
            backgroundColor: AppTheme.warningOrange,
            foregroundColor: Colors.white,
            icon: _isReporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.report),
            label: Text(_isReporting ? 'Reporting...' : 'Report Hazard'),
            heroTag: "report_hazard",
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => context.go(AppRouter.main),
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.home),
            label: const Text('Back to Dashboard'),
            heroTag: "back_to_dashboard",
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsTab() {
    if (_activeAlerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No Active Alerts',
        subtitle: 'No hazard alerts in your area',
        color: AppTheme.safeGreen,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI-Powered Hazard Summary Section
          _buildAIHazardSummarySection(),

          const SizedBox(height: 16),

          // Divider with label
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ALL ACTIVE ALERTS (${_activeAlerts.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 12),

          // All active alerts
          ..._activeAlerts.map(
            (alert) => HazardAlertCard(
              alert: alert,
              onDismiss: () =>
                  _serviceManager.hazardService.dismissAlert(alert.id),
              onTap: () => _showAlertDetails(alert),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertsTab() {
    if (_weatherAlerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.wb_sunny,
        title: 'No Weather Alerts',
        subtitle: 'Weather conditions are normal',
        color: AppTheme.infoBlue,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _weatherAlerts.length,
        itemBuilder: (context, index) {
          final alert = _weatherAlerts[index];
          return _buildWeatherAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildCommunityReportsTab() {
    if (_communityReports.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people,
        title: 'No Community Reports',
        subtitle: 'Be the first to report a hazard',
        color: AppTheme.warningOrange,
        actionLabel: 'Report Hazard',
        onAction: _showReportHazardDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _communityReports.length,
        itemBuilder: (context, index) {
          final report = _communityReports[index];
          return CommunityReportCard(
            report: report,
            onVerify: () =>
                _serviceManager.hazardService.verifyCommunityReport(report.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(backgroundColor: color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIHazardSummarySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.warningOrange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
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
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Safety Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    Text(
                      'Powered by Google Gemini',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingAISummary)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _loadAIHazardSummary,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh AI Analysis',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (_loadingAISummary)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'AI analyzing hazards...',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              ),
            )
          else if (_aiHazardSummaries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No critical threats detected by AI',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Critical Threats',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),

                // AI Hazard Cards
                ..._aiHazardSummaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _aiHazardSummaries.length - 1 ? 12 : 0,
                    ),
                    child: _buildAIHazardCard(summary, index + 1),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAIHazardCard(AIHazardSummary summary, int rank) {
    // Determine color based on severity score
    Color severityColor;
    if (summary.severityScore >= 8) {
      severityColor = AppTheme.criticalRed;
    } else if (summary.severityScore >= 6) {
      severityColor = AppTheme.warningOrange;
    } else {
      severityColor = AppTheme.infoBlue;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              // Rank Badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: severityColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Emoji
              Text(summary.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),

              // Title
              Expanded(
                child: Text(
                  summary.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),

              // Severity Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.severityScore}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            summary.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryText,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Distance/ETA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: severityColor),
                const SizedBox(width: 6),
                Text(
                  summary.distanceEta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Primary Action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: severityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.primaryAction,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertCard(WeatherAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: _getSeverityColor(
                      alert.severity,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud,
                    color: _getSeverityColor(alert.severity),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.headline,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        alert.event,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.name.toUpperCase(),
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
            Text(
              alert.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),
            if (alert.instruction.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.instruction,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Effective: ${_formatDateTime(alert.effective)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                if (alert.expires != null) ...[
                  const Spacer(),
                  Text(
                    'Expires: ${_formatDateTime(alert.expires!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => AppTheme.infoBlue,
      HazardSeverity.minor => AppTheme.safeGreen,
      HazardSeverity.moderate => AppTheme.warningOrange,
      HazardSeverity.severe => AppTheme.primaryRed,
      HazardSeverity.extreme => AppTheme.criticalRed,
      HazardSeverity.critical => AppTheme.criticalRed,
    };
  }

  String _getSeverityEmoji(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => 'ℹ️',
      HazardSeverity.minor => '⚠️',
      HazardSeverity.moderate => '🟡',
      HazardSeverity.severe => '🟠',
      HazardSeverity.extreme => '🔴',
      HazardSeverity.critical => '🚨',
    };
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Dialog showing detailed hazard alert information
class _HazardAlertDetailsDialog extends StatelessWidget {
  final HazardAlert alert;

  const _HazardAlertDetailsDialog({required this.alert});

  String _getSeverityEmoji(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => 'ℹ️',
      HazardSeverity.minor => '⚠️',
      HazardSeverity.moderate => '🟡',
      HazardSeverity.severe => '🟠',
      HazardSeverity.extreme => '🔴',
      HazardSeverity.critical => '🚨',
    };
  }

  String _getTypeEmoji(HazardType type) {
    return switch (type) {
      HazardType.weather => '🌩️',
      HazardType.earthquake => '🌍',
      HazardType.fire => '🔥',
      HazardType.flood => '🌊',
      HazardType.tornado => '🌪️',
      HazardType.hurricane => '🌀',
      HazardType.tsunami => '🌊',
      HazardType.landslide => '⛰️',
      HazardType.avalanche => '❄️',
      HazardType.chemicalSpill => '☣️',
      HazardType.gasLeak => '💨',
      HazardType.roadClosure => '🚧',
      HazardType.powerOutage => '⚡',
      HazardType.airQuality => '😷',
      _ => '⚠️',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hazard Alert Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Header
              _buildAlertHeader(),

              const SizedBox(height: 24),

              // Alert Details
              _buildAlertDetails(),

              const SizedBox(height: 24),

              // Instructions
              if (alert.instructions.isNotEmpty) ...[
                _buildInstructionsSection(),
                const SizedBox(height: 24),
              ],

              // Safety Tips
              if (alert.safetyTips.isNotEmpty) ...[
                _buildSafetyTipsSection(),
                const SizedBox(height: 24),
              ],

              // Location Information
              if (alert.affectedArea != null) ...[
                _buildLocationSection(),
                const SizedBox(height: 24),
              ],

              // Weather Data
              if (alert.weatherData != null) ...[_buildWeatherDataSection()],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(
                      alert.severity,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeEmoji(alert.type),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.type.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_getSeverityEmoji(alert.severity)} ${alert.severity.name.toUpperCase()} ALERT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              alert.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.primaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Source', _getSourceDisplayName(alert.source)),
            _buildDetailRow('Issued', _formatDateTime(alert.issuedAt)),
            if (alert.expiresAt != null)
              _buildDetailRow('Expires', _formatDateTime(alert.expiresAt!)),
            if (alert.radius != null)
              _buildDetailRow(
                'Affected Radius',
                '${alert.radius!.toStringAsFixed(1)} km',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, color: AppTheme.criticalRed),
                SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alert.instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: AppTheme.criticalRed,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.warningOrange),
                SizedBox(width: 8),
                Text(
                  'Safety Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alert.safetyTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final location = alert.affectedArea!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.criticalRed),
                SizedBox(width: 8),
                Text(
                  'Affected Area',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Coordinates',
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            ),
            if (location.address != null)
              _buildDetailRow('Address', location.address!),
            if (alert.radius != null)
              _buildDetailRow(
                'Radius',
                '${alert.radius!.toStringAsFixed(1)} km',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDataSection() {
    final weatherData = alert.weatherData!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.thermostat, color: AppTheme.infoBlue),
                SizedBox(width: 8),
                Text(
                  'Weather Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weatherData['temperature'] != null)
              _buildDetailRow(
                'Temperature',
                '${weatherData['temperature'].toStringAsFixed(1)}°C',
              ),
            if (weatherData['windSpeed'] != null)
              _buildDetailRow(
                'Wind Speed',
                '${weatherData['windSpeed'].toStringAsFixed(1)} km/h',
              ),
            if (weatherData['precipitation'] != null)
              _buildDetailRow(
                'Precipitation',
                '${weatherData['precipitation'].toStringAsFixed(1)} mm',
              ),
          ],
        ),
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
            width: 100,
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

  // Helper methods
  Color _getSeverityColor(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => AppTheme.infoBlue,
      HazardSeverity.minor => AppTheme.safeGreen,
      HazardSeverity.moderate => AppTheme.warningOrange,
      HazardSeverity.severe => AppTheme.primaryRed,
      HazardSeverity.extreme => AppTheme.criticalRed,
      HazardSeverity.critical => AppTheme.criticalRed,
    };
  }

  String _getSourceDisplayName(HazardSource source) {
    return switch (source) {
      HazardSource.nationalWeatherService => 'National Weather Service',
      HazardSource.emergencyManagement => 'Emergency Management',
      HazardSource.localAuthorities => 'Local Authorities',
      HazardSource.communityReport => 'Community Report',
      HazardSource.automatedSystem => 'Automated System',
      HazardSource.userReport => 'User Report',
      HazardSource.sensorNetwork => 'Sensor Network',
      HazardSource.satelliteData => 'Satellite Data',
    };
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
