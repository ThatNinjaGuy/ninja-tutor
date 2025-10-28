import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../models/content/book_model.dart';
import '../../models/quiz/quiz_model.dart' as quiz;
import '../../models/note/note_model.dart';

/// API service for network requests and AI integrations
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  String? _authToken;
  
  /// Callback for authentication errors (401/403)
  Function(ApiException)? onAuthError;

  ApiService._internal() {
    _initializeDio();
  }

  /// Initialize Dio with base configuration
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}/${AppConstants.apiVersion}',
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
      },
    ));

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      if (kDebugMode) LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
      _ErrorInterceptor(),
    ]);
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Authentication endpoints

  /// User login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// User registration
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // User endpoints

  /// Sync Firebase user with backend
  Future<Map<String, dynamic>> syncUser({String? classGrade}) async {
    try {
      final response = await _dio.post('/auth/sync-user', data: {
        if (classGrade != null) 'class_grade': classGrade,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/auth/profile', data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Book endpoints

  /// Get books library
  Future<List<BookModel>> getBooks({
    String? subject,
    String? grade,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/books', queryParameters: {
        if (subject != null) 'subject': subject,
        if (grade != null) 'grade': grade,
        'offset': (page - 1) * limit,
        'limit': limit,
      });

      final books = <BookModel>[];
      for (final bookJson in response.data) {
        books.add(BookModel.fromJson(bookJson));
      }
      return books;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get book details
  Future<BookModel> getBook(String bookId) async {
    try {
      final response = await _dio.get('/books/$bookId');
      return BookModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload book file
  Future<BookModel> uploadBook(File file, Map<String, dynamic> metadata) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'title': metadata['title'] ?? 'Unknown',
        'author': metadata['author'] ?? 'Unknown',
        'subject': metadata['subject'] ?? 'General',
        'grade': metadata['grade'] ?? 'General',
        'description': metadata['description'],
        'tags': metadata['tags'] ?? '',
      });

      final response = await _dio.post('/books/upload', data: formData);
      return BookModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload book from bytes (for web compatibility)
  Future<BookModel> uploadBookFromBytes(
    List<int> bytes, 
    String fileName, 
    Map<String, dynamic> metadata
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        'title': metadata['title'] ?? 'Unknown',
        'author': metadata['author'] ?? 'Unknown',
        'subject': metadata['subject'] ?? 'General',
        'grade': metadata['grade'] ?? 'General',
        'description': metadata['description'],
        'tags': metadata['tags'] ?? '',
      });

      final response = await _dio.post('/books/upload', data: formData);
      return BookModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Search books
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await _dio.get('/books/search', queryParameters: {
        'q': query,
      });

      final books = <BookModel>[];
      for (final bookJson in response.data) {
        books.add(BookModel.fromJson(bookJson));
      }
      return books;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // AI endpoints

  /// Get AI-powered definition for selected text
  Future<Map<String, dynamic>> getDefinition(String text, String context) async {
    try {
      final response = await _dio.post('/ai/definition', data: {
        'text': text,
        'context': context,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get AI explanation for concept
  Future<Map<String, dynamic>> getExplanation(String concept, String context) async {
    try {
      final response = await _dio.post('/ai/explanation', data: {
        'concept': concept,
        'context': context,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Generate practice questions
  Future<List<quiz.QuestionModel>> generateQuestions({
    required String bookId,
    required List<int> pageRange,
    required int count,
    DifficultyLevel? difficulty,
  }) async {
    try {
      final response = await _dio.post('/ai/generate-questions', data: {
        'book_id': bookId,
        'page_range': pageRange,
        'count': count,
        if (difficulty != null) 'difficulty': difficulty.name,
      });

      final questions = <quiz.QuestionModel>[];
      for (final questionJson in response.data['questions']) {
        questions.add(quiz.QuestionModel.fromJson(questionJson));
      }
      return questions;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Generate quiz from content
  Future<Map<String, dynamic>> generateQuiz({
    required String bookId,
    required int startPage,
    required int endPage,
    required int questionCount,
    required String difficulty,
    String? subject,
    List<String>? questionTypes,
  }) async {
    try {
      final response = await _dio.post('/quizzes/generate', data: {
        'book_id': bookId,
        'page_range': [startPage, endPage],
        'question_count': questionCount,
        'difficulty': difficulty,
        if (subject != null) 'subject': subject,
        'question_types': questionTypes ?? ['multipleChoice'],
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get AI insights for note
  Future<AiInsights> getAiInsights(String noteContent, String bookContext) async {
    try {
      final response = await _dio.post('/ai/insights', data: {
        'note_content': noteContent,
        'book_context': bookContext,
      });
      return AiInsights.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Analyze reading comprehension
  Future<Map<String, dynamic>> analyzeComprehension({
    required String bookId,
    required int pageNumber,
    required int timeSpent,
    required List<String> interactions,
  }) async {
    try {
      final response = await _dio.post('/ai/comprehension', data: {
        'book_id': bookId,
        'page_number': pageNumber,
        'time_spent': timeSpent,
        'interactions': interactions,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Quiz endpoints

  /// Get quiz
  Future<quiz.QuizModel> getQuiz(String quizId) async {
    try {
      final response = await _dio.get('/quizzes/$quizId');
      return quiz.QuizModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get attempt detail for review
  Future<Map<String, dynamic>> getAttemptDetail(String quizId, int attemptNumber) async {
    try {
      final response = await _dio.get('/user-quiz/attempt/$quizId/$attemptNumber');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submit quiz answers
  Future<quiz.QuizResult> submitQuiz(String quizId, List<quiz.QuestionResult> answers) async {
    try {
      final response = await _dio.post('/quizzes/$quizId/submit', data: {
        'answers': answers.map((a) => a.toJson()).toList(),
      });
      return quiz.QuizResult.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get quiz statistics
  Future<Map<String, dynamic>> getQuizStats(String userId) async {
    try {
      final response = await _dio.get('/quizzes/stats/$userId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Progress endpoints

  /// Sync reading progress
  Future<void> syncReadingProgress(List<ReadingProgress> progressList) async {
    try {
      await _dio.post('/progress/sync', data: {
        'progress': progressList.map((p) => p.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get progress analytics
  Future<Map<String, dynamic>> getProgressAnalytics(String userId) async {
    try {
      final response = await _dio.get('/progress/analytics/$userId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Notes endpoints

  /// Sync notes to cloud
  Future<void> syncNotes(List<NoteModel> notes) async {
    try {
      await _dio.post('/notes/sync', data: {
        'notes': notes.map((n) => n.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get shared notes
  Future<List<NoteModel>> getSharedNotes(String bookId) async {
    try {
      final response = await _dio.get('/notes/shared/$bookId');
      
      final notes = <NoteModel>[];
      for (final noteJson in response.data) {
        notes.add(NoteModel.fromJson(noteJson));
      }
      return notes;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // User Library Management Methods

  /// Add a book to user's personal library
  Future<Map<String, dynamic>> addBookToLibrary(String bookId) async {
    try {
      final response = await _dio.post('/library/add-book', data: {'book_id': bookId});
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Remove a book from user's personal library
  Future<Map<String, dynamic>> removeBookFromLibrary(String bookId) async {
    try {
      final response = await _dio.delete('/library/remove-book/$bookId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user's personal library with reading progress
  Future<List<Map<String, dynamic>>> getUserLibrary({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : <String, dynamic>{};
      final response = await _dio.get('/library/my-books', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update reading progress for a book
  Future<Map<String, dynamic>> updateReadingProgress({
    required String bookId,
    required int currentPage,
    int? totalPages,
    String? readingStatus,
    String? notes,
    Map<String, int>? pageTimes,
  }) async {
    try {
      final data = <String, dynamic>{
        'book_id': bookId,
        'current_page': currentPage,
      };
      
      if (totalPages != null) data['total_pages'] = totalPages;
      if (readingStatus != null) data['reading_status'] = readingStatus;
      if (notes != null) data['notes'] = notes;
      if (pageTimes != null && pageTimes.isNotEmpty) data['page_times'] = pageTimes;

      print('🌐 API Request to /library/update-progress:');
      print('   Data: $data');

      final response = await _dio.put('/library/update-progress', data: data);
      
      print('🌐 API Response:');
      print('   ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Check if a book is in user's library
  Future<Map<String, dynamic>> checkBookInLibrary(String bookId) async {
    try {
      final response = await _dio.get('/library/check-book/$bookId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // User Preferences endpoints

  /// Update user app preferences
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.put('/auth/preferences', data: preferences);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update user reading preferences
  Future<Map<String, dynamic>> updateReadingPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.put('/auth/reading-preferences', data: preferences);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload user avatar
  Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post('/auth/upload-avatar', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Quiz endpoints

  /// Get user's quiz collection
  Future<List<Map<String, dynamic>>> getUserQuizzes({String? bookId}) async {
    try {
      final queryParams = bookId != null ? {'book_id': bookId} : <String, dynamic>{};
      final response = await _dio.get('/user-quiz/my-quizzes', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submit quiz attempt
  Future<Map<String, dynamic>> submitQuizAttempt({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    required int timeTaken,
  }) async {
    try {
      final response = await _dio.post('/user-quiz/submit-attempt', data: {
        'quiz_id': quizId,
        'answers': answers,
        'time_taken': timeTaken,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get quiz results
  Future<List<Map<String, dynamic>>> getQuizResults({String? quizId}) async {
    try {
      final queryParams = quizId != null ? {'quiz_id': quizId} : <String, dynamic>{};
      final response = await _dio.get('/user-quiz/results', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete quiz from user's collection
  Future<void> deleteUserQuiz(String quizId) async {
    try {
      await _dio.delete('/user-quiz/$quizId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Dashboard endpoints

  /// Get dashboard overview data
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _dio.get('/dashboard/overview');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get practice suggestions
  Future<Map<String, dynamic>> getPracticeSuggestions() async {
    try {
      final response = await _dio.get('/dashboard/practice-suggestions');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get reading analytics for a book
  Future<Map<String, dynamic>> getReadingAnalytics(String bookId) async {
    try {
      final response = await _dio.get('/dashboard/reading-analytics/$bookId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Enhanced AI endpoints

  /// Get AI-powered definition
  Future<Map<String, dynamic>> getAiDefinition(
    String text,
    String context, {
    String? bookId,
    int? pageNumber,
  }) async {
    try {
      final response = await _dio.post('/ai/definition', data: {
        'text': text,
        'context': context,
        if (bookId != null) 'book_id': bookId,
        if (pageNumber != null) 'page_number': pageNumber,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get AI explanation
  Future<Map<String, dynamic>> getAiExplanation(
    String concept,
    String context, {
    String? bookId,
  }) async {
    try {
      final response = await _dio.post('/ai/explanation', data: {
        'concept': concept,
        'context': context,
        if (bookId != null) 'book_id': bookId,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get contextual study tips
  Future<Map<String, dynamic>> getStudyTips(String bookId, int currentPage) async {
    try {
      final response = await _dio.post(
        '/ai/study-tips',
        queryParameters: {
          'book_id': bookId,
          'current_page': currentPage,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Reading Intelligence endpoints

  /// Ask a question about reading content
  Future<Map<String, dynamic>> askReadingQuestion({
    required String question,
    required String bookId,
    required int currentPage,
    String? selectedText,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final response = await _dio.post('/ai/reading/ask', data: {
        'question': question,
        'book_id': bookId,
        'current_page': currentPage,
        if (selectedText != null) 'selected_text': selectedText,
        'conversation_history': conversationHistory ?? [],
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }


  /// Get content for a specific page
  Future<Map<String, dynamic>> getPageContent(String bookId, int pageNumber) async {
    try {
      final response = await _dio.get('/ai/reading/page-content/$bookId/$pageNumber');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Enhanced Notes endpoints

  /// Get all notes for current user
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      final response = await _dio.get('/notes/all');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get favorite notes
  Future<List<Map<String, dynamic>>> getFavoriteNotes() async {
    try {
      final response = await _dio.get('/notes/favorites');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Toggle note favorite status
  Future<Map<String, dynamic>> toggleNoteFavorite(String noteId) async {
    try {
      final response = await _dio.put('/notes/$noteId/favorite');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Bookmark-specific endpoints

  /// Get all bookmarks for a book
  Future<List<Map<String, dynamic>>> getBookmarksForBook(String bookId) async {
    try {
      final response = await _dio.get('/bookmarks/book/$bookId');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a bookmark for a specific page
  Future<Map<String, dynamic>> createBookmark({
    required String bookId,
    required int pageNumber,
    String? note,
  }) async {
    try {
      final response = await _dio.post('/bookmarks', data: {
        'book_id': bookId,
        'page_number': pageNumber,
        if (note != null) 'note': note,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete a bookmark by ID
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _dio.delete('/bookmarks/$bookmarkId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete a bookmark by page number
  Future<void> deleteBookmarkByPage(String bookId, int pageNumber) async {
    try {
      await _dio.delete('/bookmarks/book/$bookId/page/$pageNumber');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get bookmark for a specific page
  Future<Map<String, dynamic>?> getBookmarkForPage(String bookId, int pageNumber) async {
    try {
      final response = await _dio.get('/bookmarks/book/$bookId/page/$pageNumber');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No bookmark found
      }
      throw ApiException.fromDioError(e);
    }
  }

  // Note-specific endpoints

  /// Get notes for a specific page
  Future<List<NoteModel>> getNotesForPage(String bookId, int pageNumber) async {
    try {
      final response = await _dio.get('/notes/book/$bookId/page/$pageNumber/notes');
      
      final notes = <NoteModel>[];
      for (final noteJson in response.data) {
        notes.add(NoteModel.fromJson(noteJson));
      }
      return notes;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a note on a specific page
  Future<NoteModel> createNote({
    required String bookId,
    required int pageNumber,
    required String content,
    String? title,
    String? selectedText,
  }) async {
    try {
      final response = await _dio.post('/notes', data: {
        'book_id': bookId,
        'type': 'text',
        'content': content,
        'title': title,
        'selected_text': selectedText, // Send selected text from PDF
        'position': {
          'page': pageNumber,
          'x': 0.0,
          'y': 0.0,
        },
      });
      
      // Transform snake_case response to camelCase for NoteModel
      final data = response.data as Map<String, dynamic>;
      final transformedData = {
        'id': data['id'],
        'bookId': data['book_id'],
        'pageNumber': data['position']['page'],
        'type': data['type'],
        'content': data['content'],
        'title': data['title'],
        'tags': data['tags'] ?? [],
        'createdAt': data['created_at'],
        'updatedAt': data['updated_at'] ?? data['created_at'],
        'position': data['position'],
        'style': data['style'] ?? {
          'color': '#2196F3',
          'opacity': 1.0,
          'fontSize': 14.0,
          'fontFamily': 'Inter',
          'isBold': false,
          'isItalic': false,
        },
        'isFavorite': data['is_favorite'] ?? false,
        'linkedText': data['linked_text'],
        'aiInsights': data['ai_insights'],
        'selectedText': data['selected_text'],
      };
      
      return NoteModel.fromJson(transformedData);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all notes for a book
  Future<List<NoteModel>> getNotesForBook(String bookId) async {
    try {
      final response = await _dio.get('/notes/book/$bookId');
      
      final notes = <NoteModel>[];
      for (final noteData in response.data) {
        // Transform snake_case response to camelCase for NoteModel
        final transformedData = {
          'id': noteData['id'],
          'bookId': noteData['book_id'],
          'pageNumber': noteData['position']['page'],
          'type': noteData['type'],
          'content': noteData['content'],
          'title': noteData['title'],
          'tags': noteData['tags'] ?? [],
          'createdAt': noteData['created_at'],
          'updatedAt': noteData['updated_at'] ?? noteData['created_at'],
          'position': noteData['position'],
          'style': noteData['style'] ?? {
            'color': '#2196F3',
            'opacity': 1.0,
            'fontSize': 14.0,
            'fontFamily': 'Inter',
            'isBold': false,
            'isItalic': false,
          },
          'isFavorite': noteData['is_favorite'] ?? false,
          'linkedText': noteData['linked_text'],
          'aiInsights': noteData['ai_insights'],
          'selected_text': noteData['selected_text'], // Use snake_case key for JSON parsing
        };
        notes.add(NoteModel.fromJson(transformedData));
      }
      return notes;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update a note
  Future<NoteModel> updateNote({
    required String noteId,
    required String content,
    String? title,
  }) async {
    try {
      final response = await _dio.put('/notes/$noteId', data: {
        'content': content,
        'title': title,
      });
      
      // Transform snake_case response to camelCase for NoteModel
      final data = response.data as Map<String, dynamic>;
      final transformedData = {
        'id': data['id'],
        'bookId': data['book_id'],
        'pageNumber': data['position']['page'],
        'type': data['type'],
        'content': data['content'],
        'title': data['title'],
        'tags': data['tags'] ?? [],
        'createdAt': data['created_at'],
        'updatedAt': data['updated_at'] ?? data['created_at'],
        'position': data['position'],
        'style': data['style'] ?? {
          'color': '#2196F3',
          'opacity': 1.0,
          'fontSize': 14.0,
          'fontFamily': 'Inter',
          'isBold': false,
          'isItalic': false,
        },
        'isFavorite': data['is_favorite'] ?? false,
        'linkedText': data['linked_text'],
        'aiInsights': data['ai_insights'],
        'selectedText': data['selected_text'],
      };
      
      return NoteModel.fromJson(transformedData);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _dio.delete('/notes/$noteId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all notes for current user across all books
  Future<List<NoteModel>> getAllUserNotes() async {
    try {
      final response = await _dio.get('/notes/all');
      
      final notes = <NoteModel>[];
      for (final noteData in response.data) {
        // Transform snake_case response to camelCase for NoteModel
        // Same transformation as getNotesForBook
        final transformedData = {
          'id': noteData['id'],
          'bookId': noteData['book_id'],
          'pageNumber': noteData['position']?['page'] ?? 0,
          'type': noteData['type'],
          'content': noteData['content'],
          'title': noteData['title'],
          'tags': noteData['tags'] ?? [],
          'createdAt': noteData['created_at'],
          'updatedAt': noteData['updated_at'] ?? noteData['created_at'],
          'position': noteData['position'] ?? {
            'x': 0.0,
            'y': 0.0,
          },
          'style': noteData['style'] ?? {
            'color': '#2196F3',
            'opacity': 1.0,
            'fontSize': 14.0,
            'fontFamily': 'Inter',
            'isBold': false,
            'isItalic': false,
          },
          'isFavorite': noteData['is_favorite'] ?? false,
          'linkedText': noteData['linked_text'],
          'aiInsights': noteData['ai_insights'],
          'selected_text': noteData['selected_text'], // Use snake_case key for JSON parsing
        };
        notes.add(NoteModel.fromJson(transformedData));
      }
      return notes;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all bookmarks for current user across all books
  Future<List<Map<String, dynamic>>> getAllUserBookmarks() async {
    try {
      final response = await _dio.get('/bookmarks/all');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Authentication interceptor
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._apiService);

  final ApiService _apiService;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Get current Firebase user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    
    if (firebaseUser != null) {
      try {
        // Get fresh ID token (Firebase SDK caches and auto-refreshes if expired)
        final token = await firebaseUser.getIdToken(false); // Don't force refresh every time
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          _apiService.setAuthToken(token);
        }
      } catch (e) {
        debugPrint('Error getting Firebase token: $e');
      }
    }
    
    super.onRequest(options, handler);
  }
}

/// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('API Error: ${err.message}');
    
    // Check for authentication errors (401/403)
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      final apiException = ApiException.fromDioError(err);
      
      // Trigger auth error callback if set
      final apiService = ApiService();
      if (apiService.onAuthError != null) {
        apiService.onAuthError!(apiException);
      }
    }
    
    super.onError(err, handler);
  }
}

/// API exception class
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException dioError) {
    String message;
    int? statusCode;
    
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        statusCode = null;
        break;
      case DioExceptionType.badResponse:
        statusCode = dioError.response?.statusCode;
        message = _getErrorMessage(dioError.response?.data) ?? 
                 'Server error (${statusCode ?? 'Unknown'})';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        statusCode = null;
        break;
      case DioExceptionType.unknown:
        statusCode = null;
        if (dioError.error is SocketException) {
          message = 'No internet connection';
        } else {
          message = 'An unexpected error occurred';
        }
        break;
      default:
        message = 'An error occurred';
        statusCode = null;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: dioError.response?.data,
    );
  }

  static String? _getErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['error'] ?? data['detail'];
    }
    return null;
  }

  final String message;
  final int? statusCode;
  final dynamic data;

  /// Check if this is an authentication error (401 or 403)
  bool get isAuthError => isUnauthorized || isForbidden;
  
  /// Check if this is a 401 Unauthorized error
  bool get isUnauthorized => statusCode == 401;
  
  /// Check if this is a 403 Forbidden error
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException: $message';
}
