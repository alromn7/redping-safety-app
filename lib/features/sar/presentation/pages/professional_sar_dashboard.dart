import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/app/app_launch_config.dart';
import '../../../../config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/sar_dashboard_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sar_report_page.dart';
import '../../../../services/firebase_service.dart';
import '../../../../repositories/sos_repository.dart';
import '../widgets/communication_buttons.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../widgets/upgrade_required_dialog.dart';
import '../../../../services/sar_identity_service.dart';

class ProfessionalSARDashboard extends StatefulWidget {
  const ProfessionalSARDashboard({super.key});

  @override
  State<ProfessionalSARDashboard> createState() =>
      _ProfessionalSARDashboardState();
}

class _ProfessionalSARDashboardState extends State<ProfessionalSARDashboard>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final SosRepository _sosRepo = SosRepository();
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  bool _isLoading = true;
  bool _useWebsiteFeed =
      false; // Changed: Use Firestore by default for real-time SOS sessions
  final bool _isOnline = true; // static indicator for now
  bool _isAvailable = true;
  String? _errorMessage;

  // Removed: String _sosStatusFilter = 'all'; // No longer needed with separate tabs
  // Removed: String _helpStatusFilter = 'all'; // Status filtering removed from help requests

  // Global filters
  String _dateFilter = 'all'; // all | today | 24h | 7d | 30d
  String _regionFilter = 'ALL'; // ALL or region code

  // Sorting options
  String _sosSort = 'newest'; // newest | oldest | priority
  String _helpSort = 'newest'; // newest | oldest | priority
  String _msgSort = 'newest'; // newest | oldest

  // Message composer
  final TextEditingController _msgController = TextEditingController();
  String _msgPriority = 'low';

  // Notes management
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, bool> _savingNotes = {};

  TabController? _tabController;
  int _activeTabIndex = 0;

  bool _unseenActiveSos = false;
  bool _unseenHelp = false;
  int _lastSeenActiveSosMs = 0;
  int _lastSeenHelpMs = 0;
  int _latestActiveSosMs = 0;
  int _latestHelpMs = 0;

  late final AnimationController _alertPulseController;
  late final Animation<double> _alertPulse;

  @override
  void initState() {
    super.initState();
    _alertPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _alertPulse = CurvedAnimation(
      parent: _alertPulseController,
      curve: Curves.easeInOut,
    );
    _featureAccessService.initialize();
    _loadDashboardPrefs();
    _isLoading = false;
  }

  Future<void> _loadDashboardPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _useWebsiteFeed =
            prefs.getBool('sar_useWebsiteFeed') ??
            false; // Default to Firestore mode
      });
      debugPrint(
        'SAR Dashboard: Using ${_useWebsiteFeed ? "Website Feed" : "Firestore"} mode',
      );
    } catch (_) {}
  }

  Future<void> _saveDashboardPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sar_useWebsiteFeed', _useWebsiteFeed);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _alertPulseController.dispose();
    _msgController.dispose();
    // Dispose all notes controllers
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    _notesControllers.clear();
    super.dispose();
  }

  void _bindTabController(TabController? controller) {
    if (controller == null) return;
    if (identical(_tabController, controller)) return;
    _tabController?.removeListener(_handleTabChange);
    _tabController = controller;
    _tabController?.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController == null) return;
      setState(() => _activeTabIndex = _tabController!.index);
    });
  }

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null) return;
    // Only update after the animation completes.
    if (controller.indexIsChanging) return;

    final idx = controller.index;
    if (_activeTabIndex == idx) return;

    setState(() {
      _activeTabIndex = idx;
      if (idx == 0) {
        _lastSeenActiveSosMs = _latestActiveSosMs;
        _unseenActiveSos = false;
      }
      if (idx == 2) {
        _lastSeenHelpMs = _latestHelpMs;
        _unseenHelp = false;
      }
    });
  }

  bool get _devBypass {
    final user = AuthService.instance.currentUser;
    return kDebugMode ||
        Env.appEnv == 'dev' ||
        AppConstants.testingModeEnabled ||
        user.isDeveloper;
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is admin - admins have full access
    final isAdmin = AuthService.instance.currentUser.isAdmin;
    final devBypass = _devBypass;
    final sarIdentityService = SARIdentityService();
    final isSAR = sarIdentityService.isVerifiedSARMember();

    // Entitlement gating removed in this app build.

    // Additional restriction: require verified SAR membership (or admin)
    if (!devBypass && !isAdmin && !isSAR) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          elevation: 0,
          title: const Text(
            'SAR Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => GoRouter.of(context).go(AppLaunchConfig.homeRoute),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.privacy_tip, color: Colors.orange, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Restricted: Only verified SAR members and admins can access the SAR dashboard.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => GoRouter.of(context).go('/sar-registration'),
                  child: const Text('Register as SAR Member'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    const upgradeBanner = SizedBox.shrink();
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.primaryText),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            upgradeBanner,
            _buildHeader(),
            const SizedBox(height: 8),
            _buildStatusBar(),
            Expanded(child: _buildDashboardBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.safety_check, color: AppTheme.safeGreen),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'SAR Dashboard',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Data Source Toggle
              Tooltip(
                message: _useWebsiteFeed
                    ? 'Using Website Feed (Switch to Firestore)'
                    : 'Using Firestore (Switch to Website)',
                child: IconButton(
                  icon: Icon(
                    _useWebsiteFeed ? Icons.cloud : Icons.bolt,
                    color: _useWebsiteFeed ? Colors.blue : Colors.orange,
                  ),
                  onPressed: () async {
                    setState(() => _useWebsiteFeed = !_useWebsiteFeed);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('sar_useWebsiteFeed', _useWebsiteFeed);
                    debugPrint(
                      'SAR Dashboard: Switched to ${_useWebsiteFeed ? "Website" : "Firestore"} mode',
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Dashboard Settings',
                icon: const Icon(Icons.settings, color: AppTheme.secondaryText),
                onPressed: _showSARDashboardSettings,
              ),
              const SizedBox(width: 4),
              const Text(
                'Avail',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Switch(
                value: _isAvailable,
                activeColor: AppTheme.safeGreen,
                activeTrackColor: AppTheme.safeGreen.withValues(alpha: 0.35),
                inactiveThumbColor: AppTheme.criticalRed,
                inactiveTrackColor: AppTheme.criticalRed.withValues(alpha: 0.35),
                onChanged: (v) async {
                  setState(() => _isAvailable = v);
                  final user = _firebaseService.currentUser;
                  if (user != null) {
                    try {
                      await _firebase.collection('users').doc(user.uid).set({
                        'availableForSAR': v,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    } catch (e) {
                      debugPrint('Availability update failed: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [AppTheme.safeGreen, AppTheme.safeGreen.withValues(alpha: 0.3)]
              : [
                  AppTheme.criticalRed,
                  AppTheme.criticalRed.withValues(alpha: 0.3),
                ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return DefaultTabController(
      length: 6,
      child: Builder(
        builder: (context) {
          _bindTabController(DefaultTabController.of(context));

          return Column(
            children: [
              _buildKpiHeader(),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: AppTheme.safeGreen,
                  indicatorWeight: 3,
                  labelColor: AppTheme.primaryText,
                  unselectedLabelColor: AppTheme.secondaryText,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    _buildTab(
                      icon: Icons.emergency,
                      label: 'Active SOS',
                      color: AppTheme.primaryRed,
                      showAlert: _unseenActiveSos,
                    ),
                    _buildTab(
                      icon: Icons.check_circle,
                      label: 'Resolved',
                      color: AppTheme.safeGreen,
                    ),
                    _buildTab(
                      icon: Icons.support_agent,
                      label: 'Help Requests',
                      color: AppTheme.infoBlue,
                      showAlert: _unseenHelp,
                    ),
                    _buildTab(
                      icon: Icons.assignment_ind,
                      label: 'My Assignments',
                      color: AppTheme.warningOrange,
                    ),
                    _buildTab(
                      icon: Icons.chat_bubble,
                      label: 'Messages',
                      color: AppTheme.infoBlue,
                    ),
                    _buildTab(
                      icon: Icons.personal_injury,
                      label: 'Fall Detection',
                      color: AppTheme.primaryRed,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _useWebsiteFeed
                        ? _buildActiveSOSTabWebsite()
                        : _buildActiveSOSTabRealtime(),
                    _useWebsiteFeed
                        ? _buildResolvedSOSTabWebsite()
                        : _buildResolvedSOSTabRealtime(),
                    _useWebsiteFeed
                        ? _buildHelpRequestsTabWebsite()
                        : _buildHelpRequestsTabRealtimeMerged(),
                    _buildAssignmentsTabRealtime(),
                    _useWebsiteFeed
                        ? _buildMessagesTabWebsite()
                        : _buildMessagesTab(),
                    _buildFallDetectionTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Enhanced tab with icon and color coding
  Widget _buildTab({
    required IconData icon,
    required String label,
    required Color color,
    bool showAlert = false,
  }) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 16, color: color),
              if (showAlert)
                Positioned(
                  right: -2,
                  top: -2,
                  child: FadeTransition(
                    opacity: _alertPulse,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.criticalRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActiveSOSTabWebsite() {
    return FutureBuilder<Map<String, dynamic>>(
      future: SARDashboardApiService.instance.fetchAllDashboardData(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Center(
            child: Text(
              'No data',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          );
        }
        final data = snap.data!;
        final incidents = (data['incidents'] as List?) ?? [];
        final stats = (data['stats'] as Map<String, dynamic>?) ?? {};
        return Column(
          children: [
            _buildStatsKpiFromWebsite(stats),
            _buildLiveMapSectionFromWebsite(incidents),
            Expanded(child: _buildIncidentListFromWebsite(incidents)),
          ],
        );
      },
    );
  }

  Widget _buildStatsKpiFromWebsite(Map<String, dynamic> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();

    Widget kpi(String title, String value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    final activeUsers = (stats['activeUsers'] ?? 0).toString();
    final activeTeams = (stats['activeTeams'] ?? 0).toString();
    final activeIncidents = (stats['activeIncidents'] ?? 0).toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          kpi('Active Users', activeUsers, AppTheme.infoBlue, Icons.person),
          const SizedBox(width: 8),
          kpi('Active Teams', activeTeams, AppTheme.safeGreen, Icons.groups),
          const SizedBox(width: 8),
          kpi(
            'Active Incidents',
            activeIncidents,
            AppTheme.primaryRed,
            Icons.emergency,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapSectionFromWebsite(List<dynamic> incidents) {
    if (incidents.isEmpty) return const SizedBox.shrink();
    Map<String, dynamic>? first;
    for (final it in incidents) {
      if (it is Map<String, dynamic>) {
        first = it;
        break;
      }
    }
    if (first == null) return const SizedBox.shrink();
    final loc = first['location'] as Map<String, dynamic>?;
    final lat = (loc?['latitude'] as num?)?.toDouble();
    final lon = (loc?['longitude'] as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.map, color: AppTheme.infoBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Operations Map (preview)',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: (lat != null && lon != null)
                    ? () async {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    : null,
                child: const Text('Open Maps'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentListFromWebsite(List<dynamic> incidents) {
    if (incidents.isEmpty) {
      return const Center(
        child: Text(
          'No incidents',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: incidents.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.neutralGray),
      itemBuilder: (context, i) {
        final it = incidents[i] as Map<String, dynamic>;
        final title = (it['type'] ?? 'INCIDENT').toString();
        final desc = (it['description'] ?? '').toString();
        final status = (it['status'] ?? 'active').toString();
        final priority = (it['priority'] ?? 'low').toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.neutralGray.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _priorityDot(priority),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [_priorityChip(priority)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveSOSTabRealtime() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterDropdown(
                  value: _dateFilter,
                  items: const ['all', 'today', '24h', '7d', '30d'],
                  icon: Icons.calendar_today,
                  onChanged: (v) => setState(() => _dateFilter = v ?? 'all'),
                ),
                const SizedBox(width: 8),
                _filterRegionField(),
                const SizedBox(width: 8),
                _filterDropdown(
                  value: _sosSort,
                  items: const ['newest', 'oldest', 'priority'],
                  icon: Icons.sort,
                  onChanged: (v) => setState(() => _sosSort = v ?? 'newest'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('sos_sessions')
                .orderBy('createdAt', descending: true)
                .limit(
                  500,
                ) // Increased limit to show all active cases (was 100)
                .snapshots(), // Real-time updates
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('❌ Active SOS stream error: ${snapshot.error}');
                final errorMsg = snapshot.error.toString();
                final isPermissionError = errorMsg.toLowerCase().contains(
                  'permission',
                );

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPermissionError ? Icons.lock : Icons.error_outline,
                          color: AppTheme.primaryRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPermissionError
                              ? 'Access Denied'
                              : 'Error Loading Sessions',
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPermissionError
                              ? 'Your account needs SAR member permissions.\nContact admin or check Firestore rules.'
                              : errorMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.secondaryText),
                        ),
                        if (isPermissionError) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.safeGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text(
                    'No SOS sessions',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                );
              }

              var docs = snapshot.data!.docs;
              debugPrint(
                '📊 Active SOS Tab: Received ${docs.length} total SOS sessions from Firebase',
              );

              // Track unseen/new active SOS (based on newest createdAt among active sessions)
              final activeCreatedMs = docs
                  .where((d) {
                    final status = (d.data()['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    return status != 'resolved' &&
                        status != 'cancelled' &&
                        status != 'false_alarm';
                  })
                  .map((d) => _timeToMs(d.data()['createdAt']))
                  .toList();
              final latestMs =
                  activeCreatedMs.isEmpty ? 0 : (activeCreatedMs..sort()).last;
              if (latestMs != _latestActiveSosMs) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _latestActiveSosMs = latestMs;
                    if (_activeTabIndex != 0 && latestMs > _lastSeenActiveSosMs) {
                      _unseenActiveSos = true;
                    }
                    // If user is currently on the tab, consider the newest as seen.
                    if (_activeTabIndex == 0 && latestMs > _lastSeenActiveSosMs) {
                      _lastSeenActiveSosMs = latestMs;
                      _unseenActiveSos = false;
                    }
                  });
                });
              }

              // Debug: Log first few sessions
              if (docs.isNotEmpty) {
                debugPrint('🔍 First SOS session:');
                final firstData = docs.first.data();
                debugPrint('  ID: ${docs.first.id}');
                debugPrint('  Status: ${firstData['status']}');
                debugPrint(
                  '  User: ${firstData['userName'] ?? firstData['userId']}',
                );
                debugPrint('  CreatedAt: ${firstData['createdAt']}');
              }

              // Status filter - ONLY ACTIVE statuses (client-side filtering)
              docs = docs.where((d) {
                final status = (d.data()['status'] ?? '')
                    .toString()
                    .toLowerCase();
                // Exclude resolved/cancelled/false_alarm
                final isActive =
                    status != 'resolved' &&
                    status != 'cancelled' &&
                    status != 'false_alarm';
                if (!isActive) {
                  debugPrint('  ⏭️ Filtering out: ${d.id} (status: $status)');
                }
                return isActive;
              }).toList();

              debugPrint(
                '✅ Active SOS Tab: ${docs.length} active sessions after filtering',
              );
              // Region filter
              if (_regionFilter != 'ALL' && _regionFilter.trim().isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data();
                  final region = (data['region'] ?? data['regionCode'] ?? '')
                      .toString()
                      .toUpperCase();
                  return region == _regionFilter.toUpperCase();
                }).toList();
              }
              // Date range filter
              var filtered = docs
                  .where((d) => _withinDateRange(d.data()['createdAt']))
                  .toList();
              // Sorting
              if (_sosSort == 'oldest') {
                filtered.sort(
                  (a, b) => _timeToMs(
                    a.data()['createdAt'],
                  ).compareTo(_timeToMs(b.data()['createdAt'])),
                );
              } else if (_sosSort == 'priority') {
                filtered.sort(
                  (a, b) =>
                      _priorityRank(
                        (b.data()['priority'] ?? 'low').toString(),
                      ).compareTo(
                        _priorityRank(
                          (a.data()['priority'] ?? 'low').toString(),
                        ),
                      ),
                );
              } else {
                filtered.sort(
                  (a, b) => _timeToMs(
                    b.data()['createdAt'],
                  ).compareTo(_timeToMs(a.data()['createdAt'])),
                );
              }

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching SOS sessions',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.neutralGray),
                itemBuilder: (context, i) {
                  final data = filtered[i].data();
                  final id = filtered[i].id;
                  final status = (data['status'] ?? 'unknown').toString();
                  final userName =
                      (data['userName'] ?? data['userId'] ?? 'Unknown')
                          .toString();
                  final message =
                      (data['userMessage'] ??
                              data['details'] ??
                              data['description'] ??
                              '')
                          .toString();
                  final priority = (data['priority'] ?? 'medium').toString();
                  final startTime = data['createdAt'] ?? data['updatedAt'];

                  return InkWell(
                    onTap: () => _showSosActionsSheet(id, data),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'resolved'
                              ? AppTheme.neutralGray.withValues(alpha: 0.3)
                              : AppTheme.primaryRed.withValues(alpha: 0.3),
                          width: status == 'resolved' ? 1 : 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'resolved'
                                  ? AppTheme.neutralGray.withValues(alpha: 0.1)
                                  : AppTheme.primaryRed.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emergency,
                                  color: status == 'resolved'
                                      ? AppTheme.neutralGray
                                      : AppTheme.primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _statusChip(status),
                              ],
                            ),
                          ),

                          // Message content
                          if (message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          // Detailed Information Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: _buildSosDetailsSection(data),
                          ),

                          // Status Timeline
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: _buildStatusTimeline(data),
                          ),

                          // SAR Responder Details
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: _buildResponderDetails(data),
                          ),

                          // SAR Notes/Write-up Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: _buildSarNotesSection(id, data),
                          ),

                          // Metadata
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Row(
                              children: [
                                _priorityIndicator(priority),
                                const SizedBox(width: 8),
                                if (startTime != null)
                                  Flexible(
                                    child: Text(
                                      _relativeFromTimestamp(startTime),
                                      style: const TextStyle(
                                        color: AppTheme.secondaryText,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // For resolved cases: show incident report button
                          // For active cases: show action buttons and communication
                          if (status == 'resolved' ||
                              status == 'cancelled' ||
                              status == 'false_alarm')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SarReportPage(
                                        id: id,
                                        collection: 'sos_sessions',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.description, size: 18),
                                label: const Text('View Incident Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.infoBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              child: _buildSosActionButtons(id, status),
                            ),

                            // Communication section
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: CommunicationButtons(
                                sosId: id,
                                userId: data['userId']?.toString(),
                                userName: userName,
                                userPhone:
                                    (data['phoneNumber'] ?? data['phone'] ?? '')
                                        .toString(),
                                sarMemberId:
                                    _firebaseService.currentUser?.uid ??
                                    'sar_team',
                                sarMemberName:
                                    _firebaseService.currentUser?.displayName ??
                                    'SAR Team',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResolvedSOSTabRealtime() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterDropdown(
                  value: _dateFilter,
                  items: const ['all', 'today', '24h', '7d', '30d'],
                  icon: Icons.calendar_today,
                  onChanged: (v) => setState(() => _dateFilter = v ?? 'all'),
                ),
                const SizedBox(width: 8),
                _filterRegionField(),
                const SizedBox(width: 8),
                _filterDropdown(
                  value: _sosSort,
                  items: const ['newest', 'oldest', 'priority'],
                  icon: Icons.sort,
                  onChanged: (v) => setState(() => _sosSort = v ?? 'newest'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('sos_sessions')
                .orderBy('createdAt', descending: true)
                .limit(500) // Increased to show all resolved cases
                .snapshots(),
            builder: (context, sosSnapshot) {
              // Merge SOS sessions and help requests
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firebase
                    .collection('help_requests')
                    .orderBy('createdAt', descending: true)
                    .limit(500) // Increased to show all resolved help requests
                    .snapshots(),
                builder: (context, helpSnapshot) {
                  // Merge regional_pings as well
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebase
                        .collection('sos_pings')
                        .orderBy('timestamp', descending: true)
                        .limit(
                          500,
                        ) // Increased to show all resolved regional help requests
                        .snapshots(),
                    builder: (context, regSnapshot) {
                      if (sosSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          helpSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          regSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<_ResolvedItem> items = [];

                      // Add resolved SOS sessions
                      if (sosSnapshot.hasData) {
                        for (final doc in sosSnapshot.data!.docs) {
                          final data = doc.data();
                          final status = (data['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          if (status == 'resolved' ||
                              status == 'cancelled' ||
                              status == 'false_alarm') {
                            items.add(
                              _ResolvedItem(
                                id: doc.id,
                                collection: 'sos_sessions',
                                data: data,
                                type: 'sos',
                              ),
                            );
                          }
                        }
                      }

                      // Add resolved help requests
                      if (helpSnapshot.hasData) {
                        for (final doc in helpSnapshot.data!.docs) {
                          final data = doc.data();
                          final status = (data['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          if (status == 'resolved' ||
                              status == 'completed' ||
                              status == 'closed') {
                            items.add(
                              _ResolvedItem(
                                id: doc.id,
                                collection: 'help_requests',
                                data: data,
                                type: 'help',
                              ),
                            );
                          }
                        }
                      }

                      // Add resolved help pings from sos_pings
                      if (regSnapshot.hasData) {
                        for (final doc in regSnapshot.data!.docs) {
                          final data = doc.data();
                          final id = doc.id;
                          final metadata = data['metadata'];
                          String? requestType;
                          if (metadata is Map) {
                            requestType = metadata['requestType']?.toString();
                          }
                          if (id.startsWith('help_') || requestType == 'redping_help') {
                            final status = (data['status'] ?? '')
                                .toString()
                                .toLowerCase();
                            if (status == 'resolved' ||
                                status == 'completed' ||
                                status == 'closed') {
                              items.add(
                                _ResolvedItem(
                                  id: id,
                                  collection: 'sos_pings',
                                  data: data,
                                  type: 'help',
                                ),
                              );
                            }
                          }
                        }
                      }

                      // Apply filters
                      List<_ResolvedItem> filtered = items;

                      // Region filter
                      if (_regionFilter != 'ALL' &&
                          _regionFilter.trim().isNotEmpty) {
                        filtered = filtered.where((item) {
                          final region =
                              (item.data['region'] ??
                                      item.data['regionCode'] ??
                                      '')
                                  .toString()
                                  .toUpperCase();
                          return region == _regionFilter.toUpperCase();
                        }).toList();
                      }

                      // Date filter
                      if (_dateFilter != 'all') {
                        final now = DateTime.now();
                        DateTime? cutoff;
                        if (_dateFilter == 'today') {
                          cutoff = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            0,
                            0,
                            0,
                          );
                        } else if (_dateFilter == '24h') {
                          cutoff = now.subtract(const Duration(hours: 24));
                        } else if (_dateFilter == '7d') {
                          cutoff = now.subtract(const Duration(days: 7));
                        } else if (_dateFilter == '30d') {
                          cutoff = now.subtract(const Duration(days: 30));
                        }
                        if (cutoff != null) {
                          filtered = filtered.where((item) {
                            final ts = _safeGetTimestamp(
                              item.data['createdAt'],
                            );
                            if (ts == null) return false;
                            return ts.toDate().isAfter(cutoff!);
                          }).toList();
                        }
                      }

                      // Sort
                      if (_sosSort == 'newest') {
                        filtered.sort((a, b) {
                          final tA = _safeGetTimestamp(
                            a.data['createdAt'],
                          )?.toDate();
                          final tB = _safeGetTimestamp(
                            b.data['createdAt'],
                          )?.toDate();
                          if (tA == null || tB == null) return 0;
                          return tB.compareTo(tA);
                        });
                      } else if (_sosSort == 'oldest') {
                        filtered.sort((a, b) {
                          final tA = _safeGetTimestamp(
                            a.data['createdAt'],
                          )?.toDate();
                          final tB = _safeGetTimestamp(
                            b.data['createdAt'],
                          )?.toDate();
                          if (tA == null || tB == null) return 0;
                          return tA.compareTo(tB);
                        });
                      } else if (_sosSort == 'priority') {
                        filtered.sort((a, b) {
                          // Priority sorting: critical > high > medium > low
                          int getPriorityValue(String priority) {
                            switch (priority.toLowerCase()) {
                              case 'critical':
                                return 4;
                              case 'high':
                                return 3;
                              case 'medium':
                                return 2;
                              case 'low':
                                return 1;
                              default:
                                return 0;
                            }
                          }

                          final pA = getPriorityValue(
                            a.data['priority']?.toString() ?? '',
                          );
                          final pB = getPriorityValue(
                            b.data['priority']?.toString() ?? '',
                          );
                          return pB.compareTo(pA);
                        });
                      }

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No resolved cases found',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {},
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final id = item.id;
                            final data = item.data;
                            final isHelpRequest = item.type == 'help';

                            final userName =
                                (data['userName'] ?? data['name'] ?? 'Unknown')
                                    .toString();
                            final startTime = _safeGetTimestamp(
                              data['createdAt'],
                            );
                            final status = (data['status'] ?? '').toString();
                            final priority = (data['priority'] ?? 'medium')
                                .toString();
                            final message =
                                (data['message'] ??
                                        data['notes'] ??
                                        data['details'] ??
                                        '')
                                    .toString();

                            return Card(
                              color: AppTheme.cardBackground,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppTheme.neutralGray.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with status and type indicator
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neutralGray.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isHelpRequest
                                              ? Icons.help
                                              : Icons.sos,
                                          color: AppTheme.safeGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: const TextStyle(
                                              color: AppTheme.primaryText,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _statusChip(status),
                                      ],
                                    ),
                                  ),

                                  // Message content
                                  if (message.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        0,
                                      ),
                                      child: Text(
                                        message,
                                        style: const TextStyle(
                                          color: AppTheme.secondaryText,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                  // Status Timeline
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      0,
                                    ),
                                    child: _buildStatusTimeline(data),
                                  ),

                                  // Metadata
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        _priorityIndicator(priority),
                                        const SizedBox(width: 8),
                                        if (startTime != null)
                                          Flexible(
                                            child: Text(
                                              _relativeFromTimestamp(startTime),
                                              style: const TextStyle(
                                                color: AppTheme.secondaryText,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // View Report button
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SarReportPage(
                                                id: id,
                                                collection: item
                                                    .collection, // Use actual collection (sos_sessions, help_requests, or regional_pings)
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.description,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isHelpRequest
                                              ? 'View Help Request Details'
                                              : 'View Incident Report',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.infoBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResolvedSOSTabWebsite() {
    // Since both app and website share the same Firebase source of truth,
    // we use the same real-time Firestore stream for consistency
    return _buildResolvedSOSTabRealtime();
  }

  // Merge help_requests with regional_pings(help_*)
  Widget _buildHelpRequestsTabRealtimeMerged() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Removed status filter chips (all, active, assigned, inProgress, resolved)
                _filterDropdown(
                  value: _dateFilter,
                  items: const ['all', 'today', '24h', '7d', '30d'],
                  icon: Icons.calendar_today,
                  onChanged: (v) => setState(() => _dateFilter = v ?? 'all'),
                ),
                const SizedBox(width: 8),
                _filterRegionField(),
                const SizedBox(width: 8),
                _filterDropdown(
                  value: _helpSort,
                  items: const ['newest', 'oldest', 'priority'],
                  icon: Icons.sort,
                  onChanged: (v) => setState(() => _helpSort = v ?? 'newest'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('help_requests')
                .orderBy('createdAt', descending: true)
                .limit(500) // Increased to show all help requests
                .snapshots(),
            builder: (context, helpSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firebase
                    .collection('sos_pings')
                    .orderBy('timestamp', descending: true)
                    .limit(500) // Increased to show all broadcast help pings
                    .snapshots(),
                builder: (context, pingSnap) {
                  if (helpSnap.connectionState == ConnectionState.waiting ||
                      pingSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final helpDocs = helpSnap.data?.docs ?? [];
                  final pingDocs = pingSnap.data?.docs ?? [];

                  // Track unseen/new help (help_requests + help_* pings from sos_pings)
                  final int latestHelpMs = () {
                    int maxMs = 0;
                    for (final d in helpDocs) {
                      final data = d.data();
                      final status = (data['status'] ?? 'active').toString();
                      final st = status.toLowerCase();
                      if (st == 'resolved' || st == 'completed' || st == 'closed') {
                        continue;
                      }
                      maxMs = maxMs < _timeToMs(data['createdAt'])
                          ? _timeToMs(data['createdAt'])
                          : maxMs;
                    }
                    for (final d in pingDocs) {
                      final data = d.data();
                      final id = d.id;
                      final metadata = data['metadata'];
                      String? requestType;
                      if (metadata is Map) {
                        requestType = metadata['requestType']?.toString();
                      }
                      if (!id.startsWith('help_') && requestType != 'redping_help') {
                        continue;
                      }
                      final status = (data['status'] ?? 'active').toString();
                      final st = status.toLowerCase();
                      if (st == 'resolved' || st == 'completed' || st == 'closed') {
                        continue;
                      }
                      maxMs = maxMs < _timeToMs(data['timestamp'])
                          ? _timeToMs(data['timestamp'])
                          : maxMs;
                    }
                    return maxMs;
                  }();

                  if (latestHelpMs != _latestHelpMs) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _latestHelpMs = latestHelpMs;
                        if (_activeTabIndex != 2 &&
                            latestHelpMs > _lastSeenHelpMs) {
                          _unseenHelp = true;
                        }
                        if (_activeTabIndex == 2 &&
                            latestHelpMs > _lastSeenHelpMs) {
                          _lastSeenHelpMs = latestHelpMs;
                          _unseenHelp = false;
                        }
                      });
                    });
                  }

                  if (kDebugMode) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Debug: help_requests=${helpDocs.length}, sos_pings=${pingDocs.length}, date=$_dateFilter, region=$_regionFilter',
                                  style: const TextStyle(
                                    color: AppTheme.secondaryText,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildHelpListMerged(helpDocs, pingDocs)),
                      ],
                    );
                  }

                  return _buildHelpListMerged(helpDocs, pingDocs);

                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHelpListMerged(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> helpDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pingDocs,
  ) {
    final List<_HelpItem> items = [];

    for (final d in helpDocs) {
      final data = d.data();
      final status = (data['status'] ?? 'active').toString();

      // Filter out resolved help requests - they belong in the Resolved tab
      if (status.toLowerCase() == 'resolved' ||
          status.toLowerCase() == 'completed' ||
          status.toLowerCase() == 'closed') {
        continue;
      }

      // Region/date filters
      if (_regionFilter != 'ALL' && _regionFilter.trim().isNotEmpty) {
        final region = (data['region'] ?? data['regionCode'] ?? '')
            .toString()
            .toUpperCase();
        // If a request has no region metadata, keep it visible.
        if (region.isNotEmpty && region != _regionFilter.toUpperCase()) {
          continue;
        }
      }
      if (!_withinDateRange(data['createdAt'])) continue;
      items.add(
        _HelpItem(
          id: d.id,
          title: (data['subCategoryId'] ?? data['categoryId'] ?? 'Help')
              .toString(),
          desc: (data['description'] ?? '').toString(),
          priority: (data['priority'] ?? 'low').toString(),
          status: status,
          time: data['createdAt'],
          raw: data,
          source: 'help_requests',
        ),
      );
    }

    for (final d in pingDocs) {
      final data = d.data();
      final id = d.id;
      final metadata = data['metadata'];
      String? requestType;
      String? helpCategory;
      if (metadata is Map) {
        requestType = metadata['requestType']?.toString();
        helpCategory = metadata['helpCategory']?.toString();
      }

      // Only include REDP!NG help pings
      if (!id.startsWith('help_') && requestType != 'redping_help') {
        continue;
      }
      final status = (data['status'] ?? 'active').toString();

      // Filter out resolved help requests - they belong in the Resolved tab
      if (status.toLowerCase() == 'resolved' ||
          status.toLowerCase() == 'completed' ||
          status.toLowerCase() == 'closed') {
        continue;
      }

      if (_regionFilter != 'ALL' && _regionFilter.trim().isNotEmpty) {
        final region = (data['region'] ?? data['regionCode'] ?? '')
            .toString()
            .toUpperCase();
        // If a ping has no region metadata, keep it visible.
        if (region.isNotEmpty && region != _regionFilter.toUpperCase()) {
          continue;
        }
      }
      if (!_withinDateRange(data['timestamp'])) continue;
      items.add(
        _HelpItem(
          id: d.id,
          title: (helpCategory ?? data['category'] ?? 'REDP!NG Help').toString(),
          desc: (data['userMessage'] ?? data['message'] ?? '').toString(),
          priority: (data['priority'] ?? 'low').toString(),
          status: status,
          time: data['timestamp'],
          raw: data,
          source: 'sos_pings',
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No matching help requests',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }

    if (_helpSort == 'oldest') {
      items.sort(
        (a, b) => _timeToMs(a.time).compareTo(_timeToMs(b.time)),
      );
    } else if (_helpSort == 'priority') {
      items.sort(
        (a, b) => _priorityRank(
          b.priority,
        ).compareTo(_priorityRank(a.priority)),
      );
    } else {
      items.sort(
        (a, b) => _timeToMs(b.time).compareTo(_timeToMs(a.time)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.neutralGray),
      itemBuilder: (context, i) {
        final it = items[i];
        return InkWell(
          onTap: () => _showHelpActionsSheet(
            it.id,
            it.raw,
            source: it.source,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neutralGray.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _priorityDot(it.priority),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.title,
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (it.desc.isNotEmpty)
                            Text(
                              it.desc,
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(it.status),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _priorityChip(it.priority),
                    if (it.time != null)
                      _metaChip(
                        _relativeFromTimestamp(it.time),
                        AppTheme.secondaryText,
                      ),
                    _metaChip(
                      it.source == 'help_requests' ? 'REQUEST' : 'PING',
                      AppTheme.secondaryText,
                    ),
                  ],
                ),
                if (it.source == 'help_requests') ...[
                  const SizedBox(height: 8),
                  _buildHelpActionButtons(it.id, it.status),
                ] else if (it.source == 'sos_pings') ...[
                  const SizedBox(height: 8),
                  _buildHelpPingActionButtons(it.id, it.status),
                ],
                const SizedBox(height: 12),
                // Communication buttons for SAR team
                CommunicationButtons(
                  helpRequestId: it.id,
                  userId: it.raw['userId']?.toString(),
                  userName: (it.raw['userName'] ??
                          it.raw['userId'] ??
                          'Unknown')
                      .toString(),
                  userPhone: (it.raw['phoneNumber'] ?? it.raw['phone'] ?? '')
                      .toString(),
                  sarMemberId:
                      _firebaseService.currentUser?.uid ?? 'sar_team',
                  sarMemberName:
                      _firebaseService.currentUser?.displayName ?? 'SAR Team',
                  helpCategory: it.title,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTabRealtime() {
    final u = _firebaseService.currentUser;
    if (u == null) {
      return const Center(
        child: Text(
          'Sign in to view assignments',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firebase
          .collection('help_responses')
          .where('responderId', isEqualTo: u.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No assignments yet',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.neutralGray),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final title = (data['title'] ?? data['helpTitle'] ?? 'Assignment')
                .toString();
            final status = (data['status'] ?? 'active').toString();
            final createdAt = data['createdAt'];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neutralGray.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.infoBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statusChip(status),
                            const SizedBox(width: 8),
                            if (createdAt != null)
                              _metaChip(
                                _relativeFromTimestamp(createdAt),
                                AppTheme.secondaryText,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHelpRequestsTabWebsite() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Removed status filter chips (all, active, pending, acknowledged, assigned, inprogress, resolved)
                _filterDropdown(
                  value: _helpSort,
                  items: const ['newest', 'oldest'],
                  icon: Icons.sort,
                  onChanged: (v) => setState(() => _helpSort = v ?? 'newest'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: SARDashboardApiService.instance.fetchHelpRequests(
              status: null, // Removed status filter - show all help requests
              limit: 50,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || (snap.data?.isEmpty ?? true)) {
                return const Center(
                  child: Text(
                    'No help requests',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                );
              }
              var items = List<Map<String, dynamic>>.from(snap.data!);

              int createdAtMs(Map<String, dynamic> m) {
                final v = m['createdAt'];
                if (v is String) {
                  return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
                }
                if (v is Map) {
                  // Firestore Timestamp JSON {_seconds, _nanoseconds} or {seconds, nanoseconds}
                  final sec = (v['_seconds'] ?? v['seconds']);
                  final ns = (v['_nanoseconds'] ?? v['nanoseconds']) ?? 0;
                  if (sec is int) {
                    return sec * 1000 + ((ns is int) ? (ns ~/ 1000000) : 0);
                  }
                }
                return 0;
              }

              items.sort((a, b) {
                final ta = createdAtMs(a), tb = createdAtMs(b);
                return _helpSort == 'oldest'
                    ? ta.compareTo(tb)
                    : tb.compareTo(ta);
              });

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.neutralGray),
                itemBuilder: (context, i) {
                  final it = items[i];
                  final title =
                      (it['subCategoryId'] ?? it['categoryId'] ?? 'Help')
                          .toString();
                  final desc = (it['description'] ?? '').toString();
                  final status = (it['status'] ?? 'active').toString();
                  final pr = (it['priority'] ?? 'low').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.neutralGray.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _priorityDot(pr),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (desc.isNotEmpty)
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        color: AppTheme.secondaryText,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [_priorityChip(pr)],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSARDashboardSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Mirror website SAR feed',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
                subtitle: const Text(
                  'Use website API for incidents/help/messages',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
                value: _useWebsiteFeed,
                onChanged: (v) {
                  setState(() => _useWebsiteFeed = v);
                  _saveDashboardPrefs();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesTabWebsite() {
    return FutureBuilder<List<dynamic>>(
      future: SARDashboardApiService.instance.fetchCommunications(limit: 50),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No messages',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final m = items[i] as Map<String, dynamic>;
            final text = (m['content'] ?? '').toString();
            final sender = (m['sender'] ?? 'SAR').toString();
            final ts = (m['timestamp'] ?? '').toString();
            final pr = (m['priority'] ?? 'low').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.neutralGray.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 16,
                        color: AppTheme.infoBlue.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sender,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ts.isNotEmpty)
                        Text(
                          ts,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(color: AppTheme.primaryText),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [_priorityChip(pr)]),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            children: [
              _filterDropdown(
                value: _dateFilter,
                items: const ['all', 'today', '24h', '7d', '30d'],
                icon: Icons.calendar_today,
                onChanged: (v) => setState(() => _dateFilter = v ?? 'all'),
              ),
              _filterRegionField(),
              _filterDropdown(
                value: _msgSort,
                items: const ['newest', 'oldest'],
                icon: Icons.sort,
                onChanged: (v) => setState(() => _msgSort = v ?? 'newest'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('sar_messages')
                .orderBy('timestamp', descending: true)
                .limit(500) // Increased to show more message history
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              // Filters
              if (_regionFilter != 'ALL' && _regionFilter.trim().isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data();
                  final region = (data['region'] ?? data['regionCode'] ?? '')
                      .toString()
                      .toUpperCase();
                  return region == _regionFilter.toUpperCase();
                }).toList();
              }
              docs = docs
                  .where((d) => _withinDateRange(d.data()['timestamp']))
                  .toList();
              // Sorting
              if (_msgSort == 'oldest') {
                docs.sort(
                  (a, b) => _timeToMs(
                    a.data()['timestamp'],
                  ).compareTo(_timeToMs(b.data()['timestamp'])),
                );
              } else {
                docs.sort(
                  (a, b) => _timeToMs(
                    b.data()['timestamp'],
                  ).compareTo(_timeToMs(a.data()['timestamp'])),
                );
              }

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final m = docs[i].data();
                  final text = (m['text'] ?? '').toString();
                  final sender = (m['senderName'] ?? m['senderId'] ?? 'SAR')
                      .toString();
                  final ts = m['timestamp'];
                  final pr = (m['priority'] ?? 'low').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.neutralGray.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 16,
                              color: AppTheme.infoBlue.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sender,
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ts != null)
                              Text(
                                _relativeFromTimestamp(ts),
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          text,
                          style: const TextStyle(color: AppTheme.primaryText),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _priorityChip(pr),
                            if ((m['region'] ?? m['regionCode']) != null) ...[
                              const SizedBox(width: 8),
                              _metaChip(
                                (m['region'] ?? m['regionCode']).toString(),
                                AppTheme.secondaryText,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildComposer(),
      ],
    );
  }

  // Actions
  Future<void> _showHelpActionsSheet(
    String id,
    Map<String, dynamic> data, {
    String source = 'help_requests',
  }) async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to perform SAR actions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final status = (data['status'] ?? 'active').toString();
    final isHelpRequest = source == 'help_requests';
    final isHelpPing = source == 'sos_pings';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryText,
                ),
                title: const Text(
                  'View details',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              if (isHelpRequest || isHelpPing)
                ListTile(
                  leading: const Icon(Icons.map, color: AppTheme.primaryText),
                  title: const Text(
                    'Open in Maps',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final loc =
                        (data['location'] ?? {}) as Map<String, dynamic>;
                    double? toD(v) {
                      if (v is num) return v.toDouble();
                      if (v is String) return double.tryParse(v);
                      return null;
                    }

                    final lat = toD(loc['latitude']);
                    final lon = toD(loc['longitude']);
                    if (lat != null && lon != null) {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}',
                      );
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              if (isHelpRequest)
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.primaryText,
                  ),
                  title: const Text(
                    'View SAR Report',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SarReportPage(id: id, collection: 'help_requests'),
                      ),
                    );
                  },
                ),
              if (isHelpRequest && status == 'active')
                ListTile(
                  leading: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.infoBlue,
                  ),
                  title: const Text(
                    'Start handling (In Progress)',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await _firebase
                          .collection('help_requests')
                          .doc(id)
                          .update({
                            'status': 'in_progress',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    } catch (e) {
                      debugPrint('Start handling failed: $e');
                    }
                  },
                ),
              if (isHelpRequest && status != 'resolved')
                ListTile(
                  leading: const Icon(
                    Icons.done_all,
                    color: AppTheme.safeGreen,
                  ),
                  title: const Text(
                    'Mark as Resolved',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await _firebase
                          .collection('help_requests')
                          .doc(id)
                          .update({
                            'status': 'resolved',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    } catch (e) {
                      debugPrint('Resolve help failed: $e');
                    }
                  },
                ),
              if (isHelpPing && status != 'resolved')
                ListTile(
                  leading: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.infoBlue,
                  ),
                  title: const Text(
                    'Start handling (In Progress)',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _updateHelpPingStatus(id, 'in_progress');
                  },
                ),
              if (isHelpPing && status != 'resolved')
                ListTile(
                  leading: const Icon(
                    Icons.done_all,
                    color: AppTheme.safeGreen,
                  ),
                  title: const Text(
                    'Mark as Resolved',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _updateHelpPingStatus(id, 'resolved');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSosActionsSheet(
    String id,
    Map<String, dynamic> data,
  ) async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to perform SAR actions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final status = (data['status'] ?? 'active').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryText,
                ),
                title: const Text(
                  'View details',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.map, color: AppTheme.primaryText),
                title: const Text(
                  'Open in Maps',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final loc = (data['location'] ?? {}) as Map<String, dynamic>;
                  double? toD(v) {
                    if (v is num) return v.toDouble();
                    if (v is String) return double.tryParse(v);
                    return null;
                  }

                  final lat = toD(loc['latitude']);
                  final lon = toD(loc['longitude']);
                  if (lat != null && lon != null) {
                    final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}',
                    );
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (status == 'active')
                ListTile(
                  leading: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.infoBlue,
                  ),
                  title: const Text(
                    'Set In Progress',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await _firebase
                          .collection('sos_sessions')
                          .doc(id)
                          .update({
                            'status': 'in_progress',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    } catch (e) {
                      debugPrint('Update SOS failed: $e');
                    }
                  },
                ),
              if (status != 'resolved')
                ListTile(
                  leading: const Icon(
                    Icons.done_all,
                    color: AppTheme.safeGreen,
                  ),
                  title: const Text(
                    'Mark Resolved',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await _firebase
                          .collection('sos_sessions')
                          .doc(id)
                          .update({
                            'status': 'resolved',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    } catch (e) {
                      debugPrint('Resolve SOS failed: $e');
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // KPI Header (Firestore-based)
  Widget _buildKpiHeader() {
    final activeSosStatuses = [
      'active',
      'acknowledged',
      'assigned',
      'enroute',
      'en_route',
      'dispatch',
      'dispatched',
      'responded',
      'inProgress',
      'in_progress',
    ];
    final activeHelpStatuses = [
      'active',
      'pending',
      'acknowledged',
      'assigned',
      'inProgress',
      'in_progress',
    ];
    final resolvedStatuses = ['resolved', 'completed', 'closed'];

    Widget kpiCard(String title, int value, Color color, IconData icon) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // Active SOS count
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase
                  .collection('sos_sessions')
                  .where('status', whereIn: activeSosStatuses)
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return kpiCard(
                  'Active SOS',
                  count,
                  AppTheme.primaryRed,
                  Icons.emergency,
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Active Help count
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase
                  .collection('help_requests')
                  .where('status', whereIn: activeHelpStatuses)
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return kpiCard(
                  'Active Help',
                  count,
                  AppTheme.infoBlue,
                  Icons.support_agent,
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Resolved count (SOS + Help Requests)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase
                  .collection('sos_sessions')
                  .where('status', whereIn: resolvedStatuses)
                  .snapshots(),
              builder: (context, sosSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firebase
                      .collection('help_requests')
                      .where('status', whereIn: resolvedStatuses)
                      .snapshots(),
                  builder: (context, helpSnap) {
                    final sosCount = sosSnap.data?.docs.length ?? 0;
                    final helpCount = helpSnap.data?.docs.length ?? 0;
                    final totalResolved = sosCount + helpCount;
                    return kpiCard(
                      'Resolved',
                      totalResolved,
                      AppTheme.safeGreen,
                      Icons.check_circle,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Unresolved count (cancelled, false_alarm, etc.)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase
                  .collection('sos_sessions')
                  .where(
                    'status',
                    whereIn: ['cancelled', 'false_alarm', 'timeout'],
                  )
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return kpiCard(
                  'Unresolved',
                  count,
                  AppTheme.warningOrange,
                  Icons.cancel,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Action buttons for SOS/Help
  Widget _buildSosActionButtons(String sosId, String currentStatus) {
    final st = currentStatus.toLowerCase();
    final isResolved =
        st == 'resolved' || st == 'cancelled' || st == 'false_alarm';

    if (isResolved) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
            SizedBox(width: 6),
            Text(
              'Case ${st.toUpperCase()}',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Entitlement/subscription gating removed in this app build.

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Acknowledge button - shows different state if already acknowledged
        st == 'acknowledged' ||
                st == 'assigned' ||
                st == 'en_route' ||
                st == 'on_scene'
            ? _statusIndicatorButton(
                'Acknowledged',
                Icons.check_circle,
                AppTheme.successGreen,
              )
            : _actionButton(
                'Acknowledge',
                Icons.check_circle_outline,
                AppTheme.infoBlue,
                () => _updateSosStatus(sosId, 'acknowledged'),
              ),

        // Assign button - ONLY enabled after acknowledged
        st == 'assigned' || st == 'en_route' || st == 'on_scene'
            ? _statusIndicatorButton(
                'Assigned',
                Icons.assignment_turned_in,
                AppTheme.warningOrange,
              )
            : st == 'acknowledged'
            ? _actionButton(
                'Assign',
                Icons.assignment_turned_in,
                AppTheme.warningOrange,
                () => _openAssignSosDialog(sosId),
              )
            : _disabledButton(
                'Assign',
                Icons.assignment_turned_in,
                'Acknowledge first',
              ),

        // En Route button - ONLY enabled after assigned
        st == 'en_route' || st == 'on_scene'
            ? _statusIndicatorButton(
                'En Route',
                Icons.navigation,
                AppTheme.infoBlue,
              )
            : st == 'assigned'
            ? _actionButton(
                'En Route',
                Icons.navigation,
                AppTheme.infoBlue,
                () => _updateSosStatus(sosId, 'en_route'),
              )
            : _disabledButton('En Route', Icons.navigation, 'Assign first'),

        // On Scene button - ONLY enabled after en_route
        st == 'on_scene'
            ? _statusIndicatorButton(
                'On Scene',
                Icons.location_on,
                AppTheme.successGreen,
              )
            : st == 'en_route'
            ? _actionButton(
                'On Scene',
                Icons.location_on,
                AppTheme.successGreen,
                () => _updateSosStatus(sosId, 'on_scene'),
              )
            : _disabledButton(
                'On Scene',
                Icons.location_on,
                'Team must be en route first',
              ),

        // Resolve button
        _actionButton(
          'Resolve',
          Icons.done_all,
          AppTheme.successGreen,
          () => _updateSosStatus(sosId, 'resolved'),
          elevated: true,
        ),
      ],
    );
  }

  // Status indicator button (non-clickable, shows current state)
  Widget _statusIndicatorButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Compact action button widget
  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool elevated = false,
  }) {
    if (elevated) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _disabledButton(String label, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: null, // Disabled
        icon: Icon(icon, size: 14, color: AppTheme.secondaryText),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.secondaryText.withValues(alpha: 0.3),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildHelpActionButtons(String helpId, String currentStatus) {
    final st = currentStatus.toLowerCase();
    final isResolved = st == 'resolved' || st == 'cancelled';

    if (isResolved) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
            SizedBox(width: 6),
            Text(
              'Case ${st.toUpperCase()}',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Entitlement/subscription gating removed in this app build.

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Acknowledge button - Always available for active requests
        st == 'acknowledged' ||
                st == 'assigned' ||
                st == 'inprogress' ||
                st == 'in_progress'
            ? _statusIndicatorButton(
                'Acknowledged',
                Icons.check_circle,
                AppTheme.successGreen,
              )
            : _actionButton(
                'Acknowledge',
                Icons.check_circle_outline,
                AppTheme.infoBlue,
                () => _updateHelpStatus(helpId, 'acknowledged'),
              ),

        // Assign button - ONLY enabled after acknowledged
        st == 'assigned' || st == 'inprogress' || st == 'in_progress'
            ? _statusIndicatorButton(
                'Assigned',
                Icons.assignment_ind,
                AppTheme.warningOrange,
              )
            : st == 'acknowledged'
            ? _actionButton(
                'Assign',
                Icons.assignment_ind,
                AppTheme.warningOrange,
                () => _openAssignHelpDialog(helpId),
              )
            : _disabledButton(
                'Assign',
                Icons.assignment_ind,
                'Acknowledge first',
              ),

        // In Progress button - ONLY enabled after assigned
        st == 'inprogress' || st == 'in_progress'
            ? _statusIndicatorButton(
                'In Progress',
                Icons.play_arrow,
                AppTheme.infoBlue,
              )
            : st == 'assigned'
            ? _actionButton(
                'In Progress',
                Icons.play_arrow,
                AppTheme.infoBlue,
                () => _updateHelpStatus(helpId, 'inProgress'),
              )
            : _disabledButton('In Progress', Icons.play_arrow, 'Assign first'),

        // Resolve button - Always available
        _actionButton(
          'Resolve',
          Icons.done_all,
          AppTheme.successGreen,
          () => _updateHelpStatus(helpId, 'resolved'),
          elevated: true,
        ),
      ],
    );
  }

  Widget _buildHelpPingActionButtons(String pingId, String currentStatus) {
    final st = currentStatus.toLowerCase();
    final isResolved = st == 'resolved' || st == 'cancelled';

    if (isResolved) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
            SizedBox(width: 6),
            Text(
              'Case ${st.toUpperCase()}',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Entitlement/subscription gating removed in this app build.

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        st == 'acknowledged' || st == 'assigned' || st == 'inprogress' || st == 'in_progress'
            ? _statusIndicatorButton(
                'Acknowledged',
                Icons.check_circle,
                AppTheme.successGreen,
              )
            : _actionButton(
                'Acknowledge',
                Icons.check_circle_outline,
                AppTheme.infoBlue,
                () => _updateHelpPingStatus(pingId, 'acknowledged'),
              ),

        st == 'inprogress' || st == 'in_progress'
            ? _statusIndicatorButton(
                'In Progress',
                Icons.play_arrow,
                AppTheme.infoBlue,
              )
            : _actionButton(
                'In Progress',
                Icons.play_arrow,
                AppTheme.infoBlue,
                () => _updateHelpPingStatus(pingId, 'in_progress'),
              ),

        _actionButton(
          'Resolve',
          Icons.done_all,
          AppTheme.successGreen,
          () => _updateHelpPingStatus(pingId, 'resolved'),
          elevated: true,
        ),
      ],
    );
  }

  Future<void> _updateSosStatus(
    String sosId,
    String status, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      debugPrint('🔵 SAR Dashboard: Updating SOS $sosId to status: $status');

      // Check if document exists first
      final exists = await _sosRepo.sessionExists(sosId);

      if (!exists) {
        debugPrint('❌ SAR Dashboard: SOS session not found: $sosId');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS session not found: $sosId'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
        return;
      }

      debugPrint('✅ SAR Dashboard: Session exists, updating...');

      // Append status history entry with client timestamp
      // Note: Cannot use FieldValue.serverTimestamp() inside arrayUnion
      final historyEntry = {
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'by': 'sar_dashboard',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      };
      final mergedExtra = {
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
        ...?extra,
      };

      debugPrint(
        '📝 SAR Dashboard: Calling updateStatus with mergedExtra: $mergedExtra',
      );

      await _sosRepo.updateStatus(sosId, status: status, extra: mergedExtra);

      debugPrint('✅ SAR Dashboard: Status updated successfully to $status');
      debugPrint('   - SOS ID: $sosId');
      debugPrint('   - New status: $status');
      debugPrint('   - This session should remain in Active SOS list');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS $sosId updated to $status successfully'),
          backgroundColor: AppTheme.safeGreen,
        ),
      );
    } catch (e) {
      debugPrint('❌ SAR Dashboard: Error updating SOS status - $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update SOS: ${e.toString()}'),
          backgroundColor: AppTheme.criticalRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _updateHelpStatus(
    String helpId,
    String status, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      // Note: Cannot use FieldValue.serverTimestamp() inside arrayUnion
      final data = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
            'by': 'app',
          },
        ]),
        ...?extra,
      };
      await _firebase.collection('help_requests').doc(helpId).update(data);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('HELP $helpId updated: $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update HELP: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    }
  }

  Future<void> _updateHelpPingStatus(
    String pingId,
    String status, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final data = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
            'by': 'sar_dashboard',
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          },
        ]),
        ...?extra,
      };
      await _firebase.collection('sos_pings').doc(pingId).update(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PING $pingId updated: $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update PING: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    }
  }

  Future<void> _openAssignSosDialog(String sosId) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Responder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Responder Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Responder ID (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final extra = {
                'metadata': {
                  'responderId': idController.text.trim().isEmpty
                      ? null
                      : idController.text.trim(),
                  'responderName': nameController.text.trim(),
                },
              };
              await _updateSosStatus(sosId, 'assigned', extra: extra);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAssignHelpDialog(String helpId) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Helper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Assignee Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Assignee ID (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final extra = {
                'assignedToName': nameController.text.trim(),
                'assignedToId': idController.text.trim().isEmpty
                    ? null
                    : idController.text.trim(),
              };
              await _updateHelpStatus(helpId, 'assigned', extra: extra);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryText),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: value,
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            dropdownColor: AppTheme.darkSurface,
            style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _filterRegionField() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, size: 16, color: AppTheme.secondaryText),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Region',
                hintStyle: TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
              controller: TextEditingController(
                text: _regionFilter == 'ALL' ? '' : _regionFilter,
              ),
              onSubmitted: (val) {
                setState(
                  () =>
                      _regionFilter = (val.isEmpty ? 'ALL' : val.toUpperCase()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _withinDateRange(dynamic ts) {
    if (_dateFilter == 'all') return true;
    final ms = _timeToMs(ts);
    if (ms == 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      case '24h':
        return now.difference(dt).inHours <= 24;
      case '7d':
        return now.difference(dt).inDays <= 7;
      case '30d':
        return now.difference(dt).inDays <= 30;
      default:
        return true;
    }
  }

  int _timeToMs(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
    try {
      final dt = (v as dynamic).toDate();
      if (dt is DateTime) return dt.millisecondsSinceEpoch;
    } catch (_) {}
    return 0;
  }

  int _priorityRank(String p) {
    switch (p) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  // Safe timestamp extraction from Firestore data
  Timestamp? _safeGetTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is String) {
      // Try to parse ISO8601 string to DateTime then convert to Timestamp
      try {
        final dt = DateTime.parse(value);
        return Timestamp.fromDate(dt);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _relativeFromTimestamp(dynamic ts) {
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (ts is DateTime) dt = ts;
    if (ts is String) {
      try {
        dt = DateTime.parse(ts);
      } catch (_) {}
    }
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  Widget _statusChip(String status) {
    Color c;
    String label = status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        c = AppTheme.primaryRed;
        break;
      case 'acknowledged':
        c = AppTheme.warningOrange;
        break;
      case 'assigned':
      case 'en_route':
      case 'on_scene':
      case 'inprogress':
        c = AppTheme.infoBlue;
        break;
      case 'resolved':
      case 'completed':
        c = AppTheme.successGreen;
        break;
      default:
        c = AppTheme.secondaryText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _priorityChip(String priority) {
    return _priorityIndicator(priority);
  }

  Widget _priorityDot(String priority) {
    Color c;
    switch (priority) {
      case 'critical':
        c = AppTheme.criticalRed;
        break;
      case 'high':
        c = AppTheme.primaryRed;
        break;
      case 'medium':
        c = AppTheme.warningOrange;
        break;
      default:
        c = AppTheme.safeGreen;
    }
    return CircleAvatar(radius: 10, backgroundColor: c);
  }

  // Compact priority indicator with icon and text
  Widget _priorityIndicator(String priority) {
    Color c;
    IconData icon;
    switch (priority) {
      case 'critical':
        c = AppTheme.criticalRed;
        icon = Icons.warning;
        break;
      case 'high':
        c = AppTheme.primaryRed;
        icon = Icons.priority_high;
        break;
      case 'medium':
        c = AppTheme.warningOrange;
        icon = Icons.flag;
        break;
      default:
        c = AppTheme.safeGreen;
        icon = Icons.low_priority;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          priority.toUpperCase(),
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final user = _firebaseService.currentUser;
    final enabled = user != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(
            top: BorderSide(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Type a message for SAR channel'
                      : 'Sign in to send messages',
                  hintStyle: const TextStyle(color: AppTheme.secondaryText),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppTheme.neutralGray.withValues(alpha: 0.3),
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(color: AppTheme.primaryText),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _msgPriority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('LOW')),
                DropdownMenuItem(value: 'medium', child: Text('MED')),
                DropdownMenuItem(value: 'high', child: Text('HIGH')),
                DropdownMenuItem(value: 'critical', child: Text('CRIT')),
              ],
              onChanged: enabled
                  ? (v) => setState(() => _msgPriority = v ?? 'low')
                  : null,
              underline: const SizedBox.shrink(),
              dropdownColor: AppTheme.darkSurface,
              style: const TextStyle(color: AppTheme.primaryText),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.safeGreen),
              onPressed: enabled ? _sendMessage : null,
            ),
          ],
        ),
      ),
    );
  }

  // Build detailed SOS information section
  Widget _buildSosDetailsSection(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;
    final address = (data['locationAddress'] ?? data['address'] ?? '')
        .toString();
    final medicalCondition = (data['medicalCondition'] ?? data['medical'] ?? '')
        .toString();
    final hazard = (data['hazard'] ?? data['hazardType'] ?? '').toString();
    final accidentType =
        (data['accidentType'] ?? data['sosType'] ?? data['type'] ?? '')
            .toString();
    final notes = (data['notes'] ?? data['additionalInfo'] ?? '').toString();
    final lat = location?['latitude'];
    final lon = location?['longitude'];

    // Emergency contact information - get from emergency contacts list (family/friends)
    // Exclude emergency services contacts (911, 000, etc.)
    String? emergencyContactName;
    String? emergencyContactPhone;
    String? emergencyContactRelationship;

    final emergencyContactsList =
        data['emergencyContactsList'] as List<dynamic>?;
    if (emergencyContactsList != null && emergencyContactsList.isNotEmpty) {
      // Find first contact that is NOT an emergency services number
      final familyContact = emergencyContactsList.firstWhere(
        (contact) {
          final relationship = (contact['relationship'] ?? '')
              .toString()
              .toLowerCase();
          // Skip emergency services, police, fire, ambulance contacts
          return !relationship.contains('emergency service') &&
              !relationship.contains('police') &&
              !relationship.contains('fire') &&
              !relationship.contains('ambulance');
        },
        orElse: () => emergencyContactsList
            .first, // Fallback to first contact if all are emergency services
      );

      emergencyContactName = familyContact['name'] as String?;
      emergencyContactPhone = familyContact['phoneNumber'] as String?;
      emergencyContactRelationship = familyContact['relationship'] as String?;
    }

    // If no details available, return empty widget
    if (address.isEmpty &&
        medicalCondition.isEmpty &&
        hazard.isEmpty &&
        accidentType.isEmpty &&
        notes.isEmpty &&
        lat == null &&
        emergencyContactName == null) {
      return const SizedBox.shrink();
    }

    Widget detailRow(
      IconData icon,
      String label,
      String value, {
      Color? iconColor,
    }) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: iconColor ?? AppTheme.infoBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.infoBlue),
              SizedBox(width: 6),
              Text(
                'INCIDENT DETAILS',
                style: TextStyle(
                  color: AppTheme.infoBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location Address
          if (address.isNotEmpty || (lat != null && lon != null))
            detailRow(
              Icons.location_on,
              'LOCATION',
              address.isNotEmpty
                  ? address
                  : lat != null && lon != null
                  ? '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'
                  : '',
              iconColor: AppTheme.primaryRed,
            ),

          // Emergency Contact Information
          if (emergencyContactName != null && emergencyContactPhone != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.contact_phone,
                    size: 16,
                    color: AppTheme.successGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMERGENCY CONTACT',
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$emergencyContactName${emergencyContactRelationship != null ? " ($emergencyContactRelationship)" : ""}',
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            // Copy phone number to clipboard or initiate call
                          },
                          child: Text(
                            emergencyContactPhone,
                            style: const TextStyle(
                              color: AppTheme.infoBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Accident Type
          if (accidentType.isNotEmpty)
            detailRow(
              Icons.emergency,
              'TYPE OF INCIDENT',
              accidentType.toUpperCase(),
              iconColor: AppTheme.warningOrange,
            ),

          // Medical Condition
          if (medicalCondition.isNotEmpty)
            detailRow(
              Icons.medical_services,
              'MEDICAL CONDITION',
              medicalCondition,
              iconColor: AppTheme.criticalRed,
            ),

          // Hazard
          if (hazard.isNotEmpty)
            detailRow(
              Icons.warning,
              'HAZARD',
              hazard,
              iconColor: AppTheme.warningOrange,
            ),

          // Notes
          if (notes.isNotEmpty)
            detailRow(Icons.note, 'ADDITIONAL NOTES', notes),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Map<String, dynamic> data) {
    final statusHistory = data['statusHistory'] as List<dynamic>?;

    if (statusHistory == null || statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 14, color: AppTheme.infoBlue),
              SizedBox(width: 6),
              Text(
                'STATUS TIMELINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...statusHistory.map((history) {
            final historyMap = history as Map<String, dynamic>;
            final status = historyMap['status'] ?? 'unknown';
            final timestamp = historyMap['timestamp'];
            final by = historyMap['by'] ?? 'Unknown';

            String timeStr = 'Unknown time';
            if (timestamp != null) {
              if (timestamp is Timestamp) {
                final dt = timestamp.toDate();
                timeStr =
                    '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
              }
            }

            IconData statusIcon;
            Color statusColor;
            switch (status.toLowerCase()) {
              case 'active':
                statusIcon = Icons.warning;
                statusColor = AppTheme.primaryRed;
                break;
              case 'acknowledged':
                statusIcon = Icons.check_circle_outline;
                statusColor = AppTheme.warningOrange;
                break;
              case 'assigned':
                statusIcon = Icons.person_add;
                statusColor = AppTheme.infoBlue;
                break;
              case 'en_route':
                statusIcon = Icons.directions_car;
                statusColor = const Color(0xFF9C27B0); // Purple
                break;
              case 'on_scene':
                statusIcon = Icons.location_on;
                statusColor = AppTheme.successGreen;
                break;
              case 'resolved':
                statusIcon = Icons.check_circle;
                statusColor = AppTheme.successGreen;
                break;
              default:
                statusIcon = Icons.circle;
                statusColor = AppTheme.neutralGray;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${status.replaceAll('_', ' ').toUpperCase()} by $by at $timeStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResponderDetails(Map<String, dynamic> data) {
    final metadata = data['metadata'] as Map<String, dynamic>?;
    final responderId = metadata?['responderId'];
    final responderName = metadata?['responderName'];

    if (responderId == null && responderName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_pin_circle,
                size: 14,
                color: AppTheme.successGreen,
              ),
              SizedBox(width: 6),
              Text(
                'ASSIGNED RESPONDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppTheme.successGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  responderName ?? 'ID: $responderId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSarNotesSection(String sosId, Map<String, dynamic> data) {
    final sarNotes = data['sarNotes'] as String? ?? '';
    final notesUpdatedBy = data['notesUpdatedBy'] as String?;
    final notesUpdatedAt = data['notesUpdatedAt'];

    // Create a TextEditingController for this specific SOS
    if (!_notesControllers.containsKey(sosId)) {
      _notesControllers[sosId] = TextEditingController(text: sarNotes);
    }

    String updateInfo = '';
    if (notesUpdatedBy != null && notesUpdatedAt != null) {
      if (notesUpdatedAt is Timestamp) {
        final dt = notesUpdatedAt.toDate();
        updateInfo =
            'Last updated by $notesUpdatedBy at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                size: 14,
                color: AppTheme.warningOrange,
              ),
              const SizedBox(width: 6),
              const Text(
                'SAR INCIDENT NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningOrange,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_savingNotes[sosId] == true)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save, size: 18),
                  color: AppTheme.warningOrange,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _saveSarNotes(sosId),
                  tooltip: 'Save Notes',
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesControllers[sosId],
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Enter incident notes, observations, and actions taken...',
              hintStyle: TextStyle(
                fontSize: 11,
                color: AppTheme.secondaryText.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: AppTheme.neutralGray.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: AppTheme.neutralGray.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.warningOrange),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          if (updateInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                updateInfo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveSarNotes(String sosId) async {
    final controller = _notesControllers[sosId];
    if (controller == null) return;

    setState(() {
      _savingNotes[sosId] = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('sos_sessions')
          .doc(sosId)
          .update({
            'sarNotes': controller.text,
            'notesUpdatedAt': FieldValue.serverTimestamp(),
            'notesUpdatedBy': user?.displayName ?? user?.email ?? 'Unknown',
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: AppTheme.criticalRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingNotes[sosId] = false;
        });
      }
    }
  }

  // Fall Detection Tab
  Widget _buildFallDetectionTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebase
          .collection('sos_sessions')
          .where('source', isEqualTo: 'redping_doctor_plus')
          .where('sosType', isEqualTo: 'fall_detection')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading fall detection alerts: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.personal_injury,
                  size: 64,
                  color: AppTheme.neutralGray.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No fall detection alerts',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fall detection alerts from RedPing Doctor Plus will appear here',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final fallAlerts = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: fallAlerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = fallAlerts[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildFallAlertCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildFallAlertCard(String sessionId, Map<String, dynamic> data) {
    final userName = data['userName'] as String? ?? 'Unknown User';
    final userId = data['userId'] as String? ?? '';
    final fallDetails = data['fallDetails'] as Map<String, dynamic>? ?? {};
    final medicalContext =
        data['medicalContext'] as Map<String, dynamic>? ?? {};
    final locationData = data['location'] as Map<String, dynamic>?;
    final timestamp = data['timestamp'] as Timestamp?;

    final severity = fallDetails['severity'] as String? ?? 'moderate';
    final responseStatus =
        fallDetails['responseStatus'] as String? ?? 'unknown';
    final impactForce = (fallDetails['impactForce'] as num?)?.toDouble() ?? 0.0;

    final bloodType = medicalContext['bloodType'] as String? ?? 'Unknown';
    final allergies =
        (medicalContext['allergies'] as List<dynamic>?)?.cast<String>() ?? [];
    final medications =
        (medicalContext['medications'] as List<dynamic>?)?.cast<String>() ?? [];
    final conditions =
        (medicalContext['conditions'] as List<dynamic>?)?.cast<String>() ?? [];

    final lat = locationData?['latitude'] as double?;
    final lon = locationData?['longitude'] as double?;

    Color severityColor;
    IconData severityIcon;
    switch (severity) {
      case 'critical':
        severityColor = AppTheme.criticalRed;
        severityIcon = Icons.error;
        break;
      case 'severe':
        severityColor = AppTheme.primaryRed;
        severityIcon = Icons.warning;
        break;
      case 'moderate':
        severityColor = AppTheme.warningOrange;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = AppTheme.neutralGray;
        severityIcon = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'FALL DETECTED - ${severity.toUpperCase()}',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _relativeFromTimestamp(timestamp),
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Patient Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.infoBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: responseStatus == 'no_response'
                            ? AppTheme.criticalRed.withValues(alpha: 0.2)
                            : AppTheme.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        responseStatus.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: responseStatus == 'no_response'
                              ? AppTheme.criticalRed
                              : AppTheme.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fall Details
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            size: 14,
                            color: AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Impact Force: ${impactForce.toStringAsFixed(2)}g',
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (lat != null && lon != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.primaryRed,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Medical Context
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.infoBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.medical_information,
                            size: 14,
                            color: AppTheme.infoBlue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'MEDICAL CONTEXT',
                            style: TextStyle(
                              color: AppTheme.infoBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _medicalContextRow('Blood Type', bloodType),
                      if (allergies.isNotEmpty)
                        _medicalContextRow('Allergies', allergies.join(', ')),
                      if (medications.isNotEmpty)
                        _medicalContextRow(
                          'Medications',
                          medications.join(', '),
                        ),
                      if (conditions.isNotEmpty)
                        _medicalContextRow('Conditions', conditions.join(', ')),
                    ],
                  ),
                ),

                // Action Buttons
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Dispatch SAR team
                          _dispatchSARForFall(sessionId, data);
                        },
                        icon: const Icon(Icons.local_hospital, size: 16),
                        label: const Text(
                          'Dispatch SAR',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: lat != null && lon != null
                            ? () {
                                // Open in maps
                                _openInMaps(lat, lon);
                              }
                            : null,
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text(
                          'View on Map',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.infoBlue,
                          side: const BorderSide(color: AppTheme.infoBlue),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicalContextRow(String label, String value) {
    if (value.isEmpty || value == 'Unknown') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dispatchSARForFall(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Dispatch SAR Team',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: const Text(
          'Are you sure you want to dispatch a SAR team for this fall detection alert?',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update the SOS session with SAR dispatch status
      await _firebase.collection('sos_sessions').doc(sessionId).update({
        'sarDispatched': true,
        'sarDispatchedAt': FieldValue.serverTimestamp(),
        'sarDispatchedBy': _firebaseService.currentUser?.uid,
        'status': 'sar_dispatched',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SAR team dispatched successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dispatch SAR: $e'),
            backgroundColor: AppTheme.criticalRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(double lat, double lon) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessage() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final region = _regionFilter == 'ALL' ? null : _regionFilter;
    try {
      await _firebase.collection('sar_messages').add({
        'text': text,
        'priority': _msgPriority,
        'region': region,
        'senderId': user.uid,
        'senderName': user.displayName ?? user.email ?? 'SAR',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _msgController.clear();
    } catch (e) {
      debugPrint('Send message failed: $e');
    }
  }
}

class _HelpItem {
  final String id;
  final String title;
  final String desc;
  final String priority;
  final String status;
  final dynamic time;
  final Map<String, dynamic> raw;
  final String source;
  const _HelpItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.priority,
    required this.status,
    required this.time,
    required this.raw,
    required this.source,
  });
}

class _ResolvedItem {
  final String id;
  final String collection; // sos_sessions, help_requests, or regional_pings
  final Map<String, dynamic> data;
  final String type; // sos or help
  const _ResolvedItem({
    required this.id,
    required this.collection,
    required this.data,
    required this.type,
  });
}
