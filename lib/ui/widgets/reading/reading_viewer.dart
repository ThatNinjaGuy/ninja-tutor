import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'reading_controls_overlay.dart';

import '../../../models/content/book_model.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/reading_ai_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'reading_controls_panel.dart';

/// Main reading viewer widget for displaying book content
class ReadingViewer extends ConsumerStatefulWidget {
  const ReadingViewer({
    super.key,
    required this.book,
    this.onTextSelected,
    this.onDefinitionRequest,
    this.onPageChanged,
  });

  final BookModel book;
  final Function(String text, Offset position)? onTextSelected;
  final Function(String word)? onDefinitionRequest;
  final Function(int page)? onPageChanged;

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
  String? _pdfBlobUrl;
  bool _pdfSent = false; // Track if PDF has been sent to viewer to prevent duplicate loads
  String? _currentViewType; // Track current view type to avoid re-registration
  
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
  
  // Captured annotations storage
  final List<Map<String, dynamic>> _capturedTextSelections = [];
  final List<Map<String, dynamic>> _capturedTextAnnotations = [];
  final List<Map<String, dynamic>> _capturedDrawings = [];
  final List<Map<String, dynamic>> _capturedHighlights = [];
  
  // Message listener reference for cleanup
  void Function(html.Event)? _messageListener;

  @override
  void initState() {
    super.initState();
    print('🔄 ReadingViewer initState - Resetting state for new book load');
    _pdfSent = false; // Reset flag on each load
    _pdfBlobUrl = null; // Clear previous blob URL
    _iframeElement = null; // Reset iframe element to force re-creation
    _isLoading = true; // Reset loading state
    _error = null; // Clear any previous errors
    _currentViewType = null; // Reset view type for fresh iframe
    _loadPdfData();
    _startPeriodicProgressSave();
  }

