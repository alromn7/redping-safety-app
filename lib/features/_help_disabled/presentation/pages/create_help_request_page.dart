import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/help_request.dart';
import '../../../../models/sos_session.dart'; // For MediaType

/// Page for creating a new help request
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

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form state
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  HelpPriority _selectedPriority = HelpPriority.medium;

  // Contact preferences
  bool _allowPhone = true;
  bool _allowSMS = true;
  bool _allowEmail = true;
  bool _allowInApp = true;
  String _preferredContact = 'phone';
  final List<String> _availableTimeSlots = ['anytime'];

  // Attachments
  final List<HelpMediaAttachment> _attachments = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedSubcategoryId = widget.subcategoryId;

    // Pre-fill title if subcategory is provided
    if (widget.subcategoryId != null) {
      _titleController.text = _getSubcategoryDisplayName(widget.subcategoryId!);
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
              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Category Selection
              _buildCategorySelection(),

              const SizedBox(height: 20),

              // Request Details
              _buildRequestDetails(),

              const SizedBox(height: 20),

              // Priority Selection
              _buildPrioritySelection(),

              const SizedBox(height: 20),

              // Contact Preferences
              _buildContactPreferences(),

              const SizedBox(height: 20),

              // Attachments
              _buildAttachments(),

              const SizedBox(height: 32),

              // Submit Button
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
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.infoBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Non-Emergency Assistance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'This form is for non-emergency situations where you need help or support. Service providers, emergency contacts, and community members will be notified.',
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select category',
          ),
          items: _categoryOrder.map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text(_getCategoryDisplayName(id)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
              _selectedSubcategoryId = null; // Reset subcategory
            });
          },
          validator: (value) =>
              value == null ? 'Please select a category' : null,
        ),

        const SizedBox(height: 16),

        if (_selectedCategoryId != null) ...[
          const Text(
            'Specific Issue *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: _selectedSubcategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select specific issue',
            ),
            items: _getSubcategoriesForCategory(_selectedCategoryId!).map((
              subId,
            ) {
              return DropdownMenuItem(
                value: subId,
                child: Text(_getSubcategoryDisplayName(subId)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubcategoryId = value;
                if (value != null) {
                  _titleController.text = _getSubcategoryDisplayName(value);
                }
              });
            },
            validator: (value) =>
                value == null ? 'Please select specific issue' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Details',
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
            labelText: 'Title *',
            border: OutlineInputBorder(),
            hintText: 'Brief description of what you need help with',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            border: OutlineInputBorder(),
            hintText:
                'Provide more details about your situation and what help you need',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            return null;
          },
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags (optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., urgent, community, elderly, disabled',
            helperText: 'Separate tags with commas',
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildPrioritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
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
            return FilterChip(
              selected: isSelected,
              label: Text(_getPriorityDisplayName(priority)),
              onSelected: (selected) {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              backgroundColor: _getPriorityColor(
                priority,
              ).withValues(alpha: 0.1),
              selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
              checkmarkColor: _getPriorityColor(priority),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),
        Text(
          _getPriorityDescription(_selectedPriority),
          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
        ),
      ],
    );
  }

  Widget _buildContactPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'How can service providers contact you?',
          style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          title: const Text('Phone Call'),
          subtitle: const Text('Allow direct phone calls'),
          value: _allowPhone,
          onChanged: (value) => setState(() => _allowPhone = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          title: const Text('SMS/Text'),
          subtitle: const Text('Allow text messages'),
          value: _allowSMS,
          onChanged: (value) => setState(() => _allowSMS = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          title: const Text('Email'),
          subtitle: const Text('Allow email communication'),
          value: _allowEmail,
          onChanged: (value) => setState(() => _allowEmail = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          title: const Text('In-App Messages'),
          subtitle: const Text('Receive messages in REDP!NG app'),
          value: _allowInApp,
          onChanged: (value) => setState(() => _allowInApp = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 16),

        const Text(
          'Preferred Contact Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          initialValue: _preferredContact,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'phone', child: Text('Phone Call')),
            DropdownMenuItem(value: 'sms', child: Text('SMS/Text')),
            DropdownMenuItem(value: 'email', child: Text('Email')),
            DropdownMenuItem(value: 'in_app', child: Text('In-App Message')),
          ],
          onChanged: (value) {
            setState(() {
              _preferredContact = value ?? 'phone';
            });
          },
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addAttachment,
              icon: const Icon(Icons.add_photo_alternate, size: 16),
              label: const Text('Add Photo'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.infoBlue),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.photo_library,
                  color: AppTheme.neutralGray,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'No attachments added',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                Text(
                  'Photos can help service providers understand your situation',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachments
                .map((attachment) => _buildAttachmentChip(attachment))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAttachmentChip(HelpMediaAttachment attachment) {
    return Chip(
      label: Text(attachment.fileName, style: const TextStyle(fontSize: 12)),
      avatar: const Icon(Icons.photo, size: 16),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _attachments.remove(attachment);
        });
      },
      backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.1),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
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

  Future<void> _addAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final attachment = HelpMediaAttachment(
          id: 'att_${DateTime.now().millisecondsSinceEpoch}',
          fileName: image.name,
          filePath: image.path,
          type: MediaType.photo,
          fileSizeBytes: await image.length(),
          timestamp: DateTime.now(),
          description: 'Help request photo',
        );

        setState(() {
          _attachments.add(attachment);
        });
      }
    } catch (e) {
      _showError('Failed to add photo: $e');
    }
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

      // Return the created request
      Navigator.pop(context, request);
    } catch (e) {
      _showError('Failed to send help request: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  List<String> _getSubcategoriesForCategory(String categoryId) {
    switch (categoryId) {
      case 'vehicle':
        return [
          'breakdown',
          'flat_tire',
          'dead_battery',
          'out_of_fuel',
          'locked_out',
          'accident_minor',
          'towing',
        ];
      case 'home_security':
        return [
          'break_in',
          'suspicious_activity',
          'alarm_triggered',
          'domestic_violence',
          'theft',
          'vandalism',
        ];
      case 'personal_safety':
        return [
          'harassment',
          'stalking',
          'feeling_unsafe',
          'stuck_trapped',
          'lost_person',
        ];
      case 'lost_found':
        return [
          'lost_pet',
          'lost_keys',
          'lost_wallet',
          'lost_phone',
          'found_item',
        ];
      case 'marine':
        return ['boat_breakdown', 'boat_stuck', 'marine_assistance'];
      case 'community':
        return ['neighbor_dispute', 'noise_complaint', 'community_concern'];
      case 'legal':
        return ['legal_advice', 'document_help'];
      case 'medical_non_emergency':
        return ['medical_transport', 'prescription_help', 'wellness_check'];
      case 'utilities':
        return ['power_outage', 'water_issue', 'gas_leak_minor'];
      case 'other':
      default:
        return ['general_help', 'information_request'];
    }
  }

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'vehicle':
        return 'Vehicle Assistance';
      case 'home_security':
        return 'Home Security';
      case 'personal_safety':
        return 'Personal Safety';
      case 'lost_found':
        return 'Lost & Found';
      case 'marine':
        return 'Marine Assistance';
      case 'community':
        return 'Community Support';
      case 'legal':
        return 'Legal Assistance';
      case 'medical_non_emergency':
        return 'Medical Support';
      case 'utilities':
        return 'Utilities';
      case 'other':
      default:
        return 'General Help';
    }
  }

  String _getSubcategoryDisplayName(String subcategoryId) {
    switch (subcategoryId) {
      case 'breakdown':
        return 'Vehicle Breakdown';
      case 'flat_tire':
        return 'Flat Tire';
      case 'dead_battery':
        return 'Dead Battery';
      case 'out_of_fuel':
        return 'Out of Fuel';
      case 'locked_out':
        return 'Locked Out';
      case 'towing':
        return 'Towing Needed';
      case 'accident_minor':
        return 'Minor Accident';
      case 'break_in':
        return 'Break-in';
      case 'suspicious_activity':
        return 'Suspicious Activity';
      case 'alarm_triggered':
        return 'Alarm Triggered';
      case 'domestic_violence':
        return 'Domestic Violence';
      case 'theft':
        return 'Theft';
      case 'vandalism':
        return 'Vandalism';
      case 'harassment':
        return 'Harassment';
      case 'stalking':
        return 'Stalking';
      case 'feeling_unsafe':
        return 'Feeling Unsafe';
      case 'stuck_trapped':
        return 'Stuck or Trapped';
      case 'lost_person':
        return 'Lost Person';
      case 'lost_pet':
        return 'Lost Pet';
      case 'lost_keys':
        return 'Lost Keys';
      case 'lost_wallet':
        return 'Lost Wallet';
      case 'lost_phone':
        return 'Lost Phone';
      case 'found_item':
        return 'Found Item';
      case 'boat_breakdown':
        return 'Boat Breakdown';
      case 'boat_stuck':
        return 'Boat Stuck';
      case 'marine_assistance':
        return 'Marine Assistance';
      case 'neighbor_dispute':
        return 'Neighbor Dispute';
      case 'noise_complaint':
        return 'Noise Complaint';
      case 'community_concern':
        return 'Community Concern';
      case 'legal_advice':
        return 'Legal Advice';
      case 'document_help':
        return 'Document Help';
      case 'medical_transport':
        return 'Medical Transport';
      case 'prescription_help':
        return 'Prescription Help';
      case 'wellness_check':
        return 'Wellness Check';
      case 'power_outage':
        return 'Power Outage';
      case 'water_issue':
        return 'Water Supply Issue';
      case 'gas_leak_minor':
        return 'Minor Gas Leak';
      case 'general_help':
        return 'General Help';
      case 'information_request':
        return 'Information Request';
      default:
        return 'Other';
    }
  }

  String _getPriorityDisplayName(HelpPriority priority) {
    switch (priority) {
      case HelpPriority.low:
        return 'Low';
      case HelpPriority.medium:
        return 'Medium';
      case HelpPriority.high:
        return 'High';
      case HelpPriority.critical:
        return 'Critical';
    }
  }

  Color _getPriorityColor(HelpPriority priority) {
    switch (priority) {
      case HelpPriority.low:
        return AppTheme.safeGreen;
      case HelpPriority.medium:
        return AppTheme.infoBlue;
      case HelpPriority.high:
        return AppTheme.warningOrange;
      case HelpPriority.critical:
        return AppTheme.criticalRed;
    }
  }

  String _getPriorityDescription(HelpPriority priority) {
    switch (priority) {
      case HelpPriority.low:
        return 'Can wait several hours or days';
      case HelpPriority.medium:
        return 'Should be addressed within a few hours';
      case HelpPriority.high:
        return 'Needs attention within 1-2 hours';
      case HelpPriority.critical:
        return 'Needs immediate attention (but not life-threatening)';
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

// Minimal attachment class for UI only in disabled feature
class HelpMediaAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final MediaType type;
  final int fileSizeBytes;
  final DateTime timestamp;
  final String? description;

  const HelpMediaAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSizeBytes,
    required this.timestamp,
    this.description,
  });
}

// Category order for dropdown
const List<String> _categoryOrder = [
  'vehicle',
  'home_security',
  'personal_safety',
  'lost_found',
  'marine',
  'community',
  'legal',
  'medical_non_emergency',
  'utilities',
  'other',
];
