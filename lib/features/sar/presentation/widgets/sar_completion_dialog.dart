import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_session.dart';
import '../../../../services/sar_service.dart';

/// Dialog for completing SAR missions with detailed reporting
class SARCompletionDialog extends StatefulWidget {
  final SARSession session;
  final SARService sarService;

  const SARCompletionDialog({
    super.key,
    required this.session,
    required this.sarService,
  });

  @override
  State<SARCompletionDialog> createState() => _SARCompletionDialogState();
}

class _SARCompletionDialogState extends State<SARCompletionDialog> {
  final _summaryController = TextEditingController();
  final _detailedReportController = TextEditingController();
  final _personsFoundController = TextEditingController();
  final _personsNotFoundController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _lessonsController = TextEditingController();

  SAROutcome _selectedOutcome = SAROutcome.successfulRescue;
  SARDifficulty _selectedDifficulty = SARDifficulty.moderate;
  double _successRating = 0.8;
  int? _survivorsCount;
  int? _casualtiesCount;

  final List<SARMedia> _uploadedMedia = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete SAR Mission'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : _submitCompletion,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mission Overview
              _buildMissionOverview(),

              const SizedBox(height: 24),

              // Outcome Selection
              _buildOutcomeSection(),

              const SizedBox(height: 24),

              // Personnel Information
              _buildPersonnelSection(),

              const SizedBox(height: 24),

              // Mission Details
              _buildMissionDetailsSection(),

              const SizedBox(height: 24),

              // Media Documentation
              _buildMediaSection(),

              const SizedBox(height: 24),

