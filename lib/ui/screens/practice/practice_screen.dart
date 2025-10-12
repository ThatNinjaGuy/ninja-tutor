import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/quiz/quiz_model.dart';
import '../../widgets/practice/quiz_card.dart';
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
        icon: Icons.quiz_outlined,
        title: AppStrings.noQuizzesAvailable,
        subtitle: AppStrings.addBooksToGenerateQuizzes,
      );
    }

    // Mock quizzes for demonstration
    final mockQuizzes = _generateMockQuizzes(bookList);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: mockQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = mockQuizzes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: QuizCard(
            quiz: quiz,
            onStart: () => _startQuiz(quiz),
          ),
        );
      },
    );
  }

  Widget _buildQuizResults(BuildContext context) {
    final theme = Theme.of(context);
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

        return ListView.builder(
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading results: $error'),
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

  List<QuizModel> _generateMockQuizzes(List bookList) {
    // Generate mock quizzes for demonstration
    return bookList.take(3).map((book) {
      return QuizModel(
        id: 'quiz_${book.id}',
        title: '${book.subject} Quiz - Chapter 1',
        description: 'Test your understanding of key concepts',
        bookId: book.id,
        subject: book.subject,
        pageRange: [1, 20],
        questions: [], // Would be populated with actual questions
        settings: const QuizSettings(),
        createdAt: DateTime.now(),
        type: QuizType.practice,
        difficulty: DifficultyLevel.medium,
      );
    }).toList();
  }

  void _startQuiz(QuizModel quiz) {
    // TODO: Navigate to quiz session when implemented
  }

  void _viewResult(QuizResult result) {
    // TODO: Navigate to result details when implemented
  }

  void _selectBookForQuiz(book) {
    // Show dialog to select page range and generate quiz
    showDialog(
      context: context,
      builder: (context) => _GenerateQuizDialog(book: book),
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
class _GenerateQuizDialog extends StatefulWidget {
  const _GenerateQuizDialog({required this.book});

  final book;

  @override
  State<_GenerateQuizDialog> createState() => __GenerateQuizDialogState();
}

class __GenerateQuizDialogState extends State<_GenerateQuizDialog> {
  int startPage = 1;
  int endPage = 10;
  int questionCount = 10;
  DifficultyLevel difficulty = DifficultyLevel.medium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Generate Quiz: ${widget.book.title}'),
      content: Column(
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
                  decoration: const InputDecoration(labelText: 'End Page'),
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
            decoration: const InputDecoration(labelText: 'Number of Questions'),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _generateQuiz();
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }

  void _generateQuiz() {
    // TODO: Implement quiz generation with AI service
  }
}
