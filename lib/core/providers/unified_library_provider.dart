import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/content/book_model.dart';
import '../../services/api/api_service.dart';
import 'auth_provider.dart';
import 'app_providers.dart';

/// Unified library state that contains both all books and user's library
class LibraryState {
  const LibraryState({
    this.allBooks = const [],
    this.userLibraryBookIds = const {},
    this.userLibraryBooks = const [],
    this.searchResults = const [],
    this.isLoadingAllBooks = false,
    this.isLoadingUserLibrary = false,
    this.isSearching = false,
    this.error,
    this.isInitialized = false,
  });

  final List<BookModel> allBooks;
  final Set<String> userLibraryBookIds;
  final List<BookModel> userLibraryBooks;
  final List<BookModel> searchResults;
  final bool isLoadingAllBooks;
  final bool isLoadingUserLibrary;
  final bool isSearching;
  final String? error;
  final bool isInitialized;

  LibraryState copyWith({
    List<BookModel>? allBooks,
    Set<String>? userLibraryBookIds,
    List<BookModel>? userLibraryBooks,
    List<BookModel>? searchResults,
    bool? isLoadingAllBooks,
    bool? isLoadingUserLibrary,
    bool? isSearching,
    String? error,
    bool? isInitialized,
  }) {
    return LibraryState(
      allBooks: allBooks ?? this.allBooks,
      userLibraryBookIds: userLibraryBookIds ?? this.userLibraryBookIds,
      userLibraryBooks: userLibraryBooks ?? this.userLibraryBooks,
      searchResults: searchResults ?? this.searchResults,
      isLoadingAllBooks: isLoadingAllBooks ?? this.isLoadingAllBooks,
      isLoadingUserLibrary: isLoadingUserLibrary ?? this.isLoadingUserLibrary,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Get books to display in Explore tab (all books or search results)
  List<BookModel> get exploreBooks => searchResults.isNotEmpty ? searchResults : allBooks;

  /// Check if a book is in user's library
  bool isBookInLibrary(String bookId) => userLibraryBookIds.contains(bookId);

  /// Get user's library books with full details
  List<BookModel> get myBooks => userLibraryBooks;

  /// Check if we're currently loading anything
  bool get isLoading => isLoadingAllBooks || isLoadingUserLibrary || isSearching;
}

/// Unified library provider that manages all library-related state
final unifiedLibraryProvider = StateNotifierProvider<UnifiedLibraryNotifier, LibraryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = UnifiedLibraryNotifier(apiService);
  
  // Listen to auth changes and update token
  ref.listen<SimpleUser?>(authProvider, (previous, next) {
    if (previous?.id != next?.id) {
      // Auth changed - update token and reset initialization
      notifier.updateAuthToken(next?.token);
    }
  });
  
  // Set initial token
  final authState = ref.read(authProvider);
  notifier.updateAuthToken(authState?.token);
  
  return notifier;
});

class UnifiedLibraryNotifier extends StateNotifier<LibraryState> {
  UnifiedLibraryNotifier(this._apiService) : super(const LibraryState());

  final ApiService _apiService;
  String? _authToken;
  bool _shouldLoadOnAuth = false;

  /// Update auth token and load data if needed
  void updateAuthToken(String? token) {
    _authToken = token;
    
    if (token != null) {
      _apiService.setAuthToken(token);
      
      // If a screen requested initialization before auth was ready, load My Books now
      if (_shouldLoadOnAuth) {
        _loadUserLibrary();
        _shouldLoadOnAuth = false;
      }
    } else {
      // Auth cleared - reset state
      state = const LibraryState();
    }
  }

  /// Ensure My Books are loaded (for My Books tab)
  Future<void> ensureMyBooksLoaded() async {
    if (state.userLibraryBooks.isNotEmpty) return; // Already loaded
    
    if (_authToken == null) {
      _shouldLoadOnAuth = true;
      state = state.copyWith(isLoadingUserLibrary: true);
      return;
    }
    
    await _loadUserLibrary();
  }

  /// Ensure All Books are loaded (for Explore tab)
  Future<void> ensureAllBooksLoaded() async {
    if (state.allBooks.isNotEmpty) return; // Already loaded
    
    if (_authToken == null) {
      state = state.copyWith(isLoadingAllBooks: true);
      return;
    }
    
    await _loadAllBooks();
  }

  /// Legacy method for backward compatibility - loads My Books only
  Future<void> ensureInitialized() async {
    await ensureMyBooksLoaded();
  }

  /// Load initial data (both all books and user library) - used by refresh
  Future<void> _loadInitialData() async {
    if (_authToken == null) return;
    
    // Load both in parallel for better performance
    await Future.wait([
      _loadAllBooks(),
      _loadUserLibrary(),
    ]);
    
    // Mark as initialized
    state = state.copyWith(isInitialized: true);
  }

