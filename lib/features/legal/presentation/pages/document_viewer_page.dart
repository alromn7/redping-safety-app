import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';

/// Document viewer page for displaying legal documents
class DocumentViewerPage extends StatefulWidget {
  final String documentType;
  final String documentTitle;
  final String documentPath;
  final bool showAcceptDecline;

  const DocumentViewerPage({
    super.key,
    required this.documentType,
    required this.documentTitle,
    required this.documentPath,
    this.showAcceptDecline = true,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  String _documentContent = '';
  bool _isLoading = true;
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure the legal documents service is ready before actions
    Future.microtask(() async {
      try {
        if (!_serviceManager.legalDocumentsService.isInitialized) {
          await _serviceManager.legalDocumentsService.initialize();
        }
      } catch (_) {}
    });
    _loadDocument();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _loadDocument() async {
    try {
      setState(() => _isLoading = true);

      // Load document content from assets
      final content = await rootBundle.loadString(widget.documentPath);

      setState(() {
        _documentContent = content;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DocumentViewerPage: Error loading document - $e');
      setState(() {
        _documentContent = 'Error loading document. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptDocument() async {
    try {
      switch (widget.documentType.toLowerCase()) {
        case 'terms':
          await _serviceManager.legalDocumentsService.acceptTerms();
          break;
        case 'privacy':
          await _serviceManager.legalDocumentsService.acceptPrivacy();
          break;
        case 'security':
          await _serviceManager.legalDocumentsService.acceptSecurity();
          break;
        case 'usage':
          await _serviceManager.legalDocumentsService.acceptUsage();
          break;
        case 'compliance':
          await _serviceManager.legalDocumentsService.acceptCompliance();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.documentTitle} accepted'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
        context.pop(true); // Return true to indicate acceptance
      }
    } catch (e) {
      debugPrint('DocumentViewerPage: Error accepting document - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting document: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  Future<void> _declineDocument() async {
    try {
      switch (widget.documentType.toLowerCase()) {
        case 'terms':
          await _serviceManager.legalDocumentsService.declineTerms();
          break;
        case 'privacy':
          await _serviceManager.legalDocumentsService.declinePrivacy();
          break;
        case 'security':
          await _serviceManager.legalDocumentsService.declineSecurity();
          break;
        case 'usage':
          await _serviceManager.legalDocumentsService.declineUsage();
          break;
        case 'compliance':
          await _serviceManager.legalDocumentsService.declineCompliance();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.documentTitle} declined'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
        context.pop(false); // Return false to indicate decline
      }
    } catch (e) {
      debugPrint('DocumentViewerPage: Error declining document - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining document: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  void _showAcceptDeclineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.documentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please read the entire document before making a decision.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (!_hasScrolledToBottom)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningOrange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please scroll to the bottom of the document first.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _hasScrolledToBottom
                ? () {
                    Navigator.pop(context);
                    _declineDocument();
                  }
                : null,
            child: const Text(
              'Decline',
              style: TextStyle(color: AppTheme.criticalRed),
            ),
          ),
          ElevatedButton(
            onPressed: _hasScrolledToBottom
                ? () {
                    Navigator.pop(context);
                    _acceptDocument();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentTitle),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (widget.showAcceptDecline)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _showAcceptDeclineDialog,
              tooltip: 'Accept/Decline',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading document...'),
                ],
              ),
            )
          : Column(
              children: [
                // Document reading progress indicator
                if (!_hasScrolledToBottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.infoBlue.withValues(alpha: 0.1),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.infoBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please read the entire document to enable accept/decline options.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.infoBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Document content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _documentContent,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                // Accept/Decline buttons (fixed at bottom)
                if (widget.showAcceptDecline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _hasScrolledToBottom
                                ? _declineDocument
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.criticalRed,
                              side: const BorderSide(
                                color: AppTheme.criticalRed,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _hasScrolledToBottom
                                ? _acceptDocument
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.safeGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
