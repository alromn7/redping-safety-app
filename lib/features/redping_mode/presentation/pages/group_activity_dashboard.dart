import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/group_activity.dart';
import '../../../../services/group_activity_service.dart';
import '../widgets/group_member_card.dart';
import '../widgets/rally_point_card.dart';
import '../widgets/buddy_pair_card.dart';

/// Dashboard for managing group activities
class GroupActivityDashboard extends StatefulWidget {
  const GroupActivityDashboard({super.key});

  @override
  State<GroupActivityDashboard> createState() => _GroupActivityDashboardState();
}

class _GroupActivityDashboardState extends State<GroupActivityDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupActivityService _service = GroupActivityService.instance;

  GroupActivitySession? _session;
  List<GroupMember> _members = [];
  StreamSubscription<GroupActivitySession?>? _sessionSubscription;
  StreamSubscription<List<GroupMember>>? _membersSubscription;
  StreamSubscription<GroupAlert>? _alertSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    _session = _service.activeSession;

    _sessionSubscription = _service.sessionStream.listen((session) {
      if (mounted) {
        setState(() {
          _session = session;
        });
      }
    });

    _membersSubscription = _service.membersStream.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    });

    _alertSubscription = _service.alertStream.listen((alert) {
      if (mounted) {
        _showAlert(alert);
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  void _showAlert(GroupAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.type) {
      case GroupAlertType.buddySeparation:
        alertColor = Colors.orange;
        alertIcon = Icons.warning_amber;
        break;
      case GroupAlertType.emergencyAlert:
        alertColor = Colors.red;
        alertIcon = Icons.emergency;
        break;
      case GroupAlertType.lowBattery:
        alertColor = Colors.orange;
        alertIcon = Icons.battery_alert;
        break;
      case GroupAlertType.memberOffline:
        alertColor = Colors.grey;
        alertIcon = Icons.person_off;
        break;
      case GroupAlertType.rallyPointCheckIn:
        alertColor = Colors.green;
        alertIcon = Icons.check_circle;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(alertIcon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(alert.message)),
          ],
        ),
        backgroundColor: alertColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionSubscription?.cancel();
    _membersSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.groupName ?? 'Group Activity'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.group), text: 'Members'),
            Tab(icon: Icon(Icons.location_on), text: 'Rally Points'),
            Tab(icon: Icon(Icons.people), text: 'Buddies'),
          ],
        ),
        actions: [
          if (_session != null && _session!.isActive)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'End Session',
              onPressed: _confirmEndSession,
            ),
        ],
      ),
      body: _session == null
          ? _buildNoSessionView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMembersTab(),
                _buildRallyPointsTab(),
                _buildBuddiesTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNoSessionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Active Group Session',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Create a new group activity to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _showCreateSessionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Group Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_session == null) return const SizedBox();

    final onlineCount = _session!.onlineMembersCount;
    final checkedInCount = _session!.checkedInMembersCount;
    final totalMembers = _session!.currentMembers.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Session Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getActivityIcon(_session!.activityType),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _session!.groupName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _formatActivityType(_session!.activityType),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (_session!.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_session!.description != null) ...[
                  const SizedBox(height: 12),
                  Text(_session!.description!),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${_formatDuration(_session!.duration)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Members',
              '$totalMembers / ${_session!.maxMembers}',
              Icons.group,
              Colors.blue,
            ),
            _buildStatCard(
              'Online Now',
              '$onlineCount',
              Icons.person,
              Colors.green,
            ),
            _buildStatCard(
              'Checked In',
              '$checkedInCount',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatCard(
              'Rally Points',
              '${_session!.rallyPoints.length}',
              Icons.location_on,
              Colors.red,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quick Actions
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Member'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAddMemberDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Create Rally Point'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCreateRallyPointDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Pair Buddies'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCreateBuddyPairDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Sort: leader first, then co-leaders, then members
    final sortedMembers = [..._members]
      ..sort((a, b) {
        if (a.role == b.role) return 0;
        if (a.role == GroupMemberRole.leader) return -1;
        if (b.role == GroupMemberRole.leader) return 1;
        if (a.role == GroupMemberRole.coLeader) return -1;
        return 1;
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        return GroupMemberCard(
          member: sortedMembers[index],
          session: _session!,
          onRemove: () => _confirmRemoveMember(sortedMembers[index]),
        );
      },
    );
  }

  Widget _buildRallyPointsTab() {
    final rallyPoints = _session?.rallyPoints ?? [];

    if (rallyPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No rally points yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateRallyPointDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Rally Point'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rallyPoints.length,
      itemBuilder: (context, index) {
        return RallyPointCard(
          rallyPoint: rallyPoints[index],
          session: _session!,
          onCheckIn: (rallyPointId, memberId) async {
            await _service.checkIntoRallyPoint(
              rallyPointId: rallyPointId,
              memberId: memberId,
            );
          },
        );
      },
    );
  }

  Widget _buildBuddiesTab() {
    final buddyPairs = _session?.buddyPairs ?? [];

    if (buddyPairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No buddy pairs yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateBuddyPairDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Buddy Pair'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: buddyPairs.length,
      itemBuilder: (context, index) {
        return BuddyPairCard(pair: buddyPairs[index], members: _members);
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_session == null) return null;

    switch (_tabController.index) {
      case 1: // Members tab
        return FloatingActionButton.extended(
          onPressed: _showAddMemberDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Member'),
        );
      case 2: // Rally Points tab
        return FloatingActionButton.extended(
          onPressed: _showCreateRallyPointDialog,
          icon: const Icon(Icons.add_location),
          label: const Text('Rally Point'),
        );
      case 3: // Buddies tab
        return FloatingActionButton.extended(
          onPressed: _showCreateBuddyPairDialog,
          icon: const Icon(Icons.people),
          label: const Text('Pair Buddies'),
        );
      default:
        return null;
    }
  }

  void _showCreateSessionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    GroupActivityType selectedType = GroupActivityType.hiking;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g., Weekend Hike',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of the activity',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) =>
                    DropdownButtonFormField<GroupActivityType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Activity Type',
                      ),
                      items: GroupActivityType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              _getActivityIcon(type),
                              const SizedBox(width: 8),
                              Text(_formatActivityType(type)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }

              await _service.createSession(
                groupName: nameController.text.trim(),
                activityType: selectedType,
                leaderId: 'current_user_id', // TODO: Get from auth
                leaderName: 'Current User', // TODO: Get from auth
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    GroupMemberRole selectedRole = GroupMemberRole.member;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Member name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'email@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '+1234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) =>
                    DropdownButtonFormField<GroupMemberRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: GroupMemberRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(_formatRole(role)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRole = value);
                        }
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              try {
                await _service.addMember(
                  memberId: 'member_${DateTime.now().millisecondsSinceEpoch}',
                  memberName: nameController.text.trim(),
                  role: selectedRole,
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCreateRallyPointDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final radiusController = TextEditingController(text: '50');
    RallyPointType selectedType = RallyPointType.checkpoint;
    bool checkInRequired = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Rally Point'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Summit Peak',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '37.7749',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lonController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '-122.4194',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  hintText: '50',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    DropdownButtonFormField<RallyPointType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: RallyPointType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatRallyPointType(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Check-in required'),
                      value: checkInRequired,
                      onChanged: (value) {
                        setState(() => checkInRequired = value ?? true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  latController.text.trim().isEmpty ||
                  lonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              try {
                await _service.createRallyPoint(
                  name: nameController.text.trim(),
                  latitude: double.parse(latController.text.trim()),
                  longitude: double.parse(lonController.text.trim()),
                  radiusMeters: double.parse(radiusController.text.trim()),
                  createdBy: 'current_user_id', // TODO: Get from auth
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  type: selectedType,
                  checkInRequired: checkInRequired,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateBuddyPairDialog() {
    if (_members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 members to create a buddy pair'),
        ),
      );
      return;
    }

    String? member1Id;
    String? member2Id;
    final separationController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Buddy Pair'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: member1Id,
                decoration: const InputDecoration(labelText: 'First Buddy'),
                items: _members.map((member) {
                  return DropdownMenuItem(
                    value: member.memberId,
                    child: Text(member.memberName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => member1Id = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: member2Id,
                decoration: const InputDecoration(labelText: 'Second Buddy'),
                items: _members.where((m) => m.memberId != member1Id).map((
                  member,
                ) {
                  return DropdownMenuItem(
                    value: member.memberId,
                    child: Text(member.memberName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => member2Id = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: separationController,
                decoration: const InputDecoration(
                  labelText: 'Max Separation (meters)',
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (member1Id == null || member2Id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select both buddies')),
                  );
                  return;
                }

                try {
                  await _service.createBuddyPair(
                    member1Id: member1Id!,
                    member2Id: member2Id!,
                    maxSeparationMeters: double.parse(
                      separationController.text.trim(),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(GroupMember member) {
    if (member.role == GroupMemberRole.leader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove group leader')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.memberName} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _service.removeMember(member.memberId);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmEndSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this group session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _service.endSession();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Return to previous screen
              }
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Icon _getActivityIcon(GroupActivityType type) {
    switch (type) {
      case GroupActivityType.hiking:
        return const Icon(Icons.hiking);
      case GroupActivityType.cycling:
        return const Icon(Icons.directions_bike);
      case GroupActivityType.waterSports:
        return const Icon(Icons.surfing);
      case GroupActivityType.skiing:
        return const Icon(Icons.downhill_skiing);
      case GroupActivityType.climbing:
        return const Icon(Icons.terrain);
      case GroupActivityType.teamSports:
        return const Icon(Icons.sports_soccer);
      case GroupActivityType.camping:
        return const Icon(Icons.cabin);
    }
  }

  String _formatActivityType(GroupActivityType type) {
    switch (type) {
      case GroupActivityType.hiking:
        return 'Hiking';
      case GroupActivityType.cycling:
        return 'Cycling';
      case GroupActivityType.waterSports:
        return 'Water Sports';
      case GroupActivityType.skiing:
        return 'Skiing';
      case GroupActivityType.climbing:
        return 'Climbing';
      case GroupActivityType.teamSports:
        return 'Team Sports';
      case GroupActivityType.camping:
        return 'Camping';
    }
  }

  String _formatRole(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.leader:
        return 'Leader';
      case GroupMemberRole.coLeader:
        return 'Co-Leader';
      case GroupMemberRole.member:
        return 'Member';
    }
  }

  String _formatRallyPointType(RallyPointType type) {
    switch (type) {
      case RallyPointType.start:
        return 'Start';
      case RallyPointType.checkpoint:
        return 'Checkpoint';
      case RallyPointType.rest:
        return 'Rest Stop';
      case RallyPointType.lunch:
        return 'Lunch Break';
      case RallyPointType.emergency:
        return 'Emergency';
      case RallyPointType.finish:
        return 'Finish';
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
}
