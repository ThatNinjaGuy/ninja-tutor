import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:async';

import '../../../models/content/book_model.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/reading_ai_provider.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/notes_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'reading_viewer.dart';
import 'ai_chat_panel.dart';
import 'bookmark_panel.dart';
import 'notes_panel.dart';
import 'notes_tooltip.dart';
import 'note_creation_dialog.dart';

/// Mixin providing shared reading interface functionality
/// Used by both LibraryScreen and ReadingScreen to avoid code duplication
mixin ReadingInterfaceMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // State variables
  bool _isReadingMode = false;
  bool _showAiPanel = false;
  String? _selectedText;
  int _currentPage = 1;
  
  // Bookmark and notes tooltip state
  bool _showBookmarkPanel = false;
  bool _showNotesPanel = false;
  bool _showNotesTooltip = false;
  String? _currentBookId;
  Timer? _hideNotesTimer;
  
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
    setState(() {
      _currentPage = value;
      // Close panels when page changes
      if (_showBookmarkPanel || _showNotesPanel || _showNotesTooltip) {
        _showBookmarkPanel = false;
        _showNotesPanel = false;
        _showNotesTooltip = false;
      }
    });
  }
  
  /// Build the complete reading interface
  Widget buildReadingInterface(BookModel book) {
    // Load bookmarks and notes when book changes (only once)
    if (_currentBookId != book.id) {
      _currentBookId = book.id;
      // Reset current page when switching books
      _currentPage = book.progress?.currentPage ?? 1;
      // Use microtask to ensure it runs only once per build cycle
      Future.microtask(() {
        if (mounted && _currentBookId == book.id) {
          ref.read(bookmarkProvider.notifier).loadBookmarks(book.id);
          ref.read(notesProvider.notifier).loadNotes(book.id);
        }
      });
    }
    
    // Show AI dialog when needed
    if (_showAiPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAiDialog(book);
      });
    }
    
    // Show bookmark panel as dialog when flag is set
    if (_showBookmarkPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBookmarkDialog(book);
      });
    }
    
    // Show notes panel as dialog when flag is set
    if (_showNotesPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotesDialog(book);
      });
    }
    
    
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey.keyLabel == 'Escape') {
          if (_showBookmarkPanel || _showNotesPanel || _showNotesTooltip) {
            print('🔴 Escape key pressed - closing panels');
            setState(() {
              _showBookmarkPanel = false;
              _showNotesPanel = false;
              _showNotesTooltip = false;
            });
          }
        }
      },
      child: GestureDetector(
        onTap: () {
        // Close panels when tapping outside
        if (_showBookmarkPanel || _showNotesPanel || _showNotesTooltip) {
          print('🔴 Tap outside panels - closing all');
          setState(() {
            _showBookmarkPanel = false;
            _showNotesPanel = false;
            _showNotesTooltip = false;
          });
        }
        },
        child: Scaffold(
          body: _buildResponsiveLayout(book),
        ),
      ),
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
    final bookmarkState = ref.watch(bookmarkProvider);
    final notesState = ref.watch(notesProvider);
    
    final isBookmarked = bookmarkState.isPageBookmarked(_currentPage);
    final notesCount = notesState.getNotesCountForPage(_currentPage);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
              _buildBookmarkButton(book, isInLibrary, isBookmarked),
              const SizedBox(height: 16),
              _buildNotesButton(book, isInLibrary, notesCount),
              const SizedBox(height: 16),
              _buildCompactControlButton(
                icon: Icons.highlight,
                tooltip: isInLibrary ? 'Highlight' : 'Highlight (Add to library first)',
                isDisabled: !isInLibrary,
                onPressed: isInLibrary ? _toggleHighlight : null,
              ),
            ],
          ),
        ),
        if (_showNotesTooltip && isInLibrary)
          Positioned(
            right: AppConstants.readingPanelWidthVertical + 10,
            top: 180,
            child: MouseRegion(
              onEnter: (_) {
                print('🟢 Mouse entered notes tooltip');
                _hideNotesTimer?.cancel();
              },
              onExit: (_) {
                print('🔴 Mouse left notes tooltip - auto-hiding in 2s');
                _hideNotesTimer = Timer(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() => _showNotesTooltip = false);
                  }
                });
              },
              child: NotesTooltip(
                currentPageNotes: notesState.getNotesForPage(_currentPage),
                allBookNotes: notesState.allNotes,
                currentPage: _currentPage,
                onNoteDelete: (note) {
                  print('🗑️ Delete note: ${note.id}');
                  _deleteNote(book.id, note);
                },
                onClose: () {
                  print('🔴 Close notes tooltip');
                  setState(() => _showNotesTooltip = false);
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Horizontal helper panel for narrow screens (bottom)
  Widget _buildHorizontalHelperPanel(BookModel book) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isInLibrary = libraryState.isBookInLibrary(book.id);
    final bookmarkState = ref.watch(bookmarkProvider);
    final notesState = ref.watch(notesProvider);
    
    final isBookmarked = bookmarkState.isPageBookmarked(_currentPage);
    final notesCount = notesState.getNotesCountForPage(_currentPage);
    
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
              _buildBookmarkButton(book, isInLibrary, isBookmarked),
              _buildNotesButton(book, isInLibrary, notesCount),
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

  /// Build bookmark button with panel
  Widget _buildBookmarkButton(BookModel book, bool isInLibrary, bool isBookmarked) {
    return _buildCompactControlButton(
      icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
      tooltip: isInLibrary 
          ? 'Bookmarks'
          : 'Bookmark (Add to library first)',
      isActive: isBookmarked,
      isDisabled: !isInLibrary,
      onPressed: isInLibrary ? () {
        setState(() {
          _showBookmarkPanel = !_showBookmarkPanel;
        });
      } : null,
    );
  }
  
  /// Build notes button with count badge and tooltip
  Widget _buildNotesButton(BookModel book, bool isInLibrary, int notesCount) {
    final theme = Theme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCompactControlButton(
          icon: Icons.sticky_note_2_outlined,
          tooltip: isInLibrary ? 'Notes' : 'Notes (Add to library first)',
          isActive: _showNotesPanel,
          isDisabled: !isInLibrary,
          onPressed: isInLibrary ? () {
            setState(() {
              _showNotesPanel = !_showNotesPanel;
            });
          } : null,
        ),
        if (notesCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  '$notesCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Show AI chat as a proper Dialog
  void _showAiDialog(BookModel book) {
    // Reset flag immediately to prevent repeated calls
    if (!_showAiPanel) return;
    
    // Disable PDF pointer events when dialog opens
    _disablePdfPointerEvents();
    
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
      // Re-enable PDF pointer events when dialog closes
      _enablePdfPointerEvents();
      
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
  
  /// Show bookmark panel as a proper Dialog
  void _showBookmarkDialog(BookModel book) {
    // Reset flag immediately to prevent repeated calls
    if (!_showBookmarkPanel) return;
    
    // Disable PDF pointer events when dialog opens
    _disablePdfPointerEvents();
    
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
            child: BookmarkPanel(
              key: ValueKey('bookmark_${book.id}'),
              bookId: book.id,
              currentPage: _currentPage,
              onClose: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _showBookmarkPanel = false;
                });
              },
              onPageNavigate: (page) {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _showBookmarkPanel = false;
                });
                setCurrentPage(page);
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Re-enable PDF pointer events when dialog closes
      _enablePdfPointerEvents();
      
      // Ensure flag is reset when dialog closes
      if (mounted) {
        setState(() {
          _showBookmarkPanel = false;
        });
      }
    });
    
    // Reset flag after showing dialog
    setState(() {
      _showBookmarkPanel = false;
    });
  }
  
  /// Show notes panel as a proper Dialog
  void _showNotesDialog(BookModel book) {
    // Reset flag immediately to prevent repeated calls
    if (!_showNotesPanel) return;
    
    // Disable PDF pointer events when dialog opens
    _disablePdfPointerEvents();
    
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
            child: NotesPanel(
              key: ValueKey('notes_${book.id}'),
              bookId: book.id,
              getCurrentPage: () => _currentPage,  // Pass callback to get current page dynamically
              onClose: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _showNotesPanel = false;
                });
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Re-enable PDF pointer events when dialog closes
      _enablePdfPointerEvents();
      
      // Ensure flag is reset when dialog closes
      if (mounted) {
        setState(() {
          _showNotesPanel = false;
        });
      }
    });
    
    // Reset flag after showing dialog
    setState(() {
      _showNotesPanel = false;
    });
  }
  
  /// Disable PDF iframe pointer events
  void _disablePdfPointerEvents() {
    try {
      final iframes = html.document.querySelectorAll('iframe');
      for (var iframe in iframes) {
        if (iframe is html.IFrameElement) {
          iframe.style.pointerEvents = 'none';
          print('🚫 Disabled PDF pointer events');
        }
      }
    } catch (e) {
      print('Could not disable PDF pointer events: $e');
    }
  }
  
  /// Enable PDF iframe pointer events
  void _enablePdfPointerEvents() {
    try {
      final iframes = html.document.querySelectorAll('iframe');
      for (var iframe in iframes) {
        if (iframe is html.IFrameElement) {
          iframe.style.pointerEvents = 'auto';
          print('✅ Enabled PDF pointer events');
        }
      }
    } catch (e) {
      print('Could not enable PDF pointer events: $e');
    }
  }
  
  /// Enable or disable PDF scrolling
  
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

  
  /// Show note creation dialog
  Future<void> _showNoteCreationDialog(String bookId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NoteCreationDialog(
        pageNumber: _currentPage,
        onSave: (content, title) async {
          final note = await ref.read(notesProvider.notifier).createNote(
            bookId: bookId,
            pageNumber: _currentPage,
            content: content,
            title: title,
          );
          
          if (note != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Note added to page $_currentPage'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
  
  /// Delete a note
  Future<void> _deleteNote(String bookId, dynamic note) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await ref.read(notesProvider.notifier).deleteNote(
        bookId: bookId,
        noteId: note.id,
        pageNumber: note.pageNumber,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  

  void _toggleHighlight() {
    // TODO: Toggle highlight mode
    // Placeholder for when highlight service is implemented
  }
  
  @override
  void dispose() {
    _hideNotesTimer?.cancel();
    super.dispose();
  }
}

