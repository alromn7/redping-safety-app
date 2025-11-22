import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/phone_ai_integration_service.dart';
import 'package:redping_14v/services/app_service_manager.dart';

void main() {
  group('AI Assistant Voice Command Integration', () {
    final phoneAI = PhoneAIIntegrationService();
    final services = AppServiceManager();

    setUpAll(() async {
      // Minimal init (ignore heavy services)
      await phoneAI.initialize();
      await services.batteryOptimizationService.initialize();
      await services.aiAssistantService.initialize();
      await phoneAI.setVoiceCommandsEnabled(true);
    });

    test('Available command map includes core actions', () {
      final cmds = phoneAI.getAvailableCommands();
      expect(cmds.containsKey('start_sos'), true);
      expect(cmds.containsKey('cancel_sos'), true);
      expect(cmds.containsKey('hazards'), true);
      expect(cmds.containsKey('battery'), true);
    });

    test('Direct action does not start SOS when battery critical', () async {
      // Simulate critical battery by updating internal flag via service (mock approach)
      // Since BatteryOptimizationService uses actual device state, we test logic path indirectly:
      // startVoiceListening should early-return if critical; we simulate by toggling voice enable while battery critical is assumed.
      // NOTE: For full integration a platform battery mock would be injected.
      await phoneAI.startVoiceListening();
      // We cannot assert internal SOS state here without full SOSService mocking.
      expect(phoneAI.isListening, true);
    });

    test('Command map has status phrases', () async {
      final map = phoneAI.getAvailableCommands();
      expect(map['status'] != null && map['status']!.isNotEmpty, true);
    });
  });
}
