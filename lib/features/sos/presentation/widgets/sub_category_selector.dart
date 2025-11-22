import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/help_category.dart';

/// Widget for selecting help sub-categories
class SubCategorySelector extends StatelessWidget {
  final HelpCategory category;
  final String? selectedSubCategoryId;
  final Function(String?) onSubCategorySelected;

  const SubCategorySelector({
    super.key,
    required this.category,
    this.selectedSubCategoryId,
    required this.onSubCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (category.subCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Specific Issue:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        ...category.subCategories.map(
          (subCategory) => _buildSubCategoryCard(subCategory),
        ),
      ],
    );
  }

  Widget _buildSubCategoryCard(HelpSubCategory subCategory) {
    final isSelected = selectedSubCategoryId == subCategory.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppTheme.primaryRed.withValues(alpha: 0.1)
            : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () =>
              onSubCategorySelected(isSelected ? null : subCategory.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryRed
                    : AppTheme.neutralGray.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getSubCategoryIcon(subCategory.icon),
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.secondaryText,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subCategory.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryRed
                              : AppTheme.primaryText,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryRed,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subCategory.description,
                  style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 12),
                _buildEquipmentAndSkills(subCategory),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentAndSkills(HelpSubCategory subCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subCategory.requiredEquipment.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.build, size: 14, color: AppTheme.infoBlue),
              const SizedBox(width: 4),
              Text(
                'Equipment:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: subCategory.requiredEquipment
                .take(3)
                .map(
                  (equipment) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoBlue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      equipment,
                      style: TextStyle(fontSize: 10, color: AppTheme.infoBlue),
                    ),
                  ),
                )
                .toList(),
          ),
          if (subCategory.requiredEquipment.length > 3)
            Text(
              '+${subCategory.requiredEquipment.length - 3} more',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.infoBlue.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 6),
        ],
        if (subCategory.requiredSkills.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.school, size: 14, color: AppTheme.successGreen),
              const SizedBox(width: 4),
              Text(
                'Skills:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: subCategory.requiredSkills
                .take(2)
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (subCategory.requiredSkills.length > 2)
            Text(
              '+${subCategory.requiredSkills.length - 2} more',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.successGreen.withValues(alpha: 0.7),
              ),
            ),
        ],
      ],
    );
  }

  IconData _getSubCategoryIcon(String iconName) {
    switch (iconName) {
      case 'tire_repair':
        return Icons.tire_repair;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'car_crash':
        return Icons.car_crash;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'propeller':
        return Icons.settings;
      default:
        return Icons.help_outline;
    }
  }
}
