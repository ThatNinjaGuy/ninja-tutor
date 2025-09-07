import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../../../models/content/book_model.dart';
import '../../../core/providers/user_library_provider.dart';
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
  bool _showControls = false;
  double _zoomLevel = 1.0;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _error;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    _loadPdfData();
    
    // Hide hint after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_showControls) {
        setState(() {
          _showHint = false;
        });
      }
    });
  }

  Future<void> _loadPdfData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if we have a valid file URL
      if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No PDF file available for this book';
        });
        return;
      }

      // For web platform, we'll check if PDF is accessible
      // The PDF will be embedded directly in the interface
      setState(() {
        _isLoading = false;
        _error = null; // Successfully loaded
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load PDF: $e';
      });
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
            
            // Controls overlay
            if (_showControls)
              ReadingControlsPanel(
                book: widget.book,
                currentPage: _currentPage,
                totalPages: widget.book.totalPages,
                zoomLevel: _zoomLevel,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _updateReadingProgress(page);
                },
                onZoomChanged: (zoom) {
                  setState(() {
                    _zoomLevel = zoom;
                  });
                },
                onClose: () {
                  setState(() {
                    _showControls = false;
                  });
                },
              ),
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Stack(
        children: [
          // PDF iframe container
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildWebPdfViewer(),
              ),
            ),
          ),
          
          
          // Tap hint overlay (only show initially)
          if (!_showControls && _showHint)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tap to show reading controls',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebPdfViewer() {
    // For web platform, embed the PDF directly using iframe with PDF.js
    if (widget.book.fileUrl != null && widget.book.fileUrl!.isNotEmpty) {
      return _buildEmbeddedPdfViewer();
    } else {
      // Fallback content when no PDF URL is available
      return _buildFallbackContent();
    }
  }

  Widget _buildEmbeddedPdfViewer() {
    final fullUrl = _getFullPdfUrl();
    if (fullUrl == null) return _buildFallbackContent();

    // Create unique view type for this PDF
    final viewType = 'pdf-viewer-${widget.book.id}';
    
    // Register the platform view factory for PDF iframe
    _registerPdfViewFactory(viewType, fullUrl);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          // Full-screen PDF viewer
          Positioned.fill(
            child: HtmlElementView(viewType: viewType),
          ),
          
          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading PDF...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _registerPdfViewFactory(String viewType, String pdfUrl) {
    // Register the view factory if not already registered
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block'
            ..style.pointerEvents = 'none' // Allow touch events to pass through
            ..allowFullscreen = true
            ..onLoad.listen((_) {
              // PDF loaded successfully
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          
          return iframe;
        },
      );
    } catch (e) {
      // View factory might already be registered, that's fine
      setState(() {
        _isLoading = false;
      });
    }
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
    
    // If it's already a full URL (Firebase Storage), return as-is
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
    // Update reading progress in the backend
    final progressPercentage = page / widget.book.totalPages;
    ref.read(userLibraryProvider.notifier).updateReadingProgress(
      bookId: widget.book.id,
      currentPage: page,
      progressPercentage: progressPercentage,
    );
  }
}
