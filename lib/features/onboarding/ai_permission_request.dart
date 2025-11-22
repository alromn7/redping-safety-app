import 'package:flutter/material.dart';
import '../../services/phone_ai_service.dart';

/// AI Permission Request Widget
///
/// Shown on first app launch to request permission for phone AI integration
class AIPermissionRequest extends StatelessWidget {
  final VoidCallback onPermissionGranted;
  final VoidCallback onPermissionDenied;

  const AIPermissionRequest({
    super.key,
    required this.onPermissionGranted,
    required this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Icon Animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Phone AI Integration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enhance RedPing with your phone\'s AI capabilities',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Features list
              _buildFeatureCard(
                icon: Icons.mic,
                color: Colors.blue,
                title: 'Voice Commands',
                description:
                    '"Hey Google/Siri, activate RedPing SOS"\nHands-free emergency activation',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.lightbulb,
                color: Colors.orange,
                title: 'Smart Suggestions',
                description:
                    'AI suggests safety actions based on your location, battery, and activity',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.school,
                color: Colors.green,
                title: 'AI Tutorial',
                description:
                    'Interactive voice-guided tour explains all features',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.accessibility_new,
                color: Colors.purple,
                title: 'Accessibility Mode',
                description: 'Screen reader support and voice-only operation',
              ),

              const SizedBox(height: 24),

              // Privacy notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All AI processing happens on your device. '
                        'RedPing doesn\'t send voice data to external servers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPermissionDenied,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'Not Now',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final aiService = PhoneAIService();
                        final ctx =
                            context; // capture context for use after awaits
                        await aiService.initialize();
                        // Passing context into async API is required by service;
                        // scope to local variable and suppress linter for this line only.
                        // ignore: use_build_context_synchronously
                        final granted = await aiService.requestAIPermission(
      // ignore: use_build_context_synchronously
                          ctx,
                        );
                        if (granted) {
                          if (!ctx.mounted) return;
                          onPermissionGranted();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Enable AI',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Learn more link
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildLearnMoreDialog(context),
                  );
                },
                child: const Text('Learn More About AI Features'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnMoreDialog(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Text('About Phone AI Integration'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogSection(
              '🎤 Voice Commands',
              'Control RedPing using natural language:\n\n'
                  '• "Activate SOS" - Start emergency countdown\n'
                  '• "Send help request" - Open help system\n'
                  '• "Call emergency contact" - Instant call\n'
                  '• "Share my location" - Send location\n\n'
                  'Works with Google Assistant, Siri, Alexa, and Bixby.',
            ),
            const Divider(),
            _buildDialogSection(
              '🧠 Smart Contextual Suggestions',
              'AI monitors your context and suggests safety actions:\n\n'
                  '• Remote area? Enable crash detection\n'
                  '• Low battery? Notify contacts\n'
                  '• Long inactivity? Wellness check\n'
                  '• High-risk location? Extra alerts\n\n'
                  'All processing happens on-device for privacy.',
            ),
            const Divider(),
            _buildDialogSection(
              '📖 AI-Powered Tutorial',
              'Interactive onboarding that explains:\n\n'
                  '• Why profile setup saves lives\n'
                  '• How crash/fall detection works\n'
                  '• When to use SOS vs Help\n'
                  '• Voice command examples\n\n'
                  'Ask questions and get instant answers.',
            ),
            const Divider(),
            _buildDialogSection(
              '♿ Accessibility Features',
              'Full support for users with disabilities:\n\n'
                  '• Screen reader optimized\n'
                  '• Voice-only navigation\n'
                  '• High contrast themes\n'
                  '• Audio descriptions\n\n'
                  'Everyone deserves access to safety.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDialogSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 16),
      ],
    );
  }
}
