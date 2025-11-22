import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/help_service.dart';
import '../../../../models/help_category.dart';
import '../../../../models/help_request.dart';
import '../../../../utils/iterable_extensions.dart';

/// Optimized Help Request Page with Category and Sub-Category Selection
class HelpAssistantPage extends StatefulWidget {
  const HelpAssistantPage({super.key});

  @override
  State<HelpAssistantPage> createState() => _HelpAssistantPageState();
}

class _HelpAssistantPageState extends State<HelpAssistantPage> {
  final HelpService _helpService = HelpService();
  HelpCategory? _selectedCategory;
  HelpSubCategory? _selectedSubCategory;
  String _description = '';
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeHelpService();
  }

  Future<void> _initializeHelpService() async {
    try {
      await _helpService.initialize();
    } catch (e) {
      debugPrint('HelpAssistantPage: HelpService init failed - $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RedPing Help'),
        elevation: 0,
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryRed, AppTheme.criticalRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RedPing Help',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Choose assistance type. We'll connect you to local services or a community helper.",
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick access chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.home, size: 16),
                  label: const Text('Safe Shelter'),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () =>
                      _quickSelect('domestic_violence', 'safe_shelter'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.pets, size: 16),
                  label: const Text('Lost Pet Now'),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => _quickSelect('lost_pet', 'lost_dog'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.report, size: 16),
                  label: const Text('Report Theft'),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () =>
                      _quickSelect('theft_report', 'post_theft_report'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.medical_services, size: 16),
                  label: const Text('Overdose Help'),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => _quickSelect('drug_abuse', 'overdose'),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _selectedCategory == null
                ? _buildCategoryGrid()
                : _selectedSubCategory == null
                ? _buildSubCategoryList()
                : _buildRequestForm(),
          ),
        ],
      ),
    );
  }

  /// Build compact category grid
  Widget _buildCategoryGrid() {
    final categories = _dedupById(_helpService.getHelpCategories());

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        const Text(
          'What do you need help with?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCompactCategoryCard(category);
          },
        ),
      ],
    );
  }

  /// Build compact category card
  Widget _buildCompactCategoryCard(HelpCategory category) {
    final priorityColor = _getPriorityColor(category.priority);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
            _selectedSubCategory = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(category.icon),
                  color: priorityColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.subCategories.isNotEmpty)
                Text(
                  '${category.subCategories.length} options',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build sub-category list
  Widget _buildSubCategoryList() {
    if (_selectedCategory == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        // Back button and category header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedCategory!.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sub-categories or direct submit
        if (_selectedCategory!.subCategories.isEmpty)
          _buildDirectSubmitOption()
        else
          ..._selectedCategory!.subCategories.map((subCat) {
            return _buildSubCategoryCard(subCat);
          }),
      ],
    );
  }

  /// Build sub-category card
  Widget _buildSubCategoryCard(HelpSubCategory subCategory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(subCategory.icon),
            color: AppTheme.primaryRed,
            size: 20,
          ),
        ),
        title: Text(
          subCategory.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subCategory.description,
          style: const TextStyle(fontSize: 11),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          setState(() {
            _selectedSubCategory = subCategory;
          });
        },
      ),
    );
  }

  /// Build direct submit option for categories without sub-categories
  Widget _buildDirectSubmitOption() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your situation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Provide details about your help request...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _description.trim().isEmpty ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Submit Help Request',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build request form
  Widget _buildRequestForm() {
    if (_selectedCategory == null || _selectedSubCategory == null) {
      return const SizedBox();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        // Back button and header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedSubCategory = null;
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSubCategory!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_selectedCategory!.name} > ${_selectedSubCategory!.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe the situation',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedSubCategory!.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Provide additional details...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _description = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Required equipment info
        if (_selectedSubCategory!.requiredEquipment.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.build, size: 16, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'Required Equipment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSubCategory!.requiredEquipment
                        .map(
                          (equipment) => Chip(
                            label: Text(
                              equipment,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.blue[50],
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _description.trim().isEmpty ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit Help Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Submit help request
  Future<void> _submitRequest() async {
    if (_selectedCategory == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create help request
      await _helpService.createHelpRequest(
        categoryId: _selectedCategory!.id,
        subCategoryId: _selectedSubCategory?.id,
        description: _description.trim(),
      );

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show success and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Help request submitted successfully!'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  /// Get icon for category
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'car_repair':
        return Icons.car_repair;
      case 'directions_boat':
        return Icons.directions_boat;
      case 'security':
        return Icons.security;
      case 'pets':
        return Icons.pets;
      case 'home_work':
        return Icons.home_work;
      case 'home':
        return Icons.home;
      case 'medical_services':
        return Icons.medical_services;
      case 'warning':
        return Icons.warning;
      case 'person_search':
        return Icons.person_search;
      case 'car_crash':
        return Icons.car_crash;
      case 'search':
        return Icons.search;
      case 'report':
        return Icons.report;
      case 'priority_high':
        return Icons.priority_high;
      case 'people':
        return Icons.people;
      case 'visibility':
        return Icons.visibility;
      case 'shield':
        return Icons.shield;
      case 'tire_repair':
        return Icons.car_repair;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'build':
        return Icons.build;
      case 'gavel':
        return Icons.gavel;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'devices':
        return Icons.devices;
      case 'description':
        return Icons.description;
      case 'assignment':
        return Icons.assignment;
      case 'support':
        return Icons.support_agent;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'flutter_dash':
        return Icons.flutter_dash;
      case 'propeller':
        return Icons.settings;
      default:
        return Icons.help_outline;
    }
  }

  /// Get priority color
  Color _getPriorityColor(HelpPriority priority) {
    switch (priority) {
      case HelpPriority.critical:
        return AppTheme.criticalRed;
      case HelpPriority.high:
        return AppTheme.primaryRed;
      case HelpPriority.medium:
        return AppTheme.warningOrange;
      case HelpPriority.low:
        return AppTheme.infoBlue;
    }
  }

  // De-duplicate categories by id to avoid duplicates in service data
  List<HelpCategory> _dedupById(List<HelpCategory> list) {
    final seen = <String>{};
    final result = <HelpCategory>[];
    for (final c in list) {
      if (!seen.contains(c.id)) {
        seen.add(c.id);
        result.add(c);
      }
    }
    return result;
  }

  // Quick selection handler to jump into a category/subcategory
  void _quickSelect(String categoryId, String? subCategoryId) {
    final categories = _dedupById(_helpService.getHelpCategories());
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    if (cat == null) return;
    HelpSubCategory? sub;
    if (subCategoryId != null) {
      sub = cat.subCategories.where((s) => s.id == subCategoryId).firstOrNull;
    }
    setState(() {
      _selectedCategory = cat;
      _selectedSubCategory = sub;
    });
  }
}