  /// Load all available books
  Future<void> _loadAllBooks({
    String? subject,
    String? grade,
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) return;

    try {
      state = state.copyWith(isLoadingAllBooks: true, error: null);
      
      final books = await _apiService.getBooks(
        subject: subject,
        grade: grade,
        page: page,
        limit: limit,
      );
      
      state = state.copyWith(
        allBooks: books,
        isLoadingAllBooks: false,
      );
    } catch (e, stackTrace) {
      // Don't set error state for auth errors - dialog will handle it
      if (e is ApiException && e.isAuthError) {
        state = state.copyWith(isLoadingAllBooks: false);
      } else {
        state = state.copyWith(
          isLoadingAllBooks: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Load user's library (both IDs and full book details)
  Future<void> _loadUserLibrary() async {
    if (_authToken == null) return;

    try {
      state = state.copyWith(isLoadingUserLibrary: true, error: null);
      
      final libraryData = await _apiService.getUserLibrary();
      
      // Extract book IDs and convert to BookModel objects
      final bookIds = libraryData.map((data) => data['book_id'] as String).toSet();
      final userBooks = libraryData.map((data) {
        final bookData = data['book'] as Map<String, dynamic>;
        return BookModel.fromJson(bookData);
      }).toList();
      
      state = state.copyWith(
        userLibraryBookIds: bookIds,
        userLibraryBooks: userBooks,
        isLoadingUserLibrary: false,
      );
    } catch (e, stackTrace) {
      // Don't set error state for auth errors - dialog will handle it
      if (e is ApiException && e.isAuthError) {
        state = state.copyWith(isLoadingUserLibrary: false);
      } else {
        state = state.copyWith(
          isLoadingUserLibrary: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Search books
  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    try {
      state = state.copyWith(isSearching: true, error: null);
      
      final results = await _apiService.searchBooks(query);
      
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e, stackTrace) {
      // Don't set error state for auth errors - dialog will handle it
      if (e is ApiException && e.isAuthError) {
        state = state.copyWith(isSearching: false);
      } else {
        state = state.copyWith(
          isSearching: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  /// Add book to user's library
  Future<bool> addBookToLibrary(String bookId) async {
    if (_authToken == null) return false;

    try {
      await _apiService.addBookToLibrary(bookId);
      
      // Update local state immediately for better UX
      final updatedIds = Set<String>.from(state.userLibraryBookIds)..add(bookId);
      
      // Find the book in all books and add to user library books
      final book = state.allBooks.firstWhere((b) => b.id == bookId);
      final updatedUserBooks = [...state.userLibraryBooks, book];
      
      state = state.copyWith(
        userLibraryBookIds: updatedIds,
        userLibraryBooks: updatedUserBooks,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error adding book to library: $e');
      // Auth errors are handled by interceptor - just return false
      if (e is ApiException && e.isAuthError) {
        return false;
      }
      return false;
    }
  }

  /// Remove book from user's library
  Future<bool> removeBookFromLibrary(String bookId) async {
    if (_authToken == null) return false;

    try {
      await _apiService.removeBookFromLibrary(bookId);
      
      // Update local state immediately for better UX
      final updatedIds = Set<String>.from(state.userLibraryBookIds)..remove(bookId);
      final updatedUserBooks = state.userLibraryBooks.where((b) => b.id != bookId).toList();
      
      state = state.copyWith(
        userLibraryBookIds: updatedIds,
        userLibraryBooks: updatedUserBooks,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error removing book from library: $e');
      // Auth errors are handled by interceptor - just return false
      if (e is ApiException && e.isAuthError) {
        return false;
      }
      return false;
    }
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

  /// Refresh with filters
  Future<void> refreshWithFilters({
    String? subject,
    String? grade,
  }) async {
    await _loadAllBooks(subject: subject, grade: grade);
  }

  /// Filter books locally (for quick filtering without API calls)
  List<BookModel> filterBooks({
    required List<BookModel> books,
    String? searchQuery,
    String? subject,
    String? grade,
  }) {
    var filtered = books;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               book.subject.toLowerCase().contains(query) ||
               (book.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (subject != null && subject != 'All') {
      filtered = filtered.where((book) => book.subject == subject).toList();
    }

    if (grade != null && grade != 'All') {
      filtered = filtered.where((book) => book.grade == grade).toList();
    }

    return filtered;
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
      final currentBooks = state.allBooks;
      state = state.copyWith(allBooks: [book, ...currentBooks]);
      
      return book;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    state = state.copyWith(isInitialized: false);
    await _loadInitialData();
  }
}
