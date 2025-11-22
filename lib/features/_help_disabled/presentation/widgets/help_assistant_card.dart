import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';

/// Card widget for Help Assistant on main dashboard
class HelpAssistantCard extends StatefulWidget {
  const HelpAssistantCard({super.key});

  @override
  State<HelpAssistantCard> createState() => _HelpAssistantCardState();
}

class _HelpAssistantCardState extends State<HelpAssistantCard> {
  final AppServiceManager _serviceManager = AppServiceManager();

  List<HelpRequest> _activeRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _serviceManager.helpAssistantService.initialize();
      final requests = await _serviceManager.helpAssistantService
          .getActiveRequests();
      _activeRequests = requests;
    } catch (e) {
      debugPrint('HelpAssistantCard: Error loading data - $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.infoBlue.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => context.go('/help-assistant'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: AppTheme.infoBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Help Assistant & Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  if (_activeRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                'Get help with vehicle breakdowns, lost pets, security concerns, and more. No SOS activation needed.',
                style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
              ),

              const SizedBox(height: 16),

              // Quick Categories
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_activeRequests.isNotEmpty)
                _buildActiveRequestsSummary()
              else
                _buildQuickCategories(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRequestsSummary() {
    final statusCounts = <HelpRequestStatus, int>{};
    for (final request in _activeRequests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
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
          const Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: AppTheme.warningOrange,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Active Requests',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 12,
            children: statusCounts.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value} ${_getStatusDisplayName(entry.key)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategories() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickCategoryButton(
            'Vehicle',
            Icons.directions_car,
            AppTheme.warningOrange,
            () => _quickCreateRequest('vehicle_breakdown'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickCategoryButton(
            'Security',
            Icons.security,
            AppTheme.criticalRed,
            () => _quickCreateRequest('home_security'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickCategoryButton(
            'Lost Pet',
            Icons.pets,
            AppTheme.infoBlue,
            () => _quickCreateRequest('lost_pet'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCategoryButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _quickCreateRequest(String categoryId) {
    // Navigate directly to help assistant page with category pre-selected
    context.go('/help-assistant');
  }

  Color _getStatusColor(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.active:
        return AppTheme.warningOrange;
      case HelpRequestStatus.assigned:
        return AppTheme.infoBlue;
      case HelpRequestStatus.inProgress:
        return AppTheme.infoBlue;
      case HelpRequestStatus.resolved:
        return AppTheme.safeGreen;
      case HelpRequestStatus.cancelled:
        return AppTheme.neutralGray;
      case HelpRequestStatus.expired:
        return AppTheme.neutralGray;
    }
  }

  String _getStatusDisplayName(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.active:
        return 'active';
      case HelpRequestStatus.assigned:
        return 'assigned';
      case HelpRequestStatus.inProgress:
        return 'in progress';
      case HelpRequestStatus.resolved:
        return 'resolved';
      case HelpRequestStatus.cancelled:
        return 'cancelled';
      case HelpRequestStatus.expired:
        return 'expired';
    }
  }
}
