// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/ai_assistant.dart';

/// AI Assistant card for main dashboard
class AIAssistantCard extends StatefulWidget {
  const AIAssistantCard({super.key});

  @override
  State<AIAssistantCard> createState() => _AIAssistantCardState();
}

class _AIAssistantCardState extends State<AIAssistantCard>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  List<AISuggestion> _activeSuggestions = [];
  AIPerformanceData? _performanceData;
  bool _isLoading = true;

  late AnimationController _aiPulseController;
  late Animation<double> _aiPulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _aiPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _aiPulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _aiPulseController, curve: Curves.easeInOut),
    );

    _aiPulseController.repeat(reverse: true);
  }

  Future<void> _loadData() async {
    try {
      await _serviceManager.aiAssistantService.initialize();

      // Set up callbacks
      _serviceManager.aiAssistantService.setSuggestionGeneratedCallback(
        _onSuggestionGenerated,
      );
      _serviceManager.aiAssistantService.setPerformanceUpdateCallback(
        _onPerformanceUpdate,
      );

      // Load current data
      _activeSuggestions = await _serviceManager.aiAssistantService
          .generateSmartSuggestions();
      _performanceData = _serviceManager.aiAssistantService.lastPerformanceData;
    } catch (e) {
      debugPrint('AIAssistantCard: Error loading data - $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSuggestionGenerated(AISuggestion suggestion) {
    if (mounted) {
      setState(() {
        _activeSuggestions.add(suggestion);
        // Keep only recent, valid suggestions
        _activeSuggestions = _activeSuggestions
            .where((s) => s.validUntil.isAfter(DateTime.now()))
            .toList();
        _activeSuggestions.sort(
          (a, b) => b.priority.index.compareTo(a.priority.index),
        );
        if (_activeSuggestions.length > 5) {
          _activeSuggestions = _activeSuggestions.take(5).toList();
        }
      });
    }
  }

  void _onPerformanceUpdate(AIPerformanceData data) {
    if (mounted) {
      setState(() {
        _performanceData = data;
      });
    }
  }

  @override
  void dispose() {
    _aiPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.infoBlue.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () {
          // Direct access to AI Assistant - subscription check removed
          context.go('/ai-assistant');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _aiPulseAnimation,
                    builder: (context, child) {
                      return Icon(
                        Icons.psychology,
                        color: AppTheme.infoBlue,
                        size: 24,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Safety Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  if (_activeSuggestions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getHighestPriorityColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeSuggestions.length}',
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
              Text(
                _getStatusDescription(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),

              const SizedBox(height: 16),

              // Content based on loading state
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_activeSuggestions.isNotEmpty)
                _buildSuggestionsPreview()
              else
                _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsPreview() {
    final topSuggestions = _activeSuggestions.take(2).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getHighestPriorityColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getHighestPriorityColor().withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: _getHighestPriorityColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Smart Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...topSuggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getSuggestionPriorityColor(
                            suggestion.priority,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion.title,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_activeSuggestions.length > 2)
                Text(
                  '... and ${_activeSuggestions.length - 2} more',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'Voice',
            Icons.mic,
            AppTheme.infoBlue,
            _startVoiceCommand,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            'Status',
            Icons.health_and_safety,
            AppTheme.safeGreen,
            _quickStatusCheck,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            'Optimize',
            Icons.speed,
            AppTheme.warningOrange,
            _quickOptimize,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
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
            Icon(icon, color: color, size: 18),
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

  String _getStatusDescription() {
    if (_serviceManager.aiAssistantService.isListening) {
      return 'AI is listening for voice commands...';
    } else if (_serviceManager.aiAssistantService.isSpeaking) {
      return 'AI is providing voice guidance...';
    } else if (_activeSuggestions.isNotEmpty) {
      final urgentCount = _activeSuggestions
          .where((s) => s.priority == AISuggestionPriority.urgent)
          .length;
      if (urgentCount > 0) {
        return 'I have $urgentCount urgent suggestion${urgentCount == 1 ? '' : 's'} for you.';
      } else {
        return 'I have ${_activeSuggestions.length} suggestion${_activeSuggestions.length == 1 ? '' : 's'} to improve your safety.';
      }
    } else {
      return 'Smart AI assistance for navigation, safety, and performance. Voice commands enabled.';
    }
  }

  Color _getHighestPriorityColor() {
    if (_activeSuggestions.isEmpty) return AppTheme.infoBlue;

    final highestPriority = _activeSuggestions
        .map((s) => s.priority)
        .reduce((a, b) => a.index > b.index ? a : b);

    return _getSuggestionPriorityColor(highestPriority);
  }

  Color _getSuggestionPriorityColor(AISuggestionPriority priority) {
    switch (priority) {
      case AISuggestionPriority.urgent:
        return AppTheme.criticalRed;
      case AISuggestionPriority.high:
        return AppTheme.warningOrange;
      case AISuggestionPriority.medium:
        return AppTheme.infoBlue;
      case AISuggestionPriority.low:
        return AppTheme.safeGreen;
    }
  }

  void _startVoiceCommand() {
    // Navigate to AI assistant and start voice input
    context.go('/ai-assistant');
  }

  void _quickStatusCheck() {
    // Navigate to AI assistant with status check command
    context.go('/ai-assistant');
    // TODO: Auto-execute status check command
  }

  void _quickOptimize() {
    // Navigate to AI assistant with optimize command
    context.go('/ai-assistant');
    // TODO: Auto-execute optimize command
  }
}
