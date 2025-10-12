import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  Future<quiz.QuizModel> generateQuiz(String bookId, List<int> pageRange) async {
    try {
      final response = await _dio.post('/quizzes/generate', data: {
        'book_id': bookId,
        'page_range': pageRange,
        'question_count': 10,
        'difficulty': 'medium',
        'question_types': ['multiple_choice'],
      });
      return quiz.QuizModel.fromJson(response.data);
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
  }) async {
    try {
      final data = <String, dynamic>{
        'book_id': bookId,
        'current_page': currentPage,
      };
      
      if (totalPages != null) data['total_pages'] = totalPages;
      if (readingStatus != null) data['reading_status'] = readingStatus;
      if (notes != null) data['notes'] = notes;

      final response = await _dio.put('/library/update-progress', data: data);
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
}

/// Authentication interceptor
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._apiService);

  final ApiService _apiService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiService._authToken != null) {
      options.headers['Authorization'] = 'Bearer ${_apiService._authToken}';
    }
    // Always add ngrok header to skip browser warning
    // options.headers['ngrok-skip-browser-warning'] = 'true';
    super.onRequest(options, handler);
  }
}

/// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('API Error: ${err.message}');
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
        break;
      case DioExceptionType.badResponse:
        statusCode = dioError.response?.statusCode;
        message = _getErrorMessage(dioError.response?.data) ?? 
                 'Server error (${statusCode ?? 'Unknown'})';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.unknown:
        if (dioError.error is SocketException) {
          message = 'No internet connection';
        } else {
          message = 'An unexpected error occurred';
        }
        break;
      default:
        message = 'An error occurred';
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

  @override
  String toString() => 'ApiException: $message';
}
