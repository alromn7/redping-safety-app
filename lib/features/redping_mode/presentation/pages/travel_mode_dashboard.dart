import 'package:flutter/material.dart';
import '../../../../models/travel_trip.dart';
import '../../../../services/travel_mode_service.dart';
import '../widgets/travel_trip_card.dart';
import '../widgets/itinerary_item_card.dart';
import '../widgets/travel_document_card.dart';
import '../widgets/travel_expense_card.dart';

/// Dashboard for managing travel trips, itineraries, documents, and expenses
class TravelModeDashboard extends StatefulWidget {
  const TravelModeDashboard({super.key});

  @override
  State<TravelModeDashboard> createState() => _TravelModeDashboardState();
}

class _TravelModeDashboardState extends State<TravelModeDashboard>
    with SingleTickerProviderStateMixin {
  final _service = TravelModeService.instance;
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_service.isInitialized) {
      await _service.initialize();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Travel Manager')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Manager'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flight_takeoff), text: 'Trips'),
            Tab(icon: Icon(Icons.list_alt), text: 'Itinerary'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripsTab(),
          _buildItineraryTab(),
          _buildDocumentsTab(),
          _buildExpensesTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ====== TRIPS TAB ======

  Widget _buildTripsTab() {
    return StreamBuilder<List<TravelTrip>>(
      stream: _service.tripsStream,
      initialData: _service.trips,
      builder: (context, snapshot) {
        final trips = snapshot.data ?? [];

        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No trips planned yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showCreateTripDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Plan a Trip'),
                ),
              ],
            ),
          );
        }

        // Separate trips by status
        final activeTrips = trips.where((t) => t.isActive).toList();
        final upcomingTrips = trips.where((t) => t.isUpcoming).toList();
        final pastTrips = trips.where((t) => t.isPast).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active trip section
            if (activeTrips.isNotEmpty) ...[
              _buildSectionHeader('Active Trip', Icons.location_on),
              ...activeTrips.map(
                (trip) => TravelTripCard(
                  trip: trip,
                  onTap: () => _showTripDetails(trip),
                  onEnd: () => _endTrip(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Upcoming trips
            if (upcomingTrips.isNotEmpty) ...[
              _buildSectionHeader('Upcoming Trips', Icons.upcoming),
              ...upcomingTrips.map(
                (trip) => TravelTripCard(
                  trip: trip,
                  onTap: () => _showTripDetails(trip),
                  onStart: () => _startTrip(trip.id),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Past trips
            if (pastTrips.isNotEmpty) ...[
              _buildSectionHeader('Past Trips', Icons.history),
              ...pastTrips.map(
                (trip) => TravelTripCard(
                  trip: trip,
                  onTap: () => _showTripDetails(trip),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ====== ITINERARY TAB ======

  Widget _buildItineraryTab() {
    return StreamBuilder<TravelTrip?>(
      stream: _service.activeTripStream,
      initialData: _service.activeTrip,
      builder: (context, snapshot) {
        final trip = snapshot.data;

        if (trip == null || !trip.isActive) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No active trip'),
                const SizedBox(height: 8),
                const Text(
                  'Start a trip to view its itinerary',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final itinerary = trip.itinerary;
        if (itinerary.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No itinerary items yet'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showAddItineraryDialog(trip.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          );
        }

        // Group by date
        final itemsByDate = <DateTime, List<ItineraryItem>>{};
        for (final item in itinerary) {
          final date = DateTime(
            item.startTime.year,
            item.startTime.month,
            item.startTime.day,
          );
          itemsByDate[date] = [...(itemsByDate[date] ?? []), item];
        }

        // Sort dates
        final sortedDates = itemsByDate.keys.toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trip header
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(trip.destination),
                    if (trip.duration != null)
                      Text('${trip.duration!.inDays} days'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Itinerary by date
            ...sortedDates.map((date) {
              final items = itemsByDate[date]!;
              items.sort((a, b) => a.startTime.compareTo(b.startTime));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...items.map(
                    (item) => ItineraryItemCard(
                      item: item,
                      onTap: () => _showItineraryDetails(trip.id, item),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  // ====== DOCUMENTS TAB ======

  Widget _buildDocumentsTab() {
    return StreamBuilder<List<TravelDocument>>(
      stream: _service.documentsStream,
      initialData: _service.sharedDocuments,
      builder: (context, snapshot) {
        final sharedDocs = snapshot.data ?? [];
        final expiring = _service.getExpiringDocuments();
        final expired = _service.getExpiredDocuments();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Alerts
            if (expired.isNotEmpty)
              Card(
                color: Colors.red.shade100,
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(
                    '${expired.length} document(s) expired',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (expiring.isNotEmpty)
              Card(
                color: Colors.orange.shade100,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(
                    '${expiring.length} document(s) expiring soon',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Shared documents
            if (sharedDocs.isNotEmpty) ...[
              _buildSectionHeader('My Documents', Icons.folder),
              ...sharedDocs.map(
                (doc) => TravelDocumentCard(
                  document: doc,
                  onTap: () => _showDocumentDetails(doc),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Documents by trip
            ...(_service.trips.where((t) => t.documents.isNotEmpty).map((trip) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(trip.name, Icons.flight_takeoff),
                  ...trip.documents.map(
                    (doc) => TravelDocumentCard(
                      document: doc,
                      onTap: () => _showDocumentDetails(doc),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            })),
          ],
        );
      },
    );
  }

  // ====== EXPENSES TAB ======

  Widget _buildExpensesTab() {
    return StreamBuilder<TravelTrip?>(
      stream: _service.activeTripStream,
      initialData: _service.activeTrip,
      builder: (context, snapshot) {
        final trip = snapshot.data;

        if (trip == null || !trip.isActive) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text('No active trip'),
                const SizedBox(height: 8),
                const Text(
                  'Start a trip to track expenses',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final expenses = trip.expenses;
        final expensesByCategory = _service.getExpensesByCategory(trip.id);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total expenses card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Total Expenses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${trip.totalExpenses.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expenses by category
            if (expensesByCategory.isNotEmpty) ...[
              _buildSectionHeader('By Category', Icons.pie_chart),
              ...expensesByCategory.entries.map((entry) {
                final percentage = (entry.value / trip.totalExpenses) * 100;
                return Card(
                  child: ListTile(
                    leading: Icon(_getExpenseIcon(entry.key)),
                    title: Text(_formatCategory(entry.key)),
                    subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                    trailing: Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Recent expenses
            if (expenses.isNotEmpty) ...[
              _buildSectionHeader('Recent Expenses', Icons.receipt),
              ...expenses.reversed
                  .take(10)
                  .map(
                    (expense) => TravelExpenseCard(
                      expense: expense,
                      onTap: () => _showExpenseDetails(trip.id, expense),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }

  // ====== FLOATING ACTION BUTTON ======

  Widget? _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 0: // Trips
            _showCreateTripDialog();
            break;
          case 1: // Itinerary
            if (_service.activeTrip != null) {
              _showAddItineraryDialog(_service.activeTrip!.id);
            }
            break;
          case 2: // Documents
            _showAddDocumentDialog();
            break;
          case 3: // Expenses
            if (_service.activeTrip != null) {
              _showAddExpenseDialog(_service.activeTrip!.id);
            }
            break;
        }
      },
      child: const Icon(Icons.add),
    );
  }

  // ====== DIALOGS ======

  Future<void> _showCreateTripDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String destination = '';
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan New Trip'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Trip Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => name = v!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Destination'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => destination = v!,
                ),
                // Add date pickers, etc.
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                _service.createTrip(
                  name: name,
                  destination: destination,
                  startDate: startDate,
                  endDate: endDate,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItineraryDialog(String tripId) async {
    // Implementation simplified for brevity
  }

  Future<void> _showAddDocumentDialog() async {
    // Implementation simplified for brevity
  }

  Future<void> _showAddExpenseDialog(String tripId) async {
    // Implementation simplified for brevity
  }

  Future<void> _showTripDetails(TravelTrip trip) async {
    // Implementation simplified for brevity
  }

  Future<void> _showItineraryDetails(String tripId, ItineraryItem item) async {
    // Implementation simplified for brevity
  }

  Future<void> _showDocumentDetails(TravelDocument doc) async {
    // Implementation simplified for brevity
  }

  Future<void> _showExpenseDetails(String tripId, TravelExpense expense) async {
    // Implementation simplified for brevity
  }

  Future<void> _startTrip(String tripId) async {
    await _service.startTrip(tripId);
    setState(() {});
  }

  Future<void> _endTrip() async {
    await _service.endTrip();
    setState(() {});
  }

  // ====== HELPERS ======

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';

    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatCategory(dynamic category) {
    return category
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  IconData _getExpenseIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.activities:
        return Icons.local_activity;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.healthcare:
        return Icons.medical_services;
      case ExpenseCategory.communication:
        return Icons.phone;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}
