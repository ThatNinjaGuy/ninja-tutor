import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'reading_controls_overlay.dart';

import '../../../models/content/book_model.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'reading_controls_panel.dart';

/// Main reading viewer widget for displaying book content
class ReadingViewer extends ConsumerStatefulWidget {
  const ReadingViewer({
    super.key,
    required this.book,
    this.onTextSelected,
    this.onDefinitionRequest,
  });

  final BookModel book;
  final Function(String text, Offset position)? onTextSelected;
  final Function(String word)? onDefinitionRequest;

  @override
  ConsumerState<ReadingViewer> createState() => _ReadingViewerState();
}

class _ReadingViewerState extends ConsumerState<ReadingViewer> {
  bool _showControls = true;
  double _zoomLevel = 1.0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _error;
  html.IFrameElement? _iframeElement;
  
  // Text selection overlay
  String _selectedText = '';
  Map<String, dynamic>? _selectionPosition;
  bool _showSelectionOverlay = false;
  
  // Progress update - periodic saving every 60 seconds
  Timer? _progressSaveTimer;
  int? _pendingPage;
  double? _pendingProgressPercentage;
  Map<String, int> _pageTimesAccumulator = {}; // page_number: seconds_spent since last save
  DateTime? _currentPageStartTime; // Track when user started reading current page

  @override
  void initState() {
    super.initState();
    _loadPdfData();
    _startPeriodicProgressSave();
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _saveProgressImmediately(); // Save any pending progress before disposing
    super.dispose();
  }
  
