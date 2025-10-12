import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/quiz_provider.dart';
import '../../../models/quiz/quiz_model.dart';
import 'question_display.dart';
import 'quiz_results.dart';
import 'quiz_review.dart';

/// Quiz session widget for taking quizzes
class QuizSession extends ConsumerStatefulWidget {
  const QuizSession({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends ConsumerState<QuizSession> {
  QuizModel? _quiz;
  bool _isLoading = true;
  String? _error;
  
  // Quiz state
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {}; // questionId -> selectedOptionId
  final Map<String, DateTime> _questionStartTimes = {};
  late DateTime _quizStartTime;
  
  // Results state
  bool _showResults = false;
  bool _isSubmitting = false;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ref.read(apiServiceProvider);
      final quiz = await apiService.getQuiz(widget.sessionId);

      setState(() {
        _quiz = quiz;
        _isLoading = false;
        // Start timer for first question
        _questionStartTimes[quiz.questions[0].id] = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectOption(String questionId, String optionId) {
    setState(() {
      _userAnswers[questionId] = optionId;
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        final nextQuestion = _quiz!.questions[_currentQuestionIndex];
        _questionStartTimes.putIfAbsent(
          nextQuestion.id,
          () => DateTime.now(),
        );
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Confirm submission
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(
          'You have answered ${_userAnswers.length} out of ${_quiz!.questions.length} questions.\n\n'
          'Are you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      // Build answers for backend submission
      final answers = <Map<String, dynamic>>[];
      int correctAnswers = 0;
      
      for (final question in _quiz!.questions) {
        final userOptionId = _userAnswers[question.id];
        bool isCorrect = false;
        
        if (userOptionId != null) {
          final selectedOption = question.options.firstWhere(
            (opt) => opt.id == userOptionId,
            orElse: () => question.options.first,
          );
          isCorrect = selectedOption.isCorrect;
          if (isCorrect) {
            correctAnswers++;
          }
          
          // Build answer for backend
          answers.add({
            'question_id': question.id,
            'selected_options': [userOptionId],
            'user_answer': selectedOption.text,
            'is_correct': isCorrect,
            'points_earned': isCorrect ? question.points : 0,
            'max_points': question.points,
            'time_spent': DateTime.now().difference(_questionStartTimes[question.id] ?? _quizStartTime).inSeconds,
          });
        } else {
          // Unanswered question
          answers.add({
            'question_id': question.id,
            'selected_options': [],
            'user_answer': '',
            'is_correct': false,
            'points_earned': 0,
            'max_points': question.points,
            'time_spent': 0,
          });
        }
      }

      // Submit to backend for persistence
      final apiService = ref.read(apiServiceProvider);
      final timeTakenMinutes = DateTime.now().difference(_quizStartTime).inMinutes;
      
      await apiService.submitQuizAttempt(
        quizId: widget.sessionId,
        answers: answers,
        timeTaken: timeTakenMinutes,
      );

      // Refresh quiz results provider to show new attempt
      ref.read(quizResultsProvider.notifier).refresh();
      ref.read(userQuizzesProvider.notifier).refresh(); // Update best score

      setState(() {
        _finalScore = correctAnswers;
        _showResults = true;
        _isSubmitting = false;
      });
      
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reviewQuestions() {
    // Show quiz review using the common widget
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizReviewWidget(
          quiz: _quiz!,
          userAnswers: _userAnswers,
          title: 'Review: ${_quiz!.title}',
          subtitle: 'Score: ${_finalScore}/${_quiz!.questions.length} • ${(_finalScore! / _quiz!.questions.length * 100).toInt()}%',
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _questionStartTimes.clear();
      _showResults = false;
      _finalScore = null;
      _quizStartTime = DateTime.now();
      _questionStartTimes[_quiz!.questions[0].id] = DateTime.now();
    });
  }

  void _closeQuiz() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Quiz...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quiz...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading quiz: $_error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Quiz not found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show results screen
    if (_showResults && _finalScore != null) {
      return QuizResults(
        quiz: _quiz!,
        userAnswers: _userAnswers,
        score: _finalScore!,
        totalQuestions: _quiz!.questions.length,
        timeTaken: DateTime.now().difference(_quizStartTime),
        onReviewQuestions: _reviewQuestions,
        onRetake: _retakeQuiz,
        onClose: _closeQuiz,
      );
    }

    final currentQuestion = _quiz!.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
        actions: [
          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _getElapsedTime(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          
          // Question display
          Expanded(
            child: QuestionDisplay(
              question: currentQuestion,
              questionNumber: _currentQuestionIndex + 1,
              totalQuestions: _quiz!.questions.length,
              selectedOptionId: _userAnswers[currentQuestion.id],
              onOptionSelected: (optionId) => _selectOption(currentQuestion.id, optionId),
              showCorrectAnswer: false,
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
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _goToPreviousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  ),
                
                if (_currentQuestionIndex > 0 && !isLastQuestion)
                  const SizedBox(width: 12),
                
                // Next/Submit button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting 
                        ? null
                        : (isLastQuestion ? _submitQuiz : _goToNextQuestion),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                    label: Text(isLastQuestion ? 'Submit Quiz' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getElapsedTime() {
    final elapsed = DateTime.now().difference(_quizStartTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
