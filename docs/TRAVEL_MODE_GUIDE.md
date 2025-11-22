# Travel Mode Management System - Complete Guide

## Overview

The Travel Mode Management System provides comprehensive tools for planning, organizing, and tracking all aspects of your trips. From itineraries and documents to expenses and companions, everything you need for stress-free travel is centralized in one place.

## Key Features

### 🗺️ Trip Management
- **Trip Lifecycle**: Plan → Active → Completed workflow
- **Multi-Destination Support**: Track countries and cities visited
- **Trip Types**: Leisure, Business, Family, Adventure, Backpacking, Cruise, Road Trip
- **Companion Tracking**: Manage travel companions with emergency contacts
- **Emergency Preparedness**: Local emergency contacts for each destination

### 📋 Itinerary Organization
- **Multi-Day Schedules**: Organize activities across entire trip duration
- **10 Activity Types**: Flights, hotels, trains, tours, restaurants, meetings, and more
- **Smart Grouping**: Itinerary items automatically grouped by date
- **Today's Schedule**: Quick view of today's activities
- **Confirmation Tracking**: Store confirmation numbers for all bookings

### 📄 Document Management
- **Expiry Tracking**: Automatic alerts for expiring documents
- **Document Types**: Passports, visas, tickets, insurance, vaccination records, and more
- **Shared Documents**: Reuse documents across multiple trips (passport, driver's license)
- **Alert System**: 
  - 🔴 RED: Expired documents
  - 🟠 ORANGE: Expiring within 6 months

### 💰 Expense Tracking
- **8 Categories**: Transport, Accommodation, Food, Activities, Shopping, Healthcare, Communication, Other
- **Multi-Currency**: Track expenses in different currencies
- **Category Breakdown**: Visual percentage breakdown by category
- **Receipt Storage**: Store receipt URLs for record keeping
- **Location Tracking**: Track where each expense occurred

## User Interface

### Dashboard Tabs

#### 1. Trips Tab
- **Active Trips**: Currently ongoing trips
- **Upcoming Trips**: Trips starting in the future
- **Past Trips**: Completed trip history
- **Quick Actions**: Start trip, end trip, view details

#### 2. Itinerary Tab
- **Today's Schedule**: What's happening now
- **Timeline View**: All activities in chronological order
- **Date Grouping**: "Today", "Tomorrow", or formatted dates
- **Quick Add**: Add new itinerary items on the fly

#### 3. Documents Tab
- **Alert Banners**: Prominent warnings for expired/expiring documents
- **Shared Documents**: Passports, licenses valid for all trips
- **Trip Documents**: Specific bookings and confirmations
- **Expiry Countdown**: Days until document expires

#### 4. Expenses Tab
- **Total Overview**: Total spending across all categories
- **Category Breakdown**: Pie chart-style percentage view
- **Recent Expenses**: Last 10 expenses
- **Quick Add**: Add expenses as they occur

## Common Workflows

### Planning a New Trip

1. **Create Trip**:
   ```
   Trips Tab → FAB → Enter details
   - Name: "Japan Adventure"
   - Destination: "Tokyo, Kyoto"
   - Dates: June 1-14
   - Type: Leisure
   ```

2. **Add Companions**:
   ```
   Enter companion details:
   - Name, relationship, contact info
   - Passport number
   - Emergency contact
   ```

3. **Upload Documents**:
   ```
   Documents Tab → FAB → Add documents
   - Flight confirmations
   - Hotel bookings
   - Travel insurance
   - Visa (if required)
   ```

4. **Build Itinerary**:
   ```
   Itinerary Tab → FAB → Add items
   - Flights with confirmation numbers
   - Hotel check-ins
   - Planned activities
   - Restaurant reservations
   ```

### During the Trip

1. **Start Trip**:
   ```
   Trips Tab → Trip Card → "Start Trip"
   Status changes: Planned → Active
   ```

2. **Check Today's Schedule**:
   ```
   Itinerary Tab → Today section
   View all activities for current day
   ```

3. **Track Expenses**:
   ```
   Expenses Tab → FAB → Add expense
   - Amount, currency, category
   - Location, date
   - Optional: Receipt photo URL
   ```

4. **Monitor Documents**:
   ```
   Documents Tab → Check alerts
   Ensure all documents valid
   ```

### After the Trip

1. **End Trip**:
   ```
   Trips Tab → Trip Card → "End Trip"
   Status changes: Active → Completed
   ```

2. **Review Expenses**:
   ```
   Expenses Tab → Category breakdown
   See total spending by category
   ```

3. **Save for Records**:
   ```
   All trip data persists
   Access anytime from Past Trips
   ```

## API Reference

### TravelModeService

#### Trip Management

```dart
// Create new trip
final trip = await TravelModeService.instance.createTrip(
  name: 'Summer Vacation',
  destination: 'Hawaii',
  startDate: DateTime(2024, 7, 1),
  endDate: DateTime(2024, 7, 14),
  type: TripType.leisure,
  countries: ['USA'],
  cities: ['Honolulu', 'Maui'],
);

// Update trip
await TravelModeService.instance.updateTrip(
  trip.copyWith(description: 'Updated description'),
);

// Start trip
await TravelModeService.instance.startTrip(trip.id);

// End trip
await TravelModeService.instance.endTrip(trip.id);

// Get trips by status
final activeTrips = TravelModeService.instance.getTripsByStatus(TripStatus.active);
final upcomingTrips = TravelModeService.instance.getUpcomingTrips();
final pastTrips = TravelModeService.instance.getPastTrips();
```

#### Itinerary Management

```dart
// Add itinerary item
await TravelModeService.instance.addItineraryItem(
  tripId,
  ItineraryItem(
    id: 'item_1',
    title: 'Flight to Tokyo',
    type: ItineraryType.flight,
    startTime: DateTime(2024, 6, 1, 10, 0),
    endTime: DateTime(2024, 6, 1, 22, 0),
    location: 'Narita Airport',
    confirmationNumber: 'ABC123',
    cost: 850.00,
    currency: 'USD',
  ),
);

// Get today's itinerary
final todaysSchedule = TravelModeService.instance.getTodaysItinerary();
```

#### Document Management

```dart
// Add trip-specific document
await TravelModeService.instance.addTripDocument(
  tripId,
  TravelDocument(
    id: 'doc_1',
    name: 'Hotel Confirmation',
    type: DocumentType.hotel,
    documentNumber: 'HTL456789',
    expiryDate: DateTime(2024, 6, 14),
  ),
);

// Add shared document (reusable across trips)
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

// Get expiring documents (6 months or less)
final expiringDocs = TravelModeService.instance.getExpiringDocuments();

// Get expired documents
final expiredDocs = TravelModeService.instance.getExpiredDocuments();
```

#### Expense Management

```dart
// Add expense
await TravelModeService.instance.addExpense(
  tripId,
  TravelExpense(
    id: 'exp_1',
    description: 'Dinner at restaurant',
    amount: 85.50,
    currency: 'USD',
    category: ExpenseCategory.food,
    date: DateTime.now(),
    location: 'Tokyo, Japan',
  ),
);

// Get expenses by category
final categoryTotals = TravelModeService.instance.getExpensesByCategory(tripId);
// Returns: {food: 285.50, transport: 450.00, ...}

// Get trip statistics
final stats = TravelModeService.instance.getTripStats(tripId);
// Returns: {totalExpenses: 1250.00, expensesByCategory: {...}, ...}
```

#### Companion Management

```dart
// Add companion
await TravelModeService.instance.addCompanion(
  tripId,
  TravelCompanion(
    id: 'comp_1',
    name: 'Jane Doe',
    relationship: 'Spouse',
    email: 'jane@example.com',
    phone: '+1-555-0123',
    passportNumber: 'US987654321',
    emergencyContact: 'Mother: +1-555-9999',
  ),
);
```

## Data Models

### TravelTrip
- `id`, `name`, `destination`
- `startDate`, `endDate`, `status`, `type`
- `countries[]`, `cities[]`
- `companions[]`, `documents[]`, `itinerary[]`, `expenses[]`
- `localEmergencyContact`, `accommodation`
- Computed: `isActive`, `isUpcoming`, `isPast`, `duration`, `daysRemaining`, `totalExpenses`

### TravelDocument
- `id`, `name`, `type`, `documentNumber`
- `issuingCountry`, `issueDate`, `expiryDate`
- Computed: `isExpired`, `isExpiringSoon` (180 days)

### ItineraryItem
- `id`, `title`, `type`, `startTime`, `endTime`
- `location`, `address`, `confirmationNumber`
- `cost`, `currency`, `notes`
- Computed: `isPast`, `isToday`

### TravelExpense
- `id`, `description`, `amount`, `currency`
- `category`, `date`, `location`
- `receiptUrl`, `notes`

## Testing

### Generate Test Data

```dart
import 'package:redping_14v/utils/travel_mode_test_data.dart';

// Generate all test data
await TravelModeTestData.generateAll();

// Clear test data
await TravelModeTestData.clearAll();
```

Test data includes:
- 3 trips (upcoming, active, past)
- Multiple itinerary items per trip
- Shared documents (passport, license, insurance)
- Documents with various expiry dates
- Expenses across all categories
- Companions with emergency contacts

## Best Practices

### Document Management
1. **Upload Early**: Add documents as soon as bookings are confirmed
2. **Check Expiry**: Review document alerts before finalizing travel plans
3. **Shared Documents**: Use shared documents for items valid across trips (passport)
4. **6-Month Rule**: Many countries require passport valid 6+ months beyond travel dates

### Expense Tracking
1. **Real-Time Entry**: Log expenses as they occur
2. **Keep Receipts**: Store receipt URLs for important purchases
3. **Currency Consistency**: Use local currency for accuracy
4. **Categorize Correctly**: Proper categories enable better analysis

### Itinerary Planning
1. **Buffer Time**: Add travel time between activities
2. **Confirmation Numbers**: Always include for easy reference
3. **Contact Info**: Add addresses and phone numbers
4. **Emergency Contacts**: Update local emergency info for each destination

### Trip Organization
1. **Descriptive Names**: Use clear, memorable trip names
2. **Accurate Dates**: Double-check all dates before finalizing
3. **Companion Info**: Ensure emergency contacts are current
4. **Pre-Trip Review**: Check all documents, itinerary, and bookings before departure

## Troubleshooting

### Documents Not Showing Alerts
- Check expiry dates are set correctly
- Ensure dates are in the future (expired shows RED)
- Verify document type is set

### Expenses Not Calculating
- Confirm expenses are added to correct trip
- Check currency values are numeric
- Verify trip ID matches

### Itinerary Not Grouping
- Ensure start times are set
- Check dates fall within trip date range
- Verify itinerary items belong to active trip

## Security & Privacy

- All data stored locally via SharedPreferences
- No automatic cloud sync (user controls data sharing)
- Emergency contacts encrypted at rest
- Document numbers masked in UI previews
- Expense data never shared without explicit user action

## Future Enhancements

Potential features for future versions:
- Cloud backup and sync across devices
- Offline maps integration
- Weather forecasts for destinations
- Currency conversion with live rates
- Packing list generator
- Travel insurance recommendations
- Flight status tracking
- Translation tools integration
