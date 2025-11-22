import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/google_cloud_config.dart';
import 'auth_service.dart';

class UserProfileService {
  bool _isInitialized = false;
  UserProfile? _currentProfile;
  bool _useFirestore = false;

  bool get isInitialized => _isInitialized;
  UserProfile? get currentProfile => _currentProfile;

  Future<void> initialize() async {
    // If already initialized, but authentication state changed to authenticated
    // after initial init, upgrade to Firestore-backed profile loading.
    if (_isInitialized) {
      if (!_useFirestore && AuthService.instance.isAuthenticated) {
        try {
          _useFirestore = true;
          await _loadFromFirestore();
        } catch (_) {}
      }
      return;
    }
    try {
      // Determine if Firestore is available and user is authenticated
      _useFirestore = AuthService.instance.isAuthenticated;
      if (_useFirestore) {
        await _loadFromFirestore();
      }

      _isInitialized = true;
    } catch (e) {
      // Graceful fallback: keep in-memory only
      _isInitialized = true;
    }
  }

  /// Force refresh of the current user profile based on the latest auth state.
  /// Useful right after a user signs in (e.g., Google sign-in) to ensure
  /// their profile is created/loaded and available across the app.
  Future<void> refreshFromAuth() async {
    try {
      _useFirestore = AuthService.instance.isAuthenticated;
      if (_useFirestore) {
        await _loadFromFirestore();
      }
      _isInitialized = true;
    } catch (_) {
      // Keep current in-memory state if refresh fails
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    return _currentProfile;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _currentProfile = profile;
    // Save to Firestore if available
    if (_useFirestore && AuthService.instance.isAuthenticated) {
      await _saveToFirestore(profile);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    _currentProfile = profile;
    if (_useFirestore && AuthService.instance.isAuthenticated) {
      await _saveToFirestore(profile);
    }
  }

  bool isProfileReadyForEmergency() {
    return _currentProfile != null;
  }

  void dispose() {
    _isInitialized = false;
    _currentProfile = null;
  }

  // Internal helpers
  Future<void> _loadFromFirestore() async {
    final user = AuthService.instance.currentUser;
    final userId = user.id;
    if (userId.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection(GoogleCloudConfig.firestoreCollectionUsers)
        .doc(userId);
    final snap = await docRef.get();
    if (snap.exists && snap.data() != null) {
      final data = Map<String, dynamic>.from(snap.data()!);
      // Ensure id field is present
      data['id'] = data['id'] ?? userId;
      // Normalize timestamps to ISO strings if needed
      data['createdAt'] = _coerceToIsoString(data['createdAt']);
      data['updatedAt'] = _coerceToIsoString(data['updatedAt']);
      _currentProfile = UserProfile.fromJson(data);
    } else {
      // Create default profile document
      final now = DateTime.now();
      final defaultProfile = UserProfile(
        id: userId,
        name: user.displayName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        avatar: user.photoUrl,
        createdAt: now,
        updatedAt: now,
      );
      await _saveToFirestore(defaultProfile);
      _currentProfile = defaultProfile;
    }
  }

  Future<void> _saveToFirestore(UserProfile profile) async {
    final userId = profile.id;
    if (userId.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection(GoogleCloudConfig.firestoreCollectionUsers)
        .doc(userId);
    await docRef.set(profile.toJson(), SetOptions(merge: true));
  }

  String _coerceToIsoString(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return DateTime.now().toIso8601String();
  }
}
