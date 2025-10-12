import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/quiz_provider.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/quiz/quiz_model.dart';
import '../../widgets/practice/quiz_session.dart';
import '../../widgets/common/empty_state.dart';

/// Practice screen for quizzes and assessments
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({
    super.key,
    this.sessionId,
  });

  final String? sessionId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load My Books and user quizzes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
      ref.read(userQuizzesProvider.notifier).loadQuizzes();
      ref.read(quizResultsProvider.notifier).loadResults();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (authUser == null) {
      return _buildLoginPrompt(context);
    }

    // If sessionId is provided, show quiz session
    if (widget.sessionId != null) {
      return QuizSession(sessionId: widget.sessionId!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.practice),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.available),
            Tab(text: AppStrings.myResults),
            Tab(text: 'Generate'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableQuizzes(context),
          _buildQuizResults(context),
          _buildGenerateQuiz(context),
        ],
      ),
    );
  }

  Widget _buildAvailableQuizzes(BuildContext context) {
    final quizzesState = ref.watch(userQuizzesProvider);

    return quizzesState.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.quiz_outlined,
            title: AppStrings.noQuizzesAvailable,
            subtitle: AppStrings.addBooksToGenerateQuizzes,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(userQuizzesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quizSummary = quizzes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuizSummaryCard(
                  quiz: quizSummary,
                  onStart: () => _startQuizById(quizSummary.quizId),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading quizzes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(userQuizzesProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResults(BuildContext context) {
    final results = ref.watch(quizResultsProvider);

    return results.when(
      data: (resultList) {
        if (resultList.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.assessment_outlined,
            title: AppStrings.noResultsYet,
            subtitle: AppStrings.completeQuizzes,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(quizResultsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: resultList.length,
            itemBuilder: (context, index) {
              final result = resultList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(result.percentage).withOpacity(0.1),
                    child: Text(
                      '${(result.percentage * 100).toInt()}%',
                      style: TextStyle(
                        color: _getScoreColor(result.percentage),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text('Quiz ${result.quizId}'),
                  subtitle: Text(
                    '${result.correctAnswers}/${result.questionResults.length} correct • '
                    '${result.completionTimeMinutes} min',
                  ),
                  trailing: Icon(
                    result.isPassed ? Icons.check_circle : Icons.cancel,
                    color: result.isPassed ? Colors.green : Colors.red,
                  ),
                  onTap: () => _viewResult(result),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading results: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(quizResultsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateQuiz(BuildContext context) {
    final theme = Theme.of(context);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final bookList = libraryState.myBooks;

    if (libraryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryState.error != null) {
      return Center(child: Text('Error loading books: ${libraryState.error}'));
    }

    if (bookList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.auto_awesome_outlined,
        title: AppStrings.noBooksAvailable,
        subtitle: AppStrings.addBooksToGenerateCustomQuizzes,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Custom Quiz',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Select a book and page range to generate a personalized quiz:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: bookList.length,
              itemBuilder: (context, index) {
                final book = bookList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.menu_book,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(book.title),
                    subtitle: Text('${book.author} • ${book.totalPages} pages'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectBookForQuiz(book),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _startQuizById(String quizId) {
    // Navigate to quiz session using quiz ID
    context.push('/practice/session/$quizId');
  }

  void _viewResult(QuizResult result) {
    // Show result details in a dialog or navigate to result page
    showDialog(
      context: context,
      builder: (context) => _QuizResultDialog(result: result),
    );
  }

  void _selectBookForQuiz(book) {
    // Show dialog to select page range and generate quiz
    showDialog(
      context: context,
      builder: (context) => _GenerateQuizDialog(book: book, ref: ref),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.practice)),
      body: EmptyStateWidget(
        icon: Icons.quiz_outlined,
        title: AppStrings.pleaseLogin,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.practice);
          context.go('/login');
        },
      ),
    );
  }
}

/// Dialog for generating custom quiz
class _GenerateQuizDialog extends ConsumerStatefulWidget {
  const _GenerateQuizDialog({
    required this.book,
    required this.ref,
  });

  final book;
  final WidgetRef ref;

  @override
  ConsumerState<_GenerateQuizDialog> createState() => __GenerateQuizDialogState();
}

class __GenerateQuizDialogState extends ConsumerState<_GenerateQuizDialog> {
  int startPage = 1;
  int endPage = 10;
  int questionCount = 10;
  DifficultyLevel difficulty = DifficultyLevel.medium;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Set default end page to book's total pages or 10, whichever is smaller
    endPage = widget.book.totalPages > 10 ? 10 : widget.book.totalPages;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Generate Quiz: ${widget.book.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page range
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: startPage.toString(),
                    decoration: const InputDecoration(labelText: 'Start Page'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      startPage = int.tryParse(value) ?? 1;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: endPage.toString(),
                    decoration: InputDecoration(
                      labelText: 'End Page',
                      helperText: 'Max: ${widget.book.totalPages}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      endPage = int.tryParse(value) ?? 10;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question count
            TextFormField(
              initialValue: questionCount.toString(),
              decoration: const InputDecoration(
                labelText: 'Number of Questions',
                helperText: 'Recommended: 5-15',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                questionCount = int.tryParse(value) ?? 10;
              },
            ),
            const SizedBox(height: 16),

            // Difficulty
            DropdownButtonFormField<DifficultyLevel>(
              value: difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: DifficultyLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    difficulty = value;
                  });
                }
              },
            ),

            if (_isGenerating) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Generating quiz with AI...'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateQuiz,
          child: const Text('Generate'),
        ),
      ],
    );
  }

  Future<void> _generateQuiz() async {
    // Validate inputs
    if (startPage < 1 || endPage > widget.book.totalPages || startPage > endPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid page range (1-${widget.book.totalPages})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (questionCount < 1 || questionCount > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 1-50 questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate quiz using the provider
      final quiz = await ref.read(quizGenerationProvider.notifier).generateQuiz(
            bookId: widget.book.id,
            startPage: startPage,
            endPage: endPage,
            questionCount: questionCount,
            difficulty: difficulty.name,
            subject: widget.book.subject,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz "${quiz.title}" generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Start',
              textColor: Colors.white,
              onPressed: () {
                context.push('/practice/session/${quiz.id}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for viewing quiz result details
class _QuizResultDialog extends StatelessWidget {
  const _QuizResultDialog({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(result.percentage);

    return AlertDialog(
      title: const Text('Quiz Results'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      '${(result.percentage * 100).toInt()}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      result.isPassed ? Icons.check_circle : Icons.cancel,
                      color: scoreColor,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            _StatRow(
              label: 'Correct Answers',
              value: '${result.correctAnswers}/${result.questionResults.length}',
            ),
            _StatRow(
              label: 'Time Taken',
              value: '${result.completionTimeMinutes} min',
            ),
            _StatRow(
              label: 'Status',
              value: result.isPassed ? 'Passed' : 'Failed',
              valueColor: result.isPassed ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),

            // Question breakdown
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Question Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...result.questionResults.asMap().entries.map((entry) {
              final index = entry.key;
              final qResult = entry.value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: qResult.isCorrect
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    qResult.isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: qResult.isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                title: Text('Question ${index + 1}'),
                subtitle: Text(
                  qResult.isCorrect
                      ? 'Correct - ${qResult.pointsEarned}/${qResult.maxPoints} points'
                      : 'Incorrect - ${qResult.pointsEarned}/${qResult.maxPoints} points',
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiz summary card for displaying quiz metadata
class _QuizSummaryCard extends StatelessWidget {
  const _QuizSummaryCard({
    required this.quiz,
    this.onStart,
  });

  final QuizSummary quiz;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor(quiz.difficulty);

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
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: difficultyColor,
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
                        '${quiz.bookTitle} • ${quiz.subject}',
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
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz.difficulty.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.quiz_outlined,
                        text: '${quiz.questionCount} questions',
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.access_time,
                        text: '~${quiz.questionCount * 2} min',
                      ),
                      if (quiz.totalAttempts > 0) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.star,
                          text: 'Best: ${(quiz.bestScore * 100).toInt()}%',
                        ),
                      ],
                    ],
                  ),
                ),
                
                ElevatedButton(
                  onPressed: onStart,
                  child: Text(quiz.totalAttempts > 0 ? 'Retake' : 'Start Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'easy':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.orange;
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
