import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/book_categories.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/reading/reading_interface_mixin.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/search_filter_bar.dart';
import '../../widgets/common/profile_menu_button.dart';

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

class _ReadingScreenState extends ConsumerState<ReadingScreen> 
    with ReadingInterfaceMixin {
  
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    // Load only My Books for reading screen (user can only read their own books)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBook = ref.watch(currentBookProvider);
    final user = ref.watch(authProvider);

    // Check if user is authenticated
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    // If we have a current book and are in reading mode, show the reading interface from mixin
    if (currentBook != null && isReadingMode) {
      return buildReadingInterface(currentBook);
    }

    // Otherwise, show book selection screen
    final libraryState = ref.watch(unifiedLibraryProvider);
    
    // Show loading state while fetching books
    if (libraryState.isLoadingUserLibrary && libraryState.myBooks.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.selectBookToRead),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppStrings.loadingYourBooks),
            ],
          ),
        ),
      );
    }
    
    // Handle book loading from URL parameter only when needed
    if (widget.bookId != null && libraryState.myBooks.isNotEmpty) {
      try {
        final book = libraryState.myBooks.firstWhere((b) => b.id == widget.bookId);
        
        // Set the book once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(currentBookProvider.notifier).state = book;
            setReadingMode(true);
          }
        });
      } catch (e) {
        // Book not found in user's library
      }
    }

    return _buildSelectBookScreen(context, libraryState);
  }

  Widget _buildSelectBookScreen(BuildContext context, LibraryState libraryState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.selectBookToRead),
        centerTitle: true,
        elevation: 0,
        actions: [
          ProfileMenuButton(currentRoute: AppRoutes.reading),
        ],
      ),
      body: libraryState.myBooks.isEmpty
          ? EmptyStateWidget(
              icon: Icons.library_books_outlined,
              title: AppStrings.noBooks,
              subtitle: AppStrings.addBooksFromLibrary,
              actionText: AppStrings.goToLibrary,
              onAction: () => ref.read(navigationProvider.notifier).state = 3,
            )
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(child: _buildBookList(_getFilteredBooks(libraryState.myBooks))),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SearchFilterBar(
      searchHint: 'Search books...',
      searchQuery: _searchQuery,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
      },
      filterWidgets: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: BookCategories.getAll().map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
          },
        ),
      ],
    );
  }

  List<BookModel> _getFilteredBooks(List<BookModel> books) {
    var filtered = books;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) {
        final searchLower = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(searchLower) ||
               book.author.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Filter by category (which corresponds to the book's subject field in the model)
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((book) => book.subject == _selectedCategory).toList();
    }

    return filtered;
  }


  Widget _buildBookList(List<BookModel> books) {
    final theme = Theme.of(context);
    
    if (books.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No books found',
        subtitle: 'Try adjusting your search or filters',
      );
    }
    
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
            subtitle: Text('${book.author} • ${book.subject} • ${book.totalPages} pages'),
            trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${book.progress?.totalPagesRead ?? 0}/${book.totalPages}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (book.progress != null && book.progress!.timeSpent > 0)
                    Text(
                      '${book.progress!.timeSpent} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            onTap: () {
              ref.read(currentBookProvider.notifier).state = book;
              setReadingMode(true);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reading),
        centerTitle: true,
      ),
      body: EmptyStateWidget(
        icon: Icons.login,
        title: AppStrings.pleaseSignIn,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.reading);
          context.go('/login');
        },
      ),
    );
  }
}
