import '../models/help_request.dart';
import '../models/location_data.dart';

class HelpAssistantService {
  bool _isInitialized = false;
  Function(HelpRequest)? _onRequestCreated;
  Function(HelpRequest)? _onRequestUpdated;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
    // TODO: Implement help assistant initialization
  }

  Future<List<HelpRequest>> getActiveRequests() async {
    // TODO: Implement get active requests
    return [];
  }

  void setRequestCreatedCallback(Function(HelpRequest) callback) {
    _onRequestCreated = callback;
  }

  void setRequestUpdatedCallback(Function(HelpRequest) callback) {
    _onRequestUpdated = callback;
  }

  Future<HelpRequest> createHelpRequest({
    required String categoryId,
    required String subcategoryId,
    required String title,
    required String description,
    required HelpPriority priority,
    List<String> tags = const [],
  }) async {
    // Minimal stub implementation to satisfy disabled UI
    final req = HelpRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'me',
      userName: 'Me',
      categoryId: categoryId,
      subCategoryId: subcategoryId,
      description: description,
      additionalInfo: title,
      location: LocationData(
        latitude: 0,
        longitude: 0,
        address: 'Unknown',
        timestamp: DateTime.now(),
      ),
      status: HelpRequestStatus.active,
      priority: priority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachments: const [],
      assignedHelpers: const [],
      responses: const [],
    );
    _onRequestCreated?.call(req);
    // Touch updated callback to avoid unused warning in this stub
    // ignore: unnecessary_statements
    _onRequestUpdated;
    return req;
  }

  void dispose() {
    _isInitialized = false;
  }
}
