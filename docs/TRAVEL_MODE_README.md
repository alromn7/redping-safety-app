# Travel Mode - Quick Start Guide

## What is Travel Mode?

Travel Mode is a comprehensive trip management system for RedPing that helps you plan, organize, and track all aspects of your travels. From multi-day itineraries to document expiry tracking, expense management to companion coordination - everything you need for stress-free travel in one place.

## Quick Start

### 1. Generate Test Data (Development)

```dart
import 'package:redping_14v/utils/travel_mode_test_data.dart';

// Generate sample trips, documents, expenses
await TravelModeTestData.generateAll();
```

This creates:
- 3 sample trips (upcoming, active, past)
- Shared documents (passport, license, insurance)
- Itinerary items across multiple days
- Expenses across all 8 categories

### 2. Access Travel Manager

**From SOS Page** (when Travel mode active):
```
SOS Page → "Travel Manager" button
```

**Direct Navigation**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const TravelModeDashboard(),
  ),
);
```

## Core Features at a Glance

### 📅 Trips
- Plan trips with destinations, dates, and types
- Track active, upcoming, and past trips
- Start/end trips with one tap
- View trip duration and countdown

### 🗓️ Itinerary
- Add flights, hotels, activities, and more
- Auto-grouped by date
- "Today" view for current schedule
- Store confirmation numbers

### 📄 Documents
- Track passports, visas, tickets, insurance
- **6-month expiry warnings** (critical for international travel)
- Shared documents (reuse passport across trips)
- Alert banners for expired/expiring documents

### 💰 Expenses
- 8 categories: Transport, Accommodation, Food, Activities, Shopping, Healthcare, Communication, Other
- Multi-currency support
- Category breakdown with percentages
- Receipt storage

## Common Operations

### Create a Trip

```dart
final trip = await TravelModeService.instance.createTrip(
  name: 'Summer Vacation',
  destination: 'Paris, France',
  startDate: DateTime(2024, 7, 1),
  endDate: DateTime(2024, 7, 14),
  type: TripType.leisure,
  countries: ['France'],
  cities: ['Paris'],
);
```

### Add Itinerary Item

```dart
await TravelModeService.instance.addItineraryItem(
  tripId,
  ItineraryItem(
    id: 'flight_1',
    title: 'Flight to Paris',
    type: ItineraryType.flight,
    startTime: DateTime(2024, 7, 1, 10, 0),
    endTime: DateTime(2024, 7, 1, 20, 0),
    location: 'Charles de Gaulle Airport',
    confirmationNumber: 'AF123ABC',
    cost: 650.00,
    currency: 'USD',
  ),
);
```

### Add Document

```dart
// Trip-specific document
await TravelModeService.instance.addTripDocument(
  tripId,
  TravelDocument(
    id: 'hotel_conf',
    name: 'Hotel Le Marais',
    type: DocumentType.hotel,
    documentNumber: 'HTL456789',
    expiryDate: DateTime(2024, 7, 14),
  ),
);

// Shared document (reusable)
await TravelModeService.instance.addSharedDocument(
  TravelDocument(
    id: 'passport',
    name: 'US Passport',
    type: DocumentType.passport,
    documentNumber: 'US123456789',
    issuingCountry: 'United States',
    expiryDate: DateTime(2030, 1, 1),
  ),
);
```

### Add Expense

```dart
await TravelModeService.instance.addExpense(
  tripId,
  TravelExpense(
    id: 'dinner_1',
    description: 'Dinner at Le Jules Verne',
    amount: 125.00,
    currency: 'EUR',
    category: ExpenseCategory.food,
    date: DateTime.now(),
    location: 'Paris, France',
  ),
);
```

### Start/End Trip

```dart
// Start trip (sets status to active)
await TravelModeService.instance.startTrip(tripId);

