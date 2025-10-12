import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/quiz/quiz_model.dart';
import 'app_providers.dart';

/// Provider for managing user's quizzes (summary list)
final userQuizzesProvider = StateNotifierProvider<UserQuizzesNotifier, AsyncValue<List<QuizSummary>>>(
  (ref) => UserQuizzesNotifier(ref),
);

/// Provider for quiz results
final quizResultsProvider = StateNotifierProvider<QuizResultsNotifier, AsyncValue<List<QuizResult>>>(
  (ref) => QuizResultsNotifier(ref),
);

/// Provider for generating quizzes
final quizGenerationProvider = StateNotifierProvider<QuizGenerationNotifier, AsyncValue<QuizModel?>>(
  (ref) => QuizGenerationNotifier(ref),
);

/// Notifier for managing user quizzes
class UserQuizzesNotifier extends StateNotifier<AsyncValue<List<QuizSummary>>> {
  UserQuizzesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadQuizzes();
  }

  final Ref ref;

  /// Load user's quizzes from backend
  Future<void> loadQuizzes({String? bookId}) async {
    try {
      state = const AsyncValue.loading();
      
      final apiService = ref.read(apiServiceProvider);
      final quizzesData = await apiService.getUserQuizzes(bookId: bookId);
      
      final quizzes = quizzesData.map((data) {
        return QuizSummary.fromJson(data);
      }).toList();
      
      state = AsyncValue.data(quizzes);
    } catch (e, stack) {
      debugPrint('Error loading quizzes: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh quizzes
  Future<void> refresh({String? bookId}) async {
    await loadQuizzes(bookId: bookId);
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteUserQuiz(quizId);
      
      // Remove from state
      state.whenData((quizzes) {
        state = AsyncValue.data(
          quizzes.where((q) => q.quizId != quizId).toList(),
        );
      });
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      rethrow;
    }
  }
}

/// Notifier for managing quiz results
class QuizResultsNotifier extends StateNotifier<AsyncValue<List<QuizResult>>> {
  QuizResultsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadResults();
  }

  final Ref ref;

  /// Load quiz results from backend
  Future<void> loadResults({String? quizId}) async {
    try {
      state = const AsyncValue.loading();
      
      final apiService = ref.read(apiServiceProvider);
      final resultsData = await apiService.getQuizResults(quizId: quizId);
      
      final results = resultsData.map((data) {
        return QuizResult.fromJson(data);
      }).toList();
      
      state = AsyncValue.data(results);
    } catch (e, stack) {
      debugPrint('Error loading quiz results: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh results
  Future<void> refresh({String? quizId}) async {
    await loadResults(quizId: quizId);
  }

  /// Submit a quiz attempt
  Future<QuizResult> submitAttempt({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    required int timeTaken,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final resultData = await apiService.submitQuizAttempt(
        quizId: quizId,
        answers: answers,
        timeTaken: timeTaken,
      );
      
      final result = QuizResult.fromJson(resultData);
      
      // Add to state
      state.whenData((results) {
        state = AsyncValue.data([result, ...results]);
      });
      
      return result;
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      rethrow;
    }
  }
}

/// Notifier for generating quizzes
class QuizGenerationNotifier extends StateNotifier<AsyncValue<QuizModel?>> {
  QuizGenerationNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Generate a quiz for a book
  Future<QuizModel> generateQuiz({
    required String bookId,
    required int startPage,
    required int endPage,
    required int questionCount,
    required String difficulty,
    String? subject,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final apiService = ref.read(apiServiceProvider);
      
      // Call the generate quiz endpoint
      final quizData = await apiService.generateQuiz(
        bookId: bookId,
        startPage: startPage,
        endPage: endPage,
        questionCount: questionCount,
        difficulty: difficulty,
        subject: subject,
      );
      
      final quiz = QuizModel.fromJson(quizData);
      state = AsyncValue.data(quiz);
      
      // Refresh the user quizzes list
      ref.read(userQuizzesProvider.notifier).refresh();
      
      return quiz;
    } catch (e, stack) {
      debugPrint('Error generating quiz: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Clear the current quiz state
  void clear() {
    state = const AsyncValue.data(null);
  }
}

