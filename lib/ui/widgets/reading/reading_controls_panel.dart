import 'package:flutter/material.dart';

import '../../../models/content/book_model.dart';

/// Reading controls panel with Adobe Reader-like features
class ReadingControlsPanel extends StatefulWidget {
  const ReadingControlsPanel({
    super.key,
    required this.book,
    required this.currentPage,
    required this.totalPages,
    required this.zoomLevel,
    required this.onPageChanged,
    required this.onZoomChanged,
    required this.onClose,
  });

  final BookModel book;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onClose;

  @override
  State<ReadingControlsPanel> createState() => _ReadingControlsPanelState();
}

class _ReadingControlsPanelState extends State<ReadingControlsPanel> {
  late TextEditingController _pageController;
  late TextEditingController _searchController;
  bool _showSearch = false;
  bool _showBookmarks = false;
  bool _showTableOfContents = false;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(text: '${widget.currentPage + 1}');
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(ReadingControlsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _pageController.text = '${widget.currentPage + 1}';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Column(
          children: [
            // Top controls bar
            _buildTopControls(theme),
            
            // Main controls area
            Expanded(
              child: _showSearch
                  ? _buildSearchPanel(theme)
                  : _showBookmarks
                      ? _buildBookmarksPanel(theme)
                      : _showTableOfContents
                          ? _buildTableOfContentsPanel(theme)
                          : _buildMainControls(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            color: theme.colorScheme.onSurface,
          ),
          
          // Book title
          Expanded(
            child: Text(
              widget.book.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Control buttons
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                _showBookmarks = false;
                _showTableOfContents = false;
              });
            },
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            color: _showSearch ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showBookmarks = !_showBookmarks;
                _showSearch = false;
                _showTableOfContents = false;
              });
            },
            icon: Icon(_showBookmarks ? Icons.close : Icons.bookmark),
            color: _showBookmarks ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showTableOfContents = !_showTableOfContents;
                _showSearch = false;
                _showBookmarks = false;
              });
            },
            icon: Icon(_showTableOfContents ? Icons.close : Icons.list),
            color: _showTableOfContents ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page navigation
          _buildPageNavigation(theme),
          
          const SizedBox(height: 24),
          
          // Zoom controls
          _buildZoomControls(theme),
          
          const SizedBox(height: 24),
          
          // Reading features
          _buildReadingFeatures(theme),
        ],
      ),
    );
  }

  Widget _buildPageNavigation(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Page Navigation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Page info
        Text(
          'Page ${widget.currentPage + 1} of ${widget.totalPages}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              icon: Icons.first_page,
              label: 'First',
              onPressed: widget.currentPage > 0 ? () => widget.onPageChanged(0) : null,
            ),
            _buildNavButton(
              icon: Icons.navigate_before,
              label: 'Previous',
              onPressed: widget.currentPage > 0 ? () => widget.onPageChanged(widget.currentPage - 1) : null,
            ),
            _buildNavButton(
              icon: Icons.navigate_next,
              label: 'Next',
              onPressed: widget.currentPage < widget.totalPages - 1 ? () => widget.onPageChanged(widget.currentPage + 1) : null,
            ),
            _buildNavButton(
              icon: Icons.last_page,
              label: 'Last',
              onPressed: widget.currentPage < widget.totalPages - 1 ? () => widget.onPageChanged(widget.totalPages - 1) : null,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Page input
        Row(
          children: [
            Text(
              'Go to page:',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Page',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                onSubmitted: (value) {
                  final page = int.tryParse(value);
                  if (page != null && page >= 1 && page <= widget.totalPages) {
                    widget.onPageChanged(page - 1);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(_pageController.text);
                if (page != null && page >= 1 && page <= widget.totalPages) {
                  widget.onPageChanged(page - 1);
                }
              },
              child: const Text('Go'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Zoom Controls',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              icon: Icons.zoom_out,
              label: 'Zoom Out',
              onPressed: widget.zoomLevel > 0.5 ? () => widget.onZoomChanged(widget.zoomLevel - 0.25) : null,
            ),
            Text(
              '${(widget.zoomLevel * 100).toInt()}%',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildNavButton(
              icon: Icons.zoom_in,
              label: 'Zoom In',
              onPressed: widget.zoomLevel < 3.0 ? () => widget.onZoomChanged(widget.zoomLevel + 0.25) : null,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Zoom slider
        Slider(
          value: widget.zoomLevel,
          min: 0.5,
          max: 3.0,
          divisions: 10,
          activeColor: theme.colorScheme.primary,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (value) {
            widget.onZoomChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildReadingFeatures(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Reading Features',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureButton(
              icon: Icons.bookmark_add,
              label: 'Add Bookmark',
              onPressed: () {
                // TODO: Implement bookmark functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added!')),
                );
              },
            ),
            _buildFeatureButton(
              icon: Icons.highlight,
              label: 'Highlight',
              onPressed: () {
                // TODO: Implement highlight functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Highlight mode activated!')),
                );
              },
            ),
            _buildFeatureButton(
              icon: Icons.note_add,
              label: 'Add Note',
              onPressed: () {
                // TODO: Implement note functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note added!')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Search in Document',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for text...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                // TODO: Implement search functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: $value')),
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                // TODO: Implement search functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: ${_searchController.text}')),
                );
              }
            },
            icon: const Icon(Icons.search),
            label: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Bookmarks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder for bookmarks
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add bookmarks while reading to quickly navigate to important sections',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContentsPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Table of Contents',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder for table of contents
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Table of contents not available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This feature will be available when the PDF is processed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: onPressed != null ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            foregroundColor: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
