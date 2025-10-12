import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/common/responsive_grid_helpers.dart';
import '../../widgets/library/book_filter.dart';
import '../../widgets/library/library_empty_state.dart';
import '../../widgets/library/add_book_bottom_sheet.dart';
import '../../widgets/library/book_options_sheet.dart';
import '../../widgets/reading/reading_interface_mixin.dart';

/// Clean and simplified library screen for managing books
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> 
    with TickerProviderStateMixin, ReadingInterfaceMixin {
  late TabController _tabController;
  String? _selectedSubject = 'All';
  String? _selectedGrade = 'All';
  String _searchQuery = '';
  
  // Current book being read
  BookModel? _currentReadingBook;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    // If in reading mode, show the reading interface from mixin
    if (isReadingMode && _currentReadingBook != null) {
      return buildReadingInterface(_currentReadingBook!);
    }

    // Show initial loading state while both tabs are loading
    final isInitialLoading = libraryState.isLoadingAllBooks && 
                             libraryState.isLoadingUserLibrary &&
                             libraryState.allBooks.isEmpty &&
                             libraryState.myBooks.isEmpty;

    if (isInitialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your library...'),
            ],
          ),
        ),
      );
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your books...'),
          ],
        ),
      );
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

    return RefreshIndicator(
      onRefresh: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: ResponsiveGridHelpers.createResponsiveGridDelegate(context),
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
      ),
    );
  }

  /// Build Explore Books tab - shows all available books with add functionality
  Widget _buildExploreBooksGrid(LibraryState libraryState) {
    if (libraryState.isLoadingAllBooks || libraryState.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(libraryState.isSearching ? 'Searching books...' : 'Loading books...'),
          ],
        ),
      );
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

    return RefreshIndicator(
      onRefresh: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: ResponsiveGridHelpers.createResponsiveGridDelegate(context),
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
      ),
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
    });
    setReadingMode(true);
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

}
