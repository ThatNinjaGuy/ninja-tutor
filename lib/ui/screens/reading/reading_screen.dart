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
          // Main content in column layout
          Column(
            children: [
              // PDF viewer takes most of the space
              Expanded(
                child: ReadingViewer(
                  book: book,
                  onTextSelected: _handleTextSelection,
                  onDefinitionRequest: _handleDefinitionRequest,
                ),
              ),
              
              // Controls below the PDF
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildReadingControls(book),
              ),
            ],
          ),
          
          // AI contextual panel overlay
          if (_showAiPanel)
            _buildAiPanel(context),
        ],
      ),
    );
  }

  Widget _buildSelectBookScreen(BuildContext context, LibraryState libraryState) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Book to Read'),
        centerTitle: true,
      ),
      body: libraryState.myBooks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books in your library',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some books from the Library tab to start reading',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to library tab
                      ref.read(navigationProvider.notifier).state = 1; // Library tab index
                    },
                    icon: const Icon(Icons.library_books),
                    label: const Text('Go to Library'),
                  ),
                ],
              ),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to access your reading library',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to login screen
                ref.read(navigationProvider.notifier).state = 0; // Dashboard tab
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
            ),
          ],
        ),
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


  Widget _buildReadingControls(BookModel book) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
            // Close button - first in the menu
            _buildControlButton(
              icon: Icons.close,
              label: 'Close',
              isCloseButton: true,
              onPressed: () {
                setState(() {
                  _isReadingMode = false;
                });
              },
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.psychology,
              label: 'AI Tips',
              isActive: _showAiPanel,
              onPressed: () {
                setState(() {
                  _showAiPanel = !_showAiPanel;
                });
              },
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.quiz,
              label: 'Quiz',
              onPressed: () {
                _startQuiz();
              },
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.bookmark_add,
              label: 'Bookmark',
              onPressed: () {
                _addBookmark();
              },
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.highlight,
              label: 'Highlight',
              onPressed: () {
                _toggleHighlight();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isCloseButton = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCloseButton
                    ? Colors.red.withOpacity(0.9)
                    : isActive 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon, 
                size: 22,
                color: isCloseButton
                    ? Colors.white
                    : isActive 
                        ? Colors.white 
                        : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isCloseButton ? Colors.red : null,
          ),
        ),
      ],
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
