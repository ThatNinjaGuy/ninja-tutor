import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/quiz/quiz_model.dart';

/// Quiz card widget for displaying quiz information
class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.quiz,
    this.onStart,
  });

  final QuizModel quiz;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: _getDifficultyColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quiz.subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz.difficulty.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getDifficultyColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            if (quiz.description != null) ...[
              const SizedBox(height: 12),
              Text(
                quiz.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.quiz,
                        text: '${quiz.totalQuestions} questions',
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.access_time,
                        text: '${quiz.estimatedTime} min',
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.book,
                        text: 'Pages ${quiz.pageRange.first}-${quiz.pageRange.last}',
                      ),
                    ],
                  ),
                ),
                
                ElevatedButton(
                  onPressed: onStart,
                  child: const Text('Start Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (quiz.difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.lightGreen;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
