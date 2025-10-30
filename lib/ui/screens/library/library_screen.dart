import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/book_categories.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/common/responsive_grid_helpers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/search_filter_bar.dart';
import '../../widgets/common/profile_menu_button.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/library/add_book_bottom_sheet.dart';
import '../../widgets/library/book_options_sheet.dart';
import '../../widgets/reading/reading_interface_mixin.dart';

/// Clean and simplified library screen for managing books
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

enum ViewMode { grid, list, compact }

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin, ReadingInterfaceMixin {
  late TabController _tabController;
  String? _selectedCategory = 'All';
  String _searchQuery = '';
  String _searchCriteria = 'title'; // Default: search in title only
  late Debouncer _searchDebouncer;
  ViewMode _viewMode = ViewMode.grid;

  // Current book being read
  BookModel? _currentReadingBook;
  bool _exploreBooksLoaded = false;
  bool _myBooksLoaded = false;

  @override
  void initState() {
    super.initState();
    // Start with Explore Books tab (index 1) instead of My Books tab (index 0)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _searchDebouncer = Debouncer(duration: const Duration(milliseconds: 800));

    // Listen to tab changes to lazy load data
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Load books only when switching to a tab that hasn't been loaded yet
    // The provider's ensure* methods have cache checks, so safe to call multiple times
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 1 && !_exploreBooksLoaded) {
        // Explore Books tab - load all books only when this tab is opened for the first time
        debugPrint('📚 Switching to Explore Books tab - loading all books');
        _exploreBooksLoaded = true;
        ref.read(unifiedLibraryProvider.notifier).ensureAllBooksLoaded();
      } else if (_tabController.index == 0 && !_myBooksLoaded) {
        // My Books tab - load user library only when this tab is opened for the first time
        debugPrint('📚 Switching to My Books tab - loading user library');
        _myBooksLoaded = true;
        ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
      } else {
        debugPrint(
            '📚 Tab switched to: ${_tabController.index == 1 ? "Explore Books" : "My Books"} (already loaded)');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final horizontalPadding = context.pageHorizontalPadding;
    final verticalPadding = context.responsiveValue(
      small: AppConstants.spacingXL,
      medium: AppConstants.spacingXL,
      large: AppConstants.spacingXL + 4,
      extraLarge: AppConstants.spacingXXL,
    );
    final maxContentWidth = context.responsiveMaxContentWidth;

    // Show loading screen while syncing
    if (authState.isLoading || authState.isSyncing) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.library)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppStrings.loadingYourLibrary),
            ],
          ),
        ),
      );
    }

    // Show login prompt if not authenticated
    if (user == null) return _buildLoginPrompt();

    // Load books for the active tab on initial load (only once per tab)
    final currentTabIndex = _tabController.index;
    if ((currentTabIndex == 1 && !_exploreBooksLoaded) ||
        (currentTabIndex == 0 && !_myBooksLoaded)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Load Explore Books data if it's the active tab and hasn't been loaded yet
        if (_tabController.index == 1 && !_exploreBooksLoaded) {
          debugPrint('🚀 Initial load from build - Explore Books tab');
          _exploreBooksLoaded = true;
          ref.read(unifiedLibraryProvider.notifier).ensureAllBooksLoaded();
        }
        // Load My Books data if it's the active tab and hasn't been loaded yet
        if (_tabController.index == 0 && !_myBooksLoaded) {
          debugPrint('🚀 Initial load from build - My Books tab');
          _myBooksLoaded = true;
          ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
        }
      });
    }

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
        appBar: AppBar(title: const Text(AppStrings.library)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppStrings.loadingYourLibrary),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  _buildSearchAndFilters(),
                  SizedBox(
                      height: context.responsiveValue(
                    small: AppConstants.spacingLG,
                    medium: AppConstants.spacingLG,
                    large: AppConstants.spacingXL,
                    extraLarge: AppConstants.spacingXL,
                  )),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.library)),
      body: EmptyStateWidget(
        icon: Icons.library_books_outlined,
        title: AppStrings.pleaseLogin,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref
              .read(authStateProvider.notifier)
              .setReturnRoute(AppRoutes.library);
          context.go('/login');
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      title: const Text(AppStrings.library),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showAddBookOptions,
          icon: const Icon(Icons.add),
          tooltip: 'Add Book',
        ),
        const ProfileMenuButton(currentRoute: AppRoutes.library),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        labelStyle:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: theme.textTheme.titleMedium,
        tabs: const [
          Tab(text: AppStrings.myBooks),
          Tab(text: AppStrings.exploreBooks),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);
    final spacing = context.responsiveValue(
      small: AppConstants.spacingLG,
      medium: AppConstants.spacingLG,
      large: AppConstants.spacingXL,
      extraLarge: AppConstants.spacingXL,
    );

    return Column(
      children: [
        SearchFilterBar(
          searchHint: 'Search books...',
          searchQuery: _searchQuery,
          onSearchChanged: (value) {
            setState(() => _searchQuery = value);
            if (value.isEmpty) {
              ref.read(unifiedLibraryProvider.notifier).clearSearch();
            } else {
              // Debounce search to avoid excessive API calls
              _searchDebouncer.call(() => _handleSearchChanged(value));
            }
          },
          filterWidgets: [
            ResponsiveFilterRow(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: BookCategories.getAll().map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child:
                          Text(category, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: _handleCategoryChanged,
                ),
                DropdownButtonFormField<String>(
                  value: _searchCriteria,
                  decoration: const InputDecoration(
                    labelText: 'Search In',
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'title',
                      child: Text('Book Name', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'author',
                      child: Text('Author', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'subject',
                      child: Text('Category', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'description',
                      child:
                          Text('Description', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Fields', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _searchCriteria = value ?? 'title';
                    });
                    // Re-search if there's an active search query
                    // For Explore Books, this triggers remote search API
                    // For My Books, this triggers UI rebuild with new local filter
                    if (_searchQuery.isNotEmpty) {
                      final currentTabIndex = _tabController.index;
                      if (currentTabIndex == 1) {
                        // Explore Books - use remote search
                        _searchDebouncer
                            .call(() => _handleSearchChanged(_searchQuery));
                      } else {
                        // My Books - just trigger rebuild (local filtering happens in build)
                        setState(() {});
                      }
                    }
                  },
                ),
              ],
            ),
          ],
          compactActions: [
            Tooltip(
              message: 'Filter by category',
              child: PopupMenuButton<String>(
                tooltip: 'Filter by category',
                icon: const Icon(Icons.category_outlined),
                onSelected: _handleCategoryChanged,
                itemBuilder: (context) {
                  return BookCategories.getAll()
                      .map((c) => PopupMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ))
                      .toList();
                },
              ),
            ),
            Tooltip(
              message: 'Search scope',
              child: PopupMenuButton<String>(
                tooltip: 'Search scope',
                icon: const Icon(Icons.manage_search),
                onSelected: (value) {
                  setState(() {
                    _searchCriteria = value;
                  });
                  if (_searchQuery.isNotEmpty) {
                    final currentTabIndex = _tabController.index;
                    if (currentTabIndex == 1) {
                      _searchDebouncer
                          .call(() => _handleSearchChanged(_searchQuery));
                    } else {
                      setState(() {});
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'title', child: Text('Book Name')),
                  PopupMenuItem(value: 'author', child: Text('Author')),
                  PopupMenuItem(value: 'subject', child: Text('Category')),
                  PopupMenuItem(value: 'description', child: Text('Description')),
                  PopupMenuItem(value: 'all', child: Text('All Fields')),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.25),

        // View mode toggle
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildViewModeButton(ViewMode mode, IconData icon, ThemeData theme) {
    final isSelected = _viewMode == mode;
    return AnimatedContainer(
      duration: AnimationHelper.fast,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _viewMode = mode);
            HapticsHelper.light();
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Build My Books tab - shows only user's personal library with search and filters
  /// Organized by category in carousels (similar to Explore Books)
  Widget _buildMyBooksGrid(LibraryState libraryState) {
    // Show skeleton loader instead of spinner for better UX
    if (libraryState.isLoadingUserLibrary && libraryState.myBooks.isEmpty) {
      return const GridSkeletonLoader(itemCount: 6);
    }

    if (libraryState.error != null) {
      return _buildErrorState(libraryState.error!);
    }

    if (libraryState.myBooks.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.library_books_outlined,
        title: AppStrings.noBooksInLibrary,
        subtitle: AppStrings.addBooksFromExplore,
      );
    }

    // Apply local search and filters to user's library books
    final filteredBooks = ref.read(unifiedLibraryProvider.notifier).filterBooks(
          books: libraryState.myBooks,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          subject: _selectedCategory,
          grade: null, // No grade filtering
          searchIn: _searchCriteria, // Use the selected search criteria
        );

    if (filteredBooks.isEmpty) {
      return EmptyStateWidget(
        icon:
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list_off,
        title: _searchQuery.isNotEmpty
            ? AppStrings.noBooksFound
            : AppStrings.noBooksmatchFilters,
        subtitle: _searchQuery.isNotEmpty
            ? AppStrings.tryDifferentSearch
            : AppStrings.tryAdjustingFilters,
      );
    }

    // If search is active, show search results in a simple grid (no category grouping)
    if (_searchQuery.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          gridDelegate:
              ResponsiveGridHelpers.createResponsiveGridDelegate(context),
          itemCount: filteredBooks.length,
          itemBuilder: (context, index) {
            final book = filteredBooks[index];

            return _AnimatedBookItem(
              index: index,
              child: BookCard(
                book: book,
                layout: BookCardLayout.grid,
                showAddToLibrary: true,
                isInLibrary: true,
                onTap: () => _openBook(book),
                onLongPress: () => _showBookOptions(book),
                onRemoveFromLibrary: () => _removeBookFromLibrary(book.id),
              ),
            );
          },
        ),
      );
    }

    // Group books by category for category-based display (similar to Explore Books)
    final booksToGroup = _selectedCategory == 'All'
        ? filteredBooks
        : filteredBooks; // Already filtered by category above

    if (booksToGroup.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.library_books_outlined,
        title: AppStrings.noBooksInLibrary,
        subtitle: AppStrings.addBooksFromExplore,
      );
    }

    // Group books by category
    final Map<String, List<BookModel>> booksByCategory = {};
    for (final book in booksToGroup) {
      final category = book.subject.isEmpty ? 'General' : book.subject;
      booksByCategory.putIfAbsent(category, () => []).add(book);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: booksByCategory.length,
        itemBuilder: (context, categoryIndex) {
          final category = booksByCategory.keys.elementAt(categoryIndex);
          final categoryBooks = booksByCategory[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header with View All button
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Always show View All button for each category
                    TextButton(
                      onPressed: () {
                        context.push(
                            '/library/category/${Uri.encodeComponent(category)}');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              // Books carousel (horizontal scroll) for this category
              SizedBox(
                height: ResponsiveGridHelpers.getMaxCardWidth(context) *
                        (1 /
                            ResponsiveGridHelpers.getChildAspectRatio(
                                context)) +
                    100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding),
                  itemCount: categoryBooks.length,
                  itemBuilder: (context, index) {
                    final book = categoryBooks[index];

                    return SizedBox(
                      width: ResponsiveGridHelpers.getMaxCardWidth(context),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _AnimatedBookItem(
                          index: index,
                          axis: Axis.horizontal,
                          child: BookCard(
                            book: book,
                            layout: BookCardLayout.grid,
                            showAddToLibrary: true,
                            isInLibrary: true,
                            onTap: () => _openBook(book),
                            onLongPress: () => _showBookOptions(book),
                            onRemoveFromLibrary: () =>
                                _removeBookFromLibrary(book.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32), // Spacing between categories
            ],
          );
        },
      ),
    );
  }

  /// Build Explore Books tab - shows books grouped by category with 2 rows per category
  Widget _buildExploreBooksGrid(LibraryState libraryState) {
    // Show skeleton loader instead of spinner for better UX
    if ((libraryState.isLoadingAllBooks || libraryState.isSearching) &&
        libraryState.allBooks.isEmpty &&
        libraryState.searchResults.isEmpty) {
      return const GridSkeletonLoader(itemCount: 6);
    }

    if (libraryState.error != null) {
      return _buildErrorState(libraryState.error!);
    }

    // If search is active, show search results in a simple grid (no category grouping)
    if (_searchQuery.isNotEmpty && libraryState.searchResults.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
        child: GridView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          gridDelegate:
              ResponsiveGridHelpers.createResponsiveGridDelegate(context),
          itemCount: libraryState.searchResults.length,
          itemBuilder: (context, index) {
            final book = libraryState.searchResults[index];
            final isInLibrary = libraryState.isBookInLibrary(book.id);

            return _AnimatedBookItem(
              index: index,
              child: BookCard(
                book: book,
                layout: BookCardLayout.grid,
                showAddToLibrary: true,
                isInLibrary: isInLibrary,
                onTap: () => _openBook(book),
                onLongPress: () => _showBookOptions(book),
                onAddToLibrary: () => _addBookToLibrary(book.id),
                onRemoveFromLibrary: () => _removeBookFromLibrary(book.id),
              ),
            );
          },
        ),
      );
    }

    // Group books by category for category-based display
    final booksToGroup = _selectedCategory == 'All'
        ? libraryState.allBooks
        : ref.read(unifiedLibraryProvider.notifier).filterBooks(
              books: libraryState.allBooks,
              subject: _selectedCategory,
              grade: null,
            );

    if (booksToGroup.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.explore_outlined,
        title: AppStrings.noBooksAvailable,
        subtitle: AppStrings.checkBackLater,
      );
    }

    // Group books by category
    final Map<String, List<BookModel>> booksByCategory = {};
    for (final book in booksToGroup) {
      final category = book.subject.isEmpty ? 'General' : book.subject;
      booksByCategory.putIfAbsent(category, () => []).add(book);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: booksByCategory.length,
        itemBuilder: (context, categoryIndex) {
          final category = booksByCategory.keys.elementAt(categoryIndex);
          final categoryBooks = booksByCategory[category]!;
          final totalBooks = categoryBooks.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header with View All button
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Always show View All button for each category
                    TextButton(
                      onPressed: () {
                        context.push(
                            '/library/category/${Uri.encodeComponent(category)}');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              // Books carousel (horizontal scroll) for this category
              SizedBox(
                height: ResponsiveGridHelpers.getMaxCardWidth(context) *
                        (1 /
                            ResponsiveGridHelpers.getChildAspectRatio(
                                context)) +
                    100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding),
                  itemCount: categoryBooks.length,
                  itemBuilder: (context, index) {
                    final book = categoryBooks[index];
                    final isInLibrary = libraryState.isBookInLibrary(book.id);

                    return SizedBox(
                      width: ResponsiveGridHelpers.getMaxCardWidth(context),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _AnimatedBookItem(
                          index: index,
                          axis: Axis.horizontal,
                          child: BookCard(
                            book: book,
                            layout: BookCardLayout.grid,
                            showAddToLibrary: true,
                            isInLibrary: isInLibrary,
                            onTap: () => _openBook(book),
                            onLongPress: () => _showBookOptions(book),
                            onAddToLibrary: () => _addBookToLibrary(book.id),
                            onRemoveFromLibrary: () =>
                                _removeBookFromLibrary(book.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32), // Spacing between categories
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: AppStrings.errorLoadingBooks,
      subtitle: error,
      actionText: AppStrings.retry,
      onAction: () {
        // Retry loading all books with the same per_category parameter
        ref.read(unifiedLibraryProvider.notifier).ensureAllBooksLoaded();
      },
    );
  }

  // Event handlers
  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value);

    // Only call remote API for Explore Books tab - My Books uses local filtering
    final currentTabIndex = _tabController.index;

    if (value.isEmpty) {
      ref.read(unifiedLibraryProvider.notifier).clearSearch();
    } else {
      // For Explore Books tab (index 1), use remote search API
      if (currentTabIndex == 1) {
        ref
            .read(unifiedLibraryProvider.notifier)
            .searchBooks(value, searchIn: _searchCriteria);
      }
      // For My Books tab (index 0), local filtering is handled in _buildMyBooksGrid
      // No API call needed - books are already loaded
    }
  }

  void _handleCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);

    // Only reload from API for Explore Books tab - My Books uses local filtering
    final currentTabIndex = _tabController.index;
    if (currentTabIndex == 1) {
      // Explore Books - reload with filters
      _reloadBooksWithFilters();
    }
    // For My Books (index 0), no API call needed - local filtering happens in build
  }

  void _reloadBooksWithFilters() {
    ref.read(unifiedLibraryProvider.notifier).refreshWithFilters(
          subject: _selectedCategory == 'All' ? null : _selectedCategory,
          grade: null, // No grade filtering
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
    // Haptic feedback
    HapticFeedback.mediumImpact();

    final success = await ref
        .read(unifiedLibraryProvider.notifier)
        .addBookToLibrary(bookId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(success
                    ? AppStrings.bookAddedToLibrary
                    : AppStrings.failedToAddBook),
              ),
            ],
          ),
          backgroundColor:
              success ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(milliseconds: 2000),
        ),
      );

      if (success) {
        HapticFeedback.lightImpact();
      }
    }
  }

  /// Remove book from user's personal library
  Future<void> _removeBookFromLibrary(String bookId) async {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    final success = await ref
        .read(unifiedLibraryProvider.notifier)
        .removeBookFromLibrary(bookId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.remove_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(success
                    ? AppStrings.bookRemovedFromLibrary
                    : AppStrings.failedToRemoveBook),
              ),
            ],
          ),
          backgroundColor:
              success ? Colors.orange.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(milliseconds: 2000),
        ),
      );

      if (success) {
        HapticFeedback.lightImpact();
      }
    }
  }
}

class _AnimatedBookItem extends StatefulWidget {
  const _AnimatedBookItem({
    required this.index,
    required this.child,
    this.axis = Axis.vertical,
  });

  final int index;
  final Widget child;
  final Axis axis;

  @override
  State<_AnimatedBookItem> createState() => _AnimatedBookItemState();
}

class _AnimatedBookItemState extends State<_AnimatedBookItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialOffset = widget.axis == Axis.vertical
        ? const Offset(0, 0.1)
        : const Offset(0.1, 0);

    return AnimatedSlide(
      duration: AnimationHelper.normal,
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : initialOffset,
      child: AnimatedOpacity(
        duration: AnimationHelper.normal,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
