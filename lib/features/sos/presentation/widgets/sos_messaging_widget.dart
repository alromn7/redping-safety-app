import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';
import '../../../../services/sos_ping_service.dart';
import '../../../../services/user_profile_service.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../../../sar/presentation/widgets/emergency_messaging_widget.dart';

/// Widget for SOS messaging from civilian side
class SOSMessagingWidget extends StatefulWidget {
  final SOSSession session;

  const SOSMessagingWidget({super.key, required this.session});

  @override
  State<SOSMessagingWidget> createState() => _SOSMessagingWidgetState();
}

class _SOSMessagingWidgetState extends State<SOSMessagingWidget> {
  final SOSPingService _pingService = SOSPingService();
  final UserProfileService _userProfileService = UserProfileService();

  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _pingService.initialize();
      await _userProfileService.initialize();

      final userProfile = _userProfileService.currentProfile;
      _currentUserId = userProfile?.id ?? widget.session.userId;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SOSMessagingWidget: Initialization error - $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Find the ping associated with this SOS session
    final allPings = _pingService.getActivePings();
    final ping = allPings
        .where((p) => p.sessionId == widget.session.id)
        .firstOrNull;

    if (ping == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.message_outlined,
              size: 64,
              color: AppTheme.neutralGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No SAR Team Assigned Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A SAR team will be assigned soon.\nYou\'ll be able to communicate with them here.',
              style: TextStyle(color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _initializeService(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.infoBlue,
              ),
            ),
          ],
        ),
      );
    }

    return EmergencyMessagingWidget(
      ping: ping,
      isSARMember: false,
      currentUserId: _currentUserId ?? widget.session.userId,
    );
  }
}
