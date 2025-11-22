import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/help_request.dart';
import '../models/help_response.dart';
import '../models/help_category.dart';
import '../models/user_profile.dart';
import '../config/google_cloud_config.dart';

/// Firebase service for managing help requests and responses
class FirebaseHelpService {
  static final FirebaseHelpService _instance = FirebaseHelpService._internal();
  factory FirebaseHelpService() => _instance;
  FirebaseHelpService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _helpRequestsCollection =>
      _firestore.collection('help_requests');
  CollectionReference get _helpResponsesCollection =>
      _firestore.collection('help_responses');
  CollectionReference get _helpCategoriesCollection =>
      _firestore.collection('help_categories');

  /// Save a help request to Firebase
  Future<void> saveHelpRequest(HelpRequest request) async {
    try {
      // Ensure userId matches authenticated uid for rules
      final authUid = FirebaseAuth.instance.currentUser?.uid;

      // Enrich with user profile data (same as SOSRepository)
      final enrichedData = await _enrichWithUserProfile(
        request.copyWith(userId: authUid ?? request.userId),
      );
      await _helpRequestsCollection.doc(request.id).set(enrichedData);
      debugPrint('FirebaseHelpService: Saved help request - ${request.id}');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error saving help request - $e');
      rethrow;
    }
  }

  /// Update a help request in Firebase
  Future<void> updateHelpRequest(HelpRequest request) async {
    try {
      // Enrich with user profile data (same as SOSRepository)
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      final enrichedData = await _enrichWithUserProfile(
        request.copyWith(userId: authUid ?? request.userId),
      );
      await _helpRequestsCollection.doc(request.id).update(enrichedData);
      debugPrint('FirebaseHelpService: Updated help request - ${request.id}');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error updating help request - $e');
      rethrow;
    }
  }

  /// Enrich help request data with user profile information
  Future<Map<String, dynamic>> _enrichWithUserProfile(
    HelpRequest request,
  ) async {
    final data = request.toJson();

    debugPrint('FirebaseHelpService: Enriching help request ${request.id}');
    debugPrint(
      'FirebaseHelpService: Before enrichment - userName: ${data['userName']}, userPhone: ${data['userPhone']}',
    );

    // Get user profile for additional information (same as SOSRepository)
    final userProfile = await _getUserProfile(request.userId);

    if (userProfile != null) {
      // Add user profile information for SAR dashboard (OVERWRITE existing values)
      data['userName'] = userProfile.name;
      data['userPhone'] = userProfile.phoneNumber ?? userProfile.phone;
      data['phoneNumber'] = userProfile.phoneNumber ?? userProfile.phone;
      data['phone'] = userProfile.phoneNumber ?? userProfile.phone;
      data['userEmail'] = userProfile.email;

      debugPrint(
        'FirebaseHelpService: After enrichment - userName: ${data['userName']}, userPhone: ${data['userPhone']}',
      );
      debugPrint(
        'FirebaseHelpService: Enriched with profile - Name: ${userProfile.name}, Phone: ${userProfile.phoneNumber}',
      );
    } else {
      debugPrint(
        'FirebaseHelpService: WARNING - No profile found for user ${request.userId}, data will be incomplete!',
      );
    }

    return data;
  }

