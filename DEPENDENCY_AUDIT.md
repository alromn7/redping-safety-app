# RedPing Dependency Audit & Dynamic Loading Strategy (2025-11-23)

## 1. Objectives
Reduce launch time, memory footprint, and APK/App Bundle size by:
1. Pruning unused / low-value dependencies.
2. Converting feature-specific libraries to lazy (deferred) loading.
3. Consolidating overlapping functionality.
4. Ensuring heavy services initialize only when their feature is actually used.

## 2. High-Level Classification

| Category | Libraries | Rationale |
|----------|-----------|-----------|
| Core Runtime (retain, early init) | `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_messaging`, `flutter_local_notifications`, `hive`, `hive_flutter`, `shared_preferences`, `path_provider`, `permission_handler`, `geolocator`, `go_router`, `flutter_riverpod` | Fundamental for auth, data, navigation, persistence, permissions, location. |
| Common Utility (keep, lazy init where possible) | `http`, `crypto`, `encrypt`, `uuid`, `intl`, `logger`, `timeago`, `equatable` | Lightweight, widely used; keep standard imports. |
| Feature-Specific LARGE (defer) | `flutter_stripe`, `google_generative_ai`, `mobile_scanner`, `image_picker`, `web_socket_channel` (chat), `cloud_functions` | Not needed at cold start; can be deferred or gated by use-case. |
| Sensory/Device (conditional) | `sensors_plus`, `battery_plus`, `device_info_plus`, `vibration` | Initialize only when monitoring or diagnostics triggered. |
| Connectivity / Env (lazy) | `connectivity_plus` | Defer until first network status check. |
| Optional UX / Convenience | `share_plus`, `quick_actions`, `android_intent_plus`, `file_picker`, `google_sign_in` | Some flows optional; gate behind user action. |

## 3. Observed Usage Density (Sample)
(131 import occurrences scanned; Firestore & Auth dominate.) Feature-specific libs appear only in targeted service or page files (e.g., `mobile_scanner` only in QR widget, `flutter_stripe` only in payment services, AI libs only in AI assistant service).

## 4. Dynamic / Deferred Loading Candidates

| Library | Current Usage | Strategy | Notes |
|---------|---------------|----------|-------|
| `flutter_stripe` | Payment flows only (`stripe_payment_service.dart`, `stripe_initializer.dart`) | Deferred import + on-demand environment setup | Gate with paywall navigation. |
| `google_generative_ai` | `ai_assistant_service.dart` | Deferred import when AI chat opened | Avoid loading large models early (native bridging minimal, but Dart code large). |
| `mobile_scanner` | `qr_scanner_widget.dart` | Deferred import on QR scan screen push | Camera permission request moved post-load. |
| `image_picker` | Several attachment pages | Local wrapper with runtime `loadLibrary()` before pick | Consolidate multiple occurrences behind single service. |
| `cloud_functions` | SOS signing + callable client | Replace with direct HTTPS if minimal functions OR defer until SOS advanced flow | Could remove if endpoints replicate functionality. |
| `web_socket_channel` | Chat & realtime communication service | Lazy connect only once user enters chat feature | Keep HTTP polling fallback. |
| `share_plus` | Diagnostics share | Inline wrapper; import only when share sheet triggered | Defer; small gain. |
| `quick_actions` | Startup quick action registration | Move registration after initial screen render | Slight launch improvement. |
| `sensors_plus` / `battery_plus` | Multiple detection services | Lazy service initialization triggered by enabling detection mode | Avoid early sensor stream subscription. |
| `flutter_stripe` native | Heavy | Ensure `Stripe.publishableKey` set only when payment needed | Reduces early method channel chatter. |

## 5. Deferred Import Pattern (Example)

