import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/api_service.dart';
import 'auth_provider.dart';
import 'app_providers.dart';

/// Provider for managing user's personal library
final userLibraryProvider = StateNotifierProvider<UserLibraryNotifier, AsyncValue<Set<String>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authProvider);
  return UserLibraryNotifier(apiService, authState?.token);
});

/// Provider for checking if a specific book is in user's library
final bookInLibraryProvider = FutureProvider.family<bool, String>((ref, bookId) async {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState?.token == null) return false;
  
  try {
    final result = await apiService.checkBookInLibrary(bookId);
    return result['in_library'] ?? false;
  } catch (e) {
    return false;
  }
});

class UserLibraryNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  UserLibraryNotifier(this._apiService, this._authToken) : super(const AsyncValue.loading()) {
    if (_authToken != null) {
      _loadUserLibrary();
    } else {
      state = const AsyncValue.data({});
    }
  }

  final ApiService _apiService;
  final String? _authToken;

  /// Load user's library book IDs
  Future<void> _loadUserLibrary() async {
    if (_authToken == null) {
      state = const AsyncValue.data({});
      return;
    }

    try {
      state = const AsyncValue.loading();
      final libraryBooks = await _apiService.getUserLibrary();
      final bookIds = libraryBooks.map((book) => book['book_id'] as String).toSet();
      state = AsyncValue.data(bookIds);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Add a book to user's library
  Future<bool> addBookToLibrary(String bookId) async {
    if (_authToken == null) return false;

    try {
      await _apiService.addBookToLibrary(bookId);
      
      // Update local state
      state.whenData((bookIds) {
        final updatedIds = Set<String>.from(bookIds)..add(bookId);
        state = AsyncValue.data(updatedIds);
      });
      
      return true;
    } catch (e) {
      // Handle error (could show snackbar here)
      return false;
    }
  }

  /// Remove a book from user's library
  Future<bool> removeBookFromLibrary(String bookId) async {
    if (_authToken == null) return false;

    try {
      await _apiService.removeBookFromLibrary(bookId);
      
      // Update local state
      state.whenData((bookIds) {
        final updatedIds = Set<String>.from(bookIds)..remove(bookId);
        state = AsyncValue.data(updatedIds);
      });
      
      return true;
    } catch (e) {
      // Handle error (could show snackbar here)
      return false;
    }
  }

  /// Check if a book is in user's library
  bool isBookInLibrary(String bookId) {
    return state.maybeWhen(
      data: (bookIds) => bookIds.contains(bookId),
      orElse: () => false,
    );
  }

  /// Update reading progress for a book
  Future<void> updateReadingProgress({
    required String bookId,
    required int currentPage,
    required double progressPercentage,
  }) async {
    if (_authToken == null) return;

    try {
      await _apiService.updateReadingProgress(
        bookId: bookId,
        currentPage: currentPage,
        totalPages: null, // Will be calculated on backend
        readingStatus: progressPercentage >= 1.0 ? 'completed' : 'in_progress',
      );
    } catch (e) {
      // Handle error silently for now
      // In a real app, you might want to show a snackbar or retry
    }
  }

  /// Refresh library data
  Future<void> refresh() async {
    await _loadUserLibrary();
  }
}

/// Provider for getting user's library books with full details
final userLibraryBooksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authProvider);
  
  // Watch the userLibraryProvider to invalidate when library changes
  ref.watch(userLibraryProvider);
  
  if (authState?.token == null) {
    return [];
  }

  // Set the auth token if available
  if (authState?.token != null) {
    apiService.setAuthToken(authState!.token!);
  }
  
  try {
    final libraryData = await apiService.getUserLibrary();
    return libraryData;
  } catch (e) {
    // Log the error for debugging
    debugPrint('Error loading user library: $e');
    return [];
  }
});
