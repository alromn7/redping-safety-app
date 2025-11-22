import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Storage keys
  static const String _userKey = 'auth_user';
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

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

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock authentication (replace with real API call)
      final user = await _mockSignIn(request);

      // Save user to storage
      await _saveUser(user, _generateToken());

      // Handle remember me functionality
      await _handleRememberMe(request);

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

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock user creation (replace with real API call)
      final user = await _mockSignUp(request);

      // Save user to storage
      await _saveUser(user, _generateToken());

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

  /// Sign out current user
  Future<void> signOut() async {
    debugPrint('AuthService: Signing out user');

    try {
      // Clear stored user data
      await _clearStoredUser();

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
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock password reset (replace with real API call)
      await _mockPasswordReset(request);

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

  /// Mock sign in implementation
  Future<AuthUser> _mockSignIn(LoginRequest request) async {
    // Mock validation
    if (request.email.isEmpty || request.password.isEmpty) {
      throw const AuthException('Email and password are required');
    }

    if (!request.email.contains('@')) {
      throw const AuthException('Invalid email format');
    }

    if (request.password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    // Mock user data (replace with real API response)
    return AuthUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: request.email,
      displayName: request.email.split('@')[0],
      isEmailVerified: true,
      createdAt: DateTime.now(),
      lastSignIn: DateTime.now(),
    );
  }

  /// Mock sign up implementation
  Future<AuthUser> _mockSignUp(SignupRequest request) async {
    // Mock validation
    if (request.email.isEmpty ||
        request.password.isEmpty ||
        request.displayName.isEmpty) {
      throw const AuthException('All fields are required');
    }

    if (!request.email.contains('@')) {
      throw const AuthException('Invalid email format');
    }

    if (request.password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    if (request.displayName.length < 2) {
      throw const AuthException('Display name must be at least 2 characters');
    }

    // Mock user data (replace with real API response)
    return AuthUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: request.email,
      displayName: request.displayName,
      phoneNumber: request.phoneNumber,
      isEmailVerified: false,
      createdAt: DateTime.now(),
      lastSignIn: DateTime.now(),
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
