import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// Service to send passwordless sign-in (magic link) invitations to emails.
class MagicLinkService {
  static final MagicLinkService _instance = MagicLinkService._internal();
  factory MagicLinkService() => _instance;
  MagicLinkService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends a Firebase Email Link sign-in invitation to the given email.
  /// Returns true if the email was accepted for delivery.
  Future<bool> sendMagicLinkToEmail(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw ArgumentError('Email is required for magic link');
      }

      final settings = ActionCodeSettings(
        url: Env.magicLinkContinueUrl,
        handleCodeInApp: true,
        androidPackageName: Env.androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: Env.iosBundleId,
      );

      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: settings,
      );

      debugPrint('MagicLinkService: Sent email link to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('MagicLinkService: Firebase error sending link - ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('MagicLinkService: Error sending link - $e');
      return false;
    }
  }
}
