import 'package:equatable/equatable.dart';
import 'help_request.dart';

/// Model representing a help sub-category
class HelpSubCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> requiredEquipment;
  final List<String> requiredSkills;

  const HelpSubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredEquipment,
    required this.requiredSkills,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'requiredEquipment': requiredEquipment,
      'requiredSkills': requiredSkills,
    };
  }

  /// Create from JSON
  factory HelpSubCategory.fromJson(Map<String, dynamic> json) {
    return HelpSubCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requiredEquipment: List<String>.from(json['requiredEquipment'] ?? []),
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    requiredEquipment,
    requiredSkills,
  ];
}

/// Model representing a help category
class HelpCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final HelpPriority priority;
  final List<String> requiredServices;
  final List<HelpSubCategory> subCategories;

  const HelpCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.priority,
    required this.requiredServices,
    this.subCategories = const [],
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'priority': priority.name,
      'requiredServices': requiredServices,
      'subCategories': subCategories.map((sub) => sub.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory HelpCategory.fromJson(Map<String, dynamic> json) {
    return HelpCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      priority: HelpPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => HelpPriority.low,
      ),
      requiredServices: List<String>.from(json['requiredServices'] ?? []),
      subCategories: (json['subCategories'] as List<dynamic>?)
          ?.map((sub) => HelpSubCategory.fromJson(sub as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    priority,
    requiredServices,
    subCategories,
  ];
}