  @override
  void didUpdateWidget(ReadingViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the book changed, reset everything and reload
    if (oldWidget.book.id != widget.book.id) {
      print('🔄 Book changed, resetting state for: ${widget.book.title}');
      _pdfSent = false;
      _pdfBlobUrl = null;
      _iframeElement = null;
      _isLoading = true;
      _error = null;
      _currentViewType = null; // Force new view type for new book
      _loadPdfData();
    }
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _saveProgressImmediately(); // Save any pending progress before disposing
    
    // Remove message listener to prevent memory leaks
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener!);
      _messageListener = null;
    }
    
    // Clean up blob URL to prevent memory leaks
    if (_pdfBlobUrl != null) {
      html.Url.revokeObjectUrl(_pdfBlobUrl!);
      _pdfBlobUrl = null;
    }
    
    // Reset state for next load
    _pdfSent = false;
    _isLoading = true;
    
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
    print('🔍 DEBUG: Loading PDF for book: ${widget.book.title}');
    print('🔍 DEBUG: Book ID: ${widget.book.id}');
    print('🔍 DEBUG: fileUrl value: ${widget.book.fileUrl}');
    print('🔍 DEBUG: fileUrl is null: ${widget.book.fileUrl == null}');
    print('🔍 DEBUG: fileUrl isEmpty: ${widget.book.fileUrl?.isEmpty ?? true}');
    print('🔍 DEBUG: totalPages: ${widget.book.totalPages}');
    
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      print('❌ ERROR: No file URL available for this book');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No PDF file available for this book';
        });
      }
      return;
    }

    print('✅ File URL is valid, proceeding to load');
    
    // Fetch PDF as blob and create blob URL to pass to viewer
    try {
      final backendUrl = '${AppConstants.baseUrl}/api/v1/books/${widget.book.id}/file';
      print('🌐 Fetching PDF from backend: $backendUrl');
      
      final response = await html.window.fetch(backendUrl);
      
      // Note: FetchResponse doesn't expose status directly in Dart
      print('✅ Backend response received');
      
      // Convert response to blob
      final blob = await response.blob();
      print('✅ PDF blob created, size: ${blob.size} bytes (${(blob.size / 1024 / 1024).toStringAsFixed(2)} MB)');
      
      // Create blob URL that the viewer can use
      final blobUrl = html.Url.createObjectUrl(blob);
      print('✅ Blob URL created: $blobUrl');
      
      if (mounted) {
        setState(() {
          _pdfBlobUrl = blobUrl;
          _isLoading = false;
          _error = null;
        });
        
        // Try to send PDF URL to iframe if it's already loaded
        Future.delayed(const Duration(milliseconds: 300), () {
          _sendPdfUrlToIframe();
        });
      }
      
      print('✅ PDF data loaded successfully');
    } catch (e) {
      print('❌ Failed to fetch PDF: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load PDF: $e';
        });
      }
    }
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

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading ${widget.book.title}...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching from Firebase',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(ThemeData theme) {
    final fullUrl = _getFullPdfUrl();
    
    // Show loading screen while blob URL is being created
    if (fullUrl == null && _isLoading) {
      return _buildLoadingScreen();
    }
    
    // Show error screen if loading failed
    if (fullUrl == null && _error == null && !_isLoading) {
      return _buildFallbackContent();
    }

    // Log the final PDF URL that will be requested
    print('🎯 FINAL PDF URL THAT WILL BE LOADED: $fullUrl');

    // Return loading screen if URL is still null at this point
    if (fullUrl == null) {
      return _buildLoadingScreen();
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
    // Only create a new view type if book changes
    if (_currentViewType == null || !_currentViewType!.contains(widget.book.id)) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentViewType = 'pdf-viewer-${widget.book.id}-$timestamp';
    }
    final viewType = _currentViewType!;
    
    // Use PDF.js viewer from Flutter app (same origin - avoids X-Frame-Options issues)
    // Build iframe without file parameter - will send via postMessage when ready
    final pdfJsUrl = '/pdfjs/web/custom_viewer.html';
    
    // Debug: Log the URLs
    print('📚 Building PDF viewer for book: ${widget.book.title}');
    print('📄 PDF URL to load: $pdfUrl');
    print('🌐 PDF.js Viewer URL: $pdfJsUrl');
    
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
                
                // CRITICAL: Send PDF URL via postMessage when iframe is ready
                // Wait a bit for viewer to initialize, then send the PDF URL
                Future.delayed(const Duration(milliseconds: 500), () {
                  _sendPdfUrlToIframe();
                });
                
                // Also try to send if blob URL becomes available
                Future.delayed(const Duration(milliseconds: 1000), () {
                  _sendPdfUrlToIframe();
                });
              }
            })
            ..onError.listen((event) {
              print('❌ IFRAME ERROR: $event');
              print('❌ Error loading PDF.js viewer');
              if (mounted) {
                setState(() {
                  _error = 'Failed to load PDF viewer: ${event.toString()}';
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
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Loading PDF...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoading 
              ? 'Fetching PDF from server...' 
              : 'This book does not have a PDF file associated with it.',
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
    // Use blob URL if available (PDF data loaded as blob to avoid origin issues)
    if (_pdfBlobUrl != null) {
      print('✅ Using blob URL for PDF: $_pdfBlobUrl');
      return _pdfBlobUrl;
    }
    
    // If blob URL is not ready yet, return null to wait
    if (_isLoading) {
      print('⏳ Waiting for blob URL to be created...');
      return null;
    }
    
    // Fallback to backend endpoint (for legacy support)
    final bookId = widget.book.id;
    final backendUrl = '${AppConstants.baseUrl}/api/v1/books/$bookId/file';
    print('✅ Using backend endpoint for PDF: $backendUrl');
    return backendUrl;
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
    // Store the listener so we can remove it later
    _messageListener = (html.Event event) {
      // Check if widget is still mounted before processing
      if (!mounted) return;
      
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
    };
    
    html.window.addEventListener('message', _messageListener!);
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
        _onTextSelection(message['text'] ?? '', message['page'] ?? 1, message['position']);
        break;
      case 'highlight':
        _onHighlight(message['text'] ?? '', message['page'] ?? 1, message['color'] ?? 'yellow');
        break;
      case 'annotation':
        _onAnnotation(message);
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
      
      // Notify parent widget about page change
      widget.onPageChanged?.call(newPage);
      
      // Update AI provider context (clear selected text on page change)
      ref.read(readingAiProvider.notifier).updateContext(
        page: newPage,
        selectedText: null,
        bookId: widget.book.id,
      );
    }
  }

  void _onTextSelection(String text, int pageNum, Map<String, dynamic>? position) {
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    
    // Store selection data and show overlay
    setState(() {
      _selectedText = text;
      _showSelectionOverlay = text.isNotEmpty;
    });
    
    if (text.isNotEmpty && position != null) {
      // Save to captured selections list
      final selection = {
        'text': text,
        'page': pageNum,
        'position': position,
        'timestamp': DateTime.now().toIso8601String(),
        'bookId': widget.book.id,
      };
      
      _capturedTextSelections.add(selection);
      
      print('📝 Text selected #${_capturedTextSelections.length}: "$text" (${position['charCount'] ?? text.length} chars) on page $pageNum');
      print('   Position: PDF(${position['pdfX']}, ${position['pdfY']}) Size: ${position['pdfWidth']}x${position['pdfHeight']}');
      print('   Total selections captured: ${_capturedTextSelections.length}');
    }
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
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    
    setState(() {
      _currentPage = currentPage;
    });
    // Start tracking time for the initial page
    _currentPageStartTime = DateTime.now();
    print('📖 PDF ready - starting time tracking for page $currentPage');
  }

  void _sendPageTimeData(int pageNum, int timeSpent) {
    // TODO: Implement API call to save page time data
    print('Sending page time data: page $pageNum, time $timeSpent seconds');
  }

  void _saveHighlight(String text, int pageNum, String color) {
    // TODO: Implement API call to save highlight
    print('💾 Saving highlight: "$text" on page $pageNum with color $color');
  }
  
  void _onAnnotation(Map<String, dynamic> annotation) {
    final type = annotation['type'] ?? 'unknown';
    final page = annotation['page'] ?? 1;
    final position = annotation['position'] as Map<String, dynamic>?;
    
    // Add common fields
    annotation['timestamp'] = DateTime.now().toIso8601String();
    annotation['bookId'] = widget.book.id;
    
    print('✏️ Annotation captured: type=$type, page=$page');
    
    switch (type) {
      case 'freetext':
        final text = annotation['text'] ?? '';
        final fontSize = annotation['fontSize'] ?? '';
        final color = annotation['color'] ?? '';
        
        _capturedTextAnnotations.add(annotation);
        
        print('   📄 Text #${_capturedTextAnnotations.length}: "$text" (fontSize: $fontSize, color: $color)');
        print('   📍 Position: PDF(${position?['pdfX']}, ${position?['pdfY']})');
        print('   Total text annotations: ${_capturedTextAnnotations.length}');
        _saveTextAnnotation(text, page, position);
        break;
        
      case 'ink':
        final drawingData = annotation['drawingData'] ?? '';
        final width = annotation['width'] ?? 0;
        final height = annotation['height'] ?? 0;
        
        _capturedDrawings.add(annotation);
        
        print('   ✏️ Drawing #${_capturedDrawings.length}: ${width}x${height}px');
        print('   📍 Position: PDF(${position?['pdfX']}, ${position?['pdfY']})');
        print('   🖼️ Data size: ${drawingData.length} chars (base64 PNG)');
        print('   Total drawings: ${_capturedDrawings.length}');
        _saveDrawingAnnotation(drawingData, page, position);
        break;
        
      case 'highlight':
        final color = annotation['color'] ?? '';
        
        _capturedHighlights.add(annotation);
        
        print('   🎨 Highlight #${_capturedHighlights.length}: color=$color');
        print('   📍 Position: PDF(${position?['pdfX']}, ${position?['pdfY']})');
        print('   Total highlights: ${_capturedHighlights.length}');
        break;
        
      default:
        print('   ❓ Unknown annotation type: $type');
    }
  }
  
  void _saveTextAnnotation(String text, int pageNum, Map<String, dynamic>? position) {
    // TODO: Implement API call to save text annotation
    print('💾 Saving text annotation to backend:');
    print('   Text: "$text"');
    print('   Page: $pageNum');
    print('   Position: $position');
  }
  
  void _saveDrawingAnnotation(String drawingData, int pageNum, Map<String, dynamic>? position) {
    // TODO: Implement API call to save drawing annotation
    print('💾 Saving drawing annotation to backend:');
    print('   Page: $pageNum');
    print('   Position: $position');
    print('   Drawing data (base64 PNG): ${drawingData.substring(0, 50)}... (${drawingData.length} chars total)');
  }

  /// Get all captured annotations organized by type
  Map<String, dynamic> getAllCapturedAnnotations() {
    return {
      'textSelections': _capturedTextSelections,
      'textAnnotations': _capturedTextAnnotations,
      'drawings': _capturedDrawings,
      'highlights': _capturedHighlights,
      'counts': {
        'textSelections': _capturedTextSelections.length,
        'textAnnotations': _capturedTextAnnotations.length,
        'drawings': _capturedDrawings.length,
        'highlights': _capturedHighlights.length,
        'total': _capturedTextSelections.length + 
                 _capturedTextAnnotations.length + 
                 _capturedDrawings.length + 
                 _capturedHighlights.length,
      },
      'bookId': widget.book.id,
      'bookTitle': widget.book.title,
    };
  }
  
  /// Print summary of all captured data
  void printAnnotationsSummary() {
    final data = getAllCapturedAnnotations();
    print('\n📊 ===== ANNOTATIONS SUMMARY =====');
    print('📚 Book: ${data['bookTitle']}');
    print('🆔 Book ID: ${data['bookId']}');
    print('\n📈 Counts:');
    print('   Text Selections: ${data['counts']['textSelections']}');
    print('   Text Annotations: ${data['counts']['textAnnotations']}');
    print('   Drawings: ${data['counts']['drawings']}');
    print('   Highlights: ${data['counts']['highlights']}');
    print('   ─────────────────');
    print('   TOTAL: ${data['counts']['total']}');
    print('==================================\n');
  }

  void _hideUnwantedButtons() {
    // This method is no longer needed as we're using local PDF.js with buttons already removed
  }
  
  /// Send PDF URL to iframe via postMessage
  void _sendPdfUrlToIframe() {
    // Prevent sending PDF multiple times (which causes double rendering)
    if (_pdfSent) {
      print('⚠️ PDF already sent, skipping duplicate send');
      return;
    }
    
    print('🔍 _sendPdfUrlToIframe called');
    print('🔍 _iframeElement: $_iframeElement');
    print('🔍 _iframeElement?.contentWindow: ${_iframeElement?.contentWindow}');
    print('🔍 _pdfBlobUrl: $_pdfBlobUrl');
    
    if (_iframeElement == null || _iframeElement!.contentWindow == null) {
      print('⚠️ Cannot send PDF URL: iframe not ready');
      print('   - iframe null: ${_iframeElement == null}');
      print('   - contentWindow null: ${_iframeElement?.contentWindow == null}');
      return;
    }
    
    final pdfUrl = _pdfBlobUrl;
    if (pdfUrl == null) {
      print('⚠️ Cannot send PDF URL: blob URL not ready');
      return;
    }
    
    print('📨 Sending PDF URL to iframe: $pdfUrl');
    print('📨 Message payload: {type: loadPDF, url: $pdfUrl}');
    
    try {
      _iframeElement!.contentWindow!.postMessage({
        'type': 'loadPDF',
        'url': pdfUrl,
      }, '*');
      _pdfSent = true; // Mark as sent to prevent duplicate sends
      print('✅ PDF URL sent successfully via postMessage');
    } catch (e) {
      print('❌ Failed to send PDF URL: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
}