// End trip (sets status to completed)
await TravelModeService.instance.endTrip(tripId);
```

## Dashboard Guide

### Trips Tab
- **Active Section**: Currently ongoing trip (max 1)
- **Upcoming Section**: Planned trips ordered by start date
- **Past Section**: Completed trip history
- **Actions**: Create trip, start trip, end trip

### Itinerary Tab
- **Today's Schedule**: Highlighted current day activities
- **Timeline**: All activities grouped by date
- **Date Labels**: "Today", "Tomorrow", or formatted date
- **Empty State**: Shows when no active trip

### Documents Tab
- **Alert Banners**: 
  - 🔴 RED: Expired documents
  - 🟠 ORANGE: Expiring within 6 months
- **Shared Documents**: Passports, licenses valid for all trips
- **Trip Documents**: Confirmations and bookings per trip

### Expenses Tab
- **Total Card**: Large display of total spending
- **Category Breakdown**: Percentage by category
- **Recent List**: Last 10 expenses
- **Quick Add**: Add expenses on the go

## Data Models

### TravelTrip
```dart
{
  id, name, destination,
  startDate, endDate, status, type,
  countries[], cities[],
  companions[], documents[], itinerary[], expenses[],
  // Computed:
  isActive, isUpcoming, isPast, duration, totalExpenses
}
```

### TripStatus
- `planned` - Created but not started
- `active` - Currently ongoing
- `completed` - Finished
- `cancelled` - Cancelled but preserved

### TripType
`leisure`, `business`, `family`, `adventure`, `backpacking`, `cruise`, `roadTrip`, `other`

### DocumentType
`passport`, `visa`, `ticket`, `boardingPass`, `hotel`, `rental`, `insurance`, `vaccination`, `driverLicense`, `other`

### ItineraryType
`flight`, `train`, `bus`, `car`, `hotel`, `restaurant`, `activity`, `tour`, `meeting`, `other`

### ExpenseCategory
`transport`, `accommodation`, `food`, `activities`, `shopping`, `healthcare`, `communication`, `other`

## Service API

### TravelModeService.instance

#### Trip Management
```dart
createTrip(...)              // Create new trip
updateTrip(trip)             // Update trip details
deleteTrip(tripId)           // Delete trip
startTrip(tripId)            // Set status to active
endTrip(tripId)              // Set status to completed
getTripsByStatus(status)     // Filter by status
getUpcomingTrips()           // Planned trips in future
getPastTrips()               // Completed trips
```

#### Itinerary
```dart
addItineraryItem(tripId, item)       // Add to schedule
updateItineraryItem(tripId, item)    // Update item
removeItineraryItem(tripId, itemId)  // Remove item
getTodaysItinerary()                 // Active trip's today
```

#### Documents
```dart
addTripDocument(tripId, doc)         // Trip-specific doc
addSharedDocument(doc)               // Reusable doc
updateSharedDocument(doc)            // Update shared doc
removeSharedDocument(docId)          // Remove shared doc
getExpiringDocuments()               // < 6 months
getExpiredDocuments()                // Past expiry
```

#### Expenses
```dart
addExpense(tripId, expense)          // Add expense
updateExpense(tripId, expense)       // Update expense
removeExpense(tripId, expenseId)     // Remove expense
getExpensesByCategory(tripId)        // Totals by category
```

#### Statistics
```dart
getTripStats(tripId)  // Returns:
{
  totalExpenses: 1250.00,
  expensesByCategory: {food: 285.50, ...},
  companionCount: 2,
  documentCount: 5,
  itineraryItemCount: 12,
  daysRemaining: 30,
  duration: 14,
}
```

## Streams (Reactive UI)

```dart
// Listen to active trip changes
TravelModeService.instance.activeTripStream.listen((trip) {
  // Update UI when active trip changes
});

// Listen to trips list changes
TravelModeService.instance.tripsStream.listen((trips) {
  // Update UI when trips added/removed/updated
});

// Listen to documents changes
TravelModeService.instance.documentsStream.listen((docs) {
  // Update UI when documents change
});
```

## Important: Document Expiry Alerts

Many countries require passports valid **6+ months** beyond your travel dates. The system alerts you:

- **🔴 RED**: Document expired - renew immediately
- **🟠 ORANGE**: Document expires in < 6 months - renew soon

**Always check document alerts before booking travel!**

## File Structure

```
lib/
├── models/
│   └── travel_trip.dart              # All data models
├── services/
│   └── travel_mode_service.dart      # Business logic
├── features/redping_mode/presentation/
│   ├── pages/
│   │   └── travel_mode_dashboard.dart    # Main UI
│   └── widgets/
│       ├── travel_trip_card.dart
│       ├── itinerary_item_card.dart
│       ├── travel_document_card.dart
│       └── travel_expense_card.dart
└── utils/
    └── travel_mode_test_data.dart    # Test data generator
```

## Testing

### Generate Test Data
```dart
await TravelModeTestData.generateAll();
```

### Clear Test Data
```dart
await TravelModeTestData.clearAll();
```

### Test Scenarios Covered
- Upcoming trip (30 days away)
- Past trip (completed 90 days ago)
- Business trip (next week)
- Documents with various expiry dates
- Expenses across all 8 categories
- Itinerary spanning multiple days
- Companions with emergency contacts

## Best Practices

### Before Booking Travel
1. ✅ Check passport expiry (6+ months validity required)
2. ✅ Verify visa requirements
3. ✅ Review travel insurance coverage
4. ✅ Update vaccination records

### During Trip Planning
1. ✅ Add documents as soon as confirmed
2. ✅ Enter itinerary items with confirmation numbers
3. ✅ Add all companions with emergency contacts
4. ✅ Set local emergency contact for destination

### While Traveling
1. ✅ Log expenses in real-time
2. ✅ Check today's itinerary each morning
3. ✅ Keep confirmation numbers accessible
4. ✅ Store receipt URLs for important purchases

### After Travel
1. ✅ End trip to mark completed
2. ✅ Review expense breakdown
3. ✅ Keep trip data for tax/records
4. ✅ Update shared documents if renewed

## Troubleshooting

**Q: Why don't I see expiry alerts?**
A: Check that documents have `expiryDate` set and are not already expired.

**Q: Can I have multiple active trips?**
A: No, only one trip can be active at a time to avoid confusion.

**Q: How do I handle multi-currency expenses?**
A: Store each expense in its original currency. The system tracks them separately.

**Q: What if my passport is valid for multiple trips?**
A: Add it as a "Shared Document" - it will appear for all trips.

**Q: Can I edit a completed trip?**
A: Yes, status doesn't prevent editing. You can always update details.

## Integration with RedPing

Travel Mode integrates seamlessly:
- Available when Travel mode selected in RedPing
- Accessible via "Travel Manager" button on SOS page
- Trip data persists across mode switches
- Active trip survives app restarts

## Next Steps

1. **Generate test data** to explore features
2. **Create your first trip** for an upcoming vacation
3. **Add documents** and check for expiry alerts
4. **Build itinerary** with confirmation numbers
5. **Track expenses** as you travel

For detailed documentation, see:
- **TRAVEL_MODE_GUIDE.md** - Comprehensive feature guide
- **TRAVEL_MODE_IMPLEMENTATION_SUMMARY.md** - Technical architecture

Happy travels! ✈️🌍
