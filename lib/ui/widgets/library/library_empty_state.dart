import 'package:flutter/material.dart';

/// Reusable empty state widget for library screens
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAddBook,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAddBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddBook != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAddBook,
                child: const Text('Add Book'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
