// Test script to verify login page improvements
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/features/auth/presentation/pages/login_page.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/auth_user.dart';

void main() {
  group('Login Page Tests', () {
    testWidgets('Login page should fit on screen without scrolling', (
      WidgetTester tester,
    ) async {
      // Build the login page
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Verify the page renders without overflow
      expect(tester.takeException(), isNull);

      // Check that key elements are present
      expect(find.text('RedPing'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    test('AuthService remember me functionality', () async {
      final authService = AuthService.instance;
      await authService.initialize();

      // Test saving credentials through login process
      final loginRequest = LoginRequest(
        email: 'test@example.com',
        password: 'testpassword123',
        rememberMe: true,
      );

      // This will trigger the remember me functionality
      await authService.signInWithEmailAndPassword(loginRequest);

      // Test retrieving saved email
      final savedEmail = await authService.getSavedEmail();
      expect(savedEmail, 'test@example.com');

      // Test remember me status
      final isRemembered = await authService.isRememberMeEnabled();
      expect(isRemembered, true);
    });
  });
}