              // Performance Evaluation
              _buildPerformanceSection(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.infoBlue),
                const SizedBox(width: 8),
                const Text(
                  'Mission Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOverviewItem('Session ID', widget.session.id),
            _buildOverviewItem(
              'Type',
              _getTypeDisplayName(widget.session.type),
            ),
            _buildOverviewItem(
              'Priority',
              widget.session.priority.name.toUpperCase(),
            ),
            _buildOverviewItem(
              'Duration',
              _formatDuration(widget.session.duration),
            ),
            _buildOverviewItem(
              'Teams Deployed',
              '${widget.session.rescueTeamIds.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Outcome',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SAROutcome>(
              initialValue: _selectedOutcome,
              decoration: const InputDecoration(
                labelText: 'Outcome',
                border: OutlineInputBorder(),
              ),
              items: SAROutcome.values
                  .map(
                    (outcome) => DropdownMenuItem(
                      value: outcome,
                      child: Text(_getOutcomeDisplayName(outcome)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedOutcome = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Summary *',
                hintText: 'Brief summary of the mission outcome...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailedReportController,
              decoration: const InputDecoration(
                labelText: 'Detailed Report',
                hintText: 'Comprehensive mission report...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personnel Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Survivors',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _survivorsCount = int.tryParse(value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Casualties',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _casualtiesCount = int.tryParse(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personsFoundController,
              decoration: const InputDecoration(
                labelText: 'Persons Found',
                hintText: 'Names of persons found (one per line)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personsNotFoundController,
              decoration: const InputDecoration(
                labelText: 'Persons Not Found',
                hintText: 'Names of persons still missing (one per line)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: 'Hospital/Medical Facility',
                hintText: 'Where casualties were transported',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SARDifficulty>(
              initialValue: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Mission Difficulty',
                border: OutlineInputBorder(),
              ),
              items: SARDifficulty.values
                  .map(
                    (difficulty) => DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedDifficulty = value!),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Success Rating:',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(_successRating * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _successRating,
                  onChanged: (value) => setState(() => _successRating = value),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppTheme.safeGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lessonsController,
              decoration: const InputDecoration(
                labelText: 'Lessons Learned',
                hintText:
                    'Key insights and improvements for future missions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
                  'Media Documentation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isUploading ? null : _showMediaUploadOptions,
                  icon: const Icon(Icons.add_a_photo),
                  tooltip: 'Add Media',
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_uploadedMedia.isEmpty)
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
                      'No media uploaded yet',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _showMediaUploadOptions,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Photos/Videos'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ..._uploadedMedia.map((media) => _buildMediaItem(media)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _showMediaUploadOptions,
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

  Widget _buildMediaItem(SARMedia media) {
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
              color: _getMediaTypeColor(media.type).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getMediaTypeIcon(media.type),
              color: _getMediaTypeColor(media.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.description ?? 'Untitled ${media.type.name}',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimestamp(media.timestamp),
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
                if (media.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: media.tags
                        .take(3)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.infoBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: AppTheme.infoBlue,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          if (media.isEvidence)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EVIDENCE',
                style: TextStyle(
                  color: AppTheme.criticalRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            onPressed: () => _removeMedia(media),
            icon: const Icon(Icons.delete, size: 18),
            color: AppTheme.criticalRed,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Evaluation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Overall Success Rating:',
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${(_successRating * 100).round()}%',
                  style: TextStyle(
                    color: _getSuccessRatingColor(_successRating),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _successRating,
              onChanged: (value) => setState(() => _successRating = value),
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: _getSuccessRatingColor(_successRating),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lessonsController,
              decoration: const InputDecoration(
                labelText: 'Lessons Learned & Improvements',
                hintText: 'What went well? What could be improved?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting || _summaryController.text.trim().isEmpty
            ? null
            : _submitCompletion,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isSubmitting ? 'Completing Mission...' : 'Complete SAR Mission',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.safeGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showMediaUploadOptions() async {
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
                _uploadMedia(ImageSource.camera, SARMediaType.photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadMedia(ImageSource.gallery, SARMediaType.photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _uploadMedia(ImageSource.camera, SARMediaType.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Video'),
              onTap: () {
                Navigator.pop(context);
                _uploadMedia(ImageSource.gallery, SARMediaType.video);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadMedia(ImageSource source, SARMediaType type) async {
    setState(() => _isUploading = true);

    try {
      final picker = ImagePicker();
      final XFile? file;

      if (type == SARMediaType.photo) {
        file = await picker.pickImage(source: source);
      } else {
        file = await picker.pickVideo(source: source);
      }

      if (file != null) {
        final result = await _showMediaDetailsDialog(file.path, type);
        if (result != null) {
          await widget.sarService.addSARMedia(
            type: type,
            filePath: file.path,
            description: result['description'],
            tags: result['tags'],
            isEvidence: result['isEvidence'],
          );

          // Add to local list for UI
          final media = SARMedia(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            type: type,
            filePath: file.path,
            description: result['description'],
            timestamp: DateTime.now(),
            uploadedBy: 'current_user',
            tags: result['tags'],
            isEvidence: result['isEvidence'],
          );

          setState(() => _uploadedMedia.add(media));
        }
      }
    } catch (e) {
      _showError('Failed to upload media: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<Map<String, dynamic>?> _showMediaDetailsDialog(
    String filePath,
    SARMediaType type,
  ) async {
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    bool isEvidence = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${type.name.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe this media...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'evidence, location, person, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Mark as Evidence'),
                subtitle: const Text('Important for investigation'),
                value: isEvidence,
                onChanged: (value) =>
                    setState(() => isEvidence = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                Navigator.pop(context, {
                  'description': descriptionController.text.trim(),
                  'tags': tags,
                  'isEvidence': isEvidence,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeMedia(SARMedia media) {
    setState(() => _uploadedMedia.remove(media));
  }

  Future<void> _submitCompletion() async {
    if (_summaryController.text.trim().isEmpty) {
      _showError('Please provide a mission summary');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final personsFound = _personsFoundController.text
          .split('\n')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      final personsNotFound = _personsNotFoundController.text
          .split('\n')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      final lessonsLearned = _lessonsController.text
          .split('\n')
          .map((lesson) => lesson.trim())
          .where((lesson) => lesson.isNotEmpty)
          .toList();

      // Capture navigator before awaiting async work
      // ignore: use_build_context_synchronously
      final navigator = Navigator.of(context);
      await widget.sarService.completeSARSession(
        outcome: _selectedOutcome,
        summary: _summaryController.text.trim(),
        detailedReport: _detailedReportController.text.trim().isEmpty
            ? null
            : _detailedReportController.text.trim(),
        personsFound: personsFound,
        personsNotFound: personsNotFound,
        survivorsCount: _survivorsCount,
        casualtiesCount: _casualtiesCount,
        hospitalDestination: _hospitalController.text.trim().isEmpty
            ? null
            : _hospitalController.text.trim(),
        difficulty: _selectedDifficulty,
        successRating: _successRating,
        lessonsLearned: lessonsLearned,
      );

      navigator.pop(true);
    } catch (e) {
      _showError('Failed to complete mission: $e');
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

  Color _getMediaTypeColor(SARMediaType type) {
    switch (type) {
      case SARMediaType.photo:
        return AppTheme.infoBlue;
      case SARMediaType.video:
        return AppTheme.warningOrange;
      case SARMediaType.audio:
        return AppTheme.safeGreen;
      case SARMediaType.document:
        return AppTheme.neutralGray;
      case SARMediaType.map:
        return AppTheme.primaryRed;
      case SARMediaType.evidence:
        return AppTheme.criticalRed;
    }
  }

  IconData _getMediaTypeIcon(SARMediaType type) {
    switch (type) {
      case SARMediaType.photo:
        return Icons.photo;
      case SARMediaType.video:
        return Icons.videocam;
      case SARMediaType.audio:
        return Icons.mic;
      case SARMediaType.document:
        return Icons.description;
      case SARMediaType.map:
        return Icons.map;
      case SARMediaType.evidence:
        return Icons.gavel;
    }
  }

  Color _getSuccessRatingColor(double rating) {
    if (rating >= 0.8) return AppTheme.safeGreen;
    if (rating >= 0.6) return AppTheme.infoBlue;
    if (rating >= 0.4) return AppTheme.warningOrange;
    return AppTheme.criticalRed;
  }

  String _getOutcomeDisplayName(SAROutcome outcome) {
    switch (outcome) {
      case SAROutcome.successfulRescue:
        return 'Successful Rescue';
      case SAROutcome.personsFoundSafe:
        return 'Persons Found Safe';
      case SAROutcome.personsFoundInjured:
        return 'Persons Found Injured';
      case SAROutcome.personsFoundDeceased:
        return 'Persons Found Deceased';
      case SAROutcome.personsNotFound:
        return 'Persons Not Found';
      case SAROutcome.falseAlarm:
        return 'False Alarm';
      case SAROutcome.operationSuspended:
        return 'Operation Suspended';
      case SAROutcome.operationCancelled:
        return 'Operation Cancelled';
      case SAROutcome.transferredToAuthorities:
        return 'Transferred to Authorities';
    }
  }

  String _getTypeDisplayName(SARType type) {
    switch (type) {
      case SARType.missingPerson:
        return 'Missing Person';
      case SARType.medicalEmergency:
        return 'Medical Emergency';
      case SARType.vehicleAccident:
        return 'Vehicle Accident';
      case SARType.wildernessRescue:
        return 'Wilderness Rescue';
      case SARType.waterRescue:
        return 'Water Rescue';
      case SARType.mountainRescue:
        return 'Mountain Rescue';
      case SARType.urbanSearch:
        return 'Urban Search';
      case SARType.disasterResponse:
        return 'Disaster Response';
      case SARType.overdueParty:
        return 'Overdue Party';
      case SARType.equipmentFailure:
        return 'Equipment Failure';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
