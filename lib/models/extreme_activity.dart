/// Equipment item for extreme activities
class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.activityTypes,
    this.lastInspection,
    this.nextInspection,
    this.purchaseDate,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.notes,
    this.isRequired = true,
    this.condition = EquipmentCondition.good,
  });

  final String id;
  final String name;
  final EquipmentCategory category;
  final List<String> activityTypes; // Which extreme activities need this
  final DateTime? lastInspection;
  final DateTime? nextInspection;
  final DateTime? purchaseDate;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? notes;
  final bool isRequired;
  final EquipmentCondition condition;

  bool get needsInspection {
    if (nextInspection == null) return false;
    return DateTime.now().isAfter(nextInspection!);
  }

  bool get isExpired {
    if (purchaseDate == null) return false;
    final expiryYears = _getExpiryYears();
    if (expiryYears == null) return false;
    return DateTime.now().isAfter(
      purchaseDate!.add(Duration(days: expiryYears * 365)),
    );
  }

  int? _getExpiryYears() {
    switch (category) {
      case EquipmentCategory.helmet:
      case EquipmentCategory.harness:
        return 5;
      case EquipmentCategory.rope:
        return 7;
      case EquipmentCategory.carabiner:
        return 10;
      default:
        return null;
    }
  }

  EquipmentItem copyWith({
    String? id,
    String? name,
    EquipmentCategory? category,
    List<String>? activityTypes,
    DateTime? lastInspection,
    DateTime? nextInspection,
    DateTime? purchaseDate,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? notes,
    bool? isRequired,
    EquipmentCondition? condition,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      activityTypes: activityTypes ?? this.activityTypes,
      lastInspection: lastInspection ?? this.lastInspection,
      nextInspection: nextInspection ?? this.nextInspection,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      notes: notes ?? this.notes,
      isRequired: isRequired ?? this.isRequired,
      condition: condition ?? this.condition,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'activityTypes': activityTypes,
    'lastInspection': lastInspection?.toIso8601String(),
    'nextInspection': nextInspection?.toIso8601String(),
    'purchaseDate': purchaseDate?.toIso8601String(),
    'manufacturer': manufacturer,
    'model': model,
    'serialNumber': serialNumber,
    'notes': notes,
    'isRequired': isRequired,
    'condition': condition.name,
  };

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: EquipmentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EquipmentCategory.other,
      ),
      activityTypes: (json['activityTypes'] as List<dynamic>).cast<String>(),
      lastInspection: json['lastInspection'] != null
          ? DateTime.parse(json['lastInspection'] as String)
          : null,
      nextInspection: json['nextInspection'] != null
          ? DateTime.parse(json['nextInspection'] as String)
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      notes: json['notes'] as String?,
      isRequired: json['isRequired'] as bool? ?? true,
      condition: EquipmentCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => EquipmentCondition.good,
      ),
    );
  }
}

/// Equipment categories
enum EquipmentCategory {
  helmet,
  harness,
  rope,
  carabiner,
  belay,
  wetsuit,
  drysuit,
  lifeJacket,
  avalancheBeacon,
  probe,
  shovel,
  ice,
  parachute,
  reserve,
  altimeter,
  gps,
  radio,
  firstAid,
  emergencyBeacon,
  protection,
  other,
}

/// Equipment condition
enum EquipmentCondition { excellent, good, fair, poor, retired }

/// Activity session for extreme sports
class ExtremeActivitySession {
  const ExtremeActivitySession({
    required this.id,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.location,
    this.description,
    this.distance,
    this.duration,
    this.maxSpeed,
    this.maxAltitude,
    this.altitudeGain,
    this.altitudeLoss,
    this.averageSpeed,
    this.equipmentUsed = const [],
    this.conditions,
    this.buddies = const [],
    this.notes,
    this.incidents = const [],
    this.photos = const [],
    this.rating,
  });

  final String id;
  final String activityType; // skiing, climbing, etc.
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? description;
  final double? distance; // meters
  final Duration? duration;
  final double? maxSpeed; // m/s
  final double? maxAltitude; // meters
  final double? altitudeGain; // meters
  final double? altitudeLoss; // meters
  final double? averageSpeed; // m/s
  final List<String> equipmentUsed; // Equipment IDs
  final WeatherConditions? conditions;
  final List<String> buddies; // Buddy names/IDs
  final String? notes;
  final List<String> incidents; // Any incidents/near-misses
  final List<String> photos; // Photo paths
  final int? rating; // 1-5 stars

  bool get isActive => endTime == null;

