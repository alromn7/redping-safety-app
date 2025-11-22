import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:redping_14v/services/google_cloud_api_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Protected Ping', () {
    testWidgets('validates HMAC + Integrity on-device', (tester) async {
      final api = GoogleCloudApiService();
      await api.initialize();

      // This test requires a real Android device (Play Integrity) or iOS device
      // with non-jailbroken status when iOS runtime gating is enabled.
      if (Platform.isAndroid || Platform.isIOS) {
        final ok = await api.protectedPing();
        expect(
          ok,
          isTrue,
          reason: 'Protected ping should succeed on a compliant device',
        );
      } else {
        // Not supported on desktop/web environments
        expect(true, isTrue);
      }
    });
  });
}
