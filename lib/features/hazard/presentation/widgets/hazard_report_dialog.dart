import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/hazard_alert.dart';
import '../../../../services/location_service.dart';

/// Dialog for reporting community hazards
class HazardReportDialog extends StatefulWidget {
  final LocationService locationService;

  const HazardReportDialog({super.key, required this.locationService});

  @override
  State<HazardReportDialog> createState() => _HazardReportDialogState();
}

class _HazardReportDialogState extends State<HazardReportDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  HazardType _selectedType = HazardType.communityHazard;
  HazardSeverity _selectedSeverity = HazardSeverity.moderate;

  final List<String> _mediaFiles = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Hazard'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting || _titleController.text.trim().isEmpty
                  ? null
                  : _submitReport,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Info
              _buildLocationInfo(),

              const SizedBox(height: 24),

              // Hazard Type
              _buildHazardTypeSection(),

              const SizedBox(height: 24),

              // Hazard Details
              _buildHazardDetailsSection(),

              const SizedBox(height: 24),

              // Media Upload
              _buildMediaSection(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.criticalRed),
                SizedBox(width: 8),
                Text(
                  'Location Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppTheme.infoBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your current location will be used for this hazard report',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hazard Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HazardType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Hazard Type',
                border: OutlineInputBorder(),
              ),
              items: _getReportableHazardTypes()
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(_getTypeEmoji(type)),
                          const SizedBox(width: 8),
                          Text(_getTypeDisplayName(type)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HazardSeverity>(
              initialValue: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity Level',
                border: OutlineInputBorder(),
              ),
              items: HazardSeverity.values
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Row(
                        children: [
                          Text(_getSeverityEmoji(severity)),
                          const SizedBox(width: 8),
                          Text(severity.name.toUpperCase()),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedSeverity = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hazard Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Brief title for this hazard...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) =>
                  setState(() {}), // Trigger rebuild for submit button
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Detailed description of the hazard...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (_) =>
                  setState(() {}), // Trigger rebuild for submit button
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'urgent, road, weather, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: AppTheme.warningOrange),
                const SizedBox(width: 8),
                const Text(
                  'Media Evidence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isUploading ? null : _showMediaOptions,
                  icon: const Icon(Icons.add_a_photo),
                  tooltip: 'Add Photo/Video',
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_mediaFiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 48,
                      color: AppTheme.neutralGray.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No media added yet',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _showMediaOptions,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Photos/Videos'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ..._mediaFiles.map((file) => _buildMediaItem(file)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _showMediaOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Add More Media'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(String filePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.photo, color: AppTheme.infoBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filePath.split('/').last,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Evidence photo',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeMedia(filePath),
            icon: const Icon(Icons.delete, size: 18),
            color: AppTheme.criticalRed,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canSubmit && !_isSubmitting ? _submitReport : null,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.report),
        label: Text(
          _isSubmitting ? 'Submitting Report...' : 'Submit Hazard Report',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.warningOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showMediaOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photo'),
              onTap: () {
                Navigator.pop(context);
                _addMedia(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _addVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Video'),
              onTap: () {
                Navigator.pop(context);
                _addVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedia(ImageSource source) async {
    setState(() => _isUploading = true);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source);

      if (file != null) {
        setState(() => _mediaFiles.add(file.path));
      }
    } catch (e) {
      _showError('Failed to add photo: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _addVideo(ImageSource source) async {
    setState(() => _isUploading = true);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);

      if (file != null) {
        setState(() => _mediaFiles.add(file.path));
      }
    } catch (e) {
      _showError('Failed to add video: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeMedia(String filePath) {
    setState(() => _mediaFiles.remove(filePath));
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final result = {
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'severity': _selectedSeverity,
        'mediaFiles': _mediaFiles,
        'tags': tags,
      };

      Navigator.pop(context, result);
    } catch (e) {
      _showError('Failed to submit report: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<HazardType> _getReportableHazardTypes() {
    return [
      HazardType.communityHazard,
      HazardType.roadClosure,
      HazardType.fire,
      HazardType.flood,
      HazardType.powerOutage,
      HazardType.gasLeak,
      HazardType.chemicalSpill,
      HazardType.airQuality,
      HazardType.landslide,
      HazardType.weather,
    ];
  }

  String _getTypeEmoji(HazardType type) {
    return switch (type) {
      HazardType.weather => '🌩️',
      HazardType.earthquake => '🌍',
      HazardType.fire => '🔥',
      HazardType.flood => '🌊',
      HazardType.tornado => '🌪️',
      HazardType.hurricane => '🌀',
      HazardType.tsunami => '🌊',
      HazardType.landslide => '⛰️',
      HazardType.avalanche => '❄️',
      HazardType.chemicalSpill => '☣️',
      HazardType.gasLeak => '💨',
      HazardType.roadClosure => '🚧',
      HazardType.powerOutage => '⚡',
      HazardType.airQuality => '😷',
      HazardType.communityHazard => '⚠️',
      _ => '⚠️',
    };
  }

  String _getTypeDisplayName(HazardType type) {
    return switch (type) {
      HazardType.weather => 'Weather Hazard',
      HazardType.earthquake => 'Earthquake',
      HazardType.fire => 'Fire Hazard',
      HazardType.flood => 'Flooding',
      HazardType.tornado => 'Tornado',
      HazardType.hurricane => 'Hurricane',
      HazardType.tsunami => 'Tsunami',
      HazardType.landslide => 'Landslide',
      HazardType.avalanche => 'Avalanche',
      HazardType.chemicalSpill => 'Chemical Spill',
      HazardType.gasLeak => 'Gas Leak',
      HazardType.roadClosure => 'Road Closure',
      HazardType.powerOutage => 'Power Outage',
      HazardType.airQuality => 'Air Quality Issue',
      HazardType.communityHazard => 'General Hazard',
      _ => 'Other Hazard',
    };
  }

  String _getSeverityEmoji(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => 'ℹ️',
      HazardSeverity.minor => '⚠️',
      HazardSeverity.moderate => '🟡',
      HazardSeverity.severe => '🟠',
      HazardSeverity.extreme => '🔴',
      HazardSeverity.critical => '🚨',
    };
  }
}
