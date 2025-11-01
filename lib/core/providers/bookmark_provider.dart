import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark/bookmark_model.dart';
import '../../services/bookmarks/bookmark_service.dart';

/// State class for bookmarks
class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? error;
  final String? currentBookId;
  
  const BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
    this.currentBookId,
  });
  
  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    bool? isLoading,
    String? error,
    String? currentBookId,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentBookId: currentBookId ?? this.currentBookId,
    );
  }
  
  /// Get bookmarked page numbers
  Set<int> get bookmarkedPages {
    return bookmarks.map((b) => b.pageNumber).toSet();
  }
  
  /// Check if a page is bookmarked
  bool isPageBookmarked(int pageNumber) {
    return bookmarks.any((b) => b.pageNumber == pageNumber);
  }
  
  /// Get bookmark for a specific page
  BookmarkModel? getBookmarkForPage(int pageNumber) {
    try {
      return bookmarks.firstWhere((b) => b.pageNumber == pageNumber);
    } catch (e) {
      return null;
    }
  }
}

/// Notifier for bookmark state management
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkService _bookmarkService = BookmarkService();
  
  BookmarkNotifier() : super(const BookmarkState());
  
  /// Load bookmarks for a book
  Future<void> loadBookmarks(String bookId, {bool forceRefresh = false}) async {
    // Don't reload if already loaded for this book (unless forced)
    if (!forceRefresh && state.currentBookId == bookId && state.bookmarks.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, currentBookId: bookId);
    
    try {
      final bookmarks = await _bookmarkService.getBookmarksForBook(bookId, forceRefresh: forceRefresh);
      state = state.copyWith(
        bookmarks: bookmarks,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Toggle bookmark for a page
  Future<bool> toggleBookmark(String bookId, int pageNumber) async {
    // Prevent double-clicks by checking loading state
    if (state.isLoading) {
      return false;
    }
    
    final isBookmarked = state.isPageBookmarked(pageNumber);
    print('🔄 toggleBookmark: page=$pageNumber, isBookmarked=$isBookmarked');
    
    // Set loading state
    state = state.copyWith(isLoading: true);
    
    try {
      if (isBookmarked) {
        print('🗑️ Removing bookmark for page $pageNumber');
        // Remove bookmark by page number
        final success = await _bookmarkService.removeBookmarkByPage(
          bookId: bookId,
          pageNumber: pageNumber,
        );
        
        if (success) {
          // Update state
          final updatedBookmarks = List<BookmarkModel>.from(state.bookmarks)
            ..removeWhere((b) => b.pageNumber == pageNumber);
          state = state.copyWith(bookmarks: updatedBookmarks, isLoading: false);
          return true;
        }
        print('❌ Failed to remove bookmark');
        state = state.copyWith(isLoading: false);
        return false;
      } else {
        // Check if bookmark already exists (frontend validation)
        if (state.bookmarks.any((b) => b.pageNumber == pageNumber)) {
          print('⚠️ Bookmark already exists for page $pageNumber in state');
          state = state.copyWith(isLoading: false);
          return false;
        }
        
        print('➕ Adding bookmark for page $pageNumber');
        // Add bookmark
        final bookmark = await _bookmarkService.addBookmark(
          bookId: bookId,
          pageNumber: pageNumber,
        );
        
        if (bookmark != null) {
          // Check again before adding to prevent race condition
          if (state.bookmarks.any((b) => b.pageNumber == pageNumber)) {
            print('⚠️ Bookmark already in state, skipping add');
            state = state.copyWith(isLoading: false);
            return true; // Return true because bookmark exists
          }
          
          // Update state
          final updatedBookmarks = List<BookmarkModel>.from(state.bookmarks)..add(bookmark);
          // Sort by page number
          updatedBookmarks.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
          state = state.copyWith(bookmarks: updatedBookmarks, isLoading: false);
          return true;
        }
        print('❌ Failed to create bookmark');
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      print('❌ Error in toggleBookmark: $e');
      // If backend returns error about duplicate, reload bookmarks to sync state
      if (e.toString().contains('already exists')) {
        print('🔄 Reloading bookmarks due to duplicate error');
        await loadBookmarks(bookId, forceRefresh: true);
      }
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
  
  /// Clear bookmarks (when changing books)
  void clear() {
    state = const BookmarkState();
  }
}

/// Provider for bookmark state
final bookmarkProvider = StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier();
});

