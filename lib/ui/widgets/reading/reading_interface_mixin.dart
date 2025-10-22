import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;

import '../../../models/content/book_model.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/reading_ai_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'reading_viewer.dart';
import 'ai_chat_panel.dart';

/// Mixin providing shared reading interface functionality
/// Used by both LibraryScreen and ReadingScreen to avoid code duplication
mixin ReadingInterfaceMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // State variables
  bool _isReadingMode = false;
  bool _showAiPanel = false;
  String? _selectedText;
  int _currentPage = 1;
  
  // Getters that must be overridden
  bool get isReadingMode => _isReadingMode;
  bool get showAiPanel => _showAiPanel;
  String? get selectedText => _selectedText;
  int get currentPage => _currentPage;
  
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
  
  void setCurrentPage(int value) {
    setState(() => _currentPage = value);
  }
  
  /// Build the complete reading interface
  Widget buildReadingInterface(BookModel book) {
    // Show AI dialog when needed
    if (_showAiPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAiDialog(book);
      });
    }
    
    return Scaffold(
      body: _buildResponsiveLayout(book),
    );
  }

  /// Build responsive layout that adapts to screen size
  Widget _buildResponsiveLayout(BookModel book) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > AppConstants.wideScreenBreakpoint;
        
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
                  onPageChanged: (page) => setCurrentPage(page),
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
                onPageChanged: (page) => setCurrentPage(page),
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
      width: AppConstants.readingPanelWidthVertical,
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
      height: AppConstants.readingPanelHeightHorizontal,
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
          borderRadius: BorderRadius.circular(AppConstants.controlButtonBorderRadius),
          onTap: isDisabled ? null : onPressed,
          child: Container(
            width: AppConstants.controlButtonSize,
            height: AppConstants.controlButtonSize,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.controlButtonBorderRadius),
            ),
            child: Icon(
              icon, 
              size: AppConstants.controlButtonIconSize,
              color: isDisabled 
                  ? Colors.grey 
                  : (isCloseButton || isActive ? Colors.white : effectiveColor),
            ),
          ),
        ),
      ),
    );
  }

  /// Show AI chat as a proper Dialog
  void _showAiDialog(BookModel book) {
    // Reset flag immediately to prevent repeated calls
    if (!_showAiPanel) return;
    
    // Disable PDF scrolling when dialog opens
    _setPdfScrollingEnabled(false);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * AppConstants.aiPanelWidthPercentage,
            height: MediaQuery.of(context).size.height,
            child: AiChatPanel(
              bookId: book.id,
              currentPage: _currentPage,
              selectedText: _selectedText,
              onClose: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _showAiPanel = false;
                  _selectedText = null;
                });
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Re-enable PDF scrolling when dialog closes
      _setPdfScrollingEnabled(true);
      
      // Ensure flag is reset when dialog closes
      if (mounted) {
        setState(() {
          _showAiPanel = false;
          _selectedText = null;
        });
      }
    });
    
    // Reset flag after showing dialog
    setState(() {
      _showAiPanel = false;
    });
  }
  
  /// Enable or disable PDF scrolling
  void _setPdfScrollingEnabled(bool enabled) {
    try {
      // Find all iframes (PDF viewers) and control their events
      final iframes = html.document.querySelectorAll('iframe');
      for (var iframe in iframes) {
        if (iframe is html.IFrameElement) {
          // Send message to PDF.js to enable/disable scrolling
          final message = {
            'type': 'setScrollEnabled',
            'enabled': enabled,
          };
          iframe.contentWindow?.postMessage(message, '*');
          
          // Also set CSS pointer events as backup
          iframe.style.pointerEvents = enabled ? 'auto' : 'none';
          
          print('${enabled ? "✅ Enabled" : "🚫 Disabled"} PDF scrolling');
        }
      }
    } catch (e) {
      // Silently fail if we can't control PDF scrolling
      print('Could not control PDF scrolling: $e');
    }
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
    // Placeholder for when AI service is implemented
  }

  void _addBookmark() {
    // TODO: Add bookmark functionality
    // Placeholder for when bookmark service is implemented
  }

  void _toggleHighlight() {
    // TODO: Toggle highlight mode
    // Placeholder for when highlight service is implemented
  }
}