  void _startPeriodicProgressSave() {
    // Save progress every 60 seconds (periodic, not debounced)
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _saveProgressImmediately();
    });
    print('⏰ Started periodic progress save (every 60 seconds)');
  }

  Future<void> _loadPdfData() async {
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'No PDF file available for this book';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Main content area
          if (_isLoading)
            _buildLoadingState(theme)
          else if (_error != null)
              _buildErrorState(theme)
            else
              _buildPdfViewer(theme),
            
          ],
        ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading ${widget.book.title}...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load book',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPdfData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(ThemeData theme) {
    final fullUrl = _getFullPdfUrl();
    
    if (fullUrl == null) {
      return _buildFallbackContent();
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[200],
          child: _buildWebPdfViewer(fullUrl),
        ),
        
        // Text selection overlay
        if (_showSelectionOverlay)
          ReadingControlsOverlay(
            bookId: widget.book.id,
            selectedText: _selectedText,
            pageNumber: _currentPage,
            position: _selectionPosition,
            onClose: () {
              setState(() {
                _showSelectionOverlay = false;
                _selectedText = '';
                _selectionPosition = null;
              });
            },
          ),
      ],
    );
  }

  Widget _buildWebPdfViewer(String pdfUrl) {
    // Use Mozilla PDF.js for better web PDF viewing
    final viewType = 'pdf-viewer-${widget.book.id}';
    
    // Use PDF.js viewer from backend (same origin as PDF files - no CORS issues)
    final pdfJsUrl = '${AppConstants.baseUrl}/pdfjs/web/custom_viewer.html?file=${Uri.encodeComponent(pdfUrl)}';
    
    // Debug: Log the URLs
    print('PDF URL: $pdfUrl');
    print('PDF.js Viewer URL: $pdfJsUrl');
    
    // Register the view factory
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          _iframeElement = html.IFrameElement()
            ..src = pdfJsUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block'
            ..allowFullscreen = true
            ..onLoad.listen((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                // Hide download and print buttons using CSS injection
                _hideUnwantedButtons();
                
                // Setup message listener for PDF.js communication
                _setupPdfMessageListener();
                
                // Jump to last read page if available
                if (widget.book.progress?.currentPage != null && 
                    widget.book.progress!.currentPage > 0) {
                  setState(() {
                    _currentPage = widget.book.progress!.currentPage;
                  });
                }
              }
            })
            ..onError.listen((event) {
              if (mounted) {
                setState(() {
                  _error = 'Failed to load PDF';
                  _isLoading = false;
                });
              }
            });
          
          return _iframeElement!;
        },
      );
    } catch (e) {
      // View factory might already be registered
      setState(() {
        _isLoading = false;
      });
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: HtmlElementView(viewType: viewType),
    );
  }

  Widget _buildFallbackContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'PDF not available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This book does not have a PDF file associated with it.',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back to library
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Library'),
          ),
        ],
      ),
    );
  }

  String? _getFullPdfUrl() {
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      return null;
    }

    final fileUrl = widget.book.fileUrl!;
    
    // For Firebase Storage URLs, proxy through backend to avoid CORS issues
    if (fileUrl.contains('firebasestorage.app') || 
        fileUrl.contains('storage.googleapis.com')) {
      // Encode the Firebase URL and proxy it through backend
      final encodedUrl = Uri.encodeComponent(fileUrl);
      return '${AppConstants.baseUrl}/api/v1/proxy/pdf?url=$encodedUrl';
    }
    
    // If it's already a full URL (non-Firebase), return as-is
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    
    // If it's a local relative URL, prefix with backend base URL
    if (fileUrl.startsWith('/uploads/')) {
      return '${AppConstants.baseUrl}$fileUrl';
    }
    
    return fileUrl;
  }

  void _updateReadingProgress(int page) {
    // Just store the current page - the periodic timer will save it
    _pendingPage = page;
    _pendingProgressPercentage = page / widget.book.totalPages;
    
    final totalTime = _pageTimesAccumulator.values.fold(0, (sum, time) => sum + time);
    final pagesWithTime = _pageTimesAccumulator.length;
    print('📝 Current page: $page/${widget.book.totalPages}, tracked $pagesWithTime pages, ${totalTime}s total since last save');
  }
  
  void _saveProgressImmediately() {
    if (_pendingPage == null) return;
    
    // Calculate time on current page (if user hasn't changed pages yet)
    if (_currentPageStartTime != null && _currentPage > 0) {
      final currentPageTimeSeconds = DateTime.now().difference(_currentPageStartTime!).inSeconds;
      if (currentPageTimeSeconds > 0) {
        final currentPageKey = _currentPage.toString();
        _pageTimesAccumulator[currentPageKey] = (_pageTimesAccumulator[currentPageKey] ?? 0) + currentPageTimeSeconds;
        print('⏱️ Adding current page time: page $_currentPage spent ${currentPageTimeSeconds}s (still on this page)');
        
        // Reset the start time for the next interval
        _currentPageStartTime = DateTime.now();
      }
    }
    
    // Don't save if no time data accumulated
    if (_pageTimesAccumulator.isEmpty) {
      print('⚠️ No page time data to save yet');
      return;
    }
    
    final totalTime = _pageTimesAccumulator.values.fold(0, (sum, time) => sum + time);
    final pagesWithTime = _pageTimesAccumulator.length;
    
    print('💾 Saving progress to backend: page $_pendingPage/${widget.book.totalPages}');
    print('📊 Page times being saved: $_pageTimesAccumulator');
    print('⏱️ Total: $pagesWithTime pages, ${totalTime}s');
    
    // Call API with all accumulated page time data
    _saveProgressToBackend(
      page: _pendingPage!,
      pageTimes: Map<String, int>.from(_pageTimesAccumulator),
    );
    
    // Clear the accumulator after saving - backend has merged the times
    // This resets tracking for the next 60-second interval
    _pageTimesAccumulator.clear();
    print('🔄 Page time accumulator cleared - tracking fresh for next interval');
  }
  
  Future<void> _saveProgressToBackend({
    required int page,
    required Map<String, int> pageTimes,
  }) async {
    ref.read(unifiedLibraryProvider.notifier).updateReadingProgress(
      bookId: widget.book.id,
      currentPage: page,
      progressPercentage: page / widget.book.totalPages,
      pageTimes: pageTimes,
    );
    
    print('✅ Progress saved successfully');
  }

  void _setupPdfMessageListener() {
    html.window.addEventListener('message', (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;
      
      print('📨 Received message from PDF.js: $data');
      
      // Handle both Map<String, dynamic> and LinkedMap from JavaScript
      if (data is Map) {
        final messageData = Map<String, dynamic>.from(data);
        _handlePdfMessage(messageData);
      } else {
        print('⚠️ Message data is not a Map: ${data.runtimeType}');
      }
    });
  }

  void _handlePdfMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'pageChange':
        final previousPage = message['previousPage'] ?? 1;
        final newPage = message['newPage'] ?? 1;
        final timeSpent = message['timeSpent'] ?? 0;
        _onPageChange(previousPage, newPage, timeSpent);
        break;
      case 'textSelection':
        _onTextSelection(message['text'] ?? '', message['page'] ?? 1);
        break;
      case 'highlight':
        _onHighlight(message['text'] ?? '', message['page'] ?? 1, message['color'] ?? 'yellow');
        break;
      case 'idleStateChange':
        _onIdleStateChange(message['isIdle'] ?? false);
        break;
      case 'pdfReady':
        _onPdfReady(message['totalPages'] ?? 0, message['currentPage'] ?? 1);
        break;
    }
  }

  void _onPageChange(int previousPage, int newPage, int timeSpent) {
    print('📄 Page changed: page $previousPage spent $timeSpent seconds, now on page $newPage');
    
    // Accumulate time for the previous page
    if (timeSpent > 0) {
      final pageKey = previousPage.toString();
      _pageTimesAccumulator[pageKey] = (_pageTimesAccumulator[pageKey] ?? 0) + timeSpent;
      print('⏱️ Page $previousPage total time: ${_pageTimesAccumulator[pageKey]}s');
      print('📚 All accumulated times: $_pageTimesAccumulator');
    }
    
    // Track when we started reading the new page
    _currentPageStartTime = DateTime.now();
    
    if (mounted) {
      setState(() {
        _currentPage = newPage;
      });
      _updateReadingProgress(newPage);
    }
  }

  void _onTextSelection(String text, int pageNum) {
    // Store selection data and show overlay
    setState(() {
      _selectedText = text;
      _showSelectionOverlay = text.isNotEmpty;
    });
    print('Text selected: $text on page $pageNum');
  }

  void _onHighlight(String text, int pageNum, String color) {
    // Save highlight to backend
    _saveHighlight(text, pageNum, color);
  }

  void _onIdleStateChange(bool isIdle) {
    // Track idle state for accurate time measurement
    print('User idle state: $isIdle');
  }

  void _onPdfReady(int totalPages, int currentPage) {
    if (mounted) {
      setState(() {
        _currentPage = currentPage;
      });
      // Start tracking time for the initial page
      _currentPageStartTime = DateTime.now();
      print('📖 PDF ready - starting time tracking for page $currentPage');
    }
  }

  void _sendPageTimeData(int pageNum, int timeSpent) {
    // TODO: Implement API call to save page time data
    print('Sending page time data: page $pageNum, time $timeSpent seconds');
  }

  void _saveHighlight(String text, int pageNum, String color) {
    // TODO: Implement API call to save highlight
    print('Saving highlight: "$text" on page $pageNum with color $color');
  }

  void _hideUnwantedButtons() {
    // This method is no longer needed as we're using local PDF.js with buttons already removed
  }
}
