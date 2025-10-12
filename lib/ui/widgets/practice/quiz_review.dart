import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/quiz/quiz_model.dart';
import 'question_display.dart';

/// Reusable widget for reviewing quiz attempts
/// Shows all questions with user's answers and correct feedback
class QuizReviewWidget extends StatefulWidget {
  const QuizReviewWidget({
    super.key,
    required this.quiz,
    required this.userAnswers,
    this.title,
    this.subtitle,
    this.onClose,
  });

  final QuizModel quiz;
  final Map<String, String> userAnswers; // questionId -> selectedOptionId
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  State<QuizReviewWidget> createState() => _QuizReviewWidgetState();
}

class _QuizReviewWidgetState extends State<QuizReviewWidget> {
  int _currentQuestionIndex = 0;

  // Check if user's answer is correct for the current question
  bool _isCurrentAnswerCorrect() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = widget.userAnswers[currentQuestion.id];
    
    if (userAnswer == null) return false;
    
    final selectedOption = currentQuestion.options.firstWhere(
      (opt) => opt.id == userAnswer,
      orElse: () => currentQuestion.options.first,
    );
    
    return selectedOption.isCorrect;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = widget.userAnswers[currentQuestion.id];
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;
    final isCorrect = _isCurrentAnswerCorrect();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Review Quiz'),
        leading: widget.onClose != null
            ? IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          // Show correctness indicator in app bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCorrect ? 'Correct' : 'Incorrect',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),

          // Subtitle if provided
          if (widget.subtitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              child: Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Question display in review mode
          Expanded(
            child: QuestionDisplay(
              question: currentQuestion,
              questionNumber: _currentQuestionIndex + 1,
              totalQuestions: widget.quiz.questions.length,
              userSelectedOptionId: userAnswer,
              showCorrectAnswer: true, // Show correct/incorrect feedback + explanations
            ),
          ),

          // Question overview grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Questions Overview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(widget.quiz.questions.length, (index) {
                      final question = widget.quiz.questions[index];
                      final answer = widget.userAnswers[question.id];
                      final isAnswered = answer != null;
                      final isQuestionCorrect = isAnswered && 
                          question.options.firstWhere((opt) => opt.id == answer).isCorrect;
                      final isCurrent = index == _currentQuestionIndex;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _currentQuestionIndex = index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : isQuestionCorrect
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? theme.colorScheme.primary
                                    : isQuestionCorrect
                                        ? Colors.green
                                        : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: isCurrent
                                          ? theme.colorScheme.onPrimary
                                          : isQuestionCorrect
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Icon(
                                    isQuestionCorrect ? Icons.check_circle : Icons.cancel,
                                    size: 12,
                                    color: isCurrent
                                        ? theme.colorScheme.onPrimary
                                        : isQuestionCorrect
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                // Previous button
                if (!isFirstQuestion)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _currentQuestionIndex--);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  ),

                if (!isFirstQuestion && !isLastQuestion)
                  const SizedBox(width: 12),

                // Next button
                if (!isLastQuestion)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _currentQuestionIndex++);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  ),

                // Done button (last question)
                if (isLastQuestion)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onClose ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog wrapper for quiz review
class QuizReviewDialog extends StatelessWidget {
  const QuizReviewDialog({
    super.key,
    required this.quiz,
    required this.userAnswers,
    this.title,
    this.subtitle,
  });

  final QuizModel quiz;
  final Map<String, String> userAnswers;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: QuizReviewWidget(
          quiz: quiz,
          userAnswers: userAnswers,
          title: title,
          subtitle: subtitle,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