```dart
// Before:
import 'package:mobile_scanner/mobile_scanner.dart';

// After (qr_scanner_page.dart):
import 'package:mobile_scanner/mobile_scanner.dart' deferred as mobile_scanner;

class QrScannerPage extends StatefulWidget { /* ... */ }

class _QrScannerPageState extends State<QrScannerPage> {
  bool _libLoaded = false;
  Future<void> _ensureLib() async {
    if (!_libLoaded) {
      await mobile_scanner.loadLibrary();
      _libLoaded = true;
    }
  }
  @override
  void initState() {
    super.initState();
    _ensureLib(); // Or delay until user taps “Start Scan”.
  }
  Widget build(BuildContext context) {
    if (!_libLoaded) return const CircularProgressIndicator();
    return mobile_scanner.MobileScanner(/* params */);
  }
}
```

## 6. Lazy Service Initialization Template

```dart
class ServiceRegistry {
  static StripePaymentService? _stripe;
  static Future<StripePaymentService> stripe() async {
    if (_stripe != null) return _stripe!;
    // Deferred import ensures code split
    await stripe_lib.loadLibrary();
    _stripe = StripePaymentService();
    await _stripe!.initialize();
    return _stripe!;
  }
}
```

## 7. Potential Removals / Consolidations

| Candidate | Replacement / Justification | Action |
|-----------|------------------------------|--------|
| `cloud_functions` | Use signed REST endpoints via `http` and Firestore security rules | Measure call frequency; if low, migrate and remove. |
| `quick_actions` | Could be postponed; negligible size but startup cost | Defer registration after home screen mounts. |
| `share_plus` | Optional UX; retain due to low overhead | Keep, but defer import. |
| `device_info_plus` | If only basic model info needed, use platform channel once | Evaluate usage breadth; maybe keep. |
| `battery_plus` | If battery only requested in sensor monitoring flows | Lazy initialize; no removal. |

## 8. Measurement Plan
1. Baseline: Record cold start time & memory before changes.
2. Implement deferred imports for: `mobile_scanner`, `google_generative_ai`, `flutter_stripe`, `image_picker`.
3. Re-measure launch time & memory (expect minor improvement; biggest gain is reduced initial code loading / JIT warm-up even in AOT due to smaller snapshot segment).
4. Consider migrating `cloud_functions`.
5. Build App Bundle; inspect size breakdown with `bundletool dump manifest` & `analyze`.

## 9. Risks & Caveats
- Deferred imports do not shrink native libraries significantly—large native components (Stripe, camera) mostly remain—but can reduce initial VM image segment and method invocation at startup.
- Additional async boundaries: first-use latency (show small loading indicator).
- Ensure error handling for load failures (network offline when first invoking payment? Only relevant if remote key fetch occurs at same time).

## 10. Recommended Execution Order
1. Stripe deferred import & lazy service registry.
2. Mobile Scanner deferred import (QR feature).
3. Image Picker consolidated wrapper + deferred.
4. AI Generative service deferred.
5. Cloud Functions migration (if viable).
6. Quick Actions registration delay.

## 11. Sample Cloud Functions Migration (Callable -> REST)

```dart
// Replace cloud_functions usage:
Future<Map<String, dynamic>> callSignedEndpoint(String path, Map<String, dynamic> body) async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  final resp = await http.post(
    Uri.parse('https://example.com/api/$path'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
  throw Exception('Endpoint $path failed ${resp.statusCode}: ${resp.body}');
}
```

## 12. Tracking & Regression Prevention
Add a small `DependencyLoadMetrics` service that logs timestamp when each deferred library first loads; export to Firestore for analysis to confirm deferred usage patterns align with expectations.

```dart
class DependencyLoadMetrics {
  static final Map<String, DateTime> _loaded = {};
  static void markLoaded(String name) { _loaded[name] = DateTime.now(); }
  static Map<String, String> asIso() => _loaded.map((k,v)=>MapEntry(k,v.toIso8601String()));
}
```

## 13. Summary
Strategic deferred imports and lazy service initialization can slightly reduce initial binary segment load and memory; the largest remaining size drivers are Firebase (core + auth + messaging) and Stripe. Functional removals (e.g., cloud_functions migration) and image optimization (WebP) provide incremental gains. Combining these steps prepares the project for future modularization (e.g., platform-specific split using Play Feature Delivery).
