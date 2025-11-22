import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/app_service_manager.dart';
import '../models/auth_user.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final res = await FirebaseAuth.instance.signInWithCredential(credential);
      final fb = res.user;
      if (fb != null) {
        final adopted = AuthUser(
          id: fb.uid,
          email: fb.email ?? '',
          displayName: fb.displayName ?? (fb.email?.split('@').first ?? 'User'),
          photoUrl: fb.photoURL,
          phoneNumber: fb.phoneNumber,
          isEmailVerified: fb.emailVerified,
          createdAt: fb.metadata.creationTime ?? DateTime.now(),
          lastSignIn: fb.metadata.lastSignInTime ?? DateTime.now(),
        );
        await AuthService.instance.adoptExternalUser(adopted);
        try {
          await AppServiceManager().profileService.refreshFromAuth();
        } catch (_) {}
      }
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in with Google!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _signInWithGoogle(context),
    );
  }
}
