import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';
import '../widgets/help_category_card.dart';
import '../widgets/active_help_requests_widget.dart';

/// Main Help Assistant page for non-emergency assistance
class HelpAssistantPage extends StatefulWidget {
  const HelpAssistantPage({super.key});

  @override
  State<HelpAssistantPage> createState() => _HelpAssistantPageState();
}

class _HelpAssistantPageState extends State<HelpAssistantPage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  List<HelpRequest> _activeRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await _serviceManager.helpAssistantService.initialize();
      _loadActiveRequests();

      // Set up callbacks
      _serviceManager.helpAssistantService.setRequestCreatedCallback(
        _onRequestCreated,
      );
      _serviceManager.helpAssistantService.setRequestUpdatedCallback(
        _onRequestUpdated,
      );
    } catch (e) {
      debugPrint('HelpAssistantPage: Error initializing - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadActiveRequests() async {
    final list = await _serviceManager.helpAssistantService.getActiveRequests();
    _activeRequests = list;
    if (mounted) setState(() {});
  }

  void _onRequestCreated(HelpRequest request) {
    _loadActiveRequests();
  }

  void _onRequestUpdated(HelpRequest request) {
    _loadActiveRequests();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Assistant & Support'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showRequestHistory,
            tooltip: 'Request History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 24),

            // Active Requests
            if (_activeRequests.isNotEmpty) ...[
              ActiveHelpRequestsWidget(requests: _activeRequests),
              const SizedBox(height: 24),
            ],

            // Help Categories
            const Text(
              'What do you need help with?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            _buildHelpCategories(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCustomRequest,
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Custom Request'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoBlue, AppTheme.infoBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Non-Emergency Help & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get assistance for vehicle breakdowns, lost pets, security concerns, and more. Connect with service providers, police, or community members.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'For life-threatening emergencies, use the SOS button',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text('SOS', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCategories() {
    final categories = [
      _CategoryInfo(
        categoryId: 'vehicle',
        title: 'Vehicle Assistance',
        subtitle: 'Breakdown, towing, roadside help',
        icon: Icons.directions_car,
        color: AppTheme.warningOrange,
        subcategoryIds: const [
          'breakdown',
          'flat_tire',
          'dead_battery',
          'out_of_fuel',
          'locked_out',
          'towing',
        ],
      ),
      _CategoryInfo(
        categoryId: 'home_security',
        title: 'Security & Safety',
        subtitle: 'Break-ins, theft, domestic issues',
        icon: Icons.security,
        color: AppTheme.criticalRed,
        subcategoryIds: const [
          'break_in',
          'suspicious_activity',
          'domestic_violence',
          'theft',
          'vandalism',
        ],
      ),
      _CategoryInfo(
        categoryId: 'personal_safety',
        title: 'Personal Safety',
        subtitle: 'Harassment, feeling unsafe, stuck',
        icon: Icons.shield_outlined,
        color: AppTheme.primaryRed,
        subcategoryIds: const [
          'harassment',
          'stalking',
          'feeling_unsafe',
          'stuck_trapped',
        ],
      ),
      _CategoryInfo(
        categoryId: 'lost_found',
        title: 'Lost & Found',
        subtitle: 'Lost pets, keys, wallet, phone',
        icon: Icons.search,
        color: AppTheme.infoBlue,
        subcategoryIds: const [
          'lost_pet',
          'lost_keys',
          'lost_wallet',
          'lost_phone',
          'found_item',
        ],
      ),
      _CategoryInfo(
        categoryId: 'marine',
        title: 'Marine Assistance',
        subtitle: 'Boat breakdown, stuck, marine help',
        icon: Icons.directions_boat,
        color: AppTheme.infoBlue,
        subcategoryIds: const [
          'boat_breakdown',
          'boat_stuck',
          'marine_assistance',
        ],
      ),
      _CategoryInfo(
        categoryId: 'community',
        title: 'Community Support',
        subtitle: 'Neighbor disputes, noise, concerns',
        icon: Icons.groups,
        color: AppTheme.safeGreen,
        subcategoryIds: const [
          'neighbor_dispute',
          'noise_complaint',
          'community_concern',
        ],
      ),
      _CategoryInfo(
        categoryId: 'legal',
        title: 'Legal Assistance',
        subtitle: 'Legal advice, document help',
        icon: Icons.gavel,
        color: AppTheme.neutralGray,
        subcategoryIds: const ['legal_advice', 'document_help'],
      ),
      _CategoryInfo(
        categoryId: 'utilities',
        title: 'Utilities',
        subtitle: 'Power, water, gas issues',
        icon: Icons.power,
        color: AppTheme.warningOrange,
        subcategoryIds: const ['power_outage', 'water_issue', 'gas_leak_minor'],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return HelpCategoryCard(
          title: category.title,
          subtitle: category.subtitle,
          icon: category.icon,
          color: category.color,
          onTap: () => _showCategoryOptions(category),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Call Police\n(Non-Emergency)',
                Icons.local_police,
                AppTheme.infoBlue,
                () => _callPoliceNonEmergency(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Community\nHelp Chat',
                Icons.chat,
                AppTheme.safeGreen,
                () => _openCommunityChat(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Emergency\nContacts',
                Icons.contacts,
                AppTheme.warningOrange,
                () => _showEmergencyContacts(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Local\nServices',
                Icons.business,
                AppTheme.neutralGray,
                () => _showLocalServices(),
              ),
            ),
          ],
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
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryOptions(_CategoryInfo category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subcategories
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: category.subcategoryIds.length,
                itemBuilder: (context, index) {
                  final subcategoryId = category.subcategoryIds[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getSubcategoryIcon(subcategoryId),
                        color: category.color,
                      ),
                      title: Text(_getSubcategoryDisplayName(subcategoryId)),
                      subtitle: Text(_getSubcategoryDescription(subcategoryId)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pop(context);
                        _createHelpRequest(category.categoryId, subcategoryId);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createHelpRequest(String categoryId, String subcategoryId) {
    context
        .push(
          '/create-help-request',
          extra: {'categoryId': categoryId, 'subcategoryId': subcategoryId},
        )
        .then((result) {
          if (result is HelpRequest) {
            _loadActiveRequests();
          }
        });
  }

  void _createCustomRequest() {
    context.push('/create-help-request').then((result) {
      if (result is HelpRequest) {
        _loadActiveRequests();
      }
    });
  }

  void _showRequestHistory() {
    // TODO: Implement request history page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request history feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _callPoliceNonEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Police Non-Emergency'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For non-emergency police assistance:'),
            SizedBox(height: 8),
            Text(
              '📞 (555) POLICE-1',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Use this for:'),
            Text('• Theft reports'),
            Text('• Noise complaints'),
            Text('• Suspicious activity'),
            Text('• Minor accidents'),
            Text('• Property damage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual phone call
              _showCallConfirmation('Police Non-Emergency: (555) POLICE-1');
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _openCommunityChat() {
    context.go('/chat');
  }

  void _showEmergencyContacts() {
    context.go('/profile/emergency-contacts');
  }

  void _showLocalServices() {
    // TODO: Implement local services directory
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local services directory coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCallConfirmation(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number'),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getSubcategoryIcon(String subcategoryId) {
    switch (subcategoryId) {
      case 'breakdown':
        return Icons.car_crash;
      case 'flat_tire':
        return Icons.tire_repair;
      case 'dead_battery':
        return Icons.battery_alert;
      case 'out_of_fuel':
        return Icons.local_gas_station;
      case 'locked_out':
        return Icons.lock;
      case 'towing':
        return Icons.local_shipping;
      case 'break_in':
        return Icons.door_front_door;
      case 'suspicious_activity':
        return Icons.visibility;
      case 'domestic_violence':
        return Icons.shield;
      case 'theft':
        return Icons.report_problem;
      case 'harassment':
        return Icons.block;
      case 'stalking':
        return Icons.person_search;
      case 'feeling_unsafe':
        return Icons.sentiment_very_dissatisfied;
      case 'stuck_trapped':
        return Icons.help_outline;
      case 'lost_pet':
        return Icons.pets;
      case 'lost_keys':
        return Icons.key;
      case 'lost_wallet':
        return Icons.account_balance_wallet;
      case 'lost_phone':
        return Icons.phone_android;
      case 'boat_breakdown':
        return Icons.directions_boat;
      case 'neighbor_dispute':
        return Icons.people_outline;
      case 'legal_advice':
        return Icons.gavel;
      case 'medical_transport':
        return Icons.local_hospital;
      case 'power_outage':
        return Icons.power_off;
      case 'water_issue':
        return Icons.water_drop;
      default:
        return Icons.help_outline;
    }
  }

  String _getSubcategoryDisplayName(String subcategoryId) {
    switch (subcategoryId) {
      case 'breakdown':
        return 'Vehicle Breakdown';
      case 'flat_tire':
        return 'Flat Tyre';
      case 'dead_battery':
        return 'Dead Battery';
      case 'out_of_fuel':
        return 'Out of Fuel';
      case 'locked_out':
        return 'Locked Out';
      case 'towing':
        return 'Towing';
      case 'break_in':
        return 'Break-in';
      case 'suspicious_activity':
        return 'Suspicious Activity';
      case 'domestic_violence':
        return 'Domestic Violence';
      case 'theft':
        return 'Theft';
      case 'harassment':
        return 'Harassment';
      case 'stalking':
        return 'Stalking';
      case 'feeling_unsafe':
        return 'Feeling Unsafe';
      case 'stuck_trapped':
        return 'Stuck/Trapped';
      case 'lost_pet':
        return 'Lost Pet';
      case 'lost_keys':
        return 'Lost Keys';
      case 'lost_wallet':
        return 'Lost Wallet';
      case 'lost_phone':
        return 'Lost Phone';
      case 'boat_breakdown':
        return 'Boat Breakdown';
      case 'neighbor_dispute':
        return 'Neighbor Dispute';
      case 'legal_advice':
        return 'Legal Advice';
      case 'medical_transport':
        return 'Medical Transport';
      case 'power_outage':
        return 'Power Outage';
      case 'water_issue':
        return 'Water Supply Issue';
      default:
        return 'Other';
    }
  }

  String _getSubcategoryDescription(String subcategoryId) {
    switch (subcategoryId) {
      case 'breakdown':
        return 'Vehicle won\'t start or is disabled';
      case 'flat_tire':
        return 'Need tire change or repair';
      case 'dead_battery':
        return 'Need jump start or battery replacement';
      case 'out_of_fuel':
        return 'Need fuel delivery service';
      case 'locked_out':
        return 'Locked out of vehicle';
      case 'towing':
        return 'Need vehicle towed';
      case 'break_in':
        return 'Home or property break-in';
      case 'suspicious_activity':
        return 'Suspicious behavior in area';
      case 'domestic_violence':
        return 'Domestic violence situation';
      case 'theft':
        return 'Property theft or burglary';
      case 'harassment':
        return 'Being harassed or threatened';
      case 'stalking':
        return 'Being followed or stalked';
      case 'feeling_unsafe':
        return 'Feel unsafe in current situation';
      case 'stuck_trapped':
        return 'Stuck or trapped somewhere';
      case 'lost_pet':
        return 'Pet is missing or lost';
      case 'lost_keys':
        return 'Lost house or car keys';
      case 'lost_wallet':
        return 'Lost wallet or purse';
      case 'lost_phone':
        return 'Lost mobile phone';
      case 'boat_breakdown':
        return 'Boat engine or mechanical failure';
      case 'neighbor_dispute':
        return 'Dispute with neighbors';
      case 'legal_advice':
        return 'Need legal guidance';
      case 'medical_transport':
        return 'Non-emergency medical transport';
      case 'power_outage':
        return 'Electrical power issues';
      case 'water_issue':
        return 'Water service problems';
      default:
        return 'General assistance needed';
    }
  }
}

class _CategoryInfo {
  final String categoryId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> subcategoryIds;

  const _CategoryInfo({
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.subcategoryIds,
  });
}
