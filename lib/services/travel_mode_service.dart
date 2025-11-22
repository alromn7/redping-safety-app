import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel_trip.dart';

/// Service for managing travel trips, itineraries, documents, and expenses
class TravelModeService {
  TravelModeService._();
  static final TravelModeService _instance = TravelModeService._();
  static TravelModeService get instance => _instance;

  // Stream controllers
  final StreamController<TravelTrip?> _activeTripController =
      StreamController<TravelTrip?>.broadcast();
  final StreamController<List<TravelTrip>> _tripsController =
      StreamController<List<TravelTrip>>.broadcast();
  final StreamController<List<TravelDocument>> _documentsController =
      StreamController<List<TravelDocument>>.broadcast();

  // Current state
  TravelTrip? _activeTrip;
  List<TravelTrip> _trips = [];
  List<TravelDocument> _sharedDocuments =
      []; // Documents not tied to specific trip
  bool _isInitialized = false;

  // Storage keys
  static const String _activeTripKey = 'travel_active_trip';
  static const String _tripsKey = 'travel_trips';
  static const String _sharedDocumentsKey = 'travel_shared_documents';

  // Getters
  Stream<TravelTrip?> get activeTripStream => _activeTripController.stream;
  Stream<List<TravelTrip>> get tripsStream => _tripsController.stream;
  Stream<List<TravelDocument>> get documentsStream =>
      _documentsController.stream;

