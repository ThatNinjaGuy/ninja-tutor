import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/content/book_model.dart';
import '../../../models/bookmark/bookmark_model.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/reading_page_provider.dart';
import '../../../core/constants/app_constants.dart';

/// Bookmark Panel for managing bookmarks
class BookmarkPanel extends ConsumerStatefulWidget {
  final String bookId;
  final int currentPage;
  final VoidCallback onClose;
  final Function(int page)? onPageNavigate;

  const BookmarkPanel({
    super.key,
    required this.bookId,
    required this.currentPage,
    required this.onClose,
    this.onPageNavigate,
  });

  @override
  ConsumerState<BookmarkPanel> createState() => _BookmarkPanelState();
}

class _BookmarkPanelState extends ConsumerState<BookmarkPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Load bookmarks when panel first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔷 BookmarkPanel initState: loading bookmarks for ${widget.bookId}');
      ref.read(bookmarkProvider.notifier).loadBookmarks(widget.bookId);
    });
  }

  @override
  void didUpdateWidget(BookmarkPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload bookmarks if book changes
    if (oldWidget.bookId != widget.bookId) {
      print('🔷 BookmarkPanel: Book changed from ${oldWidget.bookId} to ${widget.bookId}');
      ref.read(bookmarkProvider.notifier).loadBookmarks(widget.bookId, forceRefresh: true);
    }
    // Log page change for debugging
    if (oldWidget.currentPage != widget.currentPage) {
      print('🔷 BookmarkPanel: Page changed from ${oldWidget.currentPage} to ${widget.currentPage}');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmarkState = ref.watch(bookmarkProvider);

    return Listener(
      onPointerDown: (_) {},
      onPointerMove: (_) {},
      onPointerUp: (_) {},
      onPointerSignal: (_) {},
      behavior: HitTestBehavior.opaque,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme),

                // Bookmarks list - now in the middle and scrollable
                Expanded(
                  child: bookmarkState.bookmarks.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildBookmarksList(theme, bookmarkState),
                ),

                // Current page bookmark section - moved to bottom
                _buildCurrentPageSection(theme, bookmarkState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bookmark,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bookmarks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Manage your reading progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPageSection(ThemeData theme, BookmarkState bookmarkState) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.currentPage;
    
    final isCurrentPageBookmarked = bookmarkState.isPageBookmarked(currentPage);
    
    print('🔷 Building current page section: page=$currentPage, isBookmarked=$isCurrentPageBookmarked, isLoading=${bookmarkState.isLoading}');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentPageBookmarked 
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCurrentPageBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isCurrentPageBookmarked 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page $currentPage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isCurrentPageBookmarked 
                      ? 'Currently bookmarked'
                      : 'Not bookmarked',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: (_isProcessing || bookmarkState.isLoading) ? null : () async {
              // Prevent double-clicks with local state
              if (_isProcessing) {
                print('⏳ Already processing bookmark operation');
                return;
              }
              
              setState(() => _isProcessing = true);
              
              // Capture the CURRENT state BEFORE the async operation
              final wasBookmarked = isCurrentPageBookmarked;
              
              print('🔵 Add/Remove button pressed for page $currentPage');
              print('🔵 Was bookmarked: $wasBookmarked');
              
              try {
                final success = await ref.read(bookmarkProvider.notifier).toggleBookmark(
                  widget.bookId, 
                  currentPage,
                );
                
                print('🔵 Toggle result: $success');
                
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasBookmarked
                              ? 'Bookmark removed from page $currentPage'
                              : 'Bookmark added to page $currentPage',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    print('⚠️ Toggle bookmark failed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to ${wasBookmarked ? 'remove' : 'add'} bookmark'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              } finally {
                if (mounted) {
                  setState(() => _isProcessing = false);
                }
              }
            },
            icon: _isProcessing 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentPageBookmarked 
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : Icon(
                    isCurrentPageBookmarked ? Icons.remove : Icons.add,
                    size: 16,
                  ),
            label: Text(
              _isProcessing 
                  ? 'Processing...'
                  : (isCurrentPageBookmarked ? 'Remove' : 'Add'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentPageBookmarked 
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              foregroundColor: isCurrentPageBookmarked 
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark pages to easily navigate back to important sections',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(ThemeData theme, BookmarkState bookmarkState) {
    final sortedBookmarks = List<BookmarkModel>.from(bookmarkState.bookmarks)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedBookmarks.map((bookmark) {
          return _buildBookmarkItem(theme, bookmark);
        }).toList(),
      ),
    );
  }

  Widget _buildBookmarkItem(ThemeData theme, BookmarkModel bookmark) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.currentPage;
    final isCurrentPage = bookmark.pageNumber == currentPage;
    final dateFormat = DateFormat('MMM d, HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentPage 
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPage 
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrentPage 
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${bookmark.pageNumber}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          'Page ${bookmark.pageNumber}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentPage 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(bookmark.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bookmark.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentPage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final success = await ref.read(bookmarkProvider.notifier).toggleBookmark(
                  widget.bookId, 
                  bookmark.pageNumber,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookmark removed from page ${bookmark.pageNumber}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 18,
              ),
              tooltip: 'Delete bookmark',
            ),
          ],
        ),
        onTap: () {
          // Navigate to the bookmarked page
          if (widget.onPageNavigate != null) {
            widget.onPageNavigate!(bookmark.pageNumber);
          }
          widget.onClose();
        },
      ),
    );
  }
}
