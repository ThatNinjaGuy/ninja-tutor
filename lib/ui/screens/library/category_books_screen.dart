import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/common/responsive_grid_helpers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';

/// Screen showing books in a specific category with pagination
class CategoryBooksScreen extends ConsumerStatefulWidget {
  const CategoryBooksScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  ConsumerState<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends ConsumerState<CategoryBooksScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _booksPerPage = 20;
  List<BookModel> _loadedBooks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoadedInitial = false; // Flag to prevent multiple initial loads

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Delay initial load to avoid race conditions when navigating back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoadedInitial) {
        _hasLoadedInitial = true;
        _loadBooks();
      }
    });
  }

  @override
  void didUpdateWidget(CategoryBooksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If category changed, reset and reload
    if (oldWidget.category != widget.category) {
      setState(() {
        _currentPage = 1;
        _loadedBooks = [];
        _hasMore = true;
        _hasLoadedInitial = false;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasLoadedInitial) {
          _hasLoadedInitial = true;
          _loadBooks();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreBooks();
      }
    }
  }

  Future<void> _loadBooks({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _loadedBooks = [];
        _hasMore = true;
        _hasLoadedInitial = true; // Ensure flag is set on refresh
      });
    }

    // Prevent duplicate calls - return early if already loading or already loaded (unless refresh)
    if (_isLoading || (!refresh && _hasLoadedInitial && _loadedBooks.isNotEmpty)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasLoadedInitial = true; // Mark as loaded
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        setState(() {
          _isLoading = false;
          _hasLoadedInitial = false; // Allow retry when auth is available
        });
        return;
      }

      // Create a temporary API service instance for fetching books
      // Note: The unifiedLibraryProvider already handles pagination, but we need direct API access here
      final tempApiService = ref.read(apiServiceProvider);
      
      // Set auth token if available
      if (authState.user?.token != null) {
        tempApiService.setAuthToken(authState.user!.token!);
      }
      
      final books = await tempApiService.getBooks(
        subject: widget.category == 'All' ? null : widget.category,
        page: _currentPage,
        limit: _booksPerPage,
      );

      setState(() {
        if (refresh) {
          _loadedBooks = books;
        } else {
          _loadedBooks.addAll(books);
        }
        _hasMore = books.length == _booksPerPage;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading books: $e');
      setState(() {
        _isLoading = false;
        _hasLoadedInitial = false; // Allow retry on error
      });
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
        return;
      }

      final apiService = ref.read(apiServiceProvider);
      
      // Set auth token if available
      if (authState.user?.token != null) {
        apiService.setAuthToken(authState.user!.token!);
      }
      
      final books = await apiService.getBooks(
        subject: widget.category == 'All' ? null : widget.category,
        page: _currentPage,
        limit: _booksPerPage,
      );

      setState(() {
        _loadedBooks.addAll(books);
        _hasMore = books.length == _booksPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more books: $e');
      setState(() {
        _currentPage--; // Rollback page increment on error
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == 'All' ? 'All Books' : widget.category),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBooks(refresh: true),
        child: _isLoading && _loadedBooks.isEmpty
            ? const GridSkeletonLoader(itemCount: 6)
            : _loadedBooks.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.book_outlined,
                    title: 'No Books Found',
                    subtitle: 'There are no books in this category yet.',
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    gridDelegate: ResponsiveGridHelpers.createResponsiveGridDelegate(context),
                    itemCount: _loadedBooks.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _loadedBooks.length) {
                        // Loading indicator at the bottom
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final book = _loadedBooks[index];
                      final isInLibrary = libraryState.isBookInLibrary(book.id);

                      return BookCard(
                        book: book,
                        layout: BookCardLayout.grid,
                        showAddToLibrary: true,
                        isInLibrary: isInLibrary,
                        onTap: () {
                          ref.read(currentBookProvider.notifier).state = book;
                          context.push('/reading/book/${book.id}');
                        },
                        onAddToLibrary: () {
                          ref.read(unifiedLibraryProvider.notifier).addBookToLibrary(book.id);
                        },
                        onRemoveFromLibrary: () {
                          ref.read(unifiedLibraryProvider.notifier).removeBookFromLibrary(book.id);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

