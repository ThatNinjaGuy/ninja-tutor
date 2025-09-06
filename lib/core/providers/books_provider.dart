import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/content/book_model.dart';
import '../../services/api/api_service.dart';
import 'auth_provider.dart';
import 'app_providers.dart';

/// API-integrated books provider for real backend integration
final booksApiProvider = StateNotifierProvider<BooksApiNotifier, AsyncValue<List<BookModel>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authProvider);
  return BooksApiNotifier(apiService, authState?.token);
});

/// Search results provider
final bookSearchProvider = StateNotifierProvider<BookSearchNotifier, AsyncValue<List<BookModel>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BookSearchNotifier(apiService);
});

/// Upload progress provider
final uploadProgressProvider = StateProvider<double?>((ref) => null);

class BooksApiNotifier extends StateNotifier<AsyncValue<List<BookModel>>> {
  BooksApiNotifier(this._apiService, this._authToken) : super(const AsyncValue.loading()) {
    if (_authToken != null) {
      _apiService.setAuthToken(_authToken!);
      loadBooks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final ApiService _apiService;
  final String? _authToken;

  /// Load books from the backend
  Future<void> loadBooks({
    String? subject,
    String? grade,
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final books = await _apiService.getBooks(
        subject: subject,
        grade: grade,
        page: page,
        limit: limit,
      );
      state = AsyncValue.data(books);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Upload a new book from file
  Future<BookModel?> uploadBook(File file, Map<String, dynamic> metadata) async {
    if (_authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final book = await _apiService.uploadBook(file, metadata);
      
      // Add the new book to the current list
      final currentBooks = state.value ?? [];
      state = AsyncValue.data([book, ...currentBooks]);
      
      return book;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload a new book from bytes (web-compatible)
  Future<BookModel?> uploadBookFromBytes(
    List<int> bytes, 
    String fileName, 
    Map<String, dynamic> metadata
  ) async {
    if (_authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final book = await _apiService.uploadBookFromBytes(bytes, fileName, metadata);
      
      // Add the new book to the current list
      final currentBooks = state.value ?? [];
      state = AsyncValue.data([book, ...currentBooks]);
      
      return book;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh the books list
  Future<void> refresh() async {
    await loadBooks();
  }

  /// Filter books locally (for quick filtering without API calls)
  List<BookModel> filterBooks({
    String? searchQuery,
    String? subject,
    String? grade,
  }) {
    final books = state.value ?? [];
    var filtered = books;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((book) =>
          book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(searchQuery.toLowerCase()) ||
          book.subject.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (subject != null) {
      filtered = filtered.where((book) => book.subject == subject).toList();
    }

    if (grade != null) {
      filtered = filtered.where((book) => book.grade == grade).toList();
    }

    return filtered;
  }
}

class BookSearchNotifier extends StateNotifier<AsyncValue<List<BookModel>>> {
  BookSearchNotifier(this._apiService) : super(const AsyncValue.data([]));

  final ApiService _apiService;

  /// Search books using the backend API
  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final results = await _apiService.searchBooks(query);
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clear search results
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}
