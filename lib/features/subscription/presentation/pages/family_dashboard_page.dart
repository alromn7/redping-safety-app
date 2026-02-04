import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app/app_launch_config.dart';
import '../../../../models/auth_user.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/check_in_service.dart';
import '../../../../services/firebase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/family_member_card.dart';
import '../widgets/family_stats_widget.dart';

class FamilyDashboardPage extends StatefulWidget {
  const FamilyDashboardPage({super.key});

  @override
  State<FamilyDashboardPage> createState() => _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends State<FamilyDashboardPage>
    with TickerProviderStateMixin {
  late final SubscriptionService _subscriptionService;
  late final TabController _tabController;

  FamilySubscription? _familySubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService.instance;
    _tabController = TabController(length: 3, vsync: this);
    _initializeFamilyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeFamilyData() async {
    try {
      await _subscriptionService.initialize();

      setState(() {
        _familySubscription = _subscriptionService.currentFamily;
        _isLoading = false;
      });

      // Listen for family updates
      _subscriptionService.familyStream.listen((family) {
        if (mounted) {
          setState(() => _familySubscription = family);
        }
      });
    } catch (e) {
      debugPrint('FamilyDashboardPage: Error initializing - $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFamilyMember() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildAddMemberDialog(),
    );

    if (result != null && _familySubscription != null) {
      try {
        await _subscriptionService.addFamilyMember(
          familyId: _familySubscription!.id,
          userId: result['userId'],
          name: result['name'],
          assignedTier: result['tier'],
          email: result['email'],
          relationship: result['relationship'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Family member added successfully!'),
              backgroundColor: AppTheme.safeGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding family member: $e'),
              backgroundColor: AppTheme.criticalRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildAddMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();
    SubscriptionTier selectedTier = SubscriptionTier.essentialPlus;

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Family Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Child, Parent, Spouse',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionTier>(
                initialValue: selectedTier,
                decoration: const InputDecoration(
                  labelText: 'Assigned Plan',
                  border: OutlineInputBorder(),
                ),
                items: [
                  if (_familySubscription?.hasAvailableSlots(
                        SubscriptionTier.essentialPlus,
                      ) ==
                      true)
                    const DropdownMenuItem(
                      value: SubscriptionTier.essentialPlus,
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: AppTheme.safeGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Essential'),
                        ],
                      ),
                    ),
                  if (_familySubscription?.hasAvailableSlots(
                        SubscriptionTier.pro,
                      ) ==
                      true)
                    const DropdownMenuItem(
                      value: SubscriptionTier.pro,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: AppTheme.infoBlue, size: 20),
                          SizedBox(width: 8),
                          Text('Pro'),
                        ],
                      ),
                    ),
                ],
                onChanged: (tier) {
                  if (tier != null) {
                    setState(() => selectedTier = tier);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: nameController.text.isNotEmpty
                ? () {
                    Navigator.pop(context, {
                      'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameController.text,
                      'email': emailController.text.isNotEmpty
                          ? emailController.text
                          : null,
                      'relationship': relationshipController.text.isNotEmpty
                          ? relationshipController.text
                          : null,
                      'tier': selectedTier,
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_familySubscription == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                    context.go(AppLaunchConfig.homeRoute);
              }
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Family Subscription Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Create a family subscription to manage family safety.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_familySubscription!.familyName ?? 'Family Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
                  context.go(AppLaunchConfig.homeRoute);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to family settings
              context.push('/subscription/family-settings');
            },
            tooltip: 'Family Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.location_on), text: 'Locations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildLocationsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Show action sheet for multiple actions (add member & check-in ping)
          final action = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            backgroundColor: AppTheme.darkSurface,
            builder: (ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_add,
                        color: AppTheme.safeGreen,
                      ),
                      title: const Text('Add Family Member'),
                      onTap: () => Navigator.pop(ctx, 'add'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.location_searching,
                        color: AppTheme.infoBlue,
                      ),
                      title: const Text('Send Check-In Ping'),
                      subtitle: const Text(
                        'Request a one-time location snapshot',
                      ),
                      onTap: () => Navigator.pop(ctx, 'checkin'),
                    ),
                  ],
                ),
              );
            },
          );
          if (action == 'add') {
            await _addFamilyMember();
          } else if (action == 'checkin') {
            await _startCheckInPingFlow();
          }
        },
        backgroundColor: AppTheme.warningOrange,
        icon: const Icon(Icons.add),
        label: const Text('Actions'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family stats
          FamilyStatsWidget(family: _familySubscription!),
          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Family Portal Messaging',
                  Icons.public,
                  AppTheme.infoBlue,
                  () => _showWebOnlyMessage('Family portal messaging'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Emergency Contacts',
                  Icons.contact_emergency,
                  AppTheme.criticalRed,
                  () => context.push('/emergency-contacts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Family Activities',
                  Icons.hiking,
                  AppTheme.safeGreen,
                  () => context.push('/activities'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'SAR Coordination',
                  Icons.search,
                  AppTheme.warningOrange,
                  () => context.push('/sar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available slots
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Slots',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSlotIndicator(
                          'Essential',
                          _familySubscription!
                              .getMembersByTier(SubscriptionTier.essentialPlus)
                              .length,
                          _familySubscription!.plan.essentialAccounts ?? 0,
                          AppTheme.safeGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSlotIndicator(
                          'Pro',
                          _familySubscription!
                              .getMembersByTier(SubscriptionTier.pro)
                              .length,
                          _familySubscription!.plan.proAccounts ?? 0,
                          AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Family members
          const Text(
            'Family Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_familySubscription!.members.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No family members added yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add family members',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._familySubscription!.members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FamilyMemberCard(
                  member: member,
                  onRemove: () => _removeFamilyMember(member.id),
                  onEdit: () => _editFamilyMember(member),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'Family Location Sharing',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Location Sharing'),
                    subtitle: const Text(
                      'Allow family members to see each other\'s locations',
                    ),
                    value:
                        _familySubscription?.settings.allowLocationSharing ??
                        false,
                    onChanged: (value) {
                      _updateFamilySettings(
                        _familySubscription!.settings.copyWith(
                          allowLocationSharing: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Family member locations (placeholder)
          if (_familySubscription?.settings.allowLocationSharing == true) ...[
            const Text(
              'Family Member Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Family Location Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Real-time family member locations would appear here',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotIndicator(String title, int used, int total, Color color) {
    final percentage = total > 0 ? used / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              '$used/$total',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWebOnlyMessage(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName is not available in-app in this build.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _removeFamilyMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: const Text(
          'Are you sure you want to remove this family member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _subscriptionService.removeFamilyMember(memberId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Family member removed'),
              backgroundColor: AppTheme.warningOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing family member: $e'),
              backgroundColor: AppTheme.criticalRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _editFamilyMember(FamilyMember member) async {
    // Placeholder for edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit member functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateFamilySettings(FamilySettings settings) async {
    try {
      await _subscriptionService.updateFamilySettings(settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: $e'),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startCheckInPingFlow() async {
    if (_familySubscription == null || _familySubscription!.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No family members available for check-in'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final targetMemberId = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send Check-In Ping'),
          content: SizedBox(
            width: 320,
            child: ListView(
              shrinkWrap: true,
              children: _familySubscription!.members.map((m) {
                return ListTile(
                  leading: const Icon(Icons.person_pin_circle),
                  title: Text(m.name),
                  subtitle: Text(m.relationship ?? 'Member'),
                  onTap: () => Navigator.pop(ctx, m.id),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (targetMemberId == null) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optional Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'e.g. Pickup confirmation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    final currentUser = FirebaseService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not authenticated'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.criticalRed,
        ),
      );
      return;
    }

    try {
      await CheckInService.instance.createRequest(
        familyId: _familySubscription!.id,
        requesterUserId: currentUser.uid,
        targetUserId: targetMemberId,
        reason: (reason != null && reason.isNotEmpty) ? reason : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-In Ping sent (expires in 7 days)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending check-in ping: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }
}
