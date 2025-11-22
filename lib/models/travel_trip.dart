/// Data models for travel trip management
library;

/// Travel trip with itinerary, documents, and companions
class TravelTrip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime? endDate;
  final TripStatus status;
  final TripType type;
  final String? description;
  final String? accommodation;
  final List<String> countries; // Countries visiting
  final List<String> cities; // Cities visiting
  final List<TravelCompanion> companions;
  final List<TravelDocument> documents;
  final List<ItineraryItem> itinerary;
  final List<TravelExpense> expenses;
  final EmergencyContact? localEmergencyContact;
  final String? notes;
  final Map<String, dynamic>? customData;

  const TravelTrip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    this.endDate,
    this.status = TripStatus.planned,
    this.type = TripType.leisure,
    this.description,
    this.accommodation,
    this.countries = const [],
    this.cities = const [],
    this.companions = const [],
    this.documents = const [],
    this.itinerary = const [],
    this.expenses = const [],
    this.localEmergencyContact,
    this.notes,
    this.customData,
  });

  bool get isActive => status == TripStatus.active;
  bool get isUpcoming =>
      status == TripStatus.planned && startDate.isAfter(DateTime.now());
  bool get isPast =>
      status == TripStatus.completed ||
      (endDate != null && endDate!.isBefore(DateTime.now()));

  Duration? get duration =>
      endDate?.difference(startDate);

  int get daysRemaining => startDate.difference(DateTime.now()).inDays;

  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);

  TravelTrip copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    TripStatus? status,
    TripType? type,
    String? description,
    String? accommodation,
    List<String>? countries,
    List<String>? cities,
    List<TravelCompanion>? companions,
    List<TravelDocument>? documents,
    List<ItineraryItem>? itinerary,
    List<TravelExpense>? expenses,
    EmergencyContact? localEmergencyContact,
    String? notes,
    Map<String, dynamic>? customData,
  }) {
    return TravelTrip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      type: type ?? this.type,
      description: description ?? this.description,
      accommodation: accommodation ?? this.accommodation,
      countries: countries ?? this.countries,
      cities: cities ?? this.cities,
      companions: companions ?? this.companions,
      documents: documents ?? this.documents,
      itinerary: itinerary ?? this.itinerary,
      expenses: expenses ?? this.expenses,
      localEmergencyContact:
          localEmergencyContact ?? this.localEmergencyContact,
      notes: notes ?? this.notes,
      customData: customData ?? this.customData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'description': description,
      'accommodation': accommodation,
      'countries': countries,
      'cities': cities,
      'companions': companions.map((c) => c.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'itinerary': itinerary.map((i) => i.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'localEmergencyContact': localEmergencyContact?.toJson(),
      'notes': notes,
      'customData': customData,
    };
  }

  factory TravelTrip.fromJson(Map<String, dynamic> json) {
    return TravelTrip(
      id: json['id'] as String,
      name: json['name'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TripStatus.planned,
      ),
      type: TripType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TripType.leisure,
      ),
      description: json['description'] as String?,
      accommodation: json['accommodation'] as String?,
      countries: (json['countries'] as List<dynamic>?)?.cast<String>() ?? [],
      cities: (json['cities'] as List<dynamic>?)?.cast<String>() ?? [],
      companions:
          (json['companions'] as List<dynamic>?)
              ?.map((c) => TravelCompanion.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((d) => TravelDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      itinerary:
          (json['itinerary'] as List<dynamic>?)
              ?.map((i) => ItineraryItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      expenses:
          (json['expenses'] as List<dynamic>?)
              ?.map((e) => TravelExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      localEmergencyContact: json['localEmergencyContact'] != null
          ? EmergencyContact.fromJson(
              json['localEmergencyContact'] as Map<String, dynamic>,
            )
          : null,
      notes: json['notes'] as String?,
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }
}

/// Trip status
enum TripStatus {
  planned, // Future trip
  active, // Currently on trip
  completed, // Trip finished
  cancelled, // Trip cancelled
}

/// Trip type
enum TripType {
  leisure, // Vacation/holiday
  business, // Work travel
  family, // Family visit
  adventure, // Adventure travel
  backpacking, // Backpacking trip
  cruise, // Cruise vacation
  roadTrip, // Road trip
  other, // Other
}

/// Travel companion
class TravelCompanion {
  final String id;
  final String name;
  final String? relationship;
  final String? email;
  final String? phone;
  final String? passportNumber;
  final String? emergencyContact;
  final String? notes;

  const TravelCompanion({
    required this.id,
    required this.name,
    this.relationship,
    this.email,
    this.phone,
    this.passportNumber,
    this.emergencyContact,
    this.notes,
  });

  TravelCompanion copyWith({
    String? name,
    String? relationship,
    String? email,
    String? phone,
    String? passportNumber,
    String? emergencyContact,
    String? notes,
  }) {
    return TravelCompanion(
      id: id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passportNumber: passportNumber ?? this.passportNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'email': email,
      'phone': phone,
      'passportNumber': passportNumber,
      'emergencyContact': emergencyContact,
      'notes': notes,
    };
  }

  factory TravelCompanion.fromJson(Map<String, dynamic> json) {
    return TravelCompanion(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      passportNumber: json['passportNumber'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Travel document (passport, visa, tickets, etc.)
class TravelDocument {
  final String id;
  final String name;
  final DocumentType type;
  final String? documentNumber;
  final String? issuingCountry;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? fileUrl; // Cloud storage URL or local path
  final String? notes;

  const TravelDocument({
    required this.id,
    required this.name,
    required this.type,
    this.documentNumber,
    this.issuingCountry,
    this.issueDate,
    this.expiryDate,
    this.fileUrl,
    this.notes,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isExpiringSoon =>
      expiryDate != null &&
      expiryDate!.difference(DateTime.now()).inDays <= 180 &&
      !isExpired;

  TravelDocument copyWith({
    String? name,
    DocumentType? type,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? fileUrl,
    String? notes,
  }) {
    return TravelDocument(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      fileUrl: fileUrl ?? this.fileUrl,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'documentNumber': documentNumber,
      'issuingCountry': issuingCountry,
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'fileUrl': fileUrl,
      'notes': notes,
    };
  }

  factory TravelDocument.fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DocumentType.other,
      ),
      documentNumber: json['documentNumber'] as String?,
      issuingCountry: json['issuingCountry'] as String?,
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      fileUrl: json['fileUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Document types
enum DocumentType {
  passport,
  visa,
  ticket,
  boardingPass,
  hotel,
  rental,
  insurance,
  vaccination,
  driverLicense,
  other,
}

/// Itinerary item (flight, hotel, activity, etc.)
class ItineraryItem {
  final String id;
  final String title;
  final ItineraryType type;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? address;
  final String? confirmationNumber;
  final String? notes;
  final double? cost;
  final String? currency;
  final Map<String, dynamic>? details; // Type-specific details

  const ItineraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    this.endTime,
    this.location,
    this.address,
    this.confirmationNumber,
    this.notes,
    this.cost,
    this.currency,
    this.details,
  });

  bool get isPast => (endTime ?? startTime).isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    final date = startTime;
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  ItineraryItem copyWith({
    String? title,
    ItineraryType? type,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? address,
    String? confirmationNumber,
    String? notes,
    double? cost,
    String? currency,
    Map<String, dynamic>? details,
  }) {
    return ItineraryItem(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      address: address ?? this.address,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'address': address,
      'confirmationNumber': confirmationNumber,
      'notes': notes,
      'cost': cost,
      'currency': currency,
      'details': details,
    };
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ItineraryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ItineraryType.other,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      location: json['location'] as String?,
      address: json['address'] as String?,
      confirmationNumber: json['confirmationNumber'] as String?,
      notes: json['notes'] as String?,
      cost: json['cost'] as double?,
      currency: json['currency'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

/// Itinerary item types
enum ItineraryType {
  flight,
  train,
  bus,
  car,
  hotel,
  restaurant,
  activity,
  tour,
  meeting,
  other,
}

/// Travel expense
class TravelExpense {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final String? location;
  final String? receiptUrl;
  final String? notes;

  const TravelExpense({
    required this.id,
    required this.description,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    required this.date,
    this.location,
    this.receiptUrl,
    this.notes,
  });

  TravelExpense copyWith({
    String? description,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    DateTime? date,
    String? location,
    String? receiptUrl,
    String? notes,
  }) {
    return TravelExpense(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      location: location ?? this.location,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.toString().split('.').last,
      'date': date.toIso8601String(),
      'location': location,
      'receiptUrl': receiptUrl,
      'notes': notes,
    };
  }

  factory TravelExpense.fromJson(Map<String, dynamic> json) {
    return TravelExpense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: json['amount'] as double,
      currency: json['currency'] as String? ?? 'USD',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Expense categories
enum ExpenseCategory {
  transport,
  accommodation,
  food,
  activities,
  shopping,
  healthcare,
  communication,
  other,
}

/// Emergency contact
class EmergencyContact {
  final String name;
  final String phone;
  final String? relationship;
  final String? email;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relationship,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'email': email,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String?,
      email: json['email'] as String?,
    );
  }
}
