import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/user_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/reading/reading_viewer.dart';
import '../../widgets/reading/reading_controls.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentBook = ref.watch(currentBookProvider);
    final userLibraryBooks = ref.watch(userLibraryBooksProvider);
    final user = ref.watch(authProvider);

    // Check if user is authenticated
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    if (widget.bookId != null) {
      // Load specific book from user's library
      BookModel? book;
      if (userLibraryBooks.value != null) {
        try {
          final libraryData = userLibraryBooks.value!;
          final bookData = libraryData.firstWhere((data) => data['book']['id'] == widget.bookId);
          book = BookModel.fromJson(bookData['book']);
        } catch (e) {
          // Book not found in user's library
          book = null;
        }
      }
      
      if (book != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(currentBookProvider.notifier).state = book;
        });
      }
    }

    if (currentBook == null) {
      return _buildSelectBookScreen(context, userLibraryBooks);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main reading interface
          SafeArea(
            child: Column(
              children: [
                // Reading header
                _buildReadingHeader(context, currentBook),
                
                // Content viewer
                Expanded(
                  child: ReadingViewer(
                    book: currentBook,
                    onTextSelected: _handleTextSelection,
                    onDefinitionRequest: _handleDefinitionRequest,
                  ),
                ),
                
                // Reading controls
                ReadingControls(
                  book: currentBook,
                  onAiTipToggle: () => setState(() {
                    _showAiPanel = !_showAiPanel;
                  }),
                  onQuizStart: _startQuiz,
                ),
              ],
            ),
          ),
          
          // AI contextual panel
          if (_showAiPanel)
            _buildAiPanel(context),
        ],
      ),
    );
  }

  Widget _buildSelectBookScreen(BuildContext context, AsyncValue<List<Map<String, dynamic>>> userLibraryBooks) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Book to Read'),
        centerTitle: true,
      ),
      body: userLibraryBooks.when(
        data: (libraryData) {
          if (libraryData.isEmpty) {
            return Center(
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
            );
          }

          // Convert library data to BookModel objects
          final books = libraryData.map((data) {
            final bookData = data['book'] as Map<String, dynamic>;
            return BookModel.fromJson(bookData);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final progress = libraryData[index]['progress'] as Map<String, dynamic>?;
              final progressPercentage = progress?['progress_percentage'] ?? 0.0;
              
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
                  trailing: Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    ref.read(currentBookProvider.notifier).state = book;
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                'Error loading your library',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildReadingHeader(BuildContext context, book) {
    final theme = Theme.of(context);
    final progress = book.progress;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                onPressed: () {
                  ref.read(currentBookProvider.notifier).state = null;
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: book.progressPercentage,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              Text(
                '${progress?.currentPage ?? 1}/${book.totalPages}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
}
