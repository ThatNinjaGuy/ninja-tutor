import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/books_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/library/book_filter.dart';
import '../../widgets/library/library_empty_state.dart';
import '../../widgets/library/add_book_bottom_sheet.dart';
import '../../widgets/library/book_options_sheet.dart';

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
    final books = ref.watch(booksApiProvider);
    final searchResults = ref.watch(bookSearchProvider);
    final user = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (user == null) return _buildLoginPrompt();

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksGrid(_searchQuery.isNotEmpty ? searchResults : books),
                _buildSubjectsView(_searchQuery.isNotEmpty ? searchResults : books),
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
          Tab(text: 'Subjects'),
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
                        ref.read(bookSearchProvider.notifier).clearSearch();
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

  Widget _buildBooksGrid(AsyncValue<List<BookModel>> booksAsync) {
    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return LibraryEmptyState(
            icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.library_books_outlined,
            title: _searchQuery.isNotEmpty ? 'No Books Found' : 'No Books in Library',
            subtitle: _searchQuery.isNotEmpty 
                ? 'Try a different search term' 
                : 'Add your first book to get started!',
            onAddBook: _searchQuery.isEmpty ? _showAddBookOptions : null,
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
          itemCount: books.length,
          itemBuilder: (context, index) => BookCard(
            book: books[index],
            layout: BookCardLayout.grid,
            onTap: () => _openBook(books[index]),
            onLongPress: () => _showBookOptions(books[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSubjectsView(AsyncValue<List<BookModel>> booksAsync) {
    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return LibraryEmptyState(
            icon: Icons.category_outlined,
            title: 'No Subjects Available',
            subtitle: 'Add books to see them organized by subject',
            onAddBook: _showAddBookOptions,
          );
        }

        final subjectMap = <String, List<BookModel>>{};
        for (final book in books) {
          subjectMap.putIfAbsent(book.subject, () => []).add(book);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: subjectMap.length,
          itemBuilder: (context, index) {
            final subject = subjectMap.keys.elementAt(index);
            final subjectBooks = subjectMap[subject]!;

            return _buildSubjectCard(subject, subjectBooks);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }


  Widget _buildSubjectCard(String subject, List<BookModel> books) {
            return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getSubjectColor(subject).withOpacity(0.1),
          child: Icon(_getSubjectIcon(subject), color: _getSubjectColor(subject)),
        ),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${books.length} books'),
                  children: [
          SizedBox(
            height: 280, // Further increased height to prevent overflow with larger cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) => Container(
                width: _getSubjectCardWidth(context), // Responsive width
                margin: const EdgeInsets.only(right: 16),
                child: BookCard(
                  book: books[index],
                  layout: BookCardLayout.grid,
                  onTap: () => _openBook(books[index]),
                  onLongPress: () => _showBookOptions(books[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorState(Object error) {
    return LibraryEmptyState(
      icon: Icons.error_outline,
      title: 'Error loading books',
      subtitle: error.toString(),
      onAddBook: () => ref.read(booksApiProvider.notifier).refresh(),
    );
  }

  // Event handlers
  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.isNotEmpty) {
      ref.read(bookSearchProvider.notifier).searchBooks(value);
    } else {
      ref.read(bookSearchProvider.notifier).clearSearch();
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
    ref.read(booksApiProvider.notifier).loadBooks(
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
    ref.read(currentBookProvider.notifier).state = book;
    // Navigate to reading screen
  }

  void _showBookOptions(BookModel book) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookOptionsSheet(book: book),
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

  double _getSubjectCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Width for horizontal cards in subject sections (increased for better content fit)
    if (screenWidth >= AppConstants.desktopBreakpoint) {
      // Desktop: larger cards for better readability (increased)
      return 220.0;
    } else if (screenWidth >= AppConstants.tabletBreakpoint) {
      // Tablet: medium-sized cards (increased)
      return 200.0;
    } else {
      // Mobile: adequate size for horizontal scroll (increased)
      return 180.0;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': case 'math': return Colors.blue;
      case 'science': case 'biology': case 'chemistry': case 'physics': return Colors.green;
      case 'english': case 'literature': return Colors.purple;
      case 'history': case 'social studies': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': case 'math': return Icons.calculate;
      case 'science': case 'biology': case 'chemistry': case 'physics': return Icons.science;
      case 'english': case 'literature': return Icons.translate;
      case 'history': case 'social studies': return Icons.public;
      default: return Icons.book;
    }
  }

}
