import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/check_in_service.dart';
import '../../core/entitlements/entitlement_service.dart';
import '../../models/check_in_request.dart';
import '../../core/theme/app_theme.dart';

class CheckInRequestDialog extends StatefulWidget {
  final CheckInRequest request;
  const CheckInRequestDialog({super.key, required this.request});

  @override
  State<CheckInRequestDialog> createState() => _CheckInRequestDialogState();
}

class _CheckInRequestDialogState extends State<CheckInRequestDialog> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _handle(bool accept) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      if (!accept) {
        await CheckInService.instance.respond(
          requestId: widget.request.id,
          accept: false,
        );
        if (mounted) Navigator.pop(context, false);
        return;
      }
      // Ensure location permission
      final perm = await Geolocator.checkPermission();
      LocationPermission finalPerm = perm;
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        finalPerm = await Geolocator.requestPermission();
      }
      if (finalPerm == LocationPermission.denied ||
          finalPerm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        // GPS-first to avoid Wi‑Fi accuracy prompts
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      await CheckInService.instance.respond(
        requestId: widget.request.id,
        accept: true,
        location: CheckInLocationSnapshot(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
          capturedAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Check-In Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.request.reason?.isNotEmpty == true
                ? widget.request.reason!
                : 'A family member is requesting your current location.',
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
            ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => _handle(false),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _handle(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.safeGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Share Location'),
        ),
      ],
    );
  }
}
