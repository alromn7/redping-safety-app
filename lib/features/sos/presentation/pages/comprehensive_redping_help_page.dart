import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/help_service.dart';
import '../../../../models/help_request.dart';
import '../../../../models/help_category.dart';
import '../../../../models/help_response.dart';
import '../widgets/sub_category_selector.dart';

/// REDP!NG Help and Support System
///
/// This page provides assistance for non-SOS emergency situations:
/// - Vehicle breakdowns and mechanical issues
/// - Domestic violence and safety concerns
/// - Lost pets and missing items
/// - Home break-ins and theft
/// - Drug abuse and criminality
/// - Kidnapping and car theft
/// - Community support and assistance
/// - Local help network coordination
class ComprehensiveRedpingHelpPage extends StatefulWidget {
  final String? initialCategoryId;

  const ComprehensiveRedpingHelpPage({super.key, this.initialCategoryId});

  @override
  State<ComprehensiveRedpingHelpPage> createState() =>
      _ComprehensiveRedpingHelpPageState();
}

class _ComprehensiveRedpingHelpPageState
    extends State<ComprehensiveRedpingHelpPage> {
  // Services
  final HelpService _helpService = HelpService();

  // State
  HelpRequest? _currentHelpRequest;
  final List<HelpResponse> _responses = [];
  bool _isLoading = false;
  String? _errorMessage;
  // Details form state
  final _formKey = GlobalKey<FormState>();
  HelpPriority _selectedPriority = HelpPriority.low;
  int _peopleCount = 1;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _extraInfoController = TextEditingController();
  final TextEditingController _hazardsController = TextEditingController();
  bool _prefersCall = true;
  final List<String> _attachments = [];

  // Help categories for non-SOS emergency situations
  List<HelpCategory> _helpCategories = [];
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    try {
      // Initialize help service
      await _helpService.initialize();

      // Load help categories
      _helpCategories = _helpService.getHelpCategories();

      // Preselect initial category if provided
      if (widget.initialCategoryId != null) {
        final exists = _helpCategories.any(
          (c) => c.id == widget.initialCategoryId,
        );
        if (exists) {
          _selectedCategoryId = widget.initialCategoryId;
        }
      }

      // Set up listeners
      _setupListeners();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize services: $e';
      });
    }
  }

  void _setupListeners() {
    // Listen for help request updates
    _helpService.requestUpdateStream.listen((request) {
      if (mounted && _currentHelpRequest?.id == request.id) {
        setState(() {
          _currentHelpRequest = request;
        });
      }
    });

    // Listen for new responses
    _helpService.responseStream.listen((response) {
      if (mounted && _currentHelpRequest?.id == response.requestId) {
        setState(() {
          _responses.add(response);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Help Ping Dashboard'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.criticalRed),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.criticalRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Ping Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_currentHelpRequest != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _currentHelpRequest = null;
                  _responses.clear();
                });
              },
            ),
        ],
      ),
      body: _currentHelpRequest == null
          ? _buildHelpCategoriesList()
          : _buildHelpRequestView(),
    );
  }

  Widget _buildHelpCategoriesList() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.infoBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.help_outline, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'REDP!NG Help & Support',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the type of assistance you need. REDP!NG will connect you with local services and community helpers.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Back button if category is selected
        if (_selectedCategoryId != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedSubCategoryId = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: AppTheme.primaryRed,
                ),
                Text(
                  'Select specific issue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),

        // Categories List or Sub-categories
        Expanded(
          child: _selectedCategoryId == null
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _helpCategories.length,
                  itemBuilder: (context, index) {
                    final category = _helpCategories[index];
                    return _buildHelpCategoryCard(category);
                  },
                )
              : _buildSubCategoriesView(),
        ),
      ],
    );
  }

  Widget _buildHelpCategoryCard(HelpCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.infoBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: AppTheme.infoBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Response: Depends on local services',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: AppTheme.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${category.requiredServices.length} services',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpRequestView() {
    return Column(
      children: [
        // Status Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.infoBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppTheme.infoBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help Request Active',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        Text(
                          'Your request has been sent to local services',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: _responses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppTheme.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No responses yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Community helpers will respond soon',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _responses.length,
                  itemBuilder: (context, index) {
                    final response = _responses[index];
                    return _buildResponseCard(response);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResponseCard(HelpResponse response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.infoBlue,
                  child: Text(
                    response.responderName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.responderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTime(response.createdAt),
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (response.isAccepted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Accepted',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(response.message, style: const TextStyle(fontSize: 14)),
            if (response.contactInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Contact: ${response.contactInfo}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: response.isAccepted
                        ? null
                        : () => _acceptResponse(response),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.safeGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept Help'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineResponse(response),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(HelpCategory category) {
    setState(() {
      _selectedCategoryId = category.id;
      _selectedSubCategoryId = null;
    });
    debugPrint(
      'Selected category: ${category.id}, Sub-categories: ${category.subCategories.length}',
    );
  }

  Widget _buildSubCategoriesView() {
    final category = _helpCategories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => _helpCategories.first,
    );
    debugPrint(
      'Building sub-categories view for: ${category.name}, Sub-categories: ${category.subCategories.length}',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.primaryRed, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sub-category selector
          SubCategorySelector(
            category: category,
            selectedSubCategoryId: _selectedSubCategoryId,
            onSubCategorySelected: (subCategoryId) {
              setState(() {
                _selectedSubCategoryId = subCategoryId;
              });
            },
          ),

          const SizedBox(height: 24),

          // Details form
          const SizedBox(height: 8),
          _buildDetailsForm(category),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedSubCategoryId != null
                  ? () => _submitDetailedRequest(category)
                  : null,
              icon: const Icon(Icons.send),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                _selectedSubCategoryId != null
                    ? 'Send Help Request'
                    : 'Select a specific issue above',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm(HelpCategory category) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provide more details to get the best help:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // Severity
          Text('Urgency', style: TextStyle(color: AppTheme.secondaryText)),
          const SizedBox(height: 6),
          SegmentedButton<HelpPriority>(
            segments: const [
              ButtonSegment(value: HelpPriority.low, label: Text('Low')),
              ButtonSegment(value: HelpPriority.medium, label: Text('Medium')),
              ButtonSegment(value: HelpPriority.high, label: Text('High')),
              ButtonSegment(
                value: HelpPriority.critical,
                label: Text('Critical'),
              ),
            ],
            selected: <HelpPriority>{_selectedPriority},
            onSelectionChanged: (s) {
              setState(() => _selectedPriority = s.first);
            },
          ),
          const SizedBox(height: 12),
          // Description
          TextFormField(
            controller: _descController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe what you need',
              hintText: 'E.g., Flat tire on highway, need towing',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please describe your situation'
                : null,
          ),
          const SizedBox(height: 12),
          // Extra info
          TextFormField(
            controller: _extraInfoController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
              hintText: 'Landmarks, vehicle info, directions, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // People count
          Row(
            children: [
              const Text('People affected:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _peopleCount,
                items: List.generate(10, (i) => i + 1)
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => setState(() => _peopleCount = v ?? 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hazards
          TextFormField(
            controller: _hazardsController,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Known hazards (optional)',
              hintText: 'E.g., traffic, fire risk, unsafe person, water',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Contact preference
          Row(
            children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 6),
              const Text('Prefer phone call'),
              const Spacer(),
              Switch(
                value: _prefersCall,
                onChanged: (v) => setState(() => _prefersCall = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Attachments placeholder (wire later if needed)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attachments.map((p) => Chip(label: Text(_fileName(p)))),
              OutlinedButton.icon(
                onPressed: () {
                  // We can integrate image_picker later; keep placeholder UI.
                  setState(() => _attachments.add('note://details.txt'));
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Add attachment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fileName(String path) => path.split('/').last;

  Future<void> _submitDetailedRequest(HelpCategory category) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final description = _descController.text.trim();
      final extra = _extraInfoController.text.trim().isEmpty
          ? null
          : _extraInfoController.text.trim();

      final details = <String, dynamic>{
        'peopleCount': _peopleCount,
        'hazards': _hazardsController.text.trim(),
        'prefersCall': _prefersCall,
        'attachments': _attachments,
      };

      // Create help request with enriched info
      final request = await _helpService.createHelpRequest(
        categoryId: category.id,
        subCategoryId: _selectedSubCategoryId,
        description: description,
        additionalInfo: extra == null ? details.toString() : '$extra\n$details',
        attachments: _attachments,
      );

      // Optionally override priority based on user selection
      if (request.priority != _selectedPriority) {
        await _helpService.updateRequestStatus(
          request.id,
          request.status, // keep status; priority is part of request model
        );
      }

      setState(() {
        _currentHelpRequest = request;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Help request sent with details'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send help request: $e';
      });
    }
  }
  // _createHelpRequest removed in favor of _submitDetailedRequest

  Future<void> _acceptResponse(HelpResponse response) async {
    try {
      await _helpService.acceptResponse(_currentHelpRequest!.id, response.id);

      setState(() {
        final index = _responses.indexWhere((r) => r.id == response.id);
        if (index != -1) {
          _responses[index] = response.copyWith(isAccepted: true);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response accepted'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept response: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  void _declineResponse(HelpResponse response) {
    // Remove the response from the list
    setState(() {
      _responses.removeWhere((r) => r.id == response.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response declined'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
