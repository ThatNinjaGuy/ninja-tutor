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
    _searchDebouncer = Debouncer(duration: const Duration(milliseconds: 300));
    
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
        debugPrint('📚 Tab switched to: ${_tabController.index == 1 ? "Explore Books" : "My Books"} (already loaded)');
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
    final user = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (user == null) return _buildLoginPrompt();

    // Load books for the active tab on initial load (only once per tab)
    final currentTabIndex = _tabController.index;
    if ((currentTabIndex == 1 && !_exploreBooksLoaded) || (currentTabIndex == 0 && !_myBooksLoaded)) {
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
      appBar: AppBar(title: const Text(AppStrings.library)),
      body: EmptyStateWidget(
        icon: Icons.library_books_outlined,
        title: AppStrings.pleaseLogin,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.library);
          context.go('/login');
        },
      ),
    );
  }

  AppBar _buildAppBar() {
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
        tabs: const [
          Tab(text: AppStrings.myBooks),
          Tab(text: AppStrings.exploreBooks),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);
    
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: BookCategories.getAll().map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: _handleCategoryChanged,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // View mode toggle
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildViewModeButton(ViewMode.grid, Icons.grid_view, theme),
                  _buildViewModeButton(ViewMode.list, Icons.view_list, theme),
                  _buildViewModeButton(ViewMode.compact, Icons.view_compact, theme),
                ],
              ),
            ),
            const Spacer(),
            // Sort indicator
            TextButton.icon(
              onPressed: () {
                // TODO: Implement sort options
              },
              icon: const Icon(Icons.sort, size: 18),
              label: const Text('Sort', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildViewModeButton(ViewMode mode, IconData icon, ThemeData theme) {
    final isSelected = _viewMode == mode;
    return Material(
      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() => _viewMode = mode);
          HapticsHelper.light();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Build My Books tab - shows only user's personal library with search and filters
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

    // Apply search and filters to user's library books
    final filteredBooks = ref.read(unifiedLibraryProvider.notifier).filterBooks(
      books: libraryState.myBooks,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      subject: _selectedCategory,
      grade: null, // No grade filtering
    );

    if (filteredBooks.isEmpty) {
      return EmptyStateWidget(
        icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list_off,
        title: _searchQuery.isNotEmpty ? AppStrings.noBooksFound : AppStrings.noBooksmatchFilters,
        subtitle: _searchQuery.isNotEmpty 
            ? AppStrings.tryDifferentSearch
            : AppStrings.tryAdjustingFilters,
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
    // Show skeleton loader instead of spinner for better UX
    if ((libraryState.isLoadingAllBooks || libraryState.isSearching) && 
        libraryState.allBooks.isEmpty && libraryState.searchResults.isEmpty) {
      return const GridSkeletonLoader(itemCount: 6);
    }

    if (libraryState.error != null) {
      return _buildErrorState(libraryState.error!);
    }

    final booksToShow = libraryState.exploreBooks;

    // Apply client-side filters for category
    final filteredBooks = ref.read(unifiedLibraryProvider.notifier).filterBooks(
      books: booksToShow,
      subject: _selectedCategory == 'All' ? null : _selectedCategory,
      grade: null, // No grade filtering
    );

    if (filteredBooks.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.explore_outlined,
        title: _searchQuery.isEmpty ? AppStrings.noBooksAvailable : AppStrings.noBooksFound,
        subtitle: _searchQuery.isEmpty 
            ? AppStrings.checkBackLater
            : AppStrings.tryAdjustingFilters,
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
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: AppStrings.errorLoadingBooks,
      subtitle: error,
      actionText: AppStrings.retry,
      onAction: () => ref.read(unifiedLibraryProvider.notifier).refresh(),
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

  void _handleCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    _reloadBooksWithFilters();
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
    
    final success = await ref.read(unifiedLibraryProvider.notifier).addBookToLibrary(bookId);
    
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
                child: Text(success ? AppStrings.bookAddedToLibrary : AppStrings.failedToAddBook),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
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
    
    final success = await ref.read(unifiedLibraryProvider.notifier).removeBookFromLibrary(bookId);
    
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
                child: Text(success ? AppStrings.bookRemovedFromLibrary : AppStrings.failedToRemoveBook),
              ),
            ],
          ),
          backgroundColor: success ? Colors.orange.shade600 : Colors.red.shade600,
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
