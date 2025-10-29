import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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

    return Hero(
      tag: 'book_${book.id}',
      child: Card(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: InkWell(
          onTap: () {
            // Add haptic feedback
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          onLongPress: () {
            // Add haptic feedback
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(_getPadding()),
            child: _buildLayoutContent(context, theme),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      duration: 300.ms,
      curve: Curves.easeOutCubic,
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
                '${book.progress?.totalPagesRead ?? 0}/${book.totalPages}',
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
              child: CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _getSubjectColor().withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _getSubjectColor(),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildDefaultCover(theme),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
            )
          : _buildDefaultCover(theme),
    );
  }

  Widget _buildDefaultCover(ThemeData theme, [double? size]) {
    // Determine font size based on layout
    double fontSize;
    EdgeInsets padding;
    
    switch (layout) {
      case BookCardLayout.compact:
        fontSize = 10;
        padding = const EdgeInsets.all(4);
        break;
      case BookCardLayout.grid:
        fontSize = 14;
        padding = const EdgeInsets.all(8);
        break;
      case BookCardLayout.full:
        fontSize = 12;
        padding = const EdgeInsets.all(6);
        break;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Padding(
          padding: padding,
          child: Text(
            _truncatedTitle,
            textAlign: TextAlign.center,
            maxLines: layout == BookCardLayout.grid ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: _getSubjectColor(),
              height: 1.2,
            ),
          ),
        ),
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
              'Page ${progress.currentPage}/${book.totalPages}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (progress.timeSpent > 0)
              Text(
                '${progress.timeSpent} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: book.progressPercentage,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.readingColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                    child: CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: _getSubjectColor().withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _getSubjectColor(),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildDefaultCover(theme, 32),
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 100),
                    ),
                  )
                : _buildDefaultCover(theme, 32),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Book info - compact layout without Spacer
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            
            const SizedBox(height: 8), // Minimal spacing before category/button
            
            // Progress and subject with flexible layout
            Column(
              mainAxisSize: MainAxisSize.min,
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
                    '${book.progress?.totalPagesRead ?? 0}/${book.totalPages}',
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
      ],
    );
  }

  /// Build library action button (Add/Remove) with visual feedback
  Widget _buildLibraryButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: ElevatedButton(
        onPressed: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          if (isInLibrary) {
            onRemoveFromLibrary?.call();
          } else {
            onAddToLibrary?.call();
          }
        },
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
              isInLibrary ? Icons.check_circle : Icons.add_circle_outline,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isInLibrary ? 'Added' : 'Add',
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
    ).animate(target: isInLibrary ? 1 : 0)
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: 200.ms,
        curve: Curves.easeOut,
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
