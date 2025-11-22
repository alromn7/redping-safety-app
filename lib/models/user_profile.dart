import 'package:equatable/equatable.dart';

/// Model representing user profile data
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? phoneNumber;
  final String? avatar;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> medications;
  final Map<String, dynamic> preferences;
  final List<String> emergencyContacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.phoneNumber,
    this.avatar,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.medications = const [],
    this.preferences = const {},
    this.emergencyContacts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this user profile with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? phoneNumber,
    String? avatar,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? medications,
    Map<String, dynamic>? preferences,
    List<String>? emergencyContacts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      preferences: preferences ?? this.preferences,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'medications': medications,
      'preferences': preferences,
      'emergencyContacts': emergencyContacts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bloodType: json['bloodType'] as String?,
      allergies: List<String>.from(json['allergies'] ?? []),
      medicalConditions: List<String>.from(json['medicalConditions'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    phoneNumber,
    avatar,
    dateOfBirth,
    age,
    gender,
    bloodType,
    allergies,
    medicalConditions,
    medications,
    preferences,
    emergencyContacts,
    createdAt,
    updatedAt,
  ];
}
