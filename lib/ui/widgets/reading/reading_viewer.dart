import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'dart:js_util' as js_util;
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
    this.onSelectedTextChanged,
    this.onNoteClicked,
    this.notes,
  });

  final BookModel book;
  final Function(String text, Offset position)? onTextSelected;
  final Function(String word)? onDefinitionRequest;
  final Function(int page)? onPageChanged;
  final Function(String? selectedText)? onSelectedTextChanged;  // Callback for when text selection changes
  final Function(String noteId)? onNoteClicked;  // Callback for when a note is clicked
  final List<dynamic>? notes;  // List of notes to display on the PDF

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
  bool _pdfSent = false; // Track if PDF has been sent to viewer to prevent duplicate loads
  String? _currentViewType; // Track current view type to avoid re-registration
  
  // EPUB support
  bool _isEpubFormat = false;
  String? _epubBlobUrl;
  bool _epubSent = false;
  
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
  
  // Notes for current book
  List<dynamic> _notesForBook = [];
  
  // Message listener reference for cleanup
  void Function(html.Event)? _messageListener;

  @override
  void initState() {
    super.initState();
    _pdfSent = false; // Reset flag on each load
    _iframeElement = null; // Reset iframe element to force re-creation
    _isLoading = true; // Reset loading state
    _error = null; // Clear any previous errors
    _currentViewType = null; // Reset view type for fresh iframe
    
    // Detect format and load appropriate viewer
    _isEpubFormat = _detectEpubFormat(widget.book);
    if (_isEpubFormat) {
      _loadEpubData();
    } else {
      _loadPdfData();
    }
    _startPeriodicProgressSave();
    
    // Initialize notes from widget
    if (widget.notes != null) {
      _notesForBook = List.from(widget.notes!);
    }
  }
  
  /// Detect if the book is in EPUB format
  bool _detectEpubFormat(BookModel book) {
    final fileUrl = book.fileUrl ?? '';
    final format = book.metadata.format?.toLowerCase();
    return fileUrl.toLowerCase().endsWith('.epub') || 
           format == 'epub';
  }

  @override
  void didUpdateWidget(ReadingViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the book changed, reset everything and reload
    if (oldWidget.book.id != widget.book.id) {
      _pdfSent = false;
      _epubSent = false;
      _epubBlobUrl = null;
      _iframeElement = null;
      _isLoading = true;
      _error = null;
      _currentViewType = null; // Force new view type for new book
      
      // Re-detect format and load appropriate viewer
      _isEpubFormat = _detectEpubFormat(widget.book);
      if (_isEpubFormat) {
        _loadEpubData();
      } else {
        _loadPdfData();
      }
    }
    
    // Update notes when widget.notes changes
    if (widget.notes != null && widget.notes != oldWidget.notes) {
      _notesForBook = List.from(widget.notes!);
      _sendNotesToPdfViewer(_notesForBook);
    }
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    // Don't save progress here - it should have been saved periodically
    // Saving here causes "ref after disposal" errors
    
    // Remove message listener to prevent memory leaks
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener!);
      _messageListener = null;
    }
    
    // Clean up blob URLs to prevent memory leaks
    if (_epubBlobUrl != null) {
      html.Url.revokeObjectUrl(_epubBlobUrl!);
      _epubBlobUrl = null;
    }
    
    // Reset state for next load
    _pdfSent = false;
    _epubSent = false;
    _isLoading = true;
    
    super.dispose();
  }
  
  void _startPeriodicProgressSave() {
    // Save progress every 60 seconds (periodic, not debounced)
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _saveProgressImmediately();
    });
  }

  Future<void> _loadPdfData() async {
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No PDF file available for this book';
        });
      }
      return;
    }
    
    // For PDF files, use direct URL (no blob pre-fetching)
    // PDF.js will handle range requests automatically for streaming
    debugPrint('📄 PDF detected - using direct URL for streaming (no blob pre-fetch)');
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = null;
        // Don't set _pdfBlobUrl - we'll use the backend endpoint directly
      });
      
      // Try to send PDF URL to iframe if it's already loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        _sendPdfUrlToIframe();
      });
    }
  }

  Future<void> _loadEpubData() async {
    debugPrint('📕 Starting EPUB load for book: ${widget.book.title}');
    debugPrint('📕 Book fileUrl: ${widget.book.fileUrl}');
    debugPrint('📕 Book format: ${widget.book.metadata.format}');
    
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      debugPrint('❌ No EPUB file URL available');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No EPUB file available for this book';
        });
      }
      return;
    }
    
    // Fetch EPUB as blob and convert to base64 data URI for EPUB.js
    try {
      final backendUrl = '${AppConstants.baseUrl}/api/v1/books/${widget.book.id}/file';
      debugPrint('📕 Fetching EPUB from: $backendUrl');
      
      final response = await html.window.fetch(backendUrl);
      
      // Use JS interop to access status safely
      final status = _getResponseStatus(response);
      final statusText = _getResponseStatusText(response);
      final isOk = _isResponseOk(response);
      debugPrint('📕 Fetch response status: $status');
      debugPrint('📕 Response OK: $isOk');
      
      if (!isOk) {
        throw Exception('HTTP $status: $statusText');
      }
      
      // Convert response to blob
      final blob = await response.blob();
      debugPrint('📕 Blob created, size: ${blob.size} bytes, type: ${blob.type}');
      
      // Convert blob to base64 data URI for EPUB.js
      // EPUB.js has issues with blob: URLs for ZIP files, so we use data URI
      final reader = html.FileReader();
      reader.readAsDataUrl(blob);
      await reader.onLoad.first;
      String dataUrl = reader.result as String;
      
      debugPrint('📕 Data URL created, length: ${dataUrl.length} chars');
      debugPrint('📕 Data URL prefix: ${dataUrl.substring(0, 50)}...');
      
      // Fix the MIME type in the data URI (backend now sets correct type, but fix just in case)
      if (dataUrl.startsWith('data:application/pdf')) {
        debugPrint('⚠️ Fixing incorrect MIME type from application/pdf to application/epub+zip');
        dataUrl = dataUrl.replaceFirst('data:application/pdf', 'data:application/epub+zip');
      }
      
      final blobUrl = dataUrl;
      
      if (mounted) {
        setState(() {
          _epubBlobUrl = blobUrl;
          _isLoading = false;
          _error = null;
        });
        
        debugPrint('✅ EPUB blob URL set, will send to iframe');
        
        // Try to send EPUB URL to iframe if it's already loaded
        Future.delayed(const Duration(milliseconds: 300), () {
          _sendEpubUrlToIframe();
        });
        
        // Retry sending after 1 second if needed
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!_epubSent) {
            debugPrint('⚠️ EPUB not sent after 1s, retrying...');
            _sendEpubUrlToIframe();
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load EPUB: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load EPUB: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    debugPrint('📖 ReadingViewer build: isEpubFormat=$_isEpubFormat, isLoading=$_isLoading, error=$_error');
    
    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Main content area
          if (_isLoading)
            _buildLoadingState(theme)
          else if (_error != null)
              _buildErrorState(theme)
            else if (_isEpubFormat) ...[
              // Show debug info for EPUB
              () {
                debugPrint('📕 Rendering EPUB viewer for: ${widget.book.title}');
                return _buildEpubViewer(theme);
              }()
            ]
            else
              _buildPdfViewer(theme),
            
          ],
        ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    final formatName = _isEpubFormat ? 'EPUB' : 'PDF';
    
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
          const SizedBox(height: 8),
          Text(
            'Format: $formatName',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
        
        // Text selection overlay - positioned relative to the Stack
        if (_showSelectionOverlay && _selectedText.isNotEmpty)
          Positioned(
            left: _selectionPosition?['x'] ?? 100,
            top: _selectionPosition?['y'] != null 
                ? (_selectionPosition!['y'] - 60) 
                : 100,
            child: ReadingControlsOverlay(
              bookId: widget.book.id,
              selectedText: _selectedText,
              pageNumber: _currentPage,
              position: null, // Don't pass position to avoid double positioning
              onClose: () {
                setState(() {
                  _showSelectionOverlay = false;
                  _selectedText = '';
                  _selectionPosition = null;
                });
              },
            ),
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

  Widget _buildEpubViewer(ThemeData theme) {
    final fullUrl = _getFullEpubUrl();
    
    // Show loading screen while blob URL is being created
    if (fullUrl == null && _isLoading) {
      return _buildLoadingScreen();
    }
    
    // Show error screen if loading failed
    if (fullUrl == null && _error == null && !_isLoading) {
      return _buildFallbackContent();
    }

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
          child: _buildWebEpubViewer(fullUrl),
        ),
        
        // Text selection overlay - positioned relative to the Stack
        if (_showSelectionOverlay && _selectedText.isNotEmpty)
          Positioned(
            left: _selectionPosition?['x'] ?? 100,
            top: _selectionPosition?['y'] != null 
                ? (_selectionPosition!['y'] - 60) 
                : 100,
            child: ReadingControlsOverlay(
              bookId: widget.book.id,
              selectedText: _selectedText,
              pageNumber: _currentPage,
              position: null,
              onClose: () {
                setState(() {
                  _showSelectionOverlay = false;
                  _selectedText = '';
                  _selectionPosition = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWebEpubViewer(String epubUrl) {
    // Use EPUB.js for web EPUB viewing
    // Only create a new view type if book changes
    if (_currentViewType == null || !_currentViewType!.contains(widget.book.id)) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentViewType = 'epub-viewer-${widget.book.id}-$timestamp';
    }
    final viewType = _currentViewType!;
    
    // Use EPUB.js viewer from Flutter app
    final epubJsUrl = '/epubjs/web/custom_epub_viewer.html';
    
    debugPrint('📕 Creating EPUB viewer iframe with viewType: $viewType');
    debugPrint('📕 EPUB viewer URL: $epubJsUrl');
    
    // Register the view factory
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          debugPrint('📕 View factory called for viewId: $viewId');
          
          _iframeElement = html.IFrameElement()
            ..src = epubJsUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block'
            ..allowFullscreen = true
            ..onLoad.listen((_) {
              debugPrint('✅ EPUB iframe loaded successfully');
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                // Setup message listener for EPUB.js communication
                _setupPdfMessageListener();
                
                // Jump to last read page if available
                if (widget.book.progress?.currentPage != null && 
                    widget.book.progress!.currentPage > 0) {
                  setState(() {
                    _currentPage = widget.book.progress!.currentPage;
                  });
                }
                
                // Send EPUB URL via postMessage when iframe is ready
                Future.delayed(const Duration(milliseconds: 500), () {
                  debugPrint('📕 Attempting to send EPUB URL (500ms delay)');
                  _sendEpubUrlToIframe();
                });
                
                // Also try to send if blob URL becomes available
                Future.delayed(const Duration(milliseconds: 1000), () {
                  debugPrint('📕 Attempting to send EPUB URL (1000ms delay)');
                  _sendEpubUrlToIframe();
                });
                
                // Additional retry after 2 seconds
                Future.delayed(const Duration(milliseconds: 2000), () {
                  if (!_epubSent && mounted) {
                    debugPrint('📕 Final retry to send EPUB URL (2000ms delay)');
                    _sendEpubUrlToIframe();
                  }
                });
              }
            })
            ..onError.listen((event) {
              debugPrint('❌ EPUB iframe error: $event');
              if (mounted) {
                setState(() {
                  _error = 'Failed to load EPUB viewer iframe: ${event.toString()}';
                  _isLoading = false;
                });
              }
            });
          
          debugPrint('📕 Returning EPUB iframe element');
          return _iframeElement!;
        },
      );
    } catch (e, stackTrace) {
      // View factory might already be registered
      debugPrint('⚠️ View factory registration error (might be already registered): $e');
      debugPrint('⚠️ Stack trace: $stackTrace');
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
    // Use direct backend endpoint for streaming with Range requests
    // No more blob URL - PDF.js will fetch the PDF incrementally
    final bookId = widget.book.id;
    final backendUrl = '${AppConstants.baseUrl}/api/v1/books/$bookId/file';
    debugPrint('✅ Using backend endpoint for PDF streaming: $backendUrl');
    return backendUrl;
  }

  String? _getFullEpubUrl() {
    // Use blob URL if available (EPUB data loaded as blob to avoid origin issues)
    if (_epubBlobUrl != null) {
      print('✅ Using blob URL for EPUB: $_epubBlobUrl');
      return _epubBlobUrl;
    }
    
    // If blob URL is not ready yet, return null to wait
    if (_isLoading) {
      print('⏳ Waiting for EPUB blob URL to be created...');
      return null;
    }
    
    // Fallback to backend endpoint
    final bookId = widget.book.id;
    final backendUrl = '${AppConstants.baseUrl}/api/v1/books/$bookId/file';
    print('✅ Using backend endpoint for EPUB: $backendUrl');
    return backendUrl;
  }

  void _updateReadingProgress(int page) {
    // Just store the current page - the periodic timer will save it
    _pendingPage = page;
    _pendingProgressPercentage = page / widget.book.totalPages;
    
  }
  
  void _saveProgressImmediately() {
    if (_pendingPage == null) return;
    
    // Calculate time on current page (if user hasn't changed pages yet)
    if (_currentPageStartTime != null && _currentPage > 0) {
      final currentPageTimeSeconds = DateTime.now().difference(_currentPageStartTime!).inSeconds;
      if (currentPageTimeSeconds > 0) {
        final currentPageKey = _currentPage.toString();
        _pageTimesAccumulator[currentPageKey] = (_pageTimesAccumulator[currentPageKey] ?? 0) + currentPageTimeSeconds;
        
        // Reset the start time for the next interval
        _currentPageStartTime = DateTime.now();
      }
    }
    
    // Don't save if no time data accumulated
    if (_pageTimesAccumulator.isEmpty) {
      return;
    }
    
    // Call API with all accumulated page time data
    _saveProgressToBackend(
      page: _pendingPage!,
      pageTimes: Map<String, int>.from(_pageTimesAccumulator),
    );
    
    // Clear the accumulator after saving - backend has merged the times
    // This resets tracking for the next 60-second interval
    _pageTimesAccumulator.clear();
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
  }

  void _setupPdfMessageListener() {
    // Store the listener so we can remove it later
    _messageListener = (html.Event event) {
      // Check if widget is still mounted before processing
      if (!mounted) return;
      
      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;
      
      // Handle both Map<String, dynamic> and LinkedMap from JavaScript
      if (data is Map) {
        final messageData = Map<String, dynamic>.from(data);
        _handlePdfMessage(messageData);
      }
    };
    
    html.window.addEventListener('message', _messageListener!);
  }

  void _handlePdfMessage(Map<String, dynamic> message) {
    debugPrint('📨 Received message from viewer: ${message['type']}');
    
    switch (message['type']) {
      case 'pageChange':
        final previousPage = message['previousPage'] ?? 1;
        final newPage = message['newPage'] ?? 1;
        final timeSpent = message['timeSpent'] ?? 0;
        _onPageChange(previousPage, newPage, timeSpent);
        break;
      case 'textSelection':
        // Convert LinkedMap to Map<String, dynamic>
        Map<String, dynamic>? position;
        if (message['position'] != null) {
          try {
            position = Map<String, dynamic>.from(message['position']);
          } catch (e) {
            position = null;
          }
        }
        
        _onTextSelection(message['text'] ?? '', message['page'] ?? 1, position);
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
      case 'bookReady':
        // Handle EPUB book ready message (same as pdfReady)
        debugPrint('📕 EPUB book ready message received');
        _onPdfReady(message['totalPages'] ?? 0, message['currentPage'] ?? 1);
        break;
      case 'error':
        // Handle error messages from viewer
        debugPrint('❌ Error from viewer: ${message['message']}');
        if (mounted) {
          setState(() {
            _error = 'Viewer error: ${message['message']}';
            _isLoading = false;
          });
        }
        break;
      case 'createNoteFromSelection':
        _onCreateNoteFromSelection(message);
        break;
      case 'noteClicked':
        widget.onNoteClicked?.call(message['noteId'] as String);
        break;
      default:
        debugPrint('⚠️ Unknown message type: ${message['type']}');
    }
  }
  
  void _onCreateNoteFromSelection(Map<String, dynamic> message) {
    final selectedText = message['selectedText'] as String?;
    final page = message['page'] as int?;
    final position = message['position'] as Map<String, dynamic>?;
    
    if (selectedText != null && page != null) {
      // Trigger note creation dialog in parent
      if (mounted) {
        // Store the selection data temporarily
        setState(() {
          _selectedText = selectedText;
          _selectionPosition = position;
          _showSelectionOverlay = false; // Hide the selection overlay since we're creating a note
        });
        
        // The actual dialog will be shown by ReadingInterfaceMixin
        widget.onTextSelected?.call(selectedText, const Offset(0, 0));
      }
    }
  }

  void _onPageChange(int previousPage, int newPage, int timeSpent) {
    
    // Accumulate time for the previous page
    if (timeSpent > 0) {
      final pageKey = previousPage.toString();
      _pageTimesAccumulator[pageKey] = (_pageTimesAccumulator[pageKey] ?? 0) + timeSpent;
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
    if (!mounted) {
      return;
    }
    
    // Just store the selected text - no overlay needed
    // The notes dialog will be triggered by the Notes button in the UI
    setState(() {
      _selectedText = text;
      _selectionPosition = position;
      // Don't show overlay anymore
      _showSelectionOverlay = false;
    });
    
    // Notify parent about selected text change
    widget.onSelectedTextChanged?.call(text.isNotEmpty ? text : null);
    
    if (text.isNotEmpty && position != null) {
      // Save to captured selections list for reference
      final selection = {
        'text': text,
        'page': pageNum,
        'position': position,
        'timestamp': DateTime.now().toIso8601String(),
        'bookId': widget.book.id,
      };
      
      _capturedTextSelections.add(selection);
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
    
    // Send notes to PDF viewer with a slight delay to ensure PDF.js is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _notesForBook.isNotEmpty) {
        print('📤 Delayed sending ${_notesForBook.length} notes to PDF viewer');
        _sendNotesToPdfViewer(_notesForBook);
      }
    });
  }
  
  /// Send notes data to PDF viewer for highlighting
  void _sendNotesToPdfViewer(List<dynamic> notes) {
    if (notes.isEmpty) return;
    
    final notesData = notes.map((note) => {
      'id': note.id,
      'page': note.pageNumber,
      'selectedText': note.selectedText,
      'content': note.content,
      'title': note.title,
    }).toList();
    
    print('📤 Sending ${notesData.length} notes to PDF viewer');
    // Debug: Check all notes for selectedText
    if (notes.isNotEmpty) {
      print('📝 Notes with selectedText:');
      for (var note in notes) {
        print('   ID: ${note.id}, Page: ${note.pageNumber}');
        print('   selectedText: ${note.selectedText}');
        print('   selectedText is null: ${note.selectedText == null}');
        print('   selectedText is empty: ${note.selectedText?.isEmpty ?? true}');
      }
    }
    // Debug: Check first note in notesData to see if conversion worked
    if (notesData.isNotEmpty) {
      print('📝 First note in notesData: ${notesData[0]}');
      print('📝 Full notesData JSON: ${notesData.toString()}');
    }
    _iframeElement?.contentWindow?.postMessage({
      'type': 'displayNotes',
      'notes': notesData,
    }, '*');
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
      debugPrint('⚠️ PDF already sent, skipping duplicate send');
      return;
    }
    
    debugPrint('🔍 _sendPdfUrlToIframe called');
    
    if (_iframeElement == null || _iframeElement!.contentWindow == null) {
      debugPrint('⚠️ Cannot send PDF URL: iframe not ready');
      return;
    }
    
    // Get direct backend URL (no blob)
    final pdfUrl = _getFullPdfUrl();
    if (pdfUrl == null) {
      debugPrint('⚠️ Cannot send PDF URL: URL not available');
      return;
    }
    
    debugPrint('📨 Sending PDF URL to iframe for streaming: $pdfUrl');
    debugPrint('📨 PDF.js will use HTTP Range requests for incremental loading');
    
    try {
      _iframeElement!.contentWindow!.postMessage({
        'type': 'loadPDF',
        'url': pdfUrl,
      }, '*');
      _pdfSent = true; // Mark as sent to prevent duplicate sends
      debugPrint('✅ PDF URL sent successfully - streaming enabled');
    } catch (e) {
      debugPrint('❌ Failed to send PDF URL: $e');
    }
  }
  
  /// Send EPUB URL to iframe via postMessage
  void _sendEpubUrlToIframe() {
    // Prevent sending EPUB multiple times (which causes double rendering)
    if (_epubSent) {
      debugPrint('⚠️ EPUB already sent, skipping duplicate send');
      return;
    }
    
    debugPrint('🔍 _sendEpubUrlToIframe called');
    debugPrint('🔍 _iframeElement: $_iframeElement');
    debugPrint('🔍 _iframeElement?.contentWindow: ${_iframeElement?.contentWindow}');
    debugPrint('🔍 _epubBlobUrl length: ${_epubBlobUrl?.length ?? 0}');
    
    if (_iframeElement == null || _iframeElement!.contentWindow == null) {
      debugPrint('⚠️ Cannot send EPUB URL: iframe not ready');
      debugPrint('   - iframe null: ${_iframeElement == null}');
      debugPrint('   - contentWindow null: ${_iframeElement?.contentWindow == null}');
      return;
    }
    
    final epubUrl = _epubBlobUrl;
    if (epubUrl == null) {
      debugPrint('⚠️ Cannot send EPUB URL: blob URL not ready');
      return;
    }
    
    debugPrint('📨 Sending EPUB URL to iframe (data URI length: ${epubUrl.length} chars)');
    debugPrint('📨 Message payload: {type: loadEPUB, url: [data URI]}');
    
    try {
      _iframeElement!.contentWindow!.postMessage({
        'type': 'loadEPUB',
        'url': epubUrl,
      }, '*');
      _epubSent = true; // Mark as sent to prevent duplicate sends
      debugPrint('✅ EPUB URL sent successfully via postMessage');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send EPUB URL: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Update error state
      if (mounted) {
        setState(() {
          _error = 'Failed to send EPUB to viewer: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Helper method to safely get response status from web Response object
  int _getResponseStatus(dynamic response) {
    try {
      // Access the underlying JS object's status property using JS interop
      return js_util.getProperty(response, 'status') as int? ?? 200;
    } catch (e) {
      // Fallback: check if response is OK
      final isOk = _isResponseOk(response);
      return isOk ? 200 : 500;
    }
  }
  
  /// Helper method to safely get response status text from web Response object
  String _getResponseStatusText(dynamic response) {
    try {
      // Use JS interop to get statusText
      return js_util.getProperty(response, 'statusText') as String? ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// Helper method to safely check if response is OK
  bool _isResponseOk(dynamic response) {
    try {
      // Use JS interop to get 'ok' property
      final ok = js_util.getProperty(response, 'ok') as bool?;
      
      // If 'ok' property is not available, check status code
      if (ok != null) {
        return ok;
      }
      
      // Fallback: check if status is between 200-299
      final status = _getResponseStatus(response);
      return status >= 200 && status < 300;
    } catch (e) {
      // Last resort: default to false for error state
      return false;
    }
  }
}