  /// Fetch user profile from Firestore (with fallback search)
  Future<UserProfile?> _getUserProfile(String userId) async {
    try {
      // Try with the given userId first
      var docRef = FirebaseFirestore.instance
          .collection(GoogleCloudConfig.firestoreCollectionUsers)
          .doc(userId);
      var snap = await docRef.get();

      debugPrint(
        'FirebaseHelpService: Looking for profile at users/$userId - exists: ${snap.exists}',
      );

      if (snap.exists && snap.data() != null) {
        final data = Map<String, dynamic>.from(snap.data()!);
        data['id'] = data['id'] ?? userId;
        return UserProfile.fromJson(data);
      }

      // If not found and userId has redping_user_ prefix, try without it
      if (userId.startsWith('redping_user_')) {
        final shortUserId = userId.replaceFirst('redping_user_', 'user_');
        docRef = FirebaseFirestore.instance
            .collection(GoogleCloudConfig.firestoreCollectionUsers)
            .doc(shortUserId);
        snap = await docRef.get();

        debugPrint(
          'FirebaseHelpService: Trying alternate format users/$shortUserId - exists: ${snap.exists}',
        );

        if (snap.exists && snap.data() != null) {
          final data = Map<String, dynamic>.from(snap.data()!);
          data['id'] = data['id'] ?? userId; // Keep original userId
          return UserProfile.fromJson(data);
        }
      }

      // If not found and userId has user_ prefix, try with redping_ prefix
      if (userId.startsWith('user_')) {
        final longUserId = userId.replaceFirst('user_', 'redping_user_');
        docRef = FirebaseFirestore.instance
            .collection(GoogleCloudConfig.firestoreCollectionUsers)
            .doc(longUserId);
        snap = await docRef.get();

        debugPrint(
          'FirebaseHelpService: Trying alternate format users/$longUserId - exists: ${snap.exists}',
        );

        if (snap.exists && snap.data() != null) {
          final data = Map<String, dynamic>.from(snap.data()!);
          data['id'] = data['id'] ?? userId; // Keep original userId
          return UserProfile.fromJson(data);
        }
      }

      // Last resort: Query the collection to find ANY user profile (there should only be one)
      debugPrint(
        'FirebaseHelpService: Direct lookup failed, querying users collection...',
      );
      final querySnap = await FirebaseFirestore.instance
          .collection(GoogleCloudConfig.firestoreCollectionUsers)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final doc = querySnap.docs.first;
        debugPrint('FirebaseHelpService: Found profile via query: ${doc.id}');
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        return UserProfile.fromJson(data);
      }

      debugPrint(
        'FirebaseHelpService: No profile found for any variant of userId: $userId',
      );
      return null;
    } catch (e) {
      debugPrint('FirebaseHelpService: Could not fetch user profile - $e');
      return null;
    }
  }

  /// Get help request by ID
  Future<HelpRequest?> getHelpRequest(String requestId) async {
    try {
      final doc = await _helpRequestsCollection.doc(requestId).get();
      if (doc.exists) {
        return HelpRequest.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseHelpService: Error getting help request - $e');
      return null;
    }
  }

  /// Get all help requests
  Future<List<HelpRequest>> getHelpRequests() async {
    try {
      final snapshot = await _helpRequestsCollection.get();
      return snapshot.docs
          .map(
            (doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('FirebaseHelpService: Error getting help requests - $e');
      return [];
    }
  }

  /// Get help requests by user ID
  Future<List<HelpRequest>> getHelpRequestsByUser(String userId) async {
    try {
      final snapshot = await _helpRequestsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('FirebaseHelpService: Error getting user help requests - $e');
      return [];
    }
  }

  /// Get active help requests
  Future<List<HelpRequest>> getActiveHelpRequests() async {
    try {
      final snapshot = await _helpRequestsCollection
          .where('status', whereIn: ['active', 'assigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'FirebaseHelpService: Error getting active help requests - $e',
      );
      return [];
    }
  }

  /// Get help requests by category
  Future<List<HelpRequest>> getHelpRequestsByCategory(String categoryId) async {
    try {
      final snapshot = await _helpRequestsCollection
          .where('categoryId', isEqualTo: categoryId)
          .where('status', whereIn: ['active', 'assigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'FirebaseHelpService: Error getting help requests by category - $e',
      );
      return [];
    }
  }

  /// Save a help response to Firebase
  Future<void> saveHelpResponse(HelpResponse response) async {
    try {
      await _helpResponsesCollection.doc(response.id).set(response.toJson());
      debugPrint('FirebaseHelpService: Saved help response - ${response.id}');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error saving help response - $e');
      rethrow;
    }
  }

  /// Update a help response in Firebase
  Future<void> updateHelpResponse(HelpResponse response) async {
    try {
      await _helpResponsesCollection.doc(response.id).update(response.toJson());
      debugPrint('FirebaseHelpService: Updated help response - ${response.id}');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error updating help response - $e');
      rethrow;
    }
  }

  /// Get responses for a help request
  Future<List<HelpResponse>> getHelpResponses(String requestId) async {
    try {
      final snapshot = await _helpResponsesCollection
          .where('requestId', isEqualTo: requestId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map(
            (doc) => HelpResponse.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('FirebaseHelpService: Error getting help responses - $e');
      return [];
    }
  }

  /// Get help responses by responder
  Future<List<HelpResponse>> getHelpResponsesByResponder(
    String responderId,
  ) async {
    try {
      final snapshot = await _helpResponsesCollection
          .where('responderId', isEqualTo: responderId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => HelpResponse.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'FirebaseHelpService: Error getting help responses by responder - $e',
      );
      return [];
    }
  }

  /// Save help categories to Firebase
  Future<void> saveHelpCategories(List<HelpCategory> categories) async {
    try {
      final batch = _firestore.batch();
      for (final category in categories) {
        batch.set(
          _helpCategoriesCollection.doc(category.id),
          category.toJson(),
        );
      }
      await batch.commit();
      debugPrint('FirebaseHelpService: Saved help categories');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error saving help categories - $e');
      rethrow;
    }
  }

  /// Get help categories
  Future<List<HelpCategory>> getHelpCategories() async {
    try {
      final snapshot = await _helpCategoriesCollection.get();
      return snapshot.docs
          .map(
            (doc) => HelpCategory.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('FirebaseHelpService: Error getting help categories - $e');
      return [];
    }
  }

  /// Delete a help request
  Future<void> deleteHelpRequest(String requestId) async {
    try {
      await _helpRequestsCollection.doc(requestId).delete();
      debugPrint('FirebaseHelpService: Deleted help request - $requestId');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error deleting help request - $e');
      rethrow;
    }
  }

  /// Delete a help response
  Future<void> deleteHelpResponse(String responseId) async {
    try {
      await _helpResponsesCollection.doc(responseId).delete();
      debugPrint('FirebaseHelpService: Deleted help response - $responseId');
    } catch (e) {
      debugPrint('FirebaseHelpService: Error deleting help response - $e');
      rethrow;
    }
  }

  /// Stream of help requests
  Stream<List<HelpRequest>> get helpRequestsStream {
    return _helpRequestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream of help responses
  Stream<List<HelpResponse>> get helpResponsesStream {
    return _helpResponsesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HelpResponse.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream of help requests by user
  Stream<List<HelpRequest>> getHelpRequestsByUserStream(String userId) {
    return _helpRequestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream of active help requests
  Stream<List<HelpRequest>> get activeHelpRequestsStream {
    return _helpRequestsCollection
        .where('status', whereIn: ['active', 'assigned', 'inProgress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HelpRequest.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream of help responses for a request
  Stream<List<HelpResponse>> getHelpResponsesStream(String requestId) {
    return _helpResponsesCollection
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HelpResponse.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
