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
import '../../../core/utils/responsive_layout.dart';

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

class _AnimatedReadingCard extends StatefulWidget {
  const _AnimatedReadingCard({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedReadingCard> createState() => _AnimatedReadingCardState();
}

class _AnimatedReadingCardState extends State<_AnimatedReadingCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 420),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _ReadingScreenState extends ConsumerState<ReadingScreen>
    with ReadingInterfaceMixin {
  String _searchQuery = '';
  String? _selectedCategory;
  String _searchCriteria = 'title';

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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Show loading screen while syncing
    if (authState.isLoading || authState.isSyncing) {
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
        final book =
            libraryState.myBooks.firstWhere((b) => b.id == widget.bookId);

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

  Widget _buildSelectBookScreen(
      BuildContext context, LibraryState libraryState) {
    final recentBooks = libraryState.myBooks
        .where((book) => book.lastReadAt != null)
        .toList()
      ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    final horizontalPadding = context.pageHorizontalPadding;
    final verticalPadding = context.responsiveValue(
      small: AppConstants.spacingXL,
      medium: AppConstants.spacingXL,
      large: AppConstants.spacingXL + 4,
      extraLarge: AppConstants.spacingXXL,
    );
    final sectionSpacing = context.responsiveValue(
      small: 18.0,
      medium: 22.0,
      large: 26.0,
      extraLarge: 30.0,
    );
    final maxContentWidth = context.responsiveMaxContentWidth;

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
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: EmptyStateWidget(
                  icon: Icons.library_books_outlined,
                  title: AppStrings.noBooks,
                  subtitle: AppStrings.addBooksFromLibrary,
                  actionText: AppStrings.goToLibrary,
                  onAction: () =>
                      ref.read(navigationProvider.notifier).state = 3,
                ),
              ),
            )
          : SafeArea(
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
                        if (recentBooks.isNotEmpty) ...[
                          SizedBox(height: sectionSpacing * 0.6),
                          _buildRecentCarousel(
                              context, recentBooks.take(6).toList()),
                          SizedBox(height: sectionSpacing * 0.6),
                        ],
                        Expanded(
                          child: _buildBookList(
                            _getFilteredBooks(libraryState.myBooks),
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

  Widget _buildRecentCarousel(
      BuildContext context, List<BookModel> recentBooks) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue your journey',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${recentBooks.length} recent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding),
            scrollDirection: Axis.horizontal,
            itemCount: recentBooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = recentBooks[index];
              final percent = book.progressPercentage;
              return _AnimatedReadingCard(
                index: index,
                child: GestureDetector(
                  onTap: () {
                    ref.read(currentBookProvider.notifier).state = book;
                    context.go('${AppRoutes.reader}/book/${book.id}');
                  },
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Page ${book.progress?.currentPage ?? 1}/${book.totalPages}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.primary),
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        DropdownButtonFormField<String>(
          value: _searchCriteria,
          decoration: const InputDecoration(
            labelText: 'Search In',
            prefixIcon: Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'title', child: Text('Book Name')),
            DropdownMenuItem(value: 'author', child: Text('Author')),
            DropdownMenuItem(value: 'subject', child: Text('Category')),
            DropdownMenuItem(value: 'all', child: Text('All Fields')),
          ],
          onChanged: (value) {
            setState(() => _searchCriteria = value ?? 'title');
          },
        ),
      ],
      compactActions: [
        Tooltip(
          message: 'Filter by category',
          child: PopupMenuButton<String>(
            tooltip: 'Filter by category',
            icon: const Icon(Icons.category_outlined),
            onSelected: (v) => setState(() => _selectedCategory = v),
            itemBuilder: (context) => BookCategories.getAll()
                .map((c) => PopupMenuItem<String>(value: c, child: Text(c)))
                .toList(),
          ),
        ),
        Tooltip(
          message: 'Search scope',
          child: PopupMenuButton<String>(
            tooltip: 'Search scope',
            icon: const Icon(Icons.manage_search),
            onSelected: (v) => setState(() => _searchCriteria = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'title', child: Text('Book Name')),
              PopupMenuItem(value: 'author', child: Text('Author')),
              PopupMenuItem(value: 'subject', child: Text('Category')),
              PopupMenuItem(value: 'all', child: Text('All Fields')),
            ],
          ),
        ),
      ],
    );
  }

  List<BookModel> _getFilteredBooks(List<BookModel> books) {
    var filtered = books;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((book) {
        switch (_searchCriteria) {
          case 'author':
            return book.author.toLowerCase().contains(q);
          case 'subject':
            return book.subject.toLowerCase().contains(q);
          case 'all':
            return book.title.toLowerCase().contains(q) ||
                book.author.toLowerCase().contains(q) ||
                book.subject.toLowerCase().contains(q);
          case 'title':
          default:
            return book.title.toLowerCase().contains(q);
        }
      }).toList();
    }

    // Filter by category (which corresponds to the book's subject field in the model)
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered =
          filtered.where((book) => book.subject == _selectedCategory).toList();
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

        return _AnimatedReadingCard(
          index: index,
          child: Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                ref.read(currentBookProvider.notifier).state = book;
                context.go('${AppRoutes.reader}/book/${book.id}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.secondary.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child:
                          const Icon(Icons.auto_stories, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
                          Text(
                            '${book.author} • ${book.subject}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.turn_right_outlined,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to jump to current page',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${book.progress?.totalPagesRead ?? 0}/${book.totalPages}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (book.progress != null &&
                            book.progress!.timeSpent > 0)
                          Text(
                            '${book.progress!.timeSpent} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
          ref
              .read(authStateProvider.notifier)
              .setReturnRoute(AppRoutes.reading);
          context.go('/login');
        },
      ),
    );
  }
}
