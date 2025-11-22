import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/feature_access_service.dart';
import '../widgets/feature_protected_widget.dart';
import '../models/sar_access_level.dart';
import '../services/firebase_service.dart';
import '../services/app_service_manager.dart';
import '../services/auth_service.dart';
import '../services/sms_service.dart';
import '../services/notification_scheduler.dart';
import '../services/sos_analytics_service.dart';
import '../features/sos/presentation/pages/sos_chat_page.dart';
import '../models/sos_session.dart';
import '../core/logging/app_logger.dart';
import '../core/routing/app_router.dart';

/// SAR Dashboard showing access levels and available features
class SARDashboard extends StatefulWidget {
  const SARDashboard({super.key});

  @override
  SARDashboardState createState() => SARDashboardState();
}

class SARDashboardState extends State<SARDashboard> {
  final _featureAccessService = FeatureAccessService.instance;
  final _firebase = FirebaseFirestore.instance;
  final _firebaseService = FirebaseService();
  final _serviceManager = AppServiceManager();

  // UI state
  bool _isAvailable = true;
  String _sosStatusFilter = 'all'; // all | active | resolved
  String _helpStatusFilter =
      'all'; // all | active | assigned | inProgress | resolved

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SAR Dashboard'),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.verified_user), text: 'Access'),
              Tab(icon: Icon(Icons.emergency), text: 'Active SOS'),
              Tab(icon: Icon(Icons.support_agent), text: 'Help Requests'),
              Tab(icon: Icon(Icons.assignment_ind), text: 'My Assignments'),
            ],
          ),
          actions: [
            Row(
              children: [
                const Text('Available'),
                Switch(
                  value: _isAvailable,
                  onChanged: (v) async {
                    setState(() => _isAvailable = v);
                    // Persist availability if signed in
                    final user = _firebaseService.currentUser;
                    if (user != null) {
                      try {
                        await _firebase.collection('users').doc(user.uid).set({
                          'availableForSAR': v,
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAccessTab(),
            _buildActiveSOSTab(),
            _buildHelpRequestsTab(),
            _buildAssignmentsTab(),
          ],
        ),
      ),
    );
  }

  // Tab 1: Access & features
  Widget _buildAccessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccessLevelCard(),
          const SizedBox(height: 16),
          _buildSARKPISection(),
          const SizedBox(height: 24),
          _buildFeatureSection('Observer Level', _getObserverFeatures()),
          const SizedBox(height: 16),
          _buildFeatureSection('Participant Level', _getParticipantFeatures()),
          const SizedBox(height: 16),
          _buildFeatureSection('Coordinator Level', _getCoordinatorFeatures()),
        ],
      ),
    );
  }

  // Tab 2: Active SOS sessions
  Widget _buildActiveSOSTab() {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _sosStatusFilter == 'all',
                onSelected: (_) => setState(() => _sosStatusFilter = 'all'),
              ),
              ChoiceChip(
                label: const Text('Active'),
                selected: _sosStatusFilter == 'active',
                onSelected: (_) => setState(() => _sosStatusFilter = 'active'),
              ),
              ChoiceChip(
                label: const Text('Resolved'),
                selected: _sosStatusFilter == 'resolved',
                onSelected: (_) =>
                    setState(() => _sosStatusFilter = 'resolved'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('sos_sessions')
                .orderBy('startTime', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('No SOS sessions'));
              }
              final docs = snapshot.data!.docs;
              final filtered = docs.where((d) {
                final status = (d.data()['status'] ?? '').toString();
                if (_sosStatusFilter == 'all') return true;
                if (_sosStatusFilter == 'active') {
                  return status == 'active' ||
                      status == 'assigned' ||
                      status == 'inProgress';
                }
                if (_sosStatusFilter == 'resolved') return status == 'resolved';
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matching SOS sessions'));
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = filtered[i].data();
                  final id = filtered[i].id;
                  final status = (data['status'] ?? 'unknown').toString();
                  final userName =
                      (data['userName'] ?? data['userId'] ?? 'Unknown')
                          .toString();
                  final message = (data['userMessage'] ?? '').toString();
                  final userId = (data['userId'] ?? '').toString();
                  return ListTile(
                    leading: Icon(
                      Icons.emergency,
                      color: status == 'resolved' ? Colors.grey : Colors.red,
                    ),
                    title: Text(userName),
                    subtitle: Text(message.isEmpty ? 'No message' : message),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status != 'resolved' && userId.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble,
                              color: Colors.green,
                            ),
                            tooltip: 'Open Chat',
                            onPressed: () => _openSOSChat(context, id, data),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.video_call,
                              color: Colors.blue,
                            ),
                            tooltip: 'Start WebRTC call',
                            onPressed: () =>
                                _startWebRTCCallToUser(userId, userName, id),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            tooltip: 'Resolve SOS',
                            onPressed: () =>
                                _showResolveDialog(context, id, data),
                          ),
                        ],
                        Text(status),
                      ],
                    ),
                    onTap: () => _showSosActionsSheet(id, data),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 3: Help requests
  Widget _buildHelpRequestsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in [
                'all',
                'active',
                'assigned',
                'inProgress',
                'resolved',
              ])
                ChoiceChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: _helpStatusFilter == f,
                  onSelected: (_) => setState(() => _helpStatusFilter = f),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebase
                .collection('help_requests')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('No help requests'));
              }
              final docs = snapshot.data!.docs;
              final filtered = docs.where((d) {
                if (_helpStatusFilter == 'all') return true;
                return (d.data()['status'] ?? '').toString() ==
                    _helpStatusFilter;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matching help requests'));
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = filtered[i].data();
                  final id = filtered[i].id;
                  final title =
                      (data['subCategoryId'] ?? data['categoryId'] ?? 'Help')
                          .toString();
                  final desc = (data['description'] ?? '').toString();
                  final priority = (data['priority'] ?? 'low').toString();
                  return ListTile(
                    leading: _priorityDot(priority),
                    title: Text(title),
                    subtitle: Text(desc.isEmpty ? 'No description' : desc),
                    trailing: Text(priority.toUpperCase()),
                    onTap: () => _showHelpActionsSheet(id, data),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 4: My assignments (basic - accepted help responses)
  Widget _buildAssignmentsTab() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to see assignments'));
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
          return const Center(child: Text('No assignments yet'));
        }
        final docs = snapshot.data!.docs;
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final reqId = (data['requestId'] ?? '').toString();
            final msg = (data['message'] ?? '').toString();
            final accepted = (data['isAccepted'] ?? false) == true;
            return ListTile(
              leading: Icon(
                accepted ? Icons.task_alt : Icons.pending_actions,
                color: accepted ? Colors.green : Colors.orange,
              ),
              title: Text('Help Response for $reqId'),
              subtitle: Text(msg.isEmpty ? 'No message' : msg),
              trailing: accepted
                  ? const Text('ACCEPTED')
                  : const Text('PENDING'),
            );
          },
        );
      },
    );
  }

  // Action sheets
  /// Start WebRTC call to user in distress
  Future<void> _startWebRTCCallToUser(
    String userId,
    String userName,
    String sosSessionId,
  ) async {
    try {
      final webrtcService =
          _serviceManager.phoneAIIntegrationService.webrtcService;

      if (!webrtcService.isInitialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebRTC service not initialized'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Starting WebRTC Call...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to emergency contact...'),
            ],
          ),
        ),
      );

      final sarMemberName =
          _firebaseService.currentUser?.displayName ?? 'SAR Member';
      final message =
          '''This is $sarMemberName from Search and Rescue team.

I am responding to your emergency alert (Session: $sosSessionId).

Please confirm your status and location.

Are you able to hear me? Please respond if you can.''';

      final channelName = await webrtcService.makeEmergencyCall(
        contactId: userId,
        emergencyMessage: message,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.video_call, color: Colors.blue),
              SizedBox(width: 12),
              Text('WebRTC Call Active'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📞 Connected to $userName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Channel: $channelName',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Voice call established',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can now speak directly with the person in distress. The call will remain active until ended.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _serviceManager.phoneAIIntegrationService.endWebRTCCall();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Call ended')));
                }
              },
              child: const Text(
                'End Call',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Active'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Open real-time chat with SOS victim
  Future<void> _openSOSChat(
    BuildContext context,
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      // Create SOSSession object from data
      final session = SOSSession(
        id: sessionId,
        userId: sessionData['userId'] ?? '',
        type: SOSType.manual,
        status: _parseSOSStatus(sessionData['status'] ?? 'active'),
        startTime:
            (sessionData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        location: LocationInfo(
          latitude: sessionData['latitude'] ?? 0.0,
          longitude: sessionData['longitude'] ?? 0.0,
          accuracy: sessionData['accuracy'] ?? 0.0,
          timestamp:
              (sessionData['timestamp'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        ),
        userMessage: sessionData['message'] ?? '',
      );

      if (!mounted) return;

      // Navigate to chat page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SOSChatPage(
            session: session,
            isSARUser: true, // SAR team member
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  SOSStatus _parseSOSStatus(String status) {
    switch (status.toLowerCase()) {
      case 'countdown':
        return SOSStatus.countdown;
      case 'active':
        return SOSStatus.active;
      case 'acknowledged':
        return SOSStatus.acknowledged;
      case 'assigned':
        return SOSStatus.assigned;
      case 'en_route':
      case 'enroute':
        return SOSStatus.enRoute;
      case 'on_scene':
      case 'onscene':
        return SOSStatus.onScene;
      case 'in_progress':
      case 'inprogress':
        return SOSStatus.inProgress;
      case 'resolved':
        return SOSStatus.resolved;
      case 'cancelled':
        return SOSStatus.cancelled;
      case 'false_alarm':
      case 'falsealarm':
        return SOSStatus.falseAlarm;
      default:
        return SOSStatus.active;
    }
  }

  /// Show resolution dialog for SAR team
  Future<void> _showResolveDialog(
    BuildContext context,
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    final notesController = TextEditingController();
    String resolution = 'safe';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve SOS Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outcome:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  title: const Text('✅ Safe - No injuries'),
                  value: 'safe',
                  // ignore: deprecated_member_use
                  groupValue: resolution,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => resolution = val!),
                  dense: true,
                ),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  title: const Text('🏥 Injured - Medical attention needed'),
                  value: 'injured',
                  // ignore: deprecated_member_use
                  groupValue: resolution,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => resolution = val!),
                  dense: true,
                ),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  title: const Text('⚠️ False Alarm'),
                  value: 'false_alarm',
                  // ignore: deprecated_member_use
                  groupValue: resolution,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => resolution = val!),
                  dense: true,
                ),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  title: const Text('❌ Unable to locate'),
                  value: 'unable_to_locate',
                  // ignore: deprecated_member_use
                  groupValue: resolution,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => resolution = val!),
                  dense: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Resolution Notes',
                    hintText: 'Enter details about the resolution...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Resolve SOS'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _resolveSOSSession(
        sessionId,
        resolution,
        notesController.text,
        sessionData,
      );
    }
  }

  /// Resolve SOS session with outcome and notes
  Future<void> _resolveSOSSession(
    String sessionId,
    String resolution,
    String notes,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser.isEmpty) {
        throw Exception('No authenticated user');
      }

      // Update SOS session in Firestore
      await _firebase.collection('sos_sessions').doc(sessionId).update({
        'status': 'resolved',
        'endTime': FieldValue.serverTimestamp(),
        'resolution': resolution,
        'resolutionNotes': notes,
        'resolvedBy': currentUser.id,
        'resolvedByName': currentUser.displayName,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ SOS session resolved successfully: $resolution'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Stop SMS notifications with final resolution SMS
      try {
        await SMSService.instance.stopSMSNotifications(
          sessionId,
          sendFinalSMS: true,
        );
      } catch (e) {
        debugPrint('Failed to stop SMS notifications: $e');
      }

      // Stop push notifications with final notification
      try {
        await NotificationScheduler.instance.stopNotifications(
          sessionId,
          sendFinalNotification: true,
        );
      } catch (e) {
        debugPrint('Failed to stop notifications: $e');
      }

      // Log resolution to analytics
      try {
        final startTime =
            (sessionData['startTime'] as Timestamp?)?.toDate() ??
            DateTime.now();
        await SOSAnalyticsService.instance.logSOSResolution(
          sessionId: sessionId,
          outcome: resolution,
          startTime: startTime,
          resolutionNotes: notes,
          resolvedBy: currentUser.id,
        );
      } catch (e) {
        debugPrint('Failed to log analytics: $e');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to resolve SOS: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showSosActionsSheet(
    String id,
    Map<String, dynamic> data,
  ) async {
    final level = await _featureAccessService.getSARAccessLevel();
    if (!mounted) return;
    final userId = (data['userId'] ?? '').toString();
    final userName = (data['userName'] ?? data['userId'] ?? 'Unknown')
        .toString();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View details'),
                onTap: () => Navigator.of(context).pop(),
              ),
              if (userId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.video_call, color: Colors.blue),
                  title: const Text('Start WebRTC Call'),
                  subtitle: const Text('Voice call to person in distress'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _startWebRTCCallToUser(userId, userName, id);
                  },
                ),
              if (level == SARAccessLevel.coordinator) ...[
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark as Resolved'),
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
                    } catch (_) {}
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHelpActionsSheet(
    String id,
    Map<String, dynamic> data,
  ) async {
    final level = await _featureAccessService.getSARAccessLevel();
    if (!mounted) return;
    final status = (data['status'] ?? 'active').toString();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View details'),
                onTap: () => Navigator.of(context).pop(),
              ),
              if (level != SARAccessLevel.none && status == 'active')
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start handling (In Progress)'),
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
                    } catch (_) {}
                  },
                ),
              if (level != SARAccessLevel.none && status != 'resolved')
                ListTile(
                  leading: const Icon(Icons.done_all),
                  title: const Text('Mark as Resolved'),
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
                    } catch (_) {}
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
        c = Colors.red;
        break;
      case 'medium':
        c = Colors.orange;
        break;
      default:
        c = Colors.green;
    }
    return CircleAvatar(radius: 10, backgroundColor: c);
  }

  Widget _buildAccessLevelCard() {
    return FutureBuilder<SARAccessLevel>(
      future: _featureAccessService.getSARAccessLevel(),
      builder: (context, snapshot) {
        final accessLevel = snapshot.data ?? SARAccessLevel.none;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getAccessLevelIcon(accessLevel),
                      color: _getAccessLevelColor(accessLevel),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current SAR Access: ${accessLevel.displayName}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            accessLevel.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (accessLevel == SARAccessLevel.none) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpgradeDialog(context),
                      icon: const Icon(Icons.upgrade),
                      label: const Text('Upgrade to Access SAR Features'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build SAR-specific KPI section (excludes regular SOS logs)
  Widget _buildSARKPISection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSARKPIs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final kpis = snapshot.data ?? {};
        final totalSARSessions = kpis['totalSARSessions'] ?? 0;
        final activeResponses = kpis['activeResponses'] ?? 0;
        final resolvedSessions = kpis['resolvedSessions'] ?? 0;
        final avgResponseTime = kpis['avgResponseTimeMinutes'] ?? 0;

        return Card(
          elevation: 2,
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'SAR Performance Metrics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        'Total SAR Sessions',
                        totalSARSessions.toString(),
                        Icons.emergency,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKPICard(
                        'Active Responses',
                        activeResponses.toString(),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        'Resolved Sessions',
                        resolvedSessions.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKPICard(
                        'Avg Response Time',
                        '$avgResponseTime min',
                        Icons.timer,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Note: Only sessions with SAR team involvement are counted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  /// Get SAR-specific KPIs (excludes regular SOS sessions without SAR involvement)
  Future<Map<String, dynamic>> _getSARKPIs() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get SAR responses (only sessions where SAR team responded)
      final responsesSnapshot = await _firebase
          .collection('analytics')
          .doc('sos_events')
          .collection('responses')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      // Get unique session IDs that had SAR responses
      final sarSessionIds = <String>{};
      final responseTimes = <int>[];

      for (final doc in responsesSnapshot.docs) {
        final data = doc.data();
        sarSessionIds.add(data['sessionId'] as String);
        responseTimes.add(data['responseTimeSeconds'] as int? ?? 0);
      }

      // Get resolution data for SAR sessions only
      final resolutionsSnapshot = await _firebase
          .collection('analytics')
          .doc('sos_events')
          .collection('resolutions')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      int resolvedSARSessions = 0;
      for (final doc in resolutionsSnapshot.docs) {
        final sessionId = doc.data()['sessionId'] as String;
        if (sarSessionIds.contains(sessionId)) {
          resolvedSARSessions++;
        }
      }

      // Calculate active responses (SAR sessions - resolved)
      final activeResponses = sarSessionIds.length - resolvedSARSessions;

      // Calculate average response time (convert seconds to minutes)
      final avgResponseTime = responseTimes.isEmpty
          ? 0
          : (responseTimes.reduce((a, b) => a + b) / responseTimes.length / 60)
                .round();

      return {
        'totalSARSessions': sarSessionIds.length,
        'activeResponses': activeResponses > 0 ? activeResponses : 0,
        'resolvedSessions': resolvedSARSessions,
        'avgResponseTimeMinutes': avgResponseTime,
      };
    } catch (e) {
      AppLogger.w('Failed to get SAR KPIs', tag: 'SARDashboard', error: e);
      return {
        'totalSARSessions': 0,
        'activeResponses': 0,
        'resolvedSessions': 0,
        'avgResponseTimeMinutes': 0,
      };
    }
  }

  Widget _buildFeatureSection(String title, List<SARFeatureItem> features) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => _buildFeatureItem(feature)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(SARFeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: FeatureProtectedWidget(
        feature: feature.featureKey,
        fallbackWidget: ListTile(
          leading: Icon(feature.icon, color: Colors.grey.shade400),
          title: Text(
            feature.title,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          subtitle: Text(
            feature.description,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          trailing: Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
        child: ListTile(
          leading: Icon(feature.icon, color: Colors.green.shade600),
          title: Text(feature.title),
          subtitle: Text(feature.description),
          trailing: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          onTap: feature.onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }

  List<SARFeatureItem> _getObserverFeatures() {
    return [
      SARFeatureItem(
        featureKey: 'sarObserver',
        title: 'View SAR Alerts',
        description: 'View active Search and Rescue alerts in your area',
        icon: Icons.notifications,
        onTap: () => _showFeatureDialog(
          'SAR Alerts',
          'View active emergency situations',
        ),
      ),
      SARFeatureItem(
        featureKey: 'sarObserver',
        title: 'Emergency Map',
        description: 'See emergency locations on interactive map',
        icon: Icons.map,
        onTap: () => _showFeatureDialog(
          'Emergency Map',
          'Interactive map showing emergencies',
        ),
      ),
    ];
  }

  List<SARFeatureItem> _getParticipantFeatures() {
    return [
      SARFeatureItem(
        featureKey: 'sarVolunteerRegistration',
        title: 'Volunteer Registration',
        description: 'Register as a certified SAR volunteer',
        icon: Icons.person_add,
        onTap: () => context.push(AppRouter.sarRegistration),
      ),
      SARFeatureItem(
        featureKey: 'sarParticipation',
        title: 'Respond to Emergencies',
        description: 'Participate in Search and Rescue operations',
        icon: Icons.emergency,
        onTap: () => _showFeatureDialog(
          'Emergency Response',
          'Respond to active SAR missions',
        ),
      ),
      SARFeatureItem(
        featureKey: 'sarParticipation',
        title: 'Training Resources',
        description: 'Access SAR training materials and courses',
        icon: Icons.school,
        onTap: () =>
            _showFeatureDialog('Training', 'Access comprehensive SAR training'),
      ),
    ];
  }

  List<SARFeatureItem> _getCoordinatorFeatures() {
    return [
      SARFeatureItem(
        featureKey: 'sarTeamManagement',
        title: 'Team Management',
        description: 'Create and manage SAR teams',
        icon: Icons.group,
        onTap: () => context.push(AppRouter.organizationDashboard),
      ),
      SARFeatureItem(
        featureKey: 'organizationManagement',
        title: 'Mission Coordination',
        description: 'Coordinate multi-team rescue operations',
        icon: Icons.hub,
        onTap: () => context.push(AppRouter.organizationDashboard),
      ),
      SARFeatureItem(
        featureKey: 'organizationManagement',
        title: 'Resource Management',
        description: 'Allocate equipment and personnel',
        icon: Icons.inventory,
        onTap: () => context.push(AppRouter.organizationDashboard),
      ),
      SARFeatureItem(
        featureKey: 'organizationManagement',
        title: 'Analytics Dashboard',
        description: 'View performance metrics and reports',
        icon: Icons.analytics,
        onTap: () => context.push(AppRouter.organizationDashboard),
      ),
    ];
  }

  IconData _getAccessLevelIcon(SARAccessLevel level) {
    switch (level) {
      case SARAccessLevel.none:
        return Icons.block;
      case SARAccessLevel.observer:
        return Icons.visibility;
      case SARAccessLevel.participant:
        return Icons.person;
      case SARAccessLevel.coordinator:
        return Icons.admin_panel_settings;
    }
  }

  Color _getAccessLevelColor(SARAccessLevel level) {
    switch (level) {
      case SARAccessLevel.none:
        return Colors.grey;
      case SARAccessLevel.observer:
        return Colors.blue;
      case SARAccessLevel.participant:
        return Colors.green;
      case SARAccessLevel.coordinator:
        return Colors.orange;
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Subscribe to Essential+ or higher to access SAR features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to subscription page
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Data class for SAR feature items
class SARFeatureItem {
  final String featureKey;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const SARFeatureItem({
    required this.featureKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}