  Duration get actualDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  ExtremeActivitySession copyWith({
    String? id,
    String? activityType,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? description,
    double? distance,
    Duration? duration,
    double? maxSpeed,
    double? maxAltitude,
    double? altitudeGain,
    double? altitudeLoss,
    double? averageSpeed,
    List<String>? equipmentUsed,
    WeatherConditions? conditions,
    List<String>? buddies,
    String? notes,
    List<String>? incidents,
    List<String>? photos,
    int? rating,
  }) {
    return ExtremeActivitySession(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      description: description ?? this.description,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      altitudeGain: altitudeGain ?? this.altitudeGain,
      altitudeLoss: altitudeLoss ?? this.altitudeLoss,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      equipmentUsed: equipmentUsed ?? this.equipmentUsed,
      conditions: conditions ?? this.conditions,
      buddies: buddies ?? this.buddies,
      notes: notes ?? this.notes,
      incidents: incidents ?? this.incidents,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'location': location,
    'description': description,
    'distance': distance,
    'durationSeconds': duration?.inSeconds,
    'maxSpeed': maxSpeed,
    'maxAltitude': maxAltitude,
    'altitudeGain': altitudeGain,
    'altitudeLoss': altitudeLoss,
    'averageSpeed': averageSpeed,
    'equipmentUsed': equipmentUsed,
    'conditions': conditions?.toJson(),
    'buddies': buddies,
    'notes': notes,
    'incidents': incidents,
    'photos': photos,
    'rating': rating,
  };

  factory ExtremeActivitySession.fromJson(Map<String, dynamic> json) {
    return ExtremeActivitySession(
      id: json['id'] as String,
      activityType: json['activityType'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      location: json['location'] as String?,
      description: json['description'] as String?,
      distance: json['distance'] as double?,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'] as int)
          : null,
      maxSpeed: json['maxSpeed'] as double?,
      maxAltitude: json['maxAltitude'] as double?,
      altitudeGain: json['altitudeGain'] as double?,
      altitudeLoss: json['altitudeLoss'] as double?,
      averageSpeed: json['averageSpeed'] as double?,
      equipmentUsed:
          (json['equipmentUsed'] as List<dynamic>?)?.cast<String>() ?? [],
      conditions: json['conditions'] != null
          ? WeatherConditions.fromJson(
              json['conditions'] as Map<String, dynamic>,
            )
          : null,
      buddies: (json['buddies'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
      incidents: (json['incidents'] as List<dynamic>?)?.cast<String>() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      rating: json['rating'] as int?,
    );
  }
}

/// Weather conditions for activity
class WeatherConditions {
  const WeatherConditions({
    this.temperature,
    this.windSpeed,
    this.windDirection,
    this.visibility,
    this.precipitation,
    this.cloudCover,
    this.conditions,
  });

  final double? temperature; // Celsius
  final double? windSpeed; // m/s
  final String? windDirection; // N, NE, E, etc.
  final double? visibility; // meters
  final String? precipitation; // none, rain, snow, etc.
  final int? cloudCover; // 0-100%
  final String? conditions; // clear, cloudy, stormy, etc.

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'windSpeed': windSpeed,
    'windDirection': windDirection,
    'visibility': visibility,
    'precipitation': precipitation,
    'cloudCover': cloudCover,
    'conditions': conditions,
  };

  factory WeatherConditions.fromJson(Map<String, dynamic> json) {
    return WeatherConditions(
      temperature: json['temperature'] as double?,
      windSpeed: json['windSpeed'] as double?,
      windDirection: json['windDirection'] as String?,
      visibility: json['visibility'] as double?,
      precipitation: json['precipitation'] as String?,
      cloudCover: json['cloudCover'] as int?,
      conditions: json['conditions'] as String?,
    );
  }
}

/// Safety checklist item
class SafetyChecklistItem {
  const SafetyChecklistItem({
    required this.id,
    required this.title,
    required this.activityTypes,
    this.description,
    this.category = ChecklistCategory.general,
    this.isRequired = true,
    this.order = 0,
  });

  final String id;
  final String title;
  final List<String> activityTypes; // Which activities need this check
  final String? description;
  final ChecklistCategory category;
  final bool isRequired;
  final int order;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'activityTypes': activityTypes,
    'description': description,
    'category': category.name,
    'isRequired': isRequired,
    'order': order,
  };

  factory SafetyChecklistItem.fromJson(Map<String, dynamic> json) {
    return SafetyChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      activityTypes: (json['activityTypes'] as List<dynamic>).cast<String>(),
      description: json['description'] as String?,
      category: ChecklistCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ChecklistCategory.general,
      ),
      isRequired: json['isRequired'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }
}

/// Checklist categories
enum ChecklistCategory {
  equipment,
  weather,
  planning,
  communication,
  skills,
  general,
}

/// Completed safety check
class SafetyCheck {
  const SafetyCheck({
    required this.id,
    required this.activityType,
    required this.checklistItemId,
    required this.completedAt,
    this.notes,
    this.passed = true,
  });

  final String id;
  final String activityType;
  final String checklistItemId;
  final DateTime completedAt;
  final String? notes;
  final bool passed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType,
    'checklistItemId': checklistItemId,
    'completedAt': completedAt.toIso8601String(),
    'notes': notes,
    'passed': passed,
  };

  factory SafetyCheck.fromJson(Map<String, dynamic> json) {
    return SafetyCheck(
      id: json['id'] as String,
      activityType: json['activityType'] as String,
      checklistItemId: json['checklistItemId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
      passed: json['passed'] as bool? ?? true,
    );
  }
}