  TravelTrip? get activeTrip => _activeTrip;
  List<TravelTrip> get trips => List.unmodifiable(_trips);
  List<TravelDocument> get sharedDocuments =>
      List.unmodifiable(_sharedDocuments);
  bool get hasActiveTrip => _activeTrip != null && _activeTrip!.isActive;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('TravelModeService: Already initialized');
      return;
    }

    try {
      await _loadData();
      _isInitialized = true;
      debugPrint('TravelModeService: Initialized successfully');
    } catch (e) {
      debugPrint('TravelModeService: Initialization error - $e');
      rethrow;
    }
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load active trip
      final activeTripJson = prefs.getString(_activeTripKey);
      if (activeTripJson != null) {
        _activeTrip = TravelTrip.fromJson(jsonDecode(activeTripJson));
        _activeTripController.add(_activeTrip);
      }

      // Load all trips
      final tripsJson = prefs.getString(_tripsKey);
      if (tripsJson != null) {
        final list = jsonDecode(tripsJson) as List<dynamic>;
        _trips = list
            .map((e) => TravelTrip.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort by start date (upcoming first)
        _trips.sort((a, b) => a.startDate.compareTo(b.startDate));
        _tripsController.add(_trips);
      }

      // Load shared documents
      final docsJson = prefs.getString(_sharedDocumentsKey);
      if (docsJson != null) {
        final list = jsonDecode(docsJson) as List<dynamic>;
        _sharedDocuments = list
            .map((e) => TravelDocument.fromJson(e as Map<String, dynamic>))
            .toList();
        _documentsController.add(_sharedDocuments);
      }

      debugPrint('TravelModeService: Data loaded');
    } catch (e) {
      debugPrint('TravelModeService: Error loading data - $e');
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save active trip
      if (_activeTrip != null) {
        await prefs.setString(
          _activeTripKey,
          jsonEncode(_activeTrip!.toJson()),
        );
      } else {
        await prefs.remove(_activeTripKey);
      }

      // Save all trips
      await prefs.setString(
        _tripsKey,
        jsonEncode(_trips.map((e) => e.toJson()).toList()),
      );

      // Save shared documents
      await prefs.setString(
        _sharedDocumentsKey,
        jsonEncode(_sharedDocuments.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('TravelModeService: Error saving data - $e');
    }
  }

  // ====== TRIP MANAGEMENT ======

  /// Create a new trip
  Future<TravelTrip> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    DateTime? endDate,
    TripType type = TripType.leisure,
    String? description,
    List<String>? countries,
    List<String>? cities,
  }) async {
    final trip = TravelTrip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      type: type,
      description: description,
      countries: countries ?? [],
      cities: cities ?? [],
      status: TripStatus.planned,
    );

    _trips.add(trip);
    _trips.sort((a, b) => a.startDate.compareTo(b.startDate));
    _tripsController.add(_trips);
    await _saveData();

    debugPrint('TravelModeService: Trip created - $name');
    return trip;
  }

  /// Update a trip
  Future<void> updateTrip(TravelTrip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
      _trips.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Update active trip if it's the same
      if (_activeTrip?.id == trip.id) {
        _activeTrip = trip;
        _activeTripController.add(_activeTrip);
      }

      _tripsController.add(_trips);
      await _saveData();
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((t) => t.id == tripId);

    // Clear active trip if it was deleted
    if (_activeTrip?.id == tripId) {
      _activeTrip = null;
      _activeTripController.add(null);
    }

    _tripsController.add(_trips);
    await _saveData();
  }

  /// Start a trip (make it active)
  Future<void> startTrip(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedTrip = trip.copyWith(status: TripStatus.active);

    // Update trip in list
    final index = _trips.indexWhere((t) => t.id == tripId);
    _trips[index] = updatedTrip;

    // Set as active
    _activeTrip = updatedTrip;
    _activeTripController.add(_activeTrip);
    _tripsController.add(_trips);
    await _saveData();

    debugPrint('TravelModeService: Trip started - ${updatedTrip.name}');
  }

  /// End active trip
  Future<void> endTrip() async {
    if (_activeTrip == null) return;

    final completedTrip = _activeTrip!.copyWith(status: TripStatus.completed);

    // Update in list
    final index = _trips.indexWhere((t) => t.id == completedTrip.id);
    if (index != -1) {
      _trips[index] = completedTrip;
    }

    _activeTrip = null;
    _activeTripController.add(null);
    _tripsController.add(_trips);
    await _saveData();

    debugPrint('TravelModeService: Trip ended');
  }

  /// Get trips by status
  List<TravelTrip> getTripsByStatus(TripStatus status) {
    return _trips.where((t) => t.status == status).toList();
  }

  /// Get upcoming trips
  List<TravelTrip> getUpcomingTrips() {
    return _trips.where((t) => t.isUpcoming).toList();
  }

  /// Get past trips
  List<TravelTrip> getPastTrips() {
    return _trips.where((t) => t.isPast).toList();
  }

  // ====== ITINERARY MANAGEMENT ======

  /// Add itinerary item to trip
  Future<void> addItineraryItem(String tripId, ItineraryItem item) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedItinerary = [...trip.itinerary, item];
    final updatedTrip = trip.copyWith(itinerary: updatedItinerary);
    await updateTrip(updatedTrip);
  }

  /// Update itinerary item
  Future<void> updateItineraryItem(String tripId, ItineraryItem item) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedItinerary = trip.itinerary.map((i) {
      return i.id == item.id ? item : i;
    }).toList();
    final updatedTrip = trip.copyWith(itinerary: updatedItinerary);
    await updateTrip(updatedTrip);
  }

  /// Remove itinerary item
  Future<void> removeItineraryItem(String tripId, String itemId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedItinerary = trip.itinerary
        .where((i) => i.id != itemId)
        .toList();
    final updatedTrip = trip.copyWith(itinerary: updatedItinerary);
    await updateTrip(updatedTrip);
  }

  /// Get today's itinerary items for active trip
  List<ItineraryItem> getTodaysItinerary() {
    if (_activeTrip == null) return [];
    return _activeTrip!.itinerary.where((i) => i.isToday).toList();
  }

  // ====== DOCUMENT MANAGEMENT ======

  /// Add document to trip
  Future<void> addTripDocument(String tripId, TravelDocument document) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedDocs = [...trip.documents, document];
    final updatedTrip = trip.copyWith(documents: updatedDocs);
    await updateTrip(updatedTrip);
  }

  /// Add shared document (not trip-specific)
  Future<void> addSharedDocument(TravelDocument document) async {
    _sharedDocuments.add(document);
    _documentsController.add(_sharedDocuments);
    await _saveData();
  }

  /// Update shared document
  Future<void> updateSharedDocument(TravelDocument document) async {
    final index = _sharedDocuments.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _sharedDocuments[index] = document;
      _documentsController.add(_sharedDocuments);
      await _saveData();
    }
  }

  /// Remove shared document
  Future<void> removeSharedDocument(String documentId) async {
    _sharedDocuments.removeWhere((d) => d.id == documentId);
    _documentsController.add(_sharedDocuments);
    await _saveData();
  }

  /// Get expiring documents (within 6 months)
  List<TravelDocument> getExpiringDocuments() {
    final allDocs = [..._sharedDocuments];
    for (final trip in _trips) {
      allDocs.addAll(trip.documents);
    }
    return allDocs.where((d) => d.isExpiringSoon).toList();
  }

  /// Get expired documents
  List<TravelDocument> getExpiredDocuments() {
    final allDocs = [..._sharedDocuments];
    for (final trip in _trips) {
      allDocs.addAll(trip.documents);
    }
    return allDocs.where((d) => d.isExpired).toList();
  }

  // ====== COMPANION MANAGEMENT ======

  /// Add companion to trip
  Future<void> addCompanion(String tripId, TravelCompanion companion) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedCompanions = [...trip.companions, companion];
    final updatedTrip = trip.copyWith(companions: updatedCompanions);
    await updateTrip(updatedTrip);
  }

  /// Remove companion
  Future<void> removeCompanion(String tripId, String companionId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedCompanions = trip.companions
        .where((c) => c.id != companionId)
        .toList();
    final updatedTrip = trip.copyWith(companions: updatedCompanions);
    await updateTrip(updatedTrip);
  }

  // ====== EXPENSE MANAGEMENT ======

  /// Add expense to trip
  Future<void> addExpense(String tripId, TravelExpense expense) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedExpenses = [...trip.expenses, expense];
    final updatedTrip = trip.copyWith(expenses: updatedExpenses);
    await updateTrip(updatedTrip);
  }

  /// Update expense
  Future<void> updateExpense(String tripId, TravelExpense expense) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedExpenses = trip.expenses.map((e) {
      return e.id == expense.id ? expense : e;
    }).toList();
    final updatedTrip = trip.copyWith(expenses: updatedExpenses);
    await updateTrip(updatedTrip);
  }

  /// Remove expense
  Future<void> removeExpense(String tripId, String expenseId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final updatedExpenses = trip.expenses
        .where((e) => e.id != expenseId)
        .toList();
    final updatedTrip = trip.copyWith(expenses: updatedExpenses);
    await updateTrip(updatedTrip);
  }

  /// Get expenses by category for trip
  Map<ExpenseCategory, double> getExpensesByCategory(String tripId) {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final result = <ExpenseCategory, double>{};

    for (final expense in trip.expenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }

    return result;
  }

  /// Get trip statistics
  Map<String, dynamic> getTripStats(String tripId) {
    final trip = _trips.firstWhere((t) => t.id == tripId);

    return {
      'totalExpenses': trip.totalExpenses,
      'expensesByCategory': getExpensesByCategory(tripId),
      'numberOfItineraryItems': trip.itinerary.length,
      'numberOfDocuments': trip.documents.length,
      'numberOfCompanions': trip.companions.length,
      'daysRemaining': trip.daysRemaining,
      'duration': trip.duration,
    };
  }

  /// Dispose of resources
  void dispose() {
    _activeTripController.close();
    _tripsController.close();
    _documentsController.close();
  }
}
