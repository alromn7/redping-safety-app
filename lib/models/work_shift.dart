/// Represents a work shift with schedule, tasks, and tracking
class WorkShift {
  final String id;
  final String jobTitle;
  final String employer;
  final DateTime shiftDate;
  final DateTime startTime;
  final DateTime endTime;
  final WorkShiftStatus status;
  final WorkShiftType type;
  final String location;
  final String? address;
  final String? supervisor;
  final String? supervisorPhone;
  final List<WorkTask> tasks;
  final List<WorkBreak> breaks;
  final List<WorkIncident> incidents;
  final WorkTimeTracking? timeTracking;
  final String? notes;
  final String? uniformRequirements;
  final String? equipment;

  const WorkShift({
    required this.id,
    required this.jobTitle,
    required this.employer,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    required this.location,
    this.address,
    this.supervisor,
    this.supervisorPhone,
    this.tasks = const [],
    this.breaks = const [],
    this.incidents = const [],
    this.timeTracking,
    this.notes,
    this.uniformRequirements,
    this.equipment,
  });

  // Computed properties
  bool get isActive => status == WorkShiftStatus.inProgress;
  bool get isUpcoming =>
      status == WorkShiftStatus.scheduled && shiftDate.isAfter(DateTime.now());
  bool get isPast => status == WorkShiftStatus.completed;
  bool get isToday {
    final now = DateTime.now();
    return shiftDate.year == now.year &&
        shiftDate.month == now.month &&
        shiftDate.day == now.day;
  }

  Duration get scheduledDuration => endTime.difference(startTime);

  Duration? get actualDuration {
    if (timeTracking?.clockInTime != null &&
        timeTracking?.clockOutTime != null) {
      return timeTracking!.clockOutTime!.difference(timeTracking!.clockInTime!);
    }
    return null;
  }

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => tasks.length;
  double get taskCompletionRate {
    if (totalTasksCount == 0) return 0.0;
    return (completedTasksCount / totalTasksCount) * 100;
  }

  Duration get totalBreakTime {
    return breaks.fold(
      Duration.zero,
      (total, b) => total + (b.duration ?? Duration.zero),
    );
  }

  bool get hasIncidents => incidents.isNotEmpty;
  int get criticalIncidentsCount =>
      incidents.where((i) => i.severity == IncidentSeverity.critical).length;

  WorkShift copyWith({
    String? id,
    String? jobTitle,
    String? employer,
    DateTime? shiftDate,
    DateTime? startTime,
    DateTime? endTime,
    WorkShiftStatus? status,
    WorkShiftType? type,
    String? location,
    String? address,
    String? supervisor,
    String? supervisorPhone,
    List<WorkTask>? tasks,
    List<WorkBreak>? breaks,
    List<WorkIncident>? incidents,
    WorkTimeTracking? timeTracking,
    String? notes,
    String? uniformRequirements,
    String? equipment,
  }) {
    return WorkShift(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      employer: employer ?? this.employer,
      shiftDate: shiftDate ?? this.shiftDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      location: location ?? this.location,
      address: address ?? this.address,
      supervisor: supervisor ?? this.supervisor,
      supervisorPhone: supervisorPhone ?? this.supervisorPhone,
      tasks: tasks ?? this.tasks,
      breaks: breaks ?? this.breaks,
      incidents: incidents ?? this.incidents,
      timeTracking: timeTracking ?? this.timeTracking,
      notes: notes ?? this.notes,
      uniformRequirements: uniformRequirements ?? this.uniformRequirements,
      equipment: equipment ?? this.equipment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'employer': employer,
      'shiftDate': shiftDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'location': location,
      'address': address,
      'supervisor': supervisor,
      'supervisorPhone': supervisorPhone,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'breaks': breaks.map((b) => b.toJson()).toList(),
      'incidents': incidents.map((i) => i.toJson()).toList(),
      'timeTracking': timeTracking?.toJson(),
      'notes': notes,
      'uniformRequirements': uniformRequirements,
      'equipment': equipment,
    };
  }

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String,
      employer: json['employer'] as String,
      shiftDate: DateTime.parse(json['shiftDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: WorkShiftStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      type: WorkShiftType.values.firstWhere((e) => e.name == json['type']),
      location: json['location'] as String,
      address: json['address'] as String?,
      supervisor: json['supervisor'] as String?,
      supervisorPhone: json['supervisorPhone'] as String?,
      tasks:
          (json['tasks'] as List?)?.map((t) => WorkTask.fromJson(t)).toList() ??
          [],
      breaks:
          (json['breaks'] as List?)
              ?.map((b) => WorkBreak.fromJson(b))
              .toList() ??
          [],
      incidents:
          (json['incidents'] as List?)
              ?.map((i) => WorkIncident.fromJson(i))
              .toList() ??
          [],
      timeTracking: json['timeTracking'] != null
          ? WorkTimeTracking.fromJson(json['timeTracking'])
          : null,
      notes: json['notes'] as String?,
      uniformRequirements: json['uniformRequirements'] as String?,
      equipment: json['equipment'] as String?,
    );
  }
}

