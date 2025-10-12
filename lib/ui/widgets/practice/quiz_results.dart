import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/quiz/quiz_model.dart';

/// Widget for displaying quiz results after completion
class QuizResults extends StatelessWidget {
  const QuizResults({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    this.onReviewQuestions,
    this.onRetake,
    this.onClose,
  });

  final QuizModel quiz;
  final Map<String, String> userAnswers;
  final int score;
  final int totalQuestions;
  final Duration timeTaken;
  final VoidCallback? onReviewQuestions;
  final VoidCallback? onRetake;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (score / totalQuestions * 100).toInt();
    final isPassed = percentage >= 70;
    final scoreColor = _getScoreColor(percentage / 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score display
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withOpacity(0.1),
                      scoreColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withOpacity(0.1),
                        border: Border.all(
                          color: scoreColor,
                          width: 4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$percentage%',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            isPassed ? Icons.check_circle : Icons.cancel,
                            color: scoreColor,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      isPassed ? 'Congratulations!' : 'Keep Practicing!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      isPassed 
                          ? 'You passed the quiz!'
                          : 'You need 70% to pass. Try again!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _StatRow(
                      label: 'Correct Answers',
                      value: '$score / $totalQuestions',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const Divider(),
                    
                    _StatRow(
                      label: 'Incorrect Answers',
                      value: '${totalQuestions - score}',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                    const Divider(),
                    
                    _StatRow(
                      label: 'Time Taken',
                      value: '${timeTaken.inMinutes}:${(timeTaken.inSeconds % 60).toString().padLeft(2, '0')}',
                      icon: Icons.access_time,
                      color: theme.colorScheme.primary,
                    ),
                    const Divider(),
                    
                    _StatRow(
                      label: 'Difficulty',
                      value: quiz.difficulty.name.toUpperCase(),
                      icon: Icons.trending_up,
                      color: _getDifficultyColor(quiz.difficulty),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                if (onReviewQuestions != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReviewQuestions,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Review'),
                    ),
                  ),
                
                if (onReviewQuestions != null && onRetake != null)
                  const SizedBox(width: 12),
                
                if (onRetake != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (onClose != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Practice'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
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

/// Stat row for displaying result statistics
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

