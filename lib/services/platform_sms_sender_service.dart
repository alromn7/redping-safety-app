import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/logging/app_logger.dart';

/// Platform SMS Sender Service
/// Sends SMS automatically without user interaction
/// Uses native Android SMS API or cloud SMS service
class PlatformSMSSenderService {
  static final PlatformSMSSenderService _instance =
      PlatformSMSSenderService._internal();
  factory PlatformSMSSenderService() => _instance;
  PlatformSMSSenderService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.redping.redping/sms',
  );

  // Cloud SMS service configuration
  // Update with your Firebase project details after deploying functions
  // Format: https://REGION-PROJECT_ID.cloudfunctions.net/sendSMS
  // Example: https://us-central1-redping-a2e37.cloudfunctions.net/sendSMS
  static const String _smsServiceUrl =
      'https://us-central1-redping-a2e37.cloudfunctions.net/sendSMS';

  /// Send SMS via platform native API (Android)
  Future<bool> sendSMSNative({
    required String phoneNumber,
    required String message,
  }) async {
    if (!Platform.isAndroid) {
      AppLogger.w('Native SMS only supported on Android', tag: 'PlatformSMS');
      return false;
    }

    try {
      AppLogger.i(
        'Sending SMS via native Android API to $phoneNumber',
        tag: 'PlatformSMS',
      );

      final result = await _channel.invokeMethod('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': message,
      });

      if (result == true) {
        AppLogger.i('SMS sent successfully via native API', tag: 'PlatformSMS');
        return true;
      } else {
        AppLogger.w('SMS send failed via native API', tag: 'PlatformSMS');
        return false;
      }
    } on PlatformException catch (e) {
      AppLogger.e(
        'Platform exception sending SMS',
        tag: 'PlatformSMS',
        error: e,
      );
      return false;
    } catch (e) {
      AppLogger.e('Error sending SMS via native', tag: 'PlatformSMS', error: e);
      return false;
    }
  }

  /// Send SMS via cloud service (Firebase Cloud Function + Twilio/AWS SNS)
  Future<bool> sendSMSCloud({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      AppLogger.i(
        'Sending SMS via cloud service to $phoneNumber',
        tag: 'PlatformSMS',
      );

      final response = await http
          .post(
            Uri.parse(_smsServiceUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phoneNumber': phoneNumber,
              'message': message,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('SMS service request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.i(
          'SMS sent successfully via cloud: ${data['messageId']}',
          tag: 'PlatformSMS',
        );
        return true;
      } else {
        AppLogger.w(
          'SMS cloud send failed: ${response.statusCode} - ${response.body}',
          tag: 'PlatformSMS',
        );
        return false;
      }
    } catch (e) {
      AppLogger.e('Error sending SMS via cloud', tag: 'PlatformSMS', error: e);
      return false;
    }
  }

  /// Send SMS with automatic fallback (tries native first, then cloud)
  Future<bool> sendSMSWithFallback({
    required String phoneNumber,
    required String message,
  }) async {
    // Try native first (faster, no cost)
    if (Platform.isAndroid) {
      final nativeSuccess = await sendSMSNative(
        phoneNumber: phoneNumber,
        message: message,
      );
      if (nativeSuccess) return true;

      AppLogger.i(
        'Native SMS failed, trying cloud fallback',
        tag: 'PlatformSMS',
      );
    }

    // Fallback to cloud service
    return await sendSMSCloud(phoneNumber: phoneNumber, message: message);
  }

  /// Send SMS to multiple recipients
  Future<List<bool>> sendSMSBulk({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final results = <bool>[];

    for (final phoneNumber in phoneNumbers) {
      final success = await sendSMSWithFallback(
        phoneNumber: phoneNumber,
        message: message,
      );
      results.add(success);

      // Small delay between messages to avoid rate limiting
      if (phoneNumbers.length > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    final successCount = results.where((r) => r).length;
    AppLogger.i(
      'Bulk SMS: $successCount/${phoneNumbers.length} sent successfully',
      tag: 'PlatformSMS',
    );

    return results;
  }

  /// Check if native SMS permission is granted (Android only)
  Future<bool> hasSMSPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('hasSMSPermission');
      return result == true;
    } catch (e) {
      AppLogger.w(
        'Error checking SMS permission',
        tag: 'PlatformSMS',
        error: e,
      );
      return false;
    }
  }

  /// Request SMS permission (Android only)
  Future<bool> requestSMSPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('requestSMSPermission');
      return result == true;
    } catch (e) {
      AppLogger.e(
        'Error requesting SMS permission',
        tag: 'PlatformSMS',
        error: e,
      );
      return false;
    }
  }
}
