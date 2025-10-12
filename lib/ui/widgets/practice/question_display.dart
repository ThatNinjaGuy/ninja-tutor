import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/quiz/quiz_model.dart';

/// Widget for displaying a quiz question with answer options
class QuestionDisplay extends StatelessWidget {
  const QuestionDisplay({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.selectedOptionId,
    this.onOptionSelected,
    this.showCorrectAnswer = false,
    this.userSelectedOptionId,
  });

  final QuestionModel question;
  final int questionNumber;
  final int totalQuestions;
  final String? selectedOptionId;
  final ValueChanged<String>? onOptionSelected;
  final bool showCorrectAnswer;
  final String? userSelectedOptionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question number indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Question $questionNumber of $totalQuestions',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Question text
          Text(
            question.question,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Answer options
          ...question.options.map((option) {
            final isSelected = selectedOptionId == option.id || userSelectedOptionId == option.id;
            final isCorrect = option.isCorrect;
            final showFeedback = showCorrectAnswer;
            
            Color? backgroundColor;
            Color? borderColor;
            
            if (showFeedback) {
              if (isCorrect) {
                backgroundColor = Colors.green.withOpacity(0.1);
                borderColor = Colors.green;
              } else if (isSelected && !isCorrect) {
                backgroundColor = Colors.red.withOpacity(0.1);
                borderColor = Colors.red;
              }
            } else if (isSelected) {
              backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
              borderColor = theme.colorScheme.primary;
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                option: option,
                isSelected: isSelected,
                showCorrectAnswer: showFeedback,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                onTap: onOptionSelected != null && !showFeedback
                    ? () => onOptionSelected!(option.id)
                    : null,
              ),
            );
          }),
          
          // Explanation (shown in review mode)
          if (showCorrectAnswer && question.explanation != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual option card
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.showCorrectAnswer,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final AnswerOption option;
  final bool isSelected;
  final bool showCorrectAnswer;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor ?? theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected ? (borderColor ?? theme.colorScheme.primary) : null,
                ),
                child: isSelected
                    ? Icon(
                        showCorrectAnswer
                            ? (option.isCorrect ? Icons.check : Icons.close)
                            : Icons.circle,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Option text
              Expanded(
                child: Text(
                  option.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              
              // Correct answer indicator (review mode)
              if (showCorrectAnswer && option.isCorrect)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

