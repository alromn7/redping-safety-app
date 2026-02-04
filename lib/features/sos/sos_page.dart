import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/entitlements/feature_gate.dart';

/// Example SOS page demonstrating feature gating for 'feature_sos_call'.
class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FeatureGate(
          featureId: 'feature_sos_call',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOS Call',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Trigger an emergency SOS call to your configured contacts.',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Integrate actual SOS action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SOS triggered')),
                  );
                },
                child: const Text('Trigger SOS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
