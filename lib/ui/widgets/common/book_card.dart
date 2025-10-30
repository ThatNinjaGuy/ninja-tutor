import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_layout.dart';
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

  bool get _isNew => DateTime.now().difference(book.addedAt).inDays < 7;
  bool get _hasProgress => book.progressPercentage > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseRadius = context.responsiveValue(
      small: AppConstants.borderRadius,
      medium: AppConstants.borderRadius + 2,
      large: AppConstants.borderRadius + 4,
      extraLarge: AppConstants.borderRadius + 6,
    );
    final outerRadiusAddition = context.responsiveValue(
      small: 6.0,
      medium: 8.0,
      large: 10.0,
      extraLarge: 12.0,
    );
    final outerRadius = baseRadius + outerRadiusAddition;
    final innerRadius = baseRadius +
        context.responsiveValue(
          small: 4.0,
          medium: 6.0,
          large: 8.0,
          extraLarge: 10.0,
        );
    final accentColor = _getSubjectColor();

    return Hero(
      tag: 'book_${book.id}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outerRadius),
              gradient: _hasProgress
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.16),
                        accentColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: context.responsiveValue(
                    small: 12,
                    medium: 16,
                    large: 22,
                    extraLarge: 28,
                  ),
                  offset: Offset(
                      0,
                      context.responsiveValue(
                        small: 6,
                        medium: 8,
                        large: 10,
                        extraLarge: 12,
                      )),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.6),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    onLongPress?.call();
                  },
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: Padding(
                    padding: EdgeInsets.all(_getPadding(context)),
                    child: _buildLayoutContent(context, theme),
                  ),
                ),
              ),
            ),
          ),
          if (_isNew)
            Positioned(
              top: 8,
              left: 12,
              child: _buildBadge('New', Colors.greenAccent),
            ),
          if (book.isCompleted)
            Positioned(
              top: 8,
              right: 12,
              child: _buildBadge('Done', AppTheme.readingColor),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Get padding based on layout mode and device size
  double _getPadding(BuildContext context) {
    switch (layout) {
      case BookCardLayout.compact:
        return context.responsiveValue(
          small: 12.0,
          medium: 14.0,
          large: 16.0,
          extraLarge: 18.0,
        );
      case BookCardLayout.grid:
        return context.responsiveValue(
          small: 12.0,
          medium: 14.0,
          large: 16.0,
          extraLarge: 18.0,
        );
      case BookCardLayout.full:
        return context.responsiveValue(
          small: 14.0,
          medium: 16.0,
          large: 20.0,
          extraLarge: 24.0,
        );
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
    final gap = context.responsiveValue(
      small: 12.0,
      medium: 14.0,
      large: 16.0,
      extraLarge: 18.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book cover and basic info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            _buildBookCover(
              context,
              theme,
              width: context.responsiveValue(
                small: 48,
                medium: 58,
                large: 66,
                extraLarge: 74,
              ),
              height: context.responsiveValue(
                small: 70,
                medium: 84,
                large: 96,
                extraLarge: 108,
              ),
            ),
            SizedBox(width: gap),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncatedTitle,
                    style: _adjustStyle(
                      context,
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: gap * 0.3),
                  Text(
                    book.author,
                    style: _adjustStyle(
                      context,
                      theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: gap * 0.3),
                  Row(
                    children: [
                      _buildSubjectChip(context, theme),
                      SizedBox(width: gap * 0.5),
                      Text(
                        book.grade,
                        style: _adjustStyle(
                          context,
                          theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
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
          SizedBox(height: gap),
          _buildProgressSection(theme),
        ],

        // Action buttons (if any)
        if (book.lastReadAt != null) ...[
          SizedBox(height: gap * 0.6),
          _buildLastReadInfo(theme),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, ThemeData theme) {
    final horizontalGap = context.responsiveValue(
      small: 10.0,
      medium: 12.0,
      large: 14.0,
      extraLarge: 16.0,
    );

    return Row(
      children: [
        // Book cover
        _buildBookCover(
          context,
          theme,
          width: context.responsiveValue(
            small: 40,
            medium: 46,
            large: 54,
            extraLarge: 60,
          ),
          height: context.responsiveValue(
            small: 56,
            medium: 64,
            large: 74,
            extraLarge: 82,
          ),
        ),
        SizedBox(width: horizontalGap),

        // Book info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _truncatedTitle,
                style: _adjustStyle(
                  context,
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                book.author,
                style: _adjustStyle(
                  context,
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showProgress) _buildMiniProgress(theme),
            ],
          ),
        ),

        // Status and progress
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubjectChip(context, theme, small: true),
            if (showProgress)
              Text(
                '${book.progress?.totalPagesRead ?? 0}/${book.totalPages}',
                style: _adjustStyle(
                  context,
                  theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookCover(
    BuildContext context,
    ThemeData theme, {
    required double width,
    required double height,
  }) {
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
                errorWidget: (context, url, error) =>
                    _buildDefaultCover(context, theme),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
            )
          : _buildDefaultCover(context, theme),
    );
  }

  Widget _buildDefaultCover(BuildContext context, ThemeData theme) {
    final fontSize = context.responsiveValue(
      small: layout == BookCardLayout.grid ? 12.0 : 10.0,
      medium: layout == BookCardLayout.grid ? 14.0 : 12.0,
      large: layout == BookCardLayout.grid ? 16.0 : 13.0,
      extraLarge: layout == BookCardLayout.grid ? 18.0 : 14.0,
    );
    final padding = EdgeInsets.all(
      context.responsiveValue(
        small: layout == BookCardLayout.grid ? 6.0 : 4.0,
        medium: layout == BookCardLayout.grid ? 8.0 : 6.0,
        large: layout == BookCardLayout.grid ? 10.0 : 8.0,
        extraLarge: layout == BookCardLayout.grid ? 12.0 : 10.0,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            _getSubjectColor().withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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

  Widget _buildSubjectChip(BuildContext context, ThemeData theme,
      {bool small = false}) {
    final horizontal = context.responsiveValue(
      small: small ? 6.0 : 8.0,
      medium: small ? 8.0 : 10.0,
      large: small ? 9.0 : 12.0,
      extraLarge: small ? 10.0 : 14.0,
    );
    final vertical = context.responsiveValue(
      small: small ? 2.0 : 4.0,
      medium: small ? 3.0 : 5.0,
      large: small ? 4.0 : 6.0,
      extraLarge: small ? 4.0 : 7.0,
    );
    final radius = context.responsiveValue(
      small: small ? 8.0 : 12.0,
      medium: small ? 9.0 : 14.0,
      large: small ? 10.0 : 16.0,
      extraLarge: small ? 11.0 : 18.0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      decoration: BoxDecoration(
        color: _getSubjectColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        book.subject,
        style: _adjustStyle(
          context,
          (small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
              ?.copyWith(
            color: _getSubjectColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  TextStyle? _adjustStyle(BuildContext context, TextStyle? style) {
    if (style == null) return null;
    return ResponsiveTypography.adjust(context, style);
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
    final percent = book.progressPercentage;

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
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                    ),
                  ),
                ),
                if (percent > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment((percent * 2) - 1, 0),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.celebratoryHaloGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.readingColor.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Grid layout optimized for responsive grids (replaces old GridBookCard)
  Widget _buildGridLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book cover (smaller vertical footprint for grid)
        Expanded(
          flex: 2,
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
                      errorWidget: (context, url, error) =>
                          _buildDefaultCover(context, theme),
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 100),
                    ),
                  )
                : _buildDefaultCover(context, theme),
          ),
        ),

        const SizedBox(height: 6),

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
            const SizedBox(height: 2),

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

            const SizedBox(height: 6), // Minimal spacing before category/button

            // Progress and subject with flexible layout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subject chip (full width)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          foregroundColor:
              isInLibrary ? theme.colorScheme.error : theme.colorScheme.primary,
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
    ).animate(target: isInLibrary ? 1 : 0).scale(
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
