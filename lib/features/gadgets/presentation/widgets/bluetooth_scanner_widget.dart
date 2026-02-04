// Bluetooth scanner widget removed in Phase 1 APK optimization
// This is a stub to satisfy imports

import 'package:flutter/material.dart';

class BluetoothScannerWidget extends StatelessWidget {
  final Function(dynamic, String)? onDeviceSelected;

  const BluetoothScannerWidget({super.key, this.onDeviceSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Bluetooth Scanning Disabled',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This feature has been temporarily disabled for app optimization.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
