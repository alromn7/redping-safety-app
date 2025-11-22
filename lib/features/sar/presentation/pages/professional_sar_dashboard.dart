import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/firebase_service.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../models/sar_access_level.dart';
import '../../../../models/sar_identity.dart';
import 'package:redping_14v/shared/widgets/status_chip.dart';

// Developer exemption email
const String _developerEmail = 'alromn7@gmail.com';

/// Professional SAR Live Dashboard with comprehensive functionality
/// Features dark UI, real-time updates, and full RedPing SAR integration
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
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  // Animation controller for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Data
  SARIdentity? _currentSARMember;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;
  bool _isAvailable = true;

  // Region/search functionality
  final TextEditingController _regionSearchController = TextEditingController();
  String _selectedRegion = 'all'; // all | region name
  // Quick toggle filters
  bool _toggleSOSOnly = false;
  bool _toggleHelpOnly = false;
  bool _toggleHighPriorityOnly = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_pulseController);
    _isLoading = false;
    _isOnline = true;
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isOnline = true;
      _errorMessage = null;
    });
  }

  void _showSARUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppTheme.warningOrange),
            SizedBox(width: 8),
            Expanded(child: Text('Upgrade to Pro')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAR Dashboard Write Access is available on Pro plans and above.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Respond to emergencies and manage SAR operations.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              SizedBox(height: 16),
              Text(
                'What you\'ll get with Pro:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Full SAR Dashboard Access'),
              SizedBox(height: 6),
              Text('• Acknowledge & Respond to SOS'),
              SizedBox(height: 6),
              Text('• Assign & Manage Operations'),
              SizedBox(height: 6),
              Text('• Update Status & Add Notes'),
              SizedBox(height: 6),
              Text('• AI Safety Assistant (24 commands)'),
              SizedBox(height: 6),
              Text('• RedPing Mode (Activity-based)'),
              SizedBox(height: 6),
              Text('• Gadget Integration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _regionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.safeGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'Initializing SAR Dashboard...',
                style: TextStyle(color: AppTheme.primaryText, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.criticalRed,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dashboard Error',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.secondaryText),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _initializeDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: AppTheme.safeGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentSARMember?.personalInfo.fullName ??
                                'SAR Member',
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _currentSARMember?.memberType.toString() ??
                                'Professional',
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Compact Availability toggle inside header
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Avail',
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isAvailable,
                            thumbColor: WidgetStatePropertyAll<Color>(
                              AppTheme.safeGreen,
                            ),
                            trackColor: WidgetStatePropertyAll<Color>(
                              AppTheme.safeGreen.withValues(alpha: 0.4),
                            ),
                            onChanged: (v) async {
                              setState(() => _isAvailable = v);
                              final user = _firebaseService.currentUser;
                              if (user != null) {
                                try {
                                  await _firebase
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                        'availableForSAR': v,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));
                                } catch (e) {
                                  debugPrint('Availability update failed: $e');
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Filter Menu Dropdown
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppTheme.primaryText,
                            size: 20,
                          ),
                          tooltip: 'Filters & Search',
                          color: AppTheme.darkSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.neutralGray.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          offset: const Offset(0, 40),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              enabled: false,
                              child: _buildFilterMenuContent(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status indicators
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusIndicator(
                      'ONLINE',
                      _isOnline ? AppTheme.safeGreen : AppTheme.criticalRed,
                    ),
                    _buildEmergencyCountBadge(),
                    // Small global status chip to indicate live dashboard
                    const StatusChip(status: 'live'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Status bar indicator
          _buildStatusBar(),
          // Main tabs
          Expanded(child: _buildDashboardBody()),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCountBadge() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firebase
          .collection('sos_sessions')
          .orderBy('startTime', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.safeGreen, width: 1),
            ),
            child: const Text(
              '0',
              style: TextStyle(
                color: AppTheme.safeGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        final docs = snap.data!.docs;
        int critical = 0;
        int high = 0;
        for (final d in docs) {
          final status = (d.data()['status'] ?? '').toString();
          if (status == 'active' ||
              status == 'assigned' ||
              status == 'inProgress') {
            final pr = (d.data()['priority'] ?? 'medium').toString();
            if (pr == 'critical') critical++;
            if (pr == 'high') high++;
          }
        }
        final total = critical + high;
        if (total > 0) {
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: critical > 0
                        ? AppTheme.criticalRed
                        : AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (critical > 0
                                    ? AppTheme.criticalRed
                                    : AppTheme.primaryRed)
                                .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.safeGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.safeGreen, width: 1),
          ),
          child: const Text(
            '0',
            style: TextStyle(
              color: AppTheme.safeGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
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
      length: 3,
      child: Column(
        children: [
          // 4 KPI COUNTER CARDS AT TOP
          _buildKPISummaryCards(),

          // Tab bar
          Container(
            color: AppTheme.darkSurface,
            child: TabBar(
              isScrollable: true,
              indicatorColor: AppTheme.safeGreen,
              indicatorWeight: 2,
              labelColor: AppTheme.primaryText,
              unselectedLabelColor: AppTheme.secondaryText,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStateProperty.all(
                AppTheme.safeGreen.withValues(alpha: 0.1),
              ),
              tabs: [
                // Active Ping (consolidated SOS + Help) with live count
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_active, size: 18),
                      const SizedBox(width: 4),
                      const Text('Active Ping'),
                      const SizedBox(width: 4),
                      // Combined live count: active SOS + non-resolved help
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firebase
                            .collection('sos_sessions')
                            .orderBy('startTime', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, sosSnap) {
                          final sosCount = (sosSnap.hasData)
                              ? sosSnap.data!.docs.where((d) {
                                  final s = (d.data()['status'] ?? '')
                                      .toString();
                                  return s == 'active' ||
                                      s == 'acknowledged' ||
                                      s == 'assigned' ||
                                      s == 'en_route' ||
                                      s == 'on_scene' ||
                                      s == 'in_progress' ||
                                      s == 'inProgress';
                                }).length
                              : 0;
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream: _firebase
                                .collection('help_requests')
                                .orderBy('createdAt', descending: true)
                                .limit(50)
                                .snapshots(),
                            builder: (context, helpSnap) {
                              final helpCount = (helpSnap.hasData)
                                  ? helpSnap.data!.docs.where((d) {
                                      final s = (d.data()['status'] ?? '')
                                          .toString();
                                      return s != 'resolved';
                                    }).length
                                  : 0;
                              final total = sosCount + helpCount;
                              if (total == 0) {
                                return const SizedBox.shrink();
                              }
                              // Use primary red to highlight urgency
                              return _buildCountBadge(
                                total,
                                AppTheme.primaryRed,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // My Assignments with live count
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_ind, size: 18),
                      const SizedBox(width: 4),
                      const Text('My Assignments'),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final u = _firebaseService.currentUser;
                          if (u == null) return const SizedBox.shrink();
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream: _firebase
                                .collection('help_responses')
                                .where('responderId', isEqualTo: u.uid)
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox.shrink();
                              final count = snap.data!.docs.length;
                              if (count == 0) return const SizedBox.shrink();
                              return _buildCountBadge(
                                count,
                                AppTheme.safeGreen,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Tab(icon: Icon(Icons.chat_bubble), text: 'Messages'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildActivePingTabRealtime(),
                _buildAssignmentsTabRealtime(),
                _buildMessagesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Small pill badge for counts
  Widget _buildCountBadge(int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Firestore-backed tabs
  // Removed: _buildActiveSOSTabRealtime (merged into _buildActivePingTabRealtime)

  // NEW: 4 KPI Summary Cards with Real-time Updates
  Widget _buildKPISummaryCards() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firebase
          .collection('sos_sessions')
          .orderBy('startTime', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, sosSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firebase
              .collection('help_requests')
              .orderBy('createdAt', descending: true)
              .limit(200)
              .snapshots(),
          builder: (context, helpSnapshot) {
            int activeSOS = 0;
            int helpRequests = 0;
            int resolved = 0;
            int unresolved = 0;

            if (sosSnapshot.hasData && helpSnapshot.hasData) {
              final sosDocs = sosSnapshot.data!.docs;
              final helpDocs = helpSnapshot.data!.docs;

              // Count Active SOS (all non-resolved statuses)
              activeSOS = sosDocs.where((d) {
                final status = (d.data()['status'] ?? '').toString();
                return status == 'active' ||
                    status == 'acknowledged' ||
                    status == 'assigned' ||
                    status == 'responder_assigned' ||
                    status == 'en_route' ||
                    status == 'on_scene' ||
                    status == 'in_progress' ||
                    status == 'inProgress';
              }).length;

              // Count Active Help Requests (all non-resolved statuses)
              helpRequests = helpDocs.where((d) {
                final status = (d.data()['status'] ?? '').toString();
                return status != 'resolved';
              }).length;

              // Count Resolved (both SOS and Help)
              resolved =
                  sosDocs.where((d) {
                    final status = (d.data()['status'] ?? '').toString();
                    return status == 'resolved';
                  }).length +
                  helpDocs.where((d) {
                    final status = (d.data()['status'] ?? '').toString();
                    return status == 'resolved';
                  }).length;

              // Unresolved = Active SOS + Active Help Requests
              unresolved = activeSOS + helpRequests;
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showActiveSOSListSheet,
                      child: _buildKPICard(
                        'Active SOS',
                        activeSOS,
                        AppTheme.primaryRed,
                        Icons.emergency,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showHelpRequestsListSheet,
                      child: _buildKPICard(
                        'Help Requests',
                        helpRequests,
                        AppTheme.warningOrange,
                        Icons.help,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showResolvedListSheet,
                      child: _buildKPICard(
                        'Resolved',
                        resolved,
                        AppTheme.safeGreen,
                        Icons.check_circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showUnresolvedListSheet,
                      child: _buildKPICard(
                        'Unresolved',
                        unresolved,
                        AppTheme.infoBlue,
                        Icons.pending_actions,
                      ),
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

  // Build Filter Menu Content for Popup
  Widget _buildFilterMenuContent() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryText, size: 18),
              SizedBox(width: 8),
              Text(
                'Filters & Search',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            controller: _regionSearchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppTheme.primaryText, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name, message, or region...',
              hintStyle: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.secondaryText,
                size: 18,
              ),
              suffixIcon: _regionSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _regionSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.darkBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neutralGray.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neutralGray.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.infoBlue),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Region Dropdown
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase.collection('sos_sessions').snapshots(),
            builder: (context, snapshot) {
              final regions = <String>{'all'};
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data();
                  final address =
                      data['location']?['address']?.toString() ?? '';
                  if (address.isNotEmpty) {
                    final parts = address.split(',');
                    if (parts.length > 1) {
                      final region = parts.last.trim();
                      if (region.isNotEmpty) regions.add(region);
                    }
                  }
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.safeGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedRegion,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        dropdownColor: AppTheme.darkSurface,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 12,
                        ),
                        items: regions.map((String region) {
                          return DropdownMenuItem<String>(
                            value: region,
                            child: Text(
                              region == 'all' ? 'All Regions' : region,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRegion = newValue ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.neutralGray, height: 1),
          const SizedBox(height: 12),

          // Filter Chips
          const Text(
            'Quick Filters',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('SOS', style: TextStyle(fontSize: 11)),
                selected: _toggleSOSOnly,
                selectedColor: AppTheme.criticalRed.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.criticalRed,
                onSelected: (val) {
                  setState(() {
                    _toggleSOSOnly = val;
                    if (val && _toggleHelpOnly) _toggleHelpOnly = false;
                  });
                },
              ),
              FilterChip(
                label: const Text('Help', style: TextStyle(fontSize: 11)),
                selected: _toggleHelpOnly,
                selectedColor: AppTheme.warningOrange.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.warningOrange,
                onSelected: (val) {
                  setState(() {
                    _toggleHelpOnly = val;
                    if (val && _toggleSOSOnly) _toggleSOSOnly = false;
                  });
                },
              ),
              FilterChip(
                label: const Text(
                  'High Priority',
                  style: TextStyle(fontSize: 11),
                ),
                selected: _toggleHighPriorityOnly,
                selectedColor: AppTheme.primaryRed.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.primaryRed,
                onSelected: (val) {
                  setState(() {
                    _toggleHighPriorityOnly = val;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Clear All Filters Button
          if (_toggleSOSOnly ||
              _toggleHelpOnly ||
              _toggleHighPriorityOnly ||
              _regionSearchController.text.isNotEmpty ||
              _selectedRegion != 'all')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _toggleSOSOnly = false;
                    _toggleHelpOnly = false;
                    _toggleHighPriorityOnly = false;
                    _selectedRegion = 'all';
                    _regionSearchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text(
                  'Clear All Filters',
                  style: TextStyle(fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryText,
                  side: BorderSide(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Consolidated Active Ping tab (SOS + Help)
  Widget _buildActivePingTabRealtime() {
    return Column(
      children: [
        if (!_isAvailable)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              border: Border.all(
                color: AppTheme.warningOrange.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppTheme.warningOrange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are currently unavailable for SAR. Toggle ON to receive assignments.',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('sos_sessions')
                .orderBy('startTime', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, sosSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firebase
                    .collection('help_requests')
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, helpSnap) {
                  if (sosSnap.connectionState == ConnectionState.waiting ||
                      helpSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sosDocs = sosSnap.data?.docs ?? const [];
                  final helpDocs = helpSnap.data?.docs ?? const [];

                  // Filters
                  final searchText = _regionSearchController.text.toLowerCase();

                  bool sosMatches(Map<String, dynamic> data) {
                    final status = (data['status'] ?? '').toString();
                    // Only include ACTIVE SOS states; exclude resolved
                    final active =
                        status == 'active' ||
                        status == 'acknowledged' ||
                        status == 'responder_assigned' ||
                        status == 'assigned' ||
                        status == 'en_route' ||
                        status == 'on_scene' ||
                        status == 'in_progress' ||
                        status == 'inProgress';
                    if (!active) return false;

                    // High priority filter
                    if (_toggleHighPriorityOnly) {
                      final prio = (data['priority'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (!(prio == 'high' || prio == 'critical')) return false;
                    }

                    // Region filter
                    if (_selectedRegion != 'all') {
                      final address =
                          data['location']?['address']?.toString() ?? '';
                      if (!address.toLowerCase().contains(
                        _selectedRegion.toLowerCase(),
                      )) {
                        return false;
                      }
                    }

                    // Search
                    if (searchText.isNotEmpty) {
                      final userName =
                          (data['userName'] ?? data['userId'] ?? '')
                              .toString()
                              .toLowerCase();
                      final message = (data['userMessage'] ?? '')
                          .toString()
                          .toLowerCase();
                      final address = (data['location']?['address'] ?? '')
                          .toString()
                          .toLowerCase();
                      final city = (data['location']?['city'] ?? '')
                          .toString()
                          .toLowerCase();
                      final province = (data['location']?['province'] ?? '')
                          .toString()
                          .toLowerCase();

                      if (!(userName.contains(searchText) ||
                          message.contains(searchText) ||
                          address.contains(searchText) ||
                          city.contains(searchText) ||
                          province.contains(searchText))) {
                        return false;
                      }
                    }
                    return true;
                  }

                  bool helpMatches(Map<String, dynamic> data) {
                    final status = (data['status'] ?? '').toString();
                    // Only include non-resolved help requests
                    if (status == 'resolved') return false;
                    // High priority filter
                    if (_toggleHighPriorityOnly) {
                      final prio = (data['priority'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (!(prio == 'high' || prio == 'critical')) return false;
                    }
                    if (searchText.isNotEmpty) {
                      final title =
                          (data['subCategoryId'] ?? data['categoryId'] ?? '')
                              .toString()
                              .toLowerCase();
                      final desc = (data['description'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (!(title.contains(searchText) ||
                          desc.contains(searchText))) {
                        return false;
                      }
                    }
                    return true;
                  }

                  // Determine allowed types based on quick toggles
                  bool allowSOS = true;
                  bool allowHelp = true;
                  if (_toggleSOSOnly && !_toggleHelpOnly) {
                    allowHelp = false;
                  } else if (_toggleHelpOnly && !_toggleSOSOnly) {
                    allowSOS = false;
                  }

                  // Build combined items
                  final items = <Map<String, dynamic>>[];

                  for (final d in sosDocs) {
                    final data = d.data();
                    if (!allowSOS) continue;
                    if (!sosMatches(data)) continue;
                    items.add({
                      'type': 'sos',
                      'id': d.id,
                      'data': data,
                      'status': (data['status'] ?? 'unknown').toString(),
                      'time': data['startTime'],
                    });
                  }

                  for (final d in helpDocs) {
                    final data = d.data();
                    if (!allowHelp) continue;
                    if (!helpMatches(data)) continue;
                    items.add({
                      'type': 'help',
                      'id': d.id,
                      'data': data,
                      'status': (data['status'] ?? 'active').toString(),
                      'time': data['createdAt'],
                    });
                  }

                  // Sort by time desc
                  items.sort((a, b) {
                    final ta = a['time'];
                    final tb = b['time'];
                    DateTime? da;
                    DateTime? db;
                    if (ta is Timestamp) da = ta.toDate();
                    if (tb is Timestamp) db = tb.toDate();
                    if (ta is DateTime) da = ta;
                    if (tb is DateTime) db = tb;
                    return (db ?? DateTime.fromMillisecondsSinceEpoch(0))
                        .compareTo(
                          da ?? DateTime.fromMillisecondsSinceEpoch(0),
                        );
                  });

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching active pings',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.neutralGray),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      final type = it['type'] as String;
                      final id = it['id'] as String;
                      final data = it['data'] as Map<String, dynamic>;
                      final status = it['status'] as String;

                      if (type == 'sos') {
                        final userName =
                            (data['userName'] ?? data['userId'] ?? 'Unknown')
                                .toString();
                        final message = (data['userMessage'] ?? '').toString();
                        final priority = (data['priority'] ?? 'medium')
                            .toString();
                        final startTime = data['startTime'];
                        final sessionId = id;
                        final sosType = (data['type'] ?? 'manual').toString();
                        final location =
                            data['location'] as Map<String, dynamic>?;
                        final medicalConditions =
                            (data['medicalConditions'] as List<dynamic>?)
                                ?.cast<String>() ??
                            [];
                        final allergies =
                            (data['allergies'] as List<dynamic>?)
                                ?.cast<String>() ??
                            [];
                        final bloodType = data['bloodType']?.toString();
                        final userPhone = (data['userPhone'] ?? '').toString();
                        final age = data['age']?.toString();
                        final gender = data['gender']?.toString();

                        // Parse emergency contacts list properly
                        List<Map<String, dynamic>> emergencyContactsList = [];
                        if (data['emergencyContactsList'] != null) {
                          try {
                            emergencyContactsList =
                                (data['emergencyContactsList'] as List<dynamic>)
                                    .map((e) => e as Map<String, dynamic>)
                                    .toList();
                          } catch (_) {}
                        }

                        final notes = (data['notes'] as List<dynamic>?) ?? [];

                        // Format activation cause
                        String activationCause = 'Manual SOS';
                        if (sosType == 'crash_detection') {
                          activationCause = 'Crash Detected';
                        } else if (sosType == 'fall_detection') {
                          activationCause = 'Fall Detected';
                        } else if (sosType == 'panic_button') {
                          activationCause = 'Panic Button';
                        } else if (sosType == 'voice_command') {
                          activationCause = 'Voice Command';
                        }

                        // Format timestamp - FIXED
                        String fullTimestamp = 'Unknown time';
                        if (startTime != null) {
                          try {
                            DateTime dt;
                            if (startTime is DateTime) {
                              dt = startTime;
                            } else if (startTime is Timestamp) {
                              dt = startTime.toDate();
                            } else if (startTime is String) {
                              // Handle ISO8601 string format
                              dt = DateTime.parse(startTime);
                            } else {
                              dt = DateTime.now();
                            }
                            fullTimestamp =
                                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          } catch (e) {
                            debugPrint('Error parsing timestamp: $e');
                            fullTimestamp = 'Invalid time';
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryRed.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row with user name and status
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.emergency,
                                    color: AppTheme.primaryRed,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            color: AppTheme.primaryText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Case: ${sessionId.substring(0, 12)}...',
                                          style: TextStyle(
                                            color: AppTheme.secondaryText
                                                .withValues(alpha: 0.8),
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(status: status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Activation cause chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.primaryRed.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sosType.contains('crash')
                                          ? Icons.car_crash
                                          : sosType.contains('fall')
                                          ? Icons.airline_seat_recline_extra
                                          : Icons.touch_app,
                                      size: 14,
                                      color: AppTheme.primaryRed,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      activationCause,
                                      style: const TextStyle(
                                        color: AppTheme.primaryRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Timestamp and priority
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neutralGray.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: AppTheme.secondaryText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          fullTimestamp,
                                          style: const TextStyle(
                                            color: AppTheme.secondaryText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _priorityChip(priority),
                                  if (startTime != null)
                                    _metaChip(
                                      _relativeFromTimestamp(startTime),
                                      AppTheme.secondaryText,
                                    ),
                                  // Battery level chip
                                  if (data['batteryLevel'] != null)
                                    _buildBatteryChip(
                                      data['batteryLevel'] as int,
                                      data['batteryState']?.toString(),
                                    ),
                                ],
                              ),

                              // Location
                              if (location != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutralGray.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.neutralGray.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: AppTheme.primaryRed,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (location['address'] != null)
                                                  Text(
                                                    location['address']
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.primaryText,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                if (location['latitude'] !=
                                                        null &&
                                                    location['longitude'] !=
                                                        null)
                                                  Text(
                                                    '${location['latitude']?.toStringAsFixed(6)}, ${location['longitude']?.toStringAsFixed(6)}',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .secondaryText
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      fontSize: 10,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Map button
                                          if (location['latitude'] != null &&
                                              location['longitude'] != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.map,
                                                size: 20,
                                              ),
                                              color: AppTheme.primaryRed,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                final lat =
                                                    location['latitude'];
                                                final lon =
                                                    location['longitude'];
                                                _openInMaps(lat, lon);
                                              },
                                              tooltip: 'Open in Maps',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Medical Information
                              if (medicalConditions.isNotEmpty ||
                                  allergies.isNotEmpty ||
                                  bloodType != null ||
                                  age != null ||
                                  gender != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.medical_information,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Medical Info',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (age != null || gender != null)
                                        Row(
                                          children: [
                                            if (age != null) ...[
                                              Text(
                                                'Age: $age',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryText,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (gender != null)
                                                const Text(
                                                  '  •  ',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.secondaryText,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                            if (gender != null)
                                              Text(
                                                'Gender: ${gender == 'male'
                                                    ? 'Male ♂'
                                                    : gender == 'female'
                                                    ? 'Female ♀'
                                                    : gender}',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryText,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (bloodType != null)
                                        Text(
                                          'Blood Type: $bloodType',
                                          style: const TextStyle(
                                            color: AppTheme.primaryText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (medicalConditions.isNotEmpty)
                                        Text(
                                          'Conditions: ${medicalConditions.join(', ')}',
                                          style: const TextStyle(
                                            color: AppTheme.primaryText,
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (allergies.isNotEmpty)
                                        Text(
                                          'Allergies: ${allergies.join(', ')}',
                                          style: const TextStyle(
                                            color: AppTheme.primaryText,
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              // Contact Information
                              if (userPhone.isNotEmpty ||
                                  emergencyContactsList.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoBlue.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.infoBlue.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.contacts,
                                            size: 16,
                                            color: AppTheme.infoBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Contact Information',
                                            style: TextStyle(
                                              color: AppTheme.infoBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (userPhone.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const SizedBox(width: 22),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'User Phone Number',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .secondaryText,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    userPhone,
                                                    style: const TextStyle(
                                                      color: AppTheme.infoBlue,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.call,
                                                size: 18,
                                              ),
                                              color: AppTheme.infoBlue,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                _makePhoneCall(userPhone);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Show family emergency contacts with proper names and numbers
                                      // Filter out emergency services (000, 911, etc.) - only show family/friend contacts
                                      if (emergencyContactsList.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...emergencyContactsList
                                            .where((contact) {
                                              final type =
                                                  contact['type']?.toString() ??
                                                  '';
                                              // Exclude emergency services contacts
                                              return type !=
                                                  'emergencyServices';
                                            })
                                            .take(2)
                                            .map((contact) {
                                              final name =
                                                  contact['name']?.toString() ??
                                                  'Unknown';
                                              final phone =
                                                  contact['phone']
                                                      ?.toString() ??
                                                  'N/A';
                                              final relationship =
                                                  contact['relationship']
                                                      ?.toString() ??
                                                  'Emergency Contact';

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 22),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '$relationship - $name',
                                                            style: const TextStyle(
                                                              color: AppTheme
                                                                  .secondaryText,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            phone,
                                                            style:
                                                                const TextStyle(
                                                                  color: AppTheme
                                                                      .infoBlue,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.call,
                                                        size: 18,
                                                      ),
                                                      color: AppTheme.infoBlue,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () {
                                                        _makePhoneCall(phone);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                        if (emergencyContactsList
                                                .where(
                                                  (c) =>
                                                      c['type']?.toString() !=
                                                      'emergencyServices',
                                                )
                                                .length >
                                            2)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 22,
                                              top: 4,
                                            ),
                                            child: Text(
                                              '+${emergencyContactsList.where((c) => c['type']?.toString() != 'emergencyServices').length - 2} more contact(s)',
                                              style: TextStyle(
                                                color: AppTheme.secondaryText
                                                    .withValues(alpha: 0.7),
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // User message
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutralGray.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      color: AppTheme.secondaryText,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],

                              // SAR Notes
                              if (notes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningOrange.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.warningOrange.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.note_alt,
                                            size: 16,
                                            color: AppTheme.warningOrange,
                                          ),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'SAR Operation Notes',
                                              style: TextStyle(
                                                color: AppTheme.warningOrange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            color: AppTheme.warningOrange,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                _showAddNoteDialog(id),
                                            tooltip: 'Add Note',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...notes.map((note) {
                                        final noteData =
                                            note as Map<String, dynamic>;
                                        final noteText =
                                            (noteData['text'] ?? '').toString();
                                        final timestamp = noteData['timestamp'];
                                        final author =
                                            (noteData['author'] ?? 'SAR Team')
                                                .toString();

                                        String timeStr = '';
                                        if (timestamp != null) {
                                          try {
                                            DateTime dt;
                                            if (timestamp is DateTime) {
                                              dt = timestamp;
                                            } else if (timestamp is Timestamp) {
                                              dt = timestamp.toDate();
                                            } else if (timestamp is String) {
                                              // Handle ISO8601 string format
                                              dt = DateTime.parse(timestamp);
                                            } else {
                                              dt = DateTime.now();
                                            }
                                            timeStr =
                                                '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                          } catch (_) {
                                            timeStr = 'Just now';
                                          }
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.darkSurface,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    author,
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.primaryText,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (timeStr.isNotEmpty) ...[
                                                    const Text(
                                                      '  •  ',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .secondaryText,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    Text(
                                                      timeStr,
                                                      style: const TextStyle(
                                                        color: AppTheme
                                                            .secondaryText,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                noteText,
                                                style: const TextStyle(
                                                  color: AppTheme.secondaryText,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],

                              // Add Note Button (if no notes yet)
                              if (notes.isEmpty) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _showAddNoteDialog(id),
                                  icon: const Icon(Icons.note_add, size: 18),
                                  label: const Text('Add Operation Note'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.warningOrange,
                                    side: const BorderSide(
                                      color: AppTheme.warningOrange,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              _buildInlineActionButtons(id, status, data),
                            ],
                          ),
                        );
                      } else {
                        // help item
                        final title =
                            (data['subCategoryId'] ??
                                    data['categoryId'] ??
                                    'Help')
                                .toString();
                        final desc = (data['description'] ?? '').toString();
                        final priority = (data['priority'] ?? 'low').toString();
                        final createdAt = data['createdAt'];
                        return InkWell(
                          onTap: () => _showHelpActionsSheet(id, data),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
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
                                    _priorityDot(priority),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          Text(
                                            desc.isEmpty
                                                ? 'No description'
                                                : desc,
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
                                    StatusChip(status: status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _priorityChip(priority),
                                    _metaChip(
                                      (data['categoryId'] ?? 'General')
                                          .toString(),
                                      AppTheme.secondaryText,
                                    ),
                                    if (createdAt != null)
                                      _metaChip(
                                        _relativeFromTimestamp(createdAt),
                                        AppTheme.secondaryText,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildHelpInlineActionButtons(id, status, data),
                              ],
                            ),
                          ),
                        );
                      }
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

  // Inline action buttons for Help Requests
  Widget _buildHelpInlineActionButtons(
    String requestId,
    String status,
    Map<String, dynamic> data,
  ) {
    if (status == 'resolved') return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (status == 'active' || status == 'assigned')
          _actionButton(
            'Start Handling',
            Icons.play_arrow,
            AppTheme.infoBlue,
            () async {
              await _updateHelpStatus(requestId, 'inProgress');
            },
          ),
        _actionButton(
          'Resolve',
          Icons.check_circle,
          AppTheme.safeGreen,
          () async {
            await _updateHelpStatus(requestId, 'resolved');
          },
        ),
      ],
    );
  }

  Future<void> _updateHelpStatus(String requestId, String newStatus) async {
    try {
      await _firebase.collection('help_requests').doc(requestId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Help request updated to $newStatus'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating help request: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  Widget _buildKPICard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          // Count
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // KPI bottom sheet header
  Widget _kpiSheetHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neutralGray.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.secondaryText),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // Show list of active SOS sessions
  void _showActiveSOSListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                _kpiSheetHeader('Active SOS'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebase
                        .collection('sos_sessions')
                        .orderBy('startTime', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs.where((d) {
                        final s = (d.data()['status'] ?? '').toString();
                        return s == 'active' ||
                            s == 'acknowledged' ||
                            s == 'responder_assigned' ||
                            s == 'assigned' ||
                            s == 'en_route' ||
                            s == 'on_scene' ||
                            s == 'in_progress' ||
                            s == 'inProgress';
                      }).toList();
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active SOS cases',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final data = docs[i].data();
                          final id = docs[i].id;
                          final status = (data['status'] ?? 'unknown')
                              .toString();
                          final userName =
                              (data['userName'] ?? data['userId'] ?? 'Unknown')
                                  .toString();
                          final message = (data['userMessage'] ?? '')
                              .toString();
                          final priority = (data['priority'] ?? 'medium')
                              .toString();
                          final startTime = data['startTime'];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Scroll to item in main list if needed
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('SOS Session: $id'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: AppTheme.infoBlue,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryRed.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryRed
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.emergency,
                                            color: AppTheme.primaryRed,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  color: AppTheme.primaryText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              if (message.isNotEmpty)
                                                Text(
                                                  message,
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.secondaryText,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusChip(status: status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _priorityChip(priority),
                                        if (startTime != null)
                                          _metaChip(
                                            _relativeFromTimestamp(startTime),
                                            AppTheme.secondaryText,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInlineActionButtons(id, status, data),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show list of non-resolved help requests
  void _showHelpRequestsListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                _kpiSheetHeader('Help Requests'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebase
                        .collection('help_requests')
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs.where((d) {
                        final s = (d.data()['status'] ?? '').toString();
                        return s != 'resolved';
                      }).toList();
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active help requests',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final data = docs[i].data();
                          final id = docs[i].id;
                          final status = (data['status'] ?? 'active')
                              .toString();
                          final title =
                              (data['subCategoryId'] ??
                                      data['categoryId'] ??
                                      'Help')
                                  .toString();
                          final desc = (data['description'] ?? '').toString();
                          final priority = (data['priority'] ?? 'low')
                              .toString();
                          final createdAt = data['createdAt'];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Help Request: $id'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: AppTheme.warningOrange,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.warningOrange.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warningOrange
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.help,
                                            color: AppTheme.warningOrange,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  color: AppTheme.primaryText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                desc.isEmpty
                                                    ? 'No description'
                                                    : desc,
                                                style: const TextStyle(
                                                  color: AppTheme.secondaryText,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusChip(status: status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _priorityChip(priority),
                                        if (createdAt != null)
                                          _metaChip(
                                            _relativeFromTimestamp(createdAt),
                                            AppTheme.secondaryText,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildHelpInlineActionButtons(
                                      id,
                                      status,
                                      data,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show list of resolved items (SOS + Help)
  Future<void> _showResolvedListSheet() async {
    try {
      final sosSnap = await _firebase
          .collection('sos_sessions')
          .where('status', isEqualTo: 'resolved')
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .get();
      final helpSnap = await _firebase
          .collection('help_requests')
          .where('status', isEqualTo: 'resolved')
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .get();

      final items = <Map<String, dynamic>>[];
      for (final d in sosSnap.docs) {
        items.add({
          'type': 'sos',
          'id': d.id,
          'data': d.data(),
          'time': d.data()['resolvedAt'] ?? d.data()['updatedAt'],
        });
      }
      for (final d in helpSnap.docs) {
        items.add({
          'type': 'help',
          'id': d.id,
          'data': d.data(),
          'time': d.data()['updatedAt'],
        });
      }
      items.sort((a, b) {
        DateTime? da;
        DateTime? db;
        final ta = a['time'];
        final tb = b['time'];
        if (ta is Timestamp) da = ta.toDate();
        if (tb is Timestamp) db = tb.toDate();
        if (ta is DateTime) da = ta;
        if (tb is DateTime) db = tb;
        return (db ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          da ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.darkSurface,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  _kpiSheetHeader('Resolved'),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'No resolved items',
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppTheme.neutralGray,
                            ),
                            itemBuilder: (context, i) {
                              final it = items[i];
                              final type = it['type'] as String;
                              final data = it['data'] as Map<String, dynamic>;
                              if (type == 'sos') {
                                final userName =
                                    (data['userName'] ??
                                            data['userId'] ??
                                            'Unknown')
                                        .toString();
                                final message = (data['userMessage'] ?? '')
                                    .toString();
                                return ListTile(
                                  leading: const Icon(
                                    Icons.emergency,
                                    color: AppTheme.safeGreen,
                                  ),
                                  title: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    message.isEmpty ? 'Resolved SOS' : message,
                                    style: const TextStyle(
                                      color: AppTheme.secondaryText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const StatusChip(
                                    status: 'resolved',
                                  ),
                                );
                              } else {
                                final title =
                                    (data['subCategoryId'] ??
                                            data['categoryId'] ??
                                            'Help')
                                        .toString();
                                final desc = (data['description'] ?? '')
                                    .toString();
                                return ListTile(
                                  leading: const Icon(
                                    Icons.help,
                                    color: AppTheme.safeGreen,
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    desc.isEmpty ? 'Resolved request' : desc,
                                    style: const TextStyle(
                                      color: AppTheme.secondaryText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const StatusChip(
                                    status: 'resolved',
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading resolved items: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    }
  }

  // Show list of unresolved items (Active SOS + non-resolved Help)
  Future<void> _showUnresolvedListSheet() async {
    try {
      final sosSnap = await _firebase
          .collection('sos_sessions')
          .orderBy('startTime', descending: true)
          .limit(200)
          .get();
      final helpSnap = await _firebase
          .collection('help_requests')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final items = <Map<String, dynamic>>[];
      for (final d in sosSnap.docs) {
        final s = (d.data()['status'] ?? '').toString();
        final active =
            s == 'active' ||
            s == 'acknowledged' ||
            s == 'responder_assigned' ||
            s == 'assigned' ||
            s == 'en_route' ||
            s == 'on_scene' ||
            s == 'in_progress' ||
            s == 'inProgress';
        if (!active) continue;
        items.add({
          'type': 'sos',
          'id': d.id,
          'data': d.data(),
          'status': s,
          'time': d.data()['startTime'],
        });
      }
      for (final d in helpSnap.docs) {
        final s = (d.data()['status'] ?? '').toString();
        if (s == 'resolved') continue;
        items.add({
          'type': 'help',
          'id': d.id,
          'data': d.data(),
          'status': s,
          'time': d.data()['createdAt'],
        });
      }
      items.sort((a, b) {
        DateTime? da;
        DateTime? db;
        final ta = a['time'];
        final tb = b['time'];
        if (ta is Timestamp) da = ta.toDate();
        if (tb is Timestamp) db = tb.toDate();
        if (ta is DateTime) da = ta;
        if (tb is DateTime) db = tb;
        return (db ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          da ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.darkSurface,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  _kpiSheetHeader('Unresolved'),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'No unresolved items',
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppTheme.neutralGray,
                            ),
                            itemBuilder: (context, i) {
                              final it = items[i];
                              final type = it['type'] as String;
                              final id = it['id'] as String;
                              final data = it['data'] as Map<String, dynamic>;
                              final status = it['status'] as String;
                              if (type == 'sos') {
                                final userName =
                                    (data['userName'] ??
                                            data['userId'] ??
                                            'Unknown')
                                        .toString();
                                final message = (data['userMessage'] ?? '')
                                    .toString();
                                final priority = (data['priority'] ?? 'medium')
                                    .toString();
                                final startTime = data['startTime'];
                                return Container(
                                  padding: const EdgeInsets.all(12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.emergency,
                                            color: AppTheme.primaryRed,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                if (message.isNotEmpty)
                                                  Text(
                                                    message,
                                                    style: const TextStyle(
                                                      color: AppTheme
                                                          .secondaryText,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusChip(status: status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _priorityChip(priority),
                                          if (startTime != null)
                                            _metaChip(
                                              _relativeFromTimestamp(startTime),
                                              AppTheme.secondaryText,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInlineActionButtons(
                                        id,
                                        status,
                                        data,
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                final title =
                                    (data['subCategoryId'] ??
                                            data['categoryId'] ??
                                            'Help')
                                        .toString();
                                final desc = (data['description'] ?? '')
                                    .toString();
                                final priority = (data['priority'] ?? 'low')
                                    .toString();
                                final createdAt = data['createdAt'];
                                return Container(
                                  padding: const EdgeInsets.all(12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _priorityDot(priority),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc.isEmpty
                                                      ? 'No description'
                                                      : desc,
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.secondaryText,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusChip(status: status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _priorityChip(priority),
                                          _metaChip(
                                            (data['categoryId'] ?? 'General')
                                                .toString(),
                                            AppTheme.secondaryText,
                                          ),
                                          if (createdAt != null)
                                            _metaChip(
                                              _relativeFromTimestamp(createdAt),
                                              AppTheme.secondaryText,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildHelpInlineActionButtons(
                                        id,
                                        status,
                                        data,
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading unresolved items: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    }
  }

  // NEW: Inline Action Buttons with Sequential Workflow
  Widget _buildInlineActionButtons(
    String sessionId,
    String status,
    Map<String, dynamic> data,
  ) {
    if (status == 'resolved') {
      return const SizedBox.shrink();
    }

    // 🔒 SUBSCRIPTION GATE: SAR Dashboard write access requires Pro or above
    if (!_featureAccessService.hasFeatureAccess('sarDashboardWrite')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => _showSARUpgradeDialog(),
          icon: const Icon(Icons.lock, size: 16, color: AppTheme.warningOrange),
          label: const Text(
            'Upgrade to Pro to Respond',
            style: TextStyle(fontSize: 12, color: AppTheme.warningOrange),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.warningOrange, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Acknowledge button - enabled only if active
        if (status == 'active')
          _actionButton(
            'Acknowledge',
            Icons.check,
            AppTheme.infoBlue,
            () => _updateSOSStatus(sessionId, 'acknowledged'),
          )
        else if (status != 'acknowledged' &&
            status != 'assigned' &&
            status != 'en_route' &&
            status != 'on_scene')
          _disabledButton('Acknowledge', Icons.check, 'Already acknowledged'),

        // Assign button - enabled only if acknowledged
        if (status == 'acknowledged')
          _actionButton(
            'Assign',
            Icons.person_add,
            AppTheme.warningOrange,
            () => _showAssignDialog(sessionId, data),
          )
        else if (status != 'assigned' &&
            status != 'en_route' &&
            status != 'on_scene')
          _disabledButton('Assign', Icons.person_add, 'Acknowledge first'),

        // En Route button - enabled only if assigned
        if (status == 'assigned')
          _actionButton(
            'En Route',
            Icons.directions_car,
            AppTheme.infoBlue,
            () => _updateSOSStatus(sessionId, 'en_route'),
          )
        else if (status != 'en_route' && status != 'on_scene')
          _disabledButton('En Route', Icons.directions_car, 'Assign first'),

        // On Scene button - enabled only if en_route
        if (status == 'en_route')
          _actionButton(
            'On Scene',
            Icons.place,
            AppTheme.warningOrange,
            () => _updateSOSStatus(sessionId, 'on_scene'),
          )
        else if (status != 'on_scene')
          _disabledButton('On Scene', Icons.place, 'Team must be en route'),

        // Resolve button - always available for any non-resolved status
        _actionButton(
          'Resolve',
          Icons.check_circle,
          AppTheme.safeGreen,
          () => _showResolveDialog(sessionId),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _disabledButton(String label, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(
          icon,
          size: 14,
          color: AppTheme.secondaryText.withValues(alpha: 0.5),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryText.withValues(alpha: 0.5),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.secondaryText.withValues(alpha: 0.3),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // NEW: Update SOS Status in Firestore
  Future<void> _updateSOSStatus(String sessionId, String newStatus) async {
    try {
      final user = _firebaseService.currentUser;
      final isDeveloper = user?.email == _developerEmail;

      if (isDeveloper) {
        debugPrint(
          '🔓 Developer exemption: Allowing status update for ${user?.email}',
        );
      }

      await _firebase.collection('sos_sessions').doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid,
        'developerUpdate': isDeveloper, // Track developer updates
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeveloper
                  ? '🔓 Developer: Status updated to $newStatus'
                  : 'Status updated to $newStatus',
            ),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  // NEW: Show Assign Dialog
  Future<void> _showAssignDialog(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    final responderController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Responder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responderController,
              decoration: const InputDecoration(
                labelText: 'Responder Name/Team',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Assignment Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responderController.text.trim().isEmpty) return;
              await _firebase.collection('sos_sessions').doc(sessionId).update({
                'status': 'assigned',
                'assignedResponder': responderController.text.trim(),
                'assignmentNotes': notesController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // NEW: Show Resolve Dialog
  Future<void> _showResolveDialog(String sessionId) async {
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve SOS Session'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Resolution Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeGreen,
            ),
            onPressed: () async {
              await _firebase.collection('sos_sessions').doc(sessionId).update({
                'status': 'resolved',
                'resolutionNotes': notesController.text.trim(),
                'resolvedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  // NEW: Show Add Note Dialog
  Future<void> _showAddNoteDialog(String sessionId) async {
    final noteController = TextEditingController();
    final user = _firebaseService.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Must be logged in to add notes'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Operation Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
                hintText: 'Enter operational note...',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            const Text(
              'This note will be visible to all SAR team members.',
              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            onPressed: () async {
              final noteText = noteController.text.trim();
              if (noteText.isEmpty) return;

              try {
                // Create new note with current timestamp
                final newNote = {
                  'text': noteText,
                  'author': user.email ?? user.uid,
                  'timestamp': DateTime.now().toUtc().toIso8601String(),
                };

                // Use arrayUnion to add the note atomically
                await _firebase
                    .collection('sos_sessions')
                    .doc(sessionId)
                    .update({
                      'notes': FieldValue.arrayUnion([newNote]),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note added successfully'),
                      backgroundColor: AppTheme.safeGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding note: $e'),
                      backgroundColor: AppTheme.criticalRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  // Removed: _buildHelpRequestsTabRealtime (merged into Active Ping)

  Widget _buildAssignmentsTabRealtime() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Sign in to see assignments',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firebase
          .collection('help_responses')
          .where('responderId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No assignments yet',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.neutralGray),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final reqId = (data['requestId'] ?? '').toString();
            final msg = (data['message'] ?? '').toString();
            final accepted = (data['isAccepted'] ?? false) == true;
            return ListTile(
              leading: Icon(
                accepted ? Icons.task_alt : Icons.pending_actions,
                color: accepted ? AppTheme.safeGreen : AppTheme.warningOrange,
              ),
              title: Text(
                'Help Response for $reqId',
                style: const TextStyle(color: AppTheme.primaryText),
              ),
              subtitle: Text(
                msg.isEmpty ? 'No message' : msg,
                style: const TextStyle(color: AppTheme.secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                accepted ? 'ACCEPTED' : 'PENDING',
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showHelpActionsSheet(
    String id,
    Map<String, dynamic> data,
  ) async {
    final level = await _featureAccessService.getSARAccessLevel();
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
    if (!mounted) return;
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
              if (level != SARAccessLevel.none && status == 'active')
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
                            'status': 'inProgress',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    } catch (e) {
                      debugPrint('Start handling failed: $e');
                    }
                  },
                ),
              if (level != SARAccessLevel.none && status != 'resolved')
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
            ],
          ),
        );
      },
    );
  }

  Widget _priorityDot(String priority) {
    Color c;
    switch (priority) {
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

  // UI helpers for chips and timestamps
  // Removed: legacy _statusChip in favor of shared StatusChip widget

  Widget _priorityChip(String priority) {
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
    return _metaChip('PRIORITY: ${priority.toUpperCase()}', c);
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

  Widget _buildBatteryChip(int batteryLevel, String? batteryState) {
    // Determine battery color based on level
    Color batteryColor;
    IconData batteryIcon;

    if (batteryLevel <= 10) {
      batteryColor = AppTheme.criticalRed;
      batteryIcon = Icons.battery_0_bar;
    } else if (batteryLevel <= 20) {
      batteryColor = AppTheme.warningOrange;
      batteryIcon = Icons.battery_1_bar;
    } else if (batteryLevel <= 40) {
      batteryColor = AppTheme.warningOrange.withValues(alpha: 0.8);
      batteryIcon = Icons.battery_3_bar;
    } else if (batteryLevel <= 60) {
      batteryColor = AppTheme.infoBlue;
      batteryIcon = Icons.battery_4_bar;
    } else if (batteryLevel <= 80) {
      batteryColor = AppTheme.safeGreen;
      batteryIcon = Icons.battery_5_bar;
    } else {
      batteryColor = AppTheme.safeGreen;
      batteryIcon = Icons.battery_full;
    }

    // Check if charging
    final isCharging =
        batteryState?.toLowerCase().contains('charging') ?? false;
    if (isCharging) {
      batteryIcon = Icons.battery_charging_full;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: batteryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: batteryColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(batteryIcon, size: 12, color: batteryColor),
          const SizedBox(width: 4),
          Text(
            '$batteryLevel%',
            style: TextStyle(
              color: batteryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeFromTimestamp(dynamic ts) {
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (ts is DateTime) dt = ts;
    if (dt == null) return '';
    return _formatTimestamp(dt);
  }

  // Open location in maps
  void _openInMaps(double latitude, double longitude) async {
    try {
      final url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      // Use url_launcher package
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps'),
              backgroundColor: AppTheme.criticalRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  // Make phone call
  void _makePhoneCall(String phoneNumber) async {
    try {
      final url = 'tel:$phoneNumber';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not initiate call'),
              backgroundColor: AppTheme.criticalRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  // Removed legacy local-tab builders in favor of Firestore-backed real-time tabs

  Widget _buildMessagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: AppTheme.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Messages',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Messages from SAR operations will appear here',
            style: TextStyle(color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  // Removed legacy helpers

  // Removed development helpers and legacy mission UI helpers no longer used
}
