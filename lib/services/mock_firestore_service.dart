import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock Firestore service for local testing
/// This simulates Firestore behavior using SharedPreferences
class MockFirestoreService {
  static final MockFirestoreService _instance =
      MockFirestoreService._internal();
  factory MockFirestoreService() => _instance;
  MockFirestoreService._internal();

  final Map<String, StreamController<Map<String, dynamic>>> _streamControllers =
      {};
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Mock collection reference
  MockCollectionReference collection(String path) {
    return MockCollectionReference(path, this);
  }

  /// Get data from local storage
  Future<Map<String, dynamic>?> getData(String path) async {
    final key = 'firestore_$path';
    final data = _prefs?.getString(key);
    if (data != null) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }
    return null;
  }

  /// Set data to local storage
  Future<void> setData(String path, Map<String, dynamic> data) async {
    final key = 'firestore_$path';
    await _prefs?.setString(key, jsonEncode(data));

    // Notify all listeners
    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.add(data);
      }
    }
  }

  /// Add document to collection
  Future<void> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final docId = '${collectionPath}_$timestamp';
    final docPath = '$collectionPath/$docId';

    final docData = {
      ...data,
      'id': docId,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };

    await setData(docPath, docData);
  }

  /// Listen to collection changes
  Stream<Map<String, dynamic>> listenToCollection(String collectionPath) {
    final controller = StreamController<Map<String, dynamic>>();
    _streamControllers[collectionPath] = controller;

    // Return existing data immediately
    _loadExistingData(collectionPath, controller);

    return controller.stream;
  }

  Future<void> _loadExistingData(
    String collectionPath,
    StreamController<Map<String, dynamic>> controller,
  ) async {
    final keys =
        _prefs?.getKeys().where(
          (key) => key.startsWith('firestore_$collectionPath/'),
        ) ??
        [];

    for (final key in keys) {
      final data = _prefs?.getString(key);
      if (data != null) {
        try {
          final docData = Map<String, dynamic>.from(jsonDecode(data));
          if (!controller.isClosed) {
            controller.add(docData);
          }
        } catch (e) {
          // Ignore invalid data
        }
      }
    }
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}

/// Mock collection reference
class MockCollectionReference {
  final String path;
  final MockFirestoreService _service;

  MockCollectionReference(this.path, this._service);

  /// Add document to collection
  Future<void> add(Map<String, dynamic> data) async {
    await _service.addDocument(path, data);
  }

  /// Get document by ID
  Future<Map<String, dynamic>?> doc(String docId) async {
    final docPath = '$path/$docId';
    return await _service.getData(docPath);
  }

  /// Listen to collection changes
  Stream<Map<String, dynamic>> snapshots() {
    return _service.listenToCollection(path);
  }
}