/// Work task within a shift
class WorkTask {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  const WorkTask({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  WorkTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return WorkTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory WorkTask.fromJson(Map<String, dynamic> json) {
    return WorkTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'] as String?,
    );
  }
}

/// Break during work shift
class WorkBreak {
  final String id;
  final BreakType type;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  const WorkBreak({
    required this.id,
    required this.type,
    this.startTime,
    this.endTime,
    this.notes,
  });

  Duration? get duration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  bool get isActive => startTime != null && endTime == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory WorkBreak.fromJson(Map<String, dynamic> json) {
    return WorkBreak(
      id: json['id'] as String,
      type: BreakType.values.firstWhere((e) => e.name == json['type']),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      notes: json['notes'] as String?,
    );
  }
}

/// Incident reporting during shift
class WorkIncident {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentSeverity severity;
  final DateTime reportedAt;
  final String? location;
  final List<String> involvedPersons;
  final String? actionTaken;
  final bool requiresFollowUp;
  final String? followUpNotes;

  const WorkIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.reportedAt,
    this.location,
    this.involvedPersons = const [],
    this.actionTaken,
    this.requiresFollowUp = false,
    this.followUpNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'severity': severity.name,
      'reportedAt': reportedAt.toIso8601String(),
      'location': location,
      'involvedPersons': involvedPersons,
      'actionTaken': actionTaken,
      'requiresFollowUp': requiresFollowUp,
      'followUpNotes': followUpNotes,
    };
  }

  factory WorkIncident.fromJson(Map<String, dynamic> json) {
    return WorkIncident(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: IncidentType.values.firstWhere((e) => e.name == json['type']),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      location: json['location'] as String?,
      involvedPersons: (json['involvedPersons'] as List?)?.cast<String>() ?? [],
      actionTaken: json['actionTaken'] as String?,
      requiresFollowUp: json['requiresFollowUp'] as bool? ?? false,
      followUpNotes: json['followUpNotes'] as String?,
    );
  }
}

/// Time tracking for shift
class WorkTimeTracking {
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;
  final String? clockOutLocation;
  final bool isLate;
  final bool isEarlyDeparture;
  final String? notes;

  const WorkTimeTracking({
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
    this.clockOutLocation,
    this.isLate = false,
    this.isEarlyDeparture = false,
    this.notes,
  });

  bool get isClockedIn => clockInTime != null && clockOutTime == null;
  bool get isClockedOut => clockInTime != null && clockOutTime != null;

  Duration? get totalTime {
    if (clockInTime != null && clockOutTime != null) {
      return clockOutTime!.difference(clockInTime!);
    }
    return null;
  }

  WorkTimeTracking copyWith({
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? clockInLocation,
    String? clockOutLocation,
    bool? isLate,
    bool? isEarlyDeparture,
    String? notes,
  }) {
    return WorkTimeTracking(
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      clockInLocation: clockInLocation ?? this.clockInLocation,
      clockOutLocation: clockOutLocation ?? this.clockOutLocation,
      isLate: isLate ?? this.isLate,
      isEarlyDeparture: isEarlyDeparture ?? this.isEarlyDeparture,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clockInTime': clockInTime?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'clockInLocation': clockInLocation,
      'clockOutLocation': clockOutLocation,
      'isLate': isLate,
      'isEarlyDeparture': isEarlyDeparture,
      'notes': notes,
    };
  }

  factory WorkTimeTracking.fromJson(Map<String, dynamic> json) {
    return WorkTimeTracking(
      clockInTime: json['clockInTime'] != null
          ? DateTime.parse(json['clockInTime'])
          : null,
      clockOutTime: json['clockOutTime'] != null
          ? DateTime.parse(json['clockOutTime'])
          : null,
      clockInLocation: json['clockInLocation'] as String?,
      clockOutLocation: json['clockOutLocation'] as String?,
      isLate: json['isLate'] as bool? ?? false,
      isEarlyDeparture: json['isEarlyDeparture'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// Emergency contact for workplace
class WorkplaceEmergencyContact {
  final String name;
  final String phone;
  final String role;
  final String? email;

  const WorkplaceEmergencyContact({
    required this.name,
    required this.phone,
    required this.role,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'role': role, 'email': email};
  }

  factory WorkplaceEmergencyContact.fromJson(Map<String, dynamic> json) {
    return WorkplaceEmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
    );
  }
}

// Enums

enum WorkShiftStatus {
  scheduled, // Shift planned but not started
  inProgress, // Currently working
  completed, // Shift finished
  cancelled, // Shift cancelled
}

enum WorkShiftType {
  regular, // Standard shift
  overtime, // Extra hours
  onCall, // On-call duty
  remote, // Work from home
  fieldWork, // Work at various locations
  night, // Night shift
  weekend, // Weekend shift
  holiday, // Holiday shift
}

enum TaskPriority { low, medium, high, critical }

enum BreakType { lunch, coffee, rest, other }

enum IncidentType {
  safety, // Safety concern
  equipment, // Equipment issue
  customer, // Customer incident
  workplace, // Workplace issue
  health, // Health concern
  security, // Security issue
  other,
}

enum IncidentSeverity {
  low, // Minor issue
  medium, // Moderate concern
  high, // Serious issue
  critical, // Critical - immediate action required
}
