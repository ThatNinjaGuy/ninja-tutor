import 'package:flutter/material.dart';

import '../../../models/content/book_model.dart';

/// Reading controls widget for book navigation and features
class ReadingControls extends StatelessWidget {
  const ReadingControls({
    super.key,
    required this.book,
    this.onAiTipToggle,
    this.onQuizStart,
  });

  final BookModel book;
  final VoidCallback? onAiTipToggle;
  final VoidCallback? onQuizStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.psychology,
            label: 'AI Tips',
            onPressed: onAiTipToggle,
          ),
          _ControlButton(
            icon: Icons.quiz,
            label: 'Quiz',
            onPressed: onQuizStart,
          ),
          _ControlButton(
            icon: Icons.bookmark_add,
            label: 'Bookmark',
            onPressed: () {
              // TODO: Add bookmark
            },
          ),
          _ControlButton(
            icon: Icons.highlight,
            label: 'Highlight',
            onPressed: () {
              // TODO: Toggle highlight mode
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
