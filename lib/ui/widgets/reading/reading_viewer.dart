import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;

import '../../../models/content/book_model.dart';
import '../../../core/providers/user_library_provider.dart';
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
          _showHint = false; // Hide hint when user taps
        });
      },
      child: Container(
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
          
          // PDF controls overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.book.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _openPdfInNewTab(),
                        icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                        tooltip: 'Open in new tab',
                      ),
                      IconButton(
                        onPressed: () => _downloadPdf(),
                        icon: const Icon(Icons.download, color: Colors.white, size: 20),
                        tooltip: 'Download PDF',
                      ),
                    ],
                  ),
                ],
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
    // For web platform, we'll show options to open the PDF externally
    // This avoids complex iframe embedding issues and provides a better user experience
    if (widget.book.fileUrl != null && widget.book.fileUrl!.isNotEmpty) {
      return _buildPdfViewerInterface();
    } else {
      // Fallback content when no PDF URL is available
      return _buildFallbackContent();
    }
  }

  Widget _buildPdfViewerInterface() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            widget.book.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'by ${widget.book.author}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'PDF Ready to Read',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Click below to open the PDF in a new tab for the best reading experience with full browser PDF features.',
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openPdfInNewTab(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _downloadPdf(),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This will open the PDF in your browser\'s built-in PDF viewer with features like zoom, search, and bookmarks.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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


  void _openPdfInNewTab() {
    if (widget.book.fileUrl != null && widget.book.fileUrl!.isNotEmpty) {
      html.window.open(widget.book.fileUrl!, '_blank');
    }
  }

  void _downloadPdf() {
    if (widget.book.fileUrl != null && widget.book.fileUrl!.isNotEmpty) {
      html.AnchorElement(href: widget.book.fileUrl!)
        ..download = '${widget.book.title}.pdf'
        ..click();
    }
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
