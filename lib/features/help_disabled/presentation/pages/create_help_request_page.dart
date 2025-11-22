/*
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';
import '../../../../models/sos_session.dart'; // For MediaType

/// Page for creating a new help request
class CreateHelpRequestPage extends StatefulWidget {
  final HelpCategory? category;
  final HelpSubcategory? subcategory;

  const CreateHelpRequestPage({super.key, this.category, this.subcategory});

  @override
  State<CreateHelpRequestPage> createState() => _CreateHelpRequestPageState();
}

class _CreateHelpRequestPageState extends State<CreateHelpRequestPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final _formKey = GlobalKey<FormState>();
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';

/// Minimal, compilable Help Request creation for the disabled help module
class CreateHelpRequestPage extends StatefulWidget {
  // Expect optional preselected IDs via router extras
  final String? categoryId;
  final String? subcategoryId;

  const CreateHelpRequestPage({super.key, this.categoryId, this.subcategoryId});

  @override
  State<CreateHelpRequestPage> createState() => _CreateHelpRequestPageState();
}

class _CreateHelpRequestPageState extends State<CreateHelpRequestPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  HelpPriority _selectedPriority = HelpPriority.low;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedSubcategoryId = widget.subcategoryId;
    if (widget.subcategoryId != null) {
      _titleController.text = _displayNameForSubcategory(widget.subcategoryId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Help Request'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCategoryInfo(),
              const SizedBox(height: 16),
              _buildRequestDetails(),
              const SizedBox(height: 16),
              _buildPrioritySelection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent, color: AppTheme.infoBlue, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Create a non-emergency help request. We\'ll connect you to community helpers or local services.',
              style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label, color: AppTheme.secondaryText, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Category: ${_selectedCategoryId ?? 'Not selected'}\nIssue: ${_selectedSubcategoryId ?? 'Not selected'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Flat Tyre - Need Help',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your situation and what help you need',
            border: OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please describe your situation'
              : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tags (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: 'e.g., tyre, roadside, car',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: HelpPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return ChoiceChip(
              label: Text(priority.name.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedPriority = priority),
              selectedColor: AppTheme.infoBlue.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.infoBlue : AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        label: _isSubmitting
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 8),
                  Text('Sending Request...'),
                ],
              )
            : const Text(
                'Send Help Request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategoryId == null) {
      _showError('Please select category and specific issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final request = await _serviceManager.helpAssistantService
          .createHelpRequest(
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        tags: tags,
      );

      _showSuccess('Help request sent successfully!');
      if (mounted) Navigator.pop(context, request);
    } catch (e) {
      _showError('Failed to send help request: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _displayNameForSubcategory(String id) {
    switch (id) {
      case 'flat_tire':
        return 'Flat Tyre';
      case 'dead_battery':
        return 'Dead Battery';
      case 'out_of_fuel':
        return 'Out of Fuel';
      case 'locked_out':
        return 'Locked Out';
      case 'towing':
        return 'Towing';
      default:
        return id.replaceAll('_', ' ');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
*/

// Minimal, compilable Help Request creation for the disabled help module
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';

class CreateHelpRequestPage extends StatefulWidget {
  final String? categoryId;
  final String? subcategoryId;

  const CreateHelpRequestPage({super.key, this.categoryId, this.subcategoryId});

  @override
  State<CreateHelpRequestPage> createState() => _CreateHelpRequestPageState();
}

class _CreateHelpRequestPageState extends State<CreateHelpRequestPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  HelpPriority _selectedPriority = HelpPriority.low;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedSubcategoryId = widget.subcategoryId;
    if (widget.subcategoryId != null) {
      _titleController.text = _displayNameForSubcategory(widget.subcategoryId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Help Request'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCategoryInfo(),
              const SizedBox(height: 16),
              _buildRequestDetails(),
              const SizedBox(height: 16),
              _buildPrioritySelection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent, color: AppTheme.infoBlue, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Create a non-emergency help request. We'll connect you to community helpers or local services.",
              style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label, color: AppTheme.secondaryText, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Category: ${_selectedCategoryId ?? 'Not selected'}\nIssue: ${_selectedSubcategoryId ?? 'Not selected'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Flat Tyre - Need Help',
            border: OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please enter a title'
              : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your situation and what help you need',
            border: OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please describe your situation'
              : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tags (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: 'e.g., tyre, roadside, car',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: HelpPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return ChoiceChip(
              label: Text(priority.name.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedPriority = priority),
              selectedColor: AppTheme.infoBlue.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.infoBlue : AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        label: _isSubmitting
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [SizedBox(width: 8), Text('Sending Request...')],
              )
            : const Text(
                'Send Help Request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategoryId == null) {
      _showError('Please select category and specific issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final request = await _serviceManager.helpAssistantService
          .createHelpRequest(
            categoryId: _selectedCategoryId!,
            subcategoryId: _selectedSubcategoryId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _selectedPriority,
            tags: tags,
          );

      _showSuccess('Help request sent successfully!');
      if (mounted) Navigator.pop(context, request);
    } catch (e) {
      _showError('Failed to send help request: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _displayNameForSubcategory(String id) {
    switch (id) {
      case 'flat_tire':
        return 'Flat Tyre';
      case 'dead_battery':
        return 'Dead Battery';
      case 'out_of_fuel':
        return 'Out of Fuel';
      case 'locked_out':
        return 'Locked Out';
      case 'towing':
        return 'Towing';
      default:
        return id.replaceAll('_', ' ');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
