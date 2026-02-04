import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redping_14v/services/auth_service.dart';
import 'package:redping_14v/models/auth_user.dart';
import 'test_utils/test_environment.dart';

/// Test for login bypass functionality
///
/// This test validates:
/// 1. Login tracking increments correctly
/// 2. Bypass is rejected for < 3 logins
/// 3. Bypass is approved for 3+ logins within 7 days
/// 4. Bypass is rejected after 7 days (weekly re-auth)
/// 5. Logout resets tracking
void main() {
  group('Login Bypass Tests', () {
    late AuthService authService;

    setUp(() async {
      await TestEnvironment.setUp();
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({});
      authService = AuthService.instance;
      authService.enableInMemoryAuthMock();
      await authService.initialize();
    });

    tearDown(() async {
      await TestEnvironment.tearDown();
    });

    test('First login should not bypass', () async {
      // Simulate first successful login
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      await authService.signInWithEmailAndPassword(request);

      // Check bypass - should be rejected (only 1 login)
      final canBypass = await authService.shouldBypassLogin();
      expect(canBypass, false);
    });

    test('Second login should not bypass', () async {
      // Simulate 2 logins
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      await authService.signInWithEmailAndPassword(request);
      await authService.signOut();
      await authService.signInWithEmailAndPassword(request);

      // Check bypass - should be rejected (only 2 logins)
      final canBypass = await authService.shouldBypassLogin();
      expect(canBypass, false);
    });

    test('Third login should enable bypass', () async {
      // Note: This test needs manual verification since signOut() resets tracking
      // In real usage, app restart preserves login count
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      // Manually set up 3 login scenario
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('login_success_count', 3);
      await prefs.setString(
        'last_login_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('device_id', 'test_device_123');

      // Login to authenticate
      await authService.signInWithEmailAndPassword(request);

      // Check bypass - should be approved (3+ logins, <7 days)
      final canBypass = await authService.shouldBypassLogin();
      expect(canBypass, true);
    });

    test('Bypass rejected after 7 days', () async {
      // Set up scenario: 3+ logins but 8 days ago
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('login_success_count', 5);
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(days: 8))
          .toIso8601String();
      await prefs.setString('last_login_timestamp', oldTimestamp);
      await prefs.setString('device_id', 'test_device_123');

      // Seed a saved user so bypass logic can evaluate without a fresh login.
      final user = AuthUser(
        id: 'test_uid',
        email: 'test@example.com',
        displayName: 'Test',
      );
      await prefs.setString('auth_user', jsonEncode(user.toJson()));

      // Check bypass - should be rejected (>7 days)
      final canBypass = await authService.shouldBypassLogin();
      expect(canBypass, false);
    });

    test('Logout resets login tracking', () async {
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      // Set up scenario with 3+ logins
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('login_success_count', 3);
      await prefs.setString(
        'last_login_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('device_id', 'test_device_123');

      // Login to authenticate
      await authService.signInWithEmailAndPassword(request);

      // Verify bypass is enabled
      var canBypass = await authService.shouldBypassLogin();
      expect(canBypass, true);

      // Sign out
      await authService.signOut();

      // Verify tracking is reset
      final loginCount = prefs.getInt('login_success_count');
      expect(loginCount, null);
    });

    test('Bypass requires authentication', () async {
      // Check bypass without authentication
      final canBypass = await authService.shouldBypassLogin();
      expect(canBypass, false);
    });
  });

  group('Login Count Tracking', () {
    test('Login count increments on successful login', () async {
      await TestEnvironment.setUp();
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService.instance;
      authService.enableInMemoryAuthMock();
      await authService.initialize();

      final request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      // First login
      await authService.signInWithEmailAndPassword(request);
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('login_success_count'), 1);

      // Note: Logout resets count in this implementation
      // In production, app restart preserves count while signOut() intentionally resets it
      await TestEnvironment.tearDown();
    });

    test('Signup counts as first login', () async {
      await TestEnvironment.setUp();
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService.instance;
      authService.enableInMemoryAuthMock();
      await authService.initialize();

      final request = SignupRequest(
        email: 'newuser@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      await authService.signUpWithEmailAndPassword(request);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('login_success_count'), 1);

      await TestEnvironment.tearDown();
    });
  });
}
