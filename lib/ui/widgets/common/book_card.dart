import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/content/book_model.dart';

/// Layout modes for the BookCard component
enum BookCardLayout {
  /// Full detailed layout for lists and large displays
  full,
  /// Compact horizontal layout for lists  
  compact,
  /// Grid layout optimized for responsive grids
  grid,
}

/// Unified book card widget for displaying book information
/// Supports multiple layouts: full, compact, and grid
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
    this.showProgress = true,
    this.layout = BookCardLayout.full,
    this.showAddToLibrary = false,
    this.isInLibrary = false,
    this.onAddToLibrary,
    this.onRemoveFromLibrary,
  });

  final BookModel book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;
  final BookCardLayout layout;
  final bool showAddToLibrary;
  final bool isInLibrary;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onRemoveFromLibrary;

  /// Truncate title to max 25 characters(22 characters + 3 dots)
  String get _truncatedTitle {
    if (book.title.length <= 22) {
      return book.title;
    }
    return '${book.title.substring(0, 22)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(_getPadding()),
          child: _buildLayoutContent(context, theme),
        ),
      ),
    );
  }

  /// Get padding based on layout mode
  double _getPadding() {
    switch (layout) {
      case BookCardLayout.compact:
        return 12.0;
      case BookCardLayout.grid:
        return 12.0;
      case BookCardLayout.full:
        return 16.0;
    }
  }

  /// Build content based on selected layout mode
  Widget _buildLayoutContent(BuildContext context, ThemeData theme) {
    switch (layout) {
      case BookCardLayout.compact:
        return _buildCompactLayout(context, theme);
      case BookCardLayout.grid:
        return _buildGridLayout(context, theme);
      case BookCardLayout.full:
        return _buildFullLayout(context, theme);
    }
  }

  Widget _buildFullLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book cover and basic info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            _buildBookCover(theme, 50, 70),
            const SizedBox(width: 12),
            
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncatedTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    book.author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      _buildSubjectChip(theme),
                      const SizedBox(width: 8),
                      Text(
                        book.grade,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status indicators
            _buildStatusIndicators(theme),
          ],
        ),
        
        if (showProgress) ...[
          const SizedBox(height: 12),
          _buildProgressSection(theme),
        ],
        
        // Action buttons (if any)
        if (book.lastReadAt != null) ...[
          const SizedBox(height: 8),
          _buildLastReadInfo(theme),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Book cover
        _buildBookCover(theme, 40, 56),
        const SizedBox(width: 12),
        
        // Book info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _truncatedTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                book.author,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showProgress)
                _buildMiniProgress(theme),
            ],
          ),
        ),
        
        // Status and progress
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubjectChip(theme, small: true),
            if (showProgress)
              Text(
                '${(book.progressPercentage * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookCover(ThemeData theme, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _getSubjectColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: book.coverUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultCover(theme),
              ),
            )
          : _buildDefaultCover(theme),
    );
  }

  Widget _buildDefaultCover(ThemeData theme, [double? size]) {
    double iconSize;
    switch (layout) {
      case BookCardLayout.compact:
        iconSize = size ?? 20;
        break;
      case BookCardLayout.grid:
        iconSize = size ?? 32;
        break;
      case BookCardLayout.full:
        iconSize = size ?? 24;
        break;
    }
    
    return Center(
      child: Icon(
        Icons.menu_book,
        color: _getSubjectColor(),
        size: iconSize,
      ),
    );
  }

  Widget _buildSubjectChip(ThemeData theme, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getSubjectColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(small ? 8 : 12),
      ),
      child: Text(
        book.subject,
        style: (small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(
          color: _getSubjectColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(ThemeData theme) {
    return Column(
      children: [
        if (book.isOfflineAvailable)
          Icon(
            Icons.download_done,
            size: 16,
            color: Colors.green.shade600,
          ),
        if (book.isCompleted)
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue.shade600,
          ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final progress = book.progress;
    if (progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${progress.currentPage} of ${book.totalPages}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              '${(book.progressPercentage * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        LinearProgressIndicator(
          value: book.progressPercentage,
          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildMiniProgress(ThemeData theme) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: book.progressPercentage,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadInfo(ThemeData theme) {
    final lastRead = book.lastReadAt!;
    final now = DateTime.now();
    final difference = now.difference(lastRead);
    
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        
        Text(
          'Last read $timeAgo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// Grid layout optimized for responsive grids (replaces old GridBookCard)
  Widget _buildGridLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book cover (larger for grid)
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getSubjectColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: book.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultCover(theme, 32),
                    ),
                  )
                : _buildDefaultCover(theme, 32),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Book info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with better sizing
              Text(
                _truncatedTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Optimized for grid
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Author with better sizing
              Text(
                book.author,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11, // Smaller for better fit
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Progress and subject with flexible layout
              Column(
                children: [
                  // Subject chip (full width)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSubjectColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.subject,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getSubjectColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 10, // Smaller for better fit
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Progress percentage or Add to Library button
                  if (showAddToLibrary)
                    _buildLibraryButton(theme)
                  else
                    Text(
                      '${(book.progressPercentage * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build library action button (Add/Remove)
  Widget _buildLibraryButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: ElevatedButton(
        onPressed: isInLibrary ? onRemoveFromLibrary : onAddToLibrary,
        style: ElevatedButton.styleFrom(
          backgroundColor: isInLibrary 
              ? theme.colorScheme.error.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          foregroundColor: isInLibrary 
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInLibrary ? Icons.remove_circle_outline : Icons.add_circle_outline,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isInLibrary ? 'Remove' : 'Add',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor() {
    switch (book.subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Colors.blue;
      case 'science':
      case 'biology':
      case 'chemistry':
      case 'physics':
        return Colors.green;
      case 'english':
      case 'literature':
        return Colors.purple;
      case 'history':
      case 'social studies':
        return Colors.orange;
      case 'computer science':
      case 'programming':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
