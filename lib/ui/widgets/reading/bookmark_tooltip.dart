import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/bookmark/bookmark_model.dart';

/// Tooltip-style popup showing bookmarks for a book
class BookmarkTooltip extends StatelessWidget {
  final List<BookmarkModel> bookmarks;
  final int currentPage;
  final Function(int) onPageNavigate;
  final Function(BookmarkModel)? onBookmarkDelete;
  final VoidCallback? onViewAll;
  final VoidCallback? onClose;
  
  const BookmarkTooltip({
    super.key,
    required this.bookmarks,
    required this.currentPage,
    required this.onPageNavigate,
    this.onBookmarkDelete,
    this.onViewAll,
    this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (bookmarks.isEmpty) {
      return _buildTooltipContainer(
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No bookmarks yet',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildTooltipContainer(
      theme: theme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  final isCurrentPage = bookmark.pageNumber == currentPage;
                  
                  return _buildBookmarkItem(
                    theme: theme,
                    bookmark: bookmark,
                    isCurrentPage: isCurrentPage,
                    onTap: () => onPageNavigate(bookmark.pageNumber),
                  );
                },
              ),
            ),
          ),
          if (onViewAll != null) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_list,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View All Bookmarks',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Bookmarks (${bookmarks.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
  
  Widget _buildTooltipContainer({
    required ThemeData theme,
    required Widget child,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: child,
      ),
    );
  }
  
  Widget _buildBookmarkItem({
    required ThemeData theme,
    required BookmarkModel bookmark,
    required bool isCurrentPage,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('MMM d, HH:mm');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentPage
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
        border: Border(
          left: BorderSide(
            color: isCurrentPage
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${bookmark.pageNumber}',
                      style: TextStyle(
                        color: isCurrentPage
                            ? Colors.white
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${bookmark.pageNumber}',
                      style: TextStyle(
                        fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(bookmark.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (onBookmarkDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () => onBookmarkDelete!(bookmark),
              tooltip: 'Delete bookmark',
            ),
        ],
      ),
    );
  }
}

