import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/phone_ai_service.dart';
import '../../core/routing/app_router.dart';

/// AI-Powered Interactive Onboarding
///
/// Introduces users to RedPing features using phone's AI capabilities.
/// Provides voice-guided tour and answers questions about the app.
class AIOnboardingPage extends StatefulWidget {
  const AIOnboardingPage({super.key});

  @override
  State<AIOnboardingPage> createState() => _AIOnboardingPageState();
}

class _AIOnboardingPageState extends State<AIOnboardingPage> {
  final PhoneAIService _aiService = PhoneAIService();
  int _currentStep = 0;
  bool _isListening = false;
  String _userQuestion = '';

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to RedPing',
      icon: Icons.waving_hand,
      color: Colors.blue,
      description: 'Your AI-powered emergency safety companion',
      aiScript:
          'Welcome to RedPing! I\'m your AI assistant. Let me show you how this life-saving app works. '
          'RedPing uses your phone\'s sensors and AI to detect emergencies and get you help fast.',
      actionButtons: [],
    ),
    OnboardingStep(
      title: 'Profile Setup',
      icon: Icons.person,
      color: Colors.purple,
      description: 'Your profile saves lives',
      aiScript:
          'First, let\'s set up your profile. This is crucial! When you send an S.O.S, rescuers need to know: '
          'Your name, your medical conditions, your blood type, any allergies, and who to contact. '
          'A complete profile can save your life in an emergency.',
      actionButtons: [
        'Why is profile important?',
        'What information is needed?',
      ],
    ),
    OnboardingStep(
      title: 'SOS Emergency System',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
      description: 'Automatic crash & fall detection',
      aiScript:
          'The S.O.S system has three ways to activate. One: You can manually press the S.O.S button. '
          'Two: Your phone automatically detects car crashes using accelerometers. '
          'Three: It detects hard falls that might cause injury. '
          'When activated, it sends your location and profile to nearby rescuers.',
      actionButtons: [
        'How does crash detection work?',
        'What happens after SOS?',
      ],
    ),
    OnboardingStep(
      title: 'Help Request System',
      icon: Icons.help_outline,
      color: Colors.orange,
      description: 'Non-emergency community help',
      aiScript:
          'The Help Request system is for non-emergency situations. '
          'Lost your pet? Car broke down? Need medical advice? '
          'Select a category like Lost Pet, Vehicle Issue, or Medical Help. '
          'The request goes to nearby volunteers and SAR teams who can assist.',
      actionButtons: [
        'When should I use Help vs SOS?',
        'What categories are available?',
      ],
    ),
    OnboardingStep(
      title: 'Voice Commands',
      icon: Icons.mic,
      color: Colors.green,
      description: 'Hands-free operation',
      aiScript:
          'You can control RedPing using voice commands. Just say: '
          'Hey Google, activate RedPing S.O.S. '
          'Or: Hey Siri, send RedPing help request. '
          'This is perfect when you can\'t use your hands in an emergency.',
      actionButtons: ['Show me voice commands', 'How to enable voice control?'],
    ),
    OnboardingStep(
      title: 'Ready to Go!',
      icon: Icons.check_circle,
      color: Colors.teal,
      description: 'You\'re all set',
      aiScript:
          'You\'re ready to use RedPing! Remember: '
          'Complete your profile first. '
          'Keep your phone charged. '
          'Enable crash detection when driving or hiking. '
          'And remember, help is just a voice command away. Stay safe!',
      actionButtons: ['Complete Profile Now', 'Explore App'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _showAIPermissionAndInitialize();
  }

  Future<void> _showAIPermissionAndInitialize() async {
    // Wait for frame to render before showing dialog
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Show AI permission request dialog first
    final granted = await _aiService.requestAIPermission(context);

    if (granted) {
      // If permission granted, initialize and start tutorial
      await _initializeAI();
    } else {
      // If permission denied, still initialize but without AI features
      await _initializeAI();
    }
  }

  Future<void> _initializeAI() async {
    await _aiService.initialize();
    _speakCurrentStep();
  }

  void _speakCurrentStep() {
    if (_currentStep < _steps.length) {
      _aiService.speak(_steps[_currentStep].aiScript);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _speakCurrentStep();
    } else {
      // Onboarding complete - go to main app
      context.go(AppRouter.main);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _speakCurrentStep();
    }
  }

  void _skipToEnd() {
    // Skip tutorial and go to main app
    context.go(AppRouter.main);
  }

  Future<void> _handleQuestion(String question) async {
    await _aiService.stopSpeaking();

    // Handle special action buttons on the last page
    if (question == 'Complete Profile Now') {
      await _aiService.speak(
        'Great! Let\'s complete your profile. This is important for emergency situations.',
      );
      if (mounted) {
        context.go(AppRouter.profile);
      }
      return;
    }

    if (question == 'Explore App') {
      await _aiService.speak(
        'Perfect! You\'re ready to explore RedPing. Stay safe!',
      );
      if (mounted) {
        context.go(AppRouter.main);
      }
      return;
    }

    String answer = '';

    // Simple Q&A logic based on keywords
    if (question.contains('profile') || question.contains('important')) {
      answer =
          'Your profile is critical because when rescuers arrive, they need to know your medical history immediately. '
          'If you\'re unconscious, they need to know your blood type, allergies, and conditions. '
          'This information can be the difference between life and death.';
    } else if (question.contains('crash detection')) {
      answer =
          'Crash detection uses your phone\'s accelerometer to detect sudden deceleration. '
          'When it detects forces over 15 G\'s, it knows you may have been in an accident. '
          'It gives you 30 seconds to cancel, then automatically sends your location to emergency services.';
    } else if (question.contains('help vs sos') ||
        question.contains('difference')) {
      answer =
          'Use S.O.S for life-threatening emergencies: crashes, falls, heart attacks, violence. '
          'Use Help Request for urgent but not life-threatening: lost pet, car breakdown, need directions. '
          'S.O.S goes to emergency services. Help goes to community volunteers.';
    } else if (question.contains('voice command') ||
        question.contains('enable voice')) {
      answer =
          'To enable voice commands, go to Settings, then enable Phone A.I Integration. '
          'You can then use: Hey Google activate RedPing S.O.S, or Hey Siri send RedPing help request. '
          'Works hands-free even when the app is closed.';
    } else if (question.contains('categories')) {
      answer =
          'Help categories include: Medical Emergency, Vehicle Issue, Lost Pet, Hiking Emergency, '
          'Maritime Emergency, Lost Person, Safety Threat, Natural Disaster, and Custom Help. '
          'Each category has specific subcategories for accurate assistance.';
    } else {
      answer =
          'I\'m not sure about that. You can ask me about: profile setup, crash detection, '
          'voice commands, or the difference between S.O.S and help requests.';
    }

    await _aiService.speak(answer);
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _userQuestion = 'Listening...';
    });

    await _aiService.listenForCommand(
      onResult: (text) {
        setState(() {
          _userQuestion = text;
        });
      },
      onError: () {
        setState(() {
          _isListening = false;
        });
      },
    );

    setState(() {
      _isListening = false;
    });

    if (_userQuestion.isNotEmpty && _userQuestion != 'Listening...') {
      await _handleQuestion(_userQuestion);
    }
  }

  @override
  void dispose() {
    _aiService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Light background for better readability
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(step.color),
            ),

            // Skip button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _aiService.stopSpeaking,
                    icon: const Icon(Icons.volume_off),
                    label: const Text('Mute'),
                  ),
                  TextButton(onPressed: _skipToEnd, child: const Text('Skip')),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.icon, size: 64, color: step.color),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: step.color,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // AI Script (shown as text with better contrast)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: step.color.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: step.color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.psychology, color: step.color, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step.aiScript,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Question buttons
                    if (step.actionButtons.isNotEmpty) ...[
                      const Text(
                        'Ask me:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: step.actionButtons.map((question) {
                          return ActionChip(
                            label: Text(question),
                            onPressed: () => _handleQuestion(question),
                            avatar: const Icon(Icons.help_outline, size: 18),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Voice input button
                    if (_aiService.voiceCommandsEnabled)
                      ElevatedButton.icon(
                        onPressed: _isListening ? null : _startListening,
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        label: Text(
                          _isListening ? 'Listening...' : 'Ask a Question',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),

                    if (_userQuestion.isNotEmpty &&
                        _userQuestion != 'Listening...')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'You asked: "$_userQuestion"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final String aiScript;
  final List<String> actionButtons;

  OnboardingStep({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.aiScript,
    required this.actionButtons,
  });
}
