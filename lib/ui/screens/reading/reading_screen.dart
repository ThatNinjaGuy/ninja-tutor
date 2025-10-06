import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/reading/reading_viewer.dart';
import '../../widgets/common/ai_tip_card.dart';

/// Interactive reading screen with contextual AI features
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({
    super.key,
    this.bookId,
  });

  final String? bookId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  bool _showAiPanel = false;
  String? _selectedText;
  bool _isReadingMode = false;

  @override
  Widget build(BuildContext context) {
    final currentBook = ref.watch(currentBookProvider);
    final user = ref.watch(authProvider);

    // Check if user is authenticated
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    // If we have a current book and are in reading mode, show the reading interface directly
    if (currentBook != null && _isReadingMode) {
      return _buildReadingInterface(currentBook);
    }

    // Otherwise, show book selection screen
    final libraryState = ref.watch(unifiedLibraryProvider);
    
    // Handle book loading from URL parameter only when needed
    if (widget.bookId != null && libraryState.myBooks.isNotEmpty) {
      try {
        final book = libraryState.myBooks.firstWhere((b) => b.id == widget.bookId);
        
        // Set the book once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(currentBookProvider.notifier).state = book;
            setState(() {
              _isReadingMode = true;
            });
          }
        });
      } catch (e) {
        // Book not found in user's library
      }
    }

    return _buildSelectBookScreen(context, libraryState);
  }

  Widget _buildReadingInterface(BookModel book) {
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

  Widget _buildSelectBookScreen(BuildContext context, LibraryState libraryState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Book to Read'),
        centerTitle: true,
      ),
      body: libraryState.myBooks.isEmpty
          ? _buildEmptyState(
              icon: Icons.library_books_outlined,
              title: 'No books in your library',
              subtitle: 'Add some books from the Library tab to start reading',
              actionText: 'Go to Library',
              onAction: () => ref.read(navigationProvider.notifier).state = 1,
            )
          : _buildBookList(libraryState.myBooks),
    );
  }

  Widget _buildBookList(List<BookModel> books) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.menu_book,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(book.title),
            subtitle: Text('${book.author} • ${book.subject}'),
            onTap: () {
              ref.read(currentBookProvider.notifier).state = book;
              setState(() {
                _isReadingMode = true;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        centerTitle: true,
      ),
      body: _buildEmptyState(
        icon: Icons.login,
        title: 'Please sign in to access your reading library',
        actionText: 'Sign In',
        onAction: () => ref.read(navigationProvider.notifier).state = 0,
      ),
    );
  }

  /// Reusable empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(icon),
              label: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

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
                      AiTipCard(
                        title: 'Definition',
                        content: 'Getting definition for "$_selectedText"...',
                        icon: Icons.search,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    const AiTipCard(
                      title: 'Study Tip',
                      content: 'This section covers important concepts about cellular biology. Consider taking notes on key terms.',
                      icon: Icons.lightbulb_outline,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const AiTipCard(
                      title: 'Quick Quiz',
                      content: 'Test your understanding of this chapter with a quick quiz.',
                      icon: Icons.quiz,
                      actionText: 'Start Quiz',
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
