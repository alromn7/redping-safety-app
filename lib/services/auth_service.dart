import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../security/secure_storage_service.dart';
import '../models/auth_user.dart';
import '../core/logging/app_logger.dart';

/// Authentication service for managing user login/signup
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  // Stream controllers for authentication state
  final StreamController<AuthUser> _userController =
      StreamController<AuthUser>.broadcast();
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  // Current user and status
  AuthUser _currentUser = AuthUser.empty;
  AuthStatus _status = AuthStatus.unknown;

  // Callbacks
  void Function(AuthUser user)? _onUserSignedIn;
  void Function()? _onUserSignedOut;

  // Test-only mode: bypass FirebaseAuth calls in unit tests.
  bool _useInMemoryAuth = false;
  AuthUser Function({required String email, String? displayName})?
  _inMemoryUserFactory;

  /// Enable in-memory auth for tests where Firebase isn't available.
  ///
  /// This is intended for `flutter test` only and should not be used in
  /// production flows.
  void enableInMemoryAuthMock({
    AuthUser Function({required String email, String? displayName})? userFactory,
  }) {
    if (kReleaseMode) return;
    _useInMemoryAuth = true;
    _inMemoryUserFactory = userFactory;
  }

  // Storage keys
  static const String _userKey = 'auth_user';
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  // Login bypass tracking keys
  static const String _loginCountKey = 'login_success_count';
  static const String _lastLoginTimestampKey = 'last_login_timestamp';
  static const String _firstLoginTimestampKey = 'first_login_timestamp';
  static const String _deviceIdKey = 'device_id';

  // Login bypass constants
  static const int _requiredLoginsForBypass = 3;
  static const int _weeklyReauthDays = 7;

  /// Initialize the authentication service
  Future<void> initialize() async {
    debugPrint('AuthService: Initializing...');

    try {
      _status = AuthStatus.loading;
      _statusController.add(_status);

      // Load saved user from storage (token from secure storage)
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      // Prefer secure storage
      await SecureStorageService.instance.initialize();
      String? token = await SecureStorageService.instance.read(key: _tokenKey);
      // Migrate legacy token from SharedPreferences if found
      token ??= prefs.getString(_tokenKey);
      if (token != null) {
        await SecureStorageService.instance.write(key: _tokenKey, value: token);
        await prefs.remove(_tokenKey);
      }

      if (userJson != null && token != null) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = AuthUser.fromJson(userData);
          _status = AuthStatus.authenticated;
          _userController.add(_currentUser);
          debugPrint(
            'AuthService: Restored user session - ${_currentUser.email}',
          );

          // Set user ID for Crashlytics
          try {
            await AppLogger.setUserId(_currentUser.id);
          } catch (_) {}
        } catch (e) {
          debugPrint('AuthService: Failed to restore user session - $e');
          await _clearStoredUser();
          _currentUser = AuthUser.empty;
          _status = AuthStatus.unauthenticated;
        }
      } else {
        debugPrint('AuthService: No saved user session found');
        _status = AuthStatus.unauthenticated;
      }

      // If we didn't restore from local storage, but FirebaseAuth already has
      // a persisted session (anonymous or non-anonymous), mirror it so the
      // rest of the app can rely on AuthService.currentUser.id.
      if (_status != AuthStatus.authenticated && !_useInMemoryAuth) {
        try {
          final fbUser = firebase_auth.FirebaseAuth.instance.currentUser;
          if (fbUser != null) {
            final user = _createAuthUserFromFirebase(fbUser);
            _currentUser = user;
            _status = AuthStatus.authenticated;
            _userController.add(_currentUser);
            debugPrint(
              'AuthService: Mirrored FirebaseAuth session - ${user.id} (anonymous: ${fbUser.isAnonymous})',
            );

            // Persist mirrored user locally so other app flows remain stable
            // across restarts (token is app-local, not a Firebase token).
            try {
              await _saveUser(user, _generateToken());
            } catch (_) {}

            // Crashlytics / logging correlation (best-effort)
            try {
              await AppLogger.setUserId(user.id);
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('AuthService: FirebaseAuth mirror skipped - $e');
        }
      }

      _statusController.add(_status);
      debugPrint('AuthService: Initialized successfully');
    } catch (e) {
      debugPrint('AuthService: Error during initialization - $e');
      _status = AuthStatus.unauthenticated;
      _statusController.add(_status);
    }
  }

  /// Sign in with email and password
  Future<AuthUser> signInWithEmailAndPassword(LoginRequest request) async {
    debugPrint('AuthService: Signing in user - ${request.email}');

    try {
      _status = AuthStatus.loading;
      _statusController.add(_status);

      if (_useInMemoryAuth) {
        final user =
            _inMemoryUserFactory?.call(email: request.email) ??
            AuthUser(
              id: 'test_${request.email.hashCode}',
              email: request.email,
              displayName: request.email.split('@').first,
              phoneNumber: '',
              photoUrl: '',
              isEmailVerified: true,
              createdAt: DateTime.now(),
              lastSignIn: DateTime.now(),
            );

        await _saveUser(user, _generateToken());
        await _handleRememberMe(request);
        await _trackSuccessfulLogin();

        _currentUser = user;
        _status = AuthStatus.authenticated;
        _userController.add(_currentUser);
        _statusController.add(_status);
        _onUserSignedIn?.call(user);
        debugPrint('AuthService: In-memory sign in success - ${user.email}');
        return user;
      }

      // Sign in with Firebase Authentication
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      // Create AuthUser from Firebase user
      final user = _createAuthUserFromFirebase(userCredential.user!);

      // Save user to storage
      await _saveUser(user, _generateToken());

      // Handle remember me functionality
      await _handleRememberMe(request);

      // Track successful login for bypass logic
      await _trackSuccessfulLogin();

      _currentUser = user;
      _status = AuthStatus.authenticated;

      _userController.add(_currentUser);
      _statusController.add(_status);

      // Trigger callback
      _onUserSignedIn?.call(user);

      // Crashlytics: set user id for correlation in production
      try {
        await AppLogger.setUserId(user.id);
        AppLogger.i('User signed in: ${user.id}', tag: 'AuthService');
      } catch (_) {}

      debugPrint('AuthService: User signed in successfully - ${user.email}');
      return user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _statusController.add(_status);
      debugPrint('AuthService: Sign in failed - $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthUser> signUpWithEmailAndPassword(SignupRequest request) async {
    debugPrint('AuthService: Signing up user - ${request.email}');

    try {
      _status = AuthStatus.loading;
      _statusController.add(_status);

      if (_useInMemoryAuth) {
        final user =
            _inMemoryUserFactory?.call(
              email: request.email,
              displayName: request.displayName,
            ) ??
            AuthUser(
              id: 'test_${request.email.hashCode}',
              email: request.email,
              displayName: request.displayName,
              phoneNumber: '',
              photoUrl: '',
              isEmailVerified: true,
              createdAt: DateTime.now(),
              lastSignIn: DateTime.now(),
            );

        await _saveUser(user, _generateToken());
        await _trackSuccessfulLogin();

        _currentUser = user;
        _status = AuthStatus.authenticated;
        _userController.add(_currentUser);
        _statusController.add(_status);
        _onUserSignedIn?.call(user);
        debugPrint('AuthService: In-memory signup success - ${user.email}');
        return user;
      }

      // Create user with Firebase Authentication
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      // Update Firebase user display name
      await userCredential.user!.updateDisplayName(request.displayName);

      // Send Firebase verification email (built-in)
      debugPrint('AuthService: Sending verification email to ${request.email}');
      try {
        await userCredential.user!.sendEmailVerification();
        debugPrint(
          'AuthService: ✅ Verification email sent successfully to ${request.email}',
        );
        debugPrint('AuthService: Email should arrive within 1-5 minutes');
        debugPrint('AuthService: Check spam folder if not received');
      } catch (e) {
        debugPrint('AuthService: ❌ FAILED to send verification email - $e');
        debugPrint('AuthService: Error type: ${e.runtimeType}');
        if (e is firebase_auth.FirebaseAuthException) {
          debugPrint('AuthService: Firebase error code: ${e.code}');
          debugPrint('AuthService: Firebase error message: ${e.message}');
        }
        // Don't fail signup if email fails, but log it clearly
      }

      // Create AuthUser from Firebase user
      final user = _createAuthUserFromFirebase(userCredential.user!);

      // Save user to storage
      await _saveUser(user, _generateToken());

      // Track successful signup as first login
      await _trackSuccessfulLogin();

      _currentUser = user;
      _status = AuthStatus.authenticated;

      _userController.add(_currentUser);
      _statusController.add(_status);

      // Trigger callback
      _onUserSignedIn?.call(user);

      // Crashlytics: set user id for correlation in production
      try {
        await AppLogger.setUserId(user.id);
        AppLogger.i('User signed up: ${user.id}', tag: 'AuthService');
      } catch (_) {}

      debugPrint('AuthService: User signed up successfully - ${user.email}');
      return user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _statusController.add(_status);
      debugPrint('AuthService: Sign up failed - $e');
      rethrow;
    }
  }

  /// Check if current user's email is verified
  bool get isEmailVerified {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser?.emailVerified ?? false;
  }

  /// Delete current user account permanently
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No user signed in');
      }

      final email = firebaseUser.email;
      debugPrint('AuthService: Deleting account for $email');

      // Delete Firebase Auth account
      await firebaseUser.delete();

      // Clear local storage
      await _clearStoredUser();

      // Reset state
      _currentUser = AuthUser.empty;
      _status = AuthStatus.unauthenticated;
      _userController.add(_currentUser);
      _statusController.add(_status);

      debugPrint('AuthService: Account deleted successfully - $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          'Please sign in again before deleting your account',
        );
      }
      debugPrint('AuthService: Failed to delete account - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Failed to delete account - $e');
      rethrow;
    }
  }

  /// Resend verification email to current user
  Future<void> resendVerificationEmail() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No user signed in');
      }

      if (firebaseUser.emailVerified) {
        throw const AuthException('Email is already verified');
      }

      await firebaseUser.sendEmailVerification();
      debugPrint(
        'AuthService: Verification email resent to ${firebaseUser.email}',
      );
    } catch (e) {
      debugPrint('AuthService: Failed to resend verification email - $e');
      rethrow;
    }
  }

  /// Reload current user to check email verification status
  Future<void> reloadUser() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (updatedUser != null) {
          _currentUser = _createAuthUserFromFirebase(updatedUser);
          _userController.add(_currentUser);
          debugPrint(
            'AuthService: User reloaded - emailVerified: ${updatedUser.emailVerified}',
          );
        }
      }
    } catch (e) {
      debugPrint('AuthService: Failed to reload user - $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    debugPrint('AuthService: Signing out user');

    // Sign out from Firebase
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('AuthService: Firebase sign out error - $e');
    }

    try {
      // Clear stored user data
      await _clearStoredUser();

      // Reset login tracking when user signs out
      await _resetLoginTracking();

      _currentUser = AuthUser.empty;
      _status = AuthStatus.unauthenticated;

      _userController.add(_currentUser);
      _statusController.add(_status);

      // Trigger callback
      _onUserSignedOut?.call();

      // Crashlytics: clear or reset user identifier
      try {
        await AppLogger.setUserId('anonymous');
        AppLogger.i('User signed out', tag: 'AuthService');
      } catch (_) {}

      debugPrint('AuthService: User signed out successfully');
    } catch (e) {
      debugPrint('AuthService: Error during sign out - $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(PasswordResetRequest request) async {
    debugPrint('AuthService: Sending password reset email to ${request.email}');

    try {
      // Send password reset email via Firebase
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: request.email,
      );

      debugPrint('AuthService: Password reset email sent successfully');
    } catch (e) {
      debugPrint('AuthService: Failed to send password reset email - $e');
      rethrow;
    }
  }

  /// Save user to local storage
  Future<void> _saveUser(AuthUser user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await SecureStorageService.instance.initialize();
    await SecureStorageService.instance.write(key: _tokenKey, value: token);
  }

  /// Clear stored user data
  Future<void> _clearStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await SecureStorageService.instance.initialize();
    await SecureStorageService.instance.delete(key: _tokenKey);
    // Also clear remember me data when user signs out
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_savedEmailKey);
  }

  /// Handle remember me functionality
  Future<void> _handleRememberMe(LoginRequest request) async {
    final prefs = await SharedPreferences.getInstance();

    if (request.rememberMe) {
      // Save email for future logins
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, request.email);
      debugPrint('AuthService: Email saved for future logins');
    } else {
      // Clear saved email if remember me is disabled
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_savedEmailKey);
      debugPrint('AuthService: Remembered email cleared');
    }
  }

  /// Get saved email if remember me was enabled
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe) {
      return prefs.getString(_savedEmailKey);
    }
    return null;
  }

  /// Check if remember me was enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Get or create device ID for this phone
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Generate device ID from device info
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId =
              iosInfo.identifierForVendor ??
              'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        }
        await prefs.setString(_deviceIdKey, deviceId);
        debugPrint('AuthService: Device ID created - $deviceId');
      } catch (e) {
        // Fallback to timestamp-based ID
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_deviceIdKey, deviceId);
        debugPrint('AuthService: Device ID created (fallback) - $deviceId');
      }
    }

    return deviceId;
  }

  /// Track successful login
  Future<void> _trackSuccessfulLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure device ID is set
    await _getDeviceId();

    // Increment login count
    int currentCount = prefs.getInt(_loginCountKey) ?? 0;
    currentCount++;
    await prefs.setInt(_loginCountKey, currentCount);

    // Update timestamp
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_lastLoginTimestampKey, now);

    // Set first login timestamp if not already set
    if (!prefs.containsKey(_firstLoginTimestampKey)) {
      await prefs.setString(_firstLoginTimestampKey, now);
      debugPrint('AuthService: First login tracked at $now');
    }

    debugPrint(
      'AuthService: Login tracked - Count: $currentCount, Timestamp: $now',
    );
  }

  /// Check if user should bypass login screen
  Future<bool> shouldBypassLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check login count - user must have logged in successfully 3+ times
      final loginCount = prefs.getInt(_loginCountKey) ?? 0;
      if (loginCount < _requiredLoginsForBypass) {
        debugPrint(
          'AuthService: Bypass rejected - Only $loginCount logins (need $_requiredLoginsForBypass)',
        );
        return false;
      }

      // Check device ID matches (must be same device)
      final deviceId = await _getDeviceId();
      final storedDeviceId = prefs.getString(_deviceIdKey);
      if (deviceId != storedDeviceId) {
        debugPrint('AuthService: Bypass rejected - Device mismatch');
        return false;
      }

      // Check if saved user exists (must have logged in before)
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        debugPrint('AuthService: Bypass rejected - No saved user found');
        return false;
      }

      // Check weekly re-auth requirement
      final lastLoginStr = prefs.getString(_lastLoginTimestampKey);
      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;

        if (daysSinceLogin >= _weeklyReauthDays) {
          debugPrint(
            'AuthService: Bypass rejected - $daysSinceLogin days since last login (weekly re-auth required)',
          );
          return false;
        }

        debugPrint(
          'AuthService: Bypass approved - $loginCount logins, $daysSinceLogin days since last login',
        );

        // Restore user session from saved data for offline use
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = AuthUser.fromJson(userData);
          _status = AuthStatus.authenticated;
          _userController.add(_currentUser);
          _statusController.add(_status);
          debugPrint(
            'AuthService: User session restored for offline bypass - ${_currentUser.email}',
          );
        } catch (e) {
          debugPrint('AuthService: Failed to restore user for bypass - $e');
          return false;
        }

        return true;
      }

      debugPrint('AuthService: Bypass rejected - No login timestamp found');
      return false;
    } catch (e) {
      debugPrint('AuthService: Error checking bypass eligibility - $e');
      return false;
    }
  }

  /// Reset login tracking (for testing or on logout)
  Future<void> _resetLoginTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginCountKey);
    await prefs.remove(_lastLoginTimestampKey);
    await prefs.remove(_firstLoginTimestampKey);
    // Keep device ID to maintain device identity
    debugPrint('AuthService: Login tracking reset');
  }

  /// Create AuthUser from Firebase user
  AuthUser _createAuthUserFromFirebase(firebase_auth.User firebaseUser) {
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'User',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
      lastSignIn: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  /// Mock password reset implementation
  Future<void> _mockPasswordReset(PasswordResetRequest request) async {
    if (request.email.isEmpty || !request.email.contains('@')) {
      throw const AuthException('Invalid email address');
    }

    // In real implementation, send API request to backend
    debugPrint(
      'AuthService: Mock password reset email sent to ${request.email}',
    );
  }

  /// Generate mock authentication token
  String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'token_$timestamp';
  }

  /// Set callback for user sign in
  void setUserSignedInCallback(void Function(AuthUser user) callback) {
    _onUserSignedIn = callback;
  }

  /// Set callback for user sign out
  void setUserSignedOutCallback(void Function() callback) {
    _onUserSignedOut = callback;
  }

  /// Get current user
  AuthUser get currentUser => _currentUser;

  /// Get current authentication status
  AuthStatus get status => _status;

  /// Stream of user changes
  Stream<AuthUser> get userStream => _userController.stream;

  /// Stream of authentication status changes
  Stream<AuthStatus> get statusStream => _statusController.stream;

  /// Check if user is authenticated
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Adopt an externally authenticated user (e.g., Firebase Google Sign-In)
  Future<void> adoptExternalUser(
    AuthUser user, {
    bool rememberEmail = true,
  }) async {
    try {
      _status = AuthStatus.loading;
      _statusController.add(_status);

      // Persist user locally
      await _saveUser(user, _generateToken());

      // Optionally remember email for convenience
      if (rememberEmail && user.email.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_savedEmailKey, user.email);
      }

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _userController.add(_currentUser);
      _statusController.add(_status);

      // Track successful external login
      await _trackSuccessfulLogin();

      // Callback and logging
      _onUserSignedIn?.call(user);
      try {
        await AppLogger.setUserId(user.id);
        AppLogger.i('External user adopted: ${user.id}', tag: 'AuthService');
      } catch (_) {}

      debugPrint('AuthService: External user adopted - ${user.email}');
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _statusController.add(_status);
      debugPrint('AuthService: Failed to adopt external user - $e');
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    _userController.close();
    _statusController.close();
  }
}
