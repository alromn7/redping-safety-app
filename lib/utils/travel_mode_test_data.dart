import '../models/travel_trip.dart';
import '../services/travel_mode_service.dart';

/// Utility class to generate test data for travel mode
class TravelModeTestData {
  static final _service = TravelModeService.instance;

  /// Generate comprehensive test data for travel mode
  static Future<void> generateAll() async {
    await generateTrips();
    await generateDocuments();
    await Future.delayed(const Duration(milliseconds: 100));
    print('✅ Travel Mode Test Data Generated Successfully!');
    print('   - ${_service.trips.length} trips');
    print('   - ${_service.sharedDocuments.length} shared documents');
  }

  /// Generate sample trips
  static Future<void> generateTrips() async {
    // Upcoming trip to Japan
    final japanTrip = await _service.createTrip(
      name: 'Japan Adventure',
      destination: 'Tokyo, Kyoto, Osaka',
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 44)),
      type: TripType.leisure,
      description: 'Two weeks exploring Japanese culture, food, and temples',
      countries: ['Japan'],
      cities: ['Tokyo', 'Kyoto', 'Osaka', 'Nara'],
    );

    // Add itinerary for Japan trip
    await _service.addItineraryItem(
      japanTrip.id,
      ItineraryItem(
        id: 'flight_to_tokyo',
        title: 'Flight to Tokyo (Narita)',
        type: ItineraryType.flight,
        startTime: japanTrip.startDate,
        endTime: japanTrip.startDate.add(const Duration(hours: 13)),
        location: 'Narita International Airport',
        confirmationNumber: 'JL123ABC',
        cost: 850.00,
        currency: 'USD',
        details: {
          'airline': 'Japan Airlines',
          'flightNumber': 'JL 123',
          'seat': '14A',
        },
      ),
    );

    await _service.addItineraryItem(
      japanTrip.id,
      ItineraryItem(
        id: 'hotel_tokyo',
        title: 'Check-in: Park Hyatt Tokyo',
        type: ItineraryType.hotel,
        startTime: japanTrip.startDate.add(const Duration(hours: 15)),
        endTime: japanTrip.startDate.add(const Duration(days: 5)),
        location: 'Shinjuku, Tokyo',
        address: '3-7-1-2 Nishi-Shinjuku',
        confirmationNumber: 'PH78945',
        cost: 450.00,
        currency: 'USD',
        notes: 'Late check-in arranged',
      ),
    );

    // Add companions
    await _service.addCompanion(
      japanTrip.id,
      const TravelCompanion(
        id: 'companion_sarah',
        name: 'Sarah Johnson',
        relationship: 'Spouse',
        email: 'sarah.j@email.com',
        phone: '+1-555-0102',
        passportNumber: 'US1234567',
        emergencyContact: '+1-555-0199 (Mother)',
      ),
    );

    // Add documents for Japan trip
    await _service.addTripDocument(
      japanTrip.id,
      TravelDocument(
        id: 'japan_visa',
        name: 'Japan Tourist Visa',
        type: DocumentType.visa,
        documentNumber: 'JP2024-5678',
        issuingCountry: 'Japan',
        issueDate: DateTime.now().subtract(const Duration(days: 15)),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        notes: 'Multiple entry visa, valid for 1 year',
      ),
    );

    // Past trip to Europe
    final europeTrip = await _service.createTrip(
      name: 'European Summer',
      destination: 'Paris, Rome, Barcelona',
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      endDate: DateTime.now().subtract(const Duration(days: 76)),
      type: TripType.leisure,
      description: 'Summer vacation across three European cities',
      countries: ['France', 'Italy', 'Spain'],
      cities: ['Paris', 'Rome', 'Barcelona'],
    );

    // Update to completed status
    final completedEurope = europeTrip.copyWith(status: TripStatus.completed);
    await _service.updateTrip(completedEurope);

    // Add expenses to Europe trip
    await _service.addExpense(
      europeTrip.id,
      TravelExpense(
        id: 'exp_flight_europe',
        description: 'Round-trip flights to Paris',
        amount: 1200.00,
        currency: 'USD',
        category: ExpenseCategory.transport,
        date: europeTrip.startDate,
        location: 'Online booking',
      ),
    );

    await _service.addExpense(
      europeTrip.id,
      TravelExpense(
        id: 'exp_hotel_paris',
        description: 'Hotel Le Marais - 5 nights',
        amount: 750.00,
        currency: 'USD',
        category: ExpenseCategory.accommodation,
        date: europeTrip.startDate,
        location: 'Paris, France',
      ),
    );

    await _service.addExpense(
      europeTrip.id,
      TravelExpense(
        id: 'exp_dinner_rome',
        description: 'Dinner at Trattoria',
        amount: 85.00,
        currency: 'EUR',
        category: ExpenseCategory.food,
        date: europeTrip.startDate.add(const Duration(days: 6)),
        location: 'Rome, Italy',
      ),
    );

    await _service.addExpense(
      europeTrip.id,
      TravelExpense(
        id: 'exp_museum',
        description: 'Vatican Museums tickets',
        amount: 120.00,
        currency: 'EUR',
        category: ExpenseCategory.activities,
        date: europeTrip.startDate.add(const Duration(days: 7)),
        location: 'Vatican City',
      ),
    );

    // Business trip next week
    final businessTrip = await _service.createTrip(
      name: 'Tech Conference SF',
      destination: 'San Francisco, CA',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      type: TripType.business,
      description: 'Annual tech conference and client meetings',
      countries: ['USA'],
      cities: ['San Francisco'],
    );

    // Add meeting to itinerary
    await _service.addItineraryItem(
      businessTrip.id,
      ItineraryItem(
        id: 'client_meeting',
        title: 'Client Meeting - TechCorp',
        type: ItineraryType.meeting,
        startTime: businessTrip.startDate.add(
          const Duration(days: 1, hours: 10),
        ),
        endTime: businessTrip.startDate.add(const Duration(days: 1, hours: 12)),
        location: 'TechCorp HQ',
        address: '1 Market Street, San Francisco',
        notes: 'Bring product demo',
      ),
    );

    print('Generated ${_service.trips.length} sample trips');
  }

  /// Generate shared documents (not trip-specific)
  static Future<void> generateDocuments() async {
    // Passport
    await _service.addSharedDocument(
      TravelDocument(
        id: 'passport_us',
        name: 'US Passport',
        type: DocumentType.passport,
        documentNumber: 'US987654321',
        issuingCountry: 'United States',
        issueDate: DateTime(2019, 6, 15),
        expiryDate: DateTime(2029, 6, 15),
        notes: 'Valid for 10 years, renewed in 2019',
      ),
    );

    // Driver's License
    await _service.addSharedDocument(
      TravelDocument(
        id: 'dl_ca',
        name: 'California Driver License',
        type: DocumentType.driverLicense,
        documentNumber: 'D1234567',
        issuingCountry: 'USA',
        issueDate: DateTime(2022, 3, 1),
        expiryDate: DateTime(2027, 3, 1),
        notes: 'Valid for international driving permit',
      ),
    );

    // Travel Insurance
    await _service.addSharedDocument(
      TravelDocument(
        id: 'insurance_travel',
        name: 'Annual Travel Insurance',
        type: DocumentType.insurance,
        documentNumber: 'TRV-2024-99887',
        issuingCountry: 'USA',
        issueDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2025, 1, 1),
        notes: 'Worldwide coverage, medical + cancellation',
      ),
    );

    // Vaccination card
    await _service.addSharedDocument(
      TravelDocument(
        id: 'vacc_covid',
        name: 'COVID-19 Vaccination Record',
        type: DocumentType.vaccination,
        issueDate: DateTime(2023, 5, 10),
        notes: 'Updated booster - May 2023',
      ),
    );

    // Expiring soon document (for testing alerts)
    await _service.addSharedDocument(
      TravelDocument(
        id: 'visa_expiring',
        name: 'Schengen Visa (Expiring Soon)',
        type: DocumentType.visa,
        documentNumber: 'EU-2024-123',
        issuingCountry: 'France',
        issueDate: DateTime(2024, 1, 1),
        expiryDate: DateTime.now().add(
          const Duration(days: 60),
        ), // Expires in 60 days
        notes: 'Need to renew before next trip',
      ),
    );

    print('Added ${_service.sharedDocuments.length} shared documents');
  }

  /// Clear all test data
  static Future<void> clearAll() async {
    for (final trip in _service.trips.toList()) {
      await _service.deleteTrip(trip.id);
    }
    for (final doc in _service.sharedDocuments.toList()) {
      await _service.removeSharedDocument(doc.id);
    }
    print('Cleared all travel test data');
  }
}
