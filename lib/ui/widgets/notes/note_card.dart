import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../models/note/note_model.dart';

/// Note card widget for displaying note information
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onFavorite,
    this.compact = false,
    this.enableSwipeActions = true,
  });

  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final bool compact;
  final bool enableSwipeActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardWidget = Card(
      elevation: compact ? 1 : AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: _getNoteTypeColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: compact ? _buildCompactLayout(context, theme) : _buildFullLayout(context, theme),
        ),
      ),
    );

    // Wrap with Slidable for swipe actions
    if (enableSwipeActions && (onEdit != null || onDelete != null || onFavorite != null)) {
      return Slidable(
        key: ValueKey(note.id),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            if (onFavorite != null)
              SlidableAction(
                onPressed: (_) {
                  HapticsHelper.light();
                  onFavorite!();
                },
                backgroundColor: note.isFavorite ? Colors.grey : Colors.pink,
                foregroundColor: Colors.white,
                icon: note.isFavorite ? Icons.favorite_border : Icons.favorite,
                label: note.isFavorite ? 'Unfavorite' : 'Favorite',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius),
                  bottomLeft: Radius.circular(AppConstants.borderRadius),
                ),
              ),
            if (onEdit != null)
              SlidableAction(
                onPressed: (_) {
                  HapticsHelper.light();
                  onEdit!();
                },
                backgroundColor: AppTheme.aiTipColor,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            if (onDelete != null)
              SlidableAction(
                onPressed: (_) {
                  HapticsHelper.heavy();
                  onDelete!();
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppConstants.borderRadius),
                  bottomRight: Radius.circular(AppConstants.borderRadius),
                ),
              ),
          ],
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildFullLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNoteTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNoteTypeIcon(),
                color: _getNoteTypeColor(),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.title != null && note.title!.isNotEmpty)
                    Text(
                      note.title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    _getNoteTypeName(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getNoteTypeColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.isFavorite)
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 16,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 16,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Content
        Text(
          note.content,
          style: theme.textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        if (note.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: note.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Footer
        Row(
          children: [
            Text(
              'Page ${note.pageNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(note.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getNoteTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _getNoteTypeIcon(),
            color: _getNoteTypeColor(),
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.displayTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                note.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.isFavorite)
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 12,
              ),
            Text(
              'P${note.pageNumber}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getNoteTypeColor() {
    switch (note.type) {
      case NoteType.highlight:
        return Colors.yellow.shade700;
      case NoteType.text:
        return Colors.blue;
      case NoteType.drawing:
        return Colors.green;
      case NoteType.bookmark:
        return Colors.red;
      case NoteType.question:
        return Colors.purple;
      case NoteType.summary:
        return Colors.orange;
    }
  }

  IconData _getNoteTypeIcon() {
    switch (note.type) {
      case NoteType.highlight:
        return Icons.highlight;
      case NoteType.text:
        return Icons.text_fields;
      case NoteType.drawing:
        return Icons.draw;
      case NoteType.bookmark:
        return Icons.bookmark;
      case NoteType.question:
        return Icons.help_outline;
      case NoteType.summary:
        return Icons.summarize;
    }
  }

  String _getNoteTypeName() {
    switch (note.type) {
      case NoteType.highlight:
        return 'Highlight';
      case NoteType.text:
        return 'Note';
      case NoteType.drawing:
        return 'Drawing';
      case NoteType.bookmark:
        return 'Bookmark';
      case NoteType.question:
        return 'Question';
      case NoteType.summary:
        return 'Summary';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

