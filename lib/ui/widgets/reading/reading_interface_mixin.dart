import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/content/book_model.dart';
import '../../../core/providers/unified_library_provider.dart';
import 'reading_viewer.dart';

/// Mixin providing shared reading interface functionality
/// Used by both LibraryScreen and ReadingScreen to avoid code duplication
mixin ReadingInterfaceMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // State variables
  bool _isReadingMode = false;
  bool _showAiPanel = false;
  String? _selectedText;
  
  // Getters that must be overridden
  bool get isReadingMode => _isReadingMode;
  bool get showAiPanel => _showAiPanel;
  String? get selectedText => _selectedText;
  
  // Setters for state management
  void setReadingMode(bool value) {
    setState(() => _isReadingMode = value);
  }
  
  void setShowAiPanel(bool value) {
    setState(() => _showAiPanel = value);
  }
  
  void setSelectedText(String? value) {
    setState(() => _selectedText = value);
  }
  
  /// Build the complete reading interface
  Widget buildReadingInterface(BookModel book) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with responsive layout
          _buildResponsiveLayout(book),
          
          // AI contextual panel overlay
          if (_showAiPanel)
            _buildAiPanel(context),
        ],
      ),
    );
  }

  /// Build responsive layout that adapts to screen size
  Widget _buildResponsiveLayout(BookModel book) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800; // Desktop/tablet landscape
        
        if (isWideScreen) {
          // Wide screen: helper panel on the right side
          return Row(
            children: [
              // PDF viewer takes most space
              Expanded(
                child: ReadingViewer(
                  book: book,
                  onTextSelected: _handleTextSelection,
                  onDefinitionRequest: _handleDefinitionRequest,
                ),
              ),
              // Vertical helper panel on the right
              _buildVerticalHelperPanel(book),
            ],
          );
        } else {
          // Narrow screen: helper panel at the bottom
          return Column(
            children: [
              // PDF viewer takes most of the space
              Expanded(
                child: ReadingViewer(
                  book: book,
                  onTextSelected: _handleTextSelection,
                  onDefinitionRequest: _handleDefinitionRequest,
                ),
              ),
              // Horizontal helper panel at the bottom
              _buildHorizontalHelperPanel(book),
            ],
          );
        }
      },
    );
  }

  /// Vertical helper panel for wide screens (right side)
  Widget _buildVerticalHelperPanel(BookModel book) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isInLibrary = libraryState.isBookInLibrary(book.id);
    
    return Container(
      width: 60, // Thin vertical panel
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCompactControlButton(
            icon: Icons.close,
            tooltip: 'Close',
            isCloseButton: true,
            onPressed: () => setState(() => _isReadingMode = false),
          ),
          const SizedBox(height: 16),
          _buildCompactControlButton(
            icon: Icons.psychology,
            tooltip: isInLibrary ? 'AI Tips' : 'AI Tips (Add to library first)',
            isActive: _showAiPanel,
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? () => setState(() => _showAiPanel = !_showAiPanel) : null,
          ),
          const SizedBox(height: 16),
          _buildCompactControlButton(
            icon: Icons.quiz,
            tooltip: 'Quiz',
            onPressed: _startQuiz,
          ),
          const SizedBox(height: 16),
          _buildCompactControlButton(
            icon: Icons.bookmark_add,
            tooltip: isInLibrary ? 'Bookmark' : 'Bookmark (Add to library first)',
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? _addBookmark : null,
          ),
          const SizedBox(height: 16),
          _buildCompactControlButton(
            icon: Icons.highlight,
            tooltip: isInLibrary ? 'Highlight' : 'Highlight (Add to library first)',
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? _toggleHighlight : null,
          ),
        ],
      ),
    );
  }

  /// Horizontal helper panel for narrow screens (bottom)
  Widget _buildHorizontalHelperPanel(BookModel book) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isInLibrary = libraryState.isBookInLibrary(book.id);
    
    return Container(
      height: 60, // Thin horizontal panel
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactControlButton(
            icon: Icons.close,
            tooltip: 'Close',
            isCloseButton: true,
            onPressed: () => setState(() => _isReadingMode = false),
          ),
          _buildCompactControlButton(
            icon: Icons.psychology,
            tooltip: isInLibrary ? 'AI Tips' : 'AI Tips (Add to library first)',
            isActive: _showAiPanel,
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? () => setState(() => _showAiPanel = !_showAiPanel) : null,
          ),
          _buildCompactControlButton(
            icon: Icons.quiz,
            tooltip: 'Quiz',
            onPressed: _startQuiz,
          ),
          _buildCompactControlButton(
            icon: Icons.bookmark_add,
            tooltip: isInLibrary ? 'Bookmark' : 'Bookmark (Add to library first)',
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? _addBookmark : null,
          ),
          _buildCompactControlButton(
            icon: Icons.highlight,
            tooltip: isInLibrary ? 'Highlight' : 'Highlight (Add to library first)',
            isDisabled: !isInLibrary,
            onPressed: isInLibrary ? _toggleHighlight : null,
          ),
        ],
      ),
    );
  }

  /// Compact control button with only icons (no labels)
  Widget _buildCompactControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    bool isCloseButton = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final color = isCloseButton ? Colors.red : theme.colorScheme.primary;
    final backgroundColor = isCloseButton 
        ? Colors.red.withOpacity(0.9)
        : isActive ? color : color.withOpacity(0.1);
    
    final effectiveColor = isDisabled ? Colors.grey : color;
    final effectiveBackgroundColor = isDisabled 
        ? Colors.grey.withOpacity(0.1)
        : backgroundColor;
    
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDisabled ? null : onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon, 
              size: 20,
              color: isDisabled 
                  ? Colors.grey 
                  : (isCloseButton || isActive ? Colors.white : effectiveColor),
            ),
          ),
        ),
      ),
    );
  }

  /// AI Panel overlay
  Widget _buildAiPanel(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Panel header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Assistant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _showAiPanel = false;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // AI content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_selectedText != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Definition for "$_selectedText"',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI features coming soon!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reading event handlers
  void _handleTextSelection(String text, Offset position) {
    setState(() {
      _selectedText = text;
      _showAiPanel = true;
    });
  }

  void _handleDefinitionRequest(String word) {
    // TODO: Implement AI definition request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Definition requested for: $word')),
    );
  }

  void _startQuiz() {
    // TODO: Navigate to quiz based on current reading position
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting quiz for current content')),
    );
  }

  void _addBookmark() {
    // TODO: Add bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }

  void _toggleHighlight() {
    // TODO: Toggle highlight mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Highlight mode toggled')),
    );
  }
}

