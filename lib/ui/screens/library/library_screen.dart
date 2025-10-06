import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/library/book_filter.dart';
import '../../widgets/library/library_empty_state.dart';
import '../../widgets/library/add_book_bottom_sheet.dart';
import '../../widgets/library/book_options_sheet.dart';
import '../../widgets/reading/reading_viewer.dart';

/// Clean and simplified library screen for managing books
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubject = 'All';
  String? _selectedGrade = 'All';
  String _searchQuery = '';
  
  // Reading mode state
  bool _isReadingMode = false;
  BookModel? _currentReadingBook;
  bool _showAiPanel = false;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed from 3 to 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final user = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (user == null) return _buildLoginPrompt();

    // If in reading mode, show the reading interface
    if (_isReadingMode && _currentReadingBook != null) {
      return _buildReadingInterface(_currentReadingBook!);
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyBooksGrid(libraryState),
                _buildExploreBooksGrid(libraryState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: LibraryEmptyState(
        icon: Icons.library_books_outlined,
        title: 'Please log in to access your library',
        subtitle: 'Your books and reading progress will be saved across devices',
        onAddBook: () => context.go('/login'),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Library'),
      actions: [
        IconButton(
          onPressed: _showAddBookOptions,
          icon: const Icon(Icons.add),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'My Books'),
          Tab(text: 'Explore Books'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search books...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        ref.read(unifiedLibraryProvider.notifier).clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: _handleSearchChanged,
          ),
          const SizedBox(height: 16),
          // Filters
          BookFilter(
            selectedSubject: _selectedSubject,
            selectedGrade: _selectedGrade,
            onSubjectChanged: _handleSubjectChanged,
            onGradeChanged: _handleGradeChanged,
          ),
        ],
      ),
    );
  }

  /// Build My Books tab - shows only user's personal library with search and filters
  Widget _buildMyBooksGrid(LibraryState libraryState) {
    if (libraryState.isLoadingUserLibrary) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryState.error != null) {
      return _buildErrorState(libraryState.error!);
    }

    if (libraryState.myBooks.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.library_books_outlined,
        title: 'No Books in Your Library',
        subtitle: 'Add books from the Explore tab to start your reading journey!',
        onAddBook: null, // No add button on My Books tab
      );
    }

    // Apply search and filters to user's library books
    final filteredBooks = ref.read(unifiedLibraryProvider.notifier).filterBooks(
      books: libraryState.myBooks,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      subject: _selectedSubject,
      grade: _selectedGrade,
    );

    if (filteredBooks.isEmpty) {
      return LibraryEmptyState(
        icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list_off,
        title: _searchQuery.isNotEmpty ? 'No Books Found' : 'No Books Match Filters',
        subtitle: _searchQuery.isNotEmpty 
            ? 'Try a different search term in your library'
            : 'Try adjusting your filters to see more books',
        onAddBook: null,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _getMaxCardWidth(context),
        childAspectRatio: _getChildAspectRatio(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
            
        return BookCard(
          book: book,
          layout: BookCardLayout.grid,
          showAddToLibrary: true,
          isInLibrary: true, // Always true in My Books tab
          onTap: () => _openBook(book),
          onLongPress: () => _showBookOptions(book),
          onRemoveFromLibrary: () => _removeBookFromLibrary(book.id),
        );
      },
    );
  }

  /// Build Explore Books tab - shows all available books with add functionality
  Widget _buildExploreBooksGrid(LibraryState libraryState) {
    if (libraryState.isLoadingAllBooks || libraryState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryState.error != null) {
      return _buildErrorState(libraryState.error!);
    }

    final booksToShow = libraryState.exploreBooks;

    if (booksToShow.isEmpty) {
      return LibraryEmptyState(
        icon: Icons.explore_outlined,
        title: _searchQuery.isEmpty ? 'No Books Available' : 'No books found',
        subtitle: _searchQuery.isEmpty 
            ? 'Check back later for new books!'
            : 'Try adjusting your search or filters',
        onAddBook: null,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _getMaxCardWidth(context),
        childAspectRatio: _getChildAspectRatio(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: booksToShow.length,
      itemBuilder: (context, index) {
        final book = booksToShow[index];
        final isInLibrary = libraryState.isBookInLibrary(book.id);
        
        return BookCard(
          book: book,
          layout: BookCardLayout.grid,
          showAddToLibrary: true,
          isInLibrary: isInLibrary,
          onTap: () => _openBook(book),
          onLongPress: () => _showBookOptions(book),
          onAddToLibrary: () => _addBookToLibrary(book.id),
          onRemoveFromLibrary: () => _removeBookFromLibrary(book.id),
        );
      },
    );
  }




  Widget _buildErrorState(String error) {
    return LibraryEmptyState(
      icon: Icons.error_outline,
      title: 'Error loading books',
      subtitle: error,
      onAddBook: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
    );
  }

  // Event handlers
  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.isNotEmpty) {
      ref.read(unifiedLibraryProvider.notifier).searchBooks(value);
    } else {
      ref.read(unifiedLibraryProvider.notifier).clearSearch();
    }
  }

  void _handleSubjectChanged(String? subject) {
    setState(() => _selectedSubject = subject);
    _reloadBooksWithFilters();
  }

  void _handleGradeChanged(String? grade) {
    setState(() => _selectedGrade = grade);
    _reloadBooksWithFilters();
  }

  void _reloadBooksWithFilters() {
    ref.read(unifiedLibraryProvider.notifier).refreshWithFilters(
      subject: _selectedSubject == 'All' ? null : _selectedSubject,
      grade: _selectedGrade == 'All' ? null : _selectedGrade,
    );
  }

  void _showAddBookOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const AddBookBottomSheet(),
    );
  }

  void _openBook(BookModel book) {
    setState(() {
      _currentReadingBook = book;
      _isReadingMode = true;
    });
    ref.read(currentBookProvider.notifier).state = book;
  }

  void _showBookOptions(BookModel book) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookOptionsSheet(book: book),
    );
  }

  /// Add book to user's personal library
  Future<void> _addBookToLibrary(String bookId) async {
    final success = await ref.read(unifiedLibraryProvider.notifier).addBookToLibrary(bookId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Book added to your library!' : 'Failed to add book'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Remove book from user's personal library
  Future<void> _removeBookFromLibrary(String bookId) async {
    final success = await ref.read(unifiedLibraryProvider.notifier).removeBookFromLibrary(bookId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Book removed from your library!' : 'Failed to remove book'),
          backgroundColor: success ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Reading interface - same as reading screen
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

  // AI Panel (simplified version)
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

  // Utility methods for responsive card sizing
  double _getMaxCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Set reasonable card width limits based on screen size (increased for better content fit)
    if (screenWidth >= AppConstants.desktopBreakpoint) {
      // Desktop: cards should be between 220-320px wide (increased)
      return 320.0;
    } else if (screenWidth >= AppConstants.tabletBreakpoint) {
      // Tablet: cards should be between 200-280px wide (increased)
      return 280.0;
    } else {
      // Mobile: cards should be between 180-240px wide (increased)
      return 240.0;
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust aspect ratio based on screen size for better proportions (increased height to prevent overflow)
    if (screenWidth >= AppConstants.desktopBreakpoint) {
      // Desktop: wider cards with more height to prevent overflow
      return 0.9;
    } else if (screenWidth >= AppConstants.tabletBreakpoint) {
      // Tablet: balanced proportions with more height
      return 0.85;
    } else {
      // Mobile: taller cards for better text readability and no overflow
      return 0.8;
    }
  }


}
