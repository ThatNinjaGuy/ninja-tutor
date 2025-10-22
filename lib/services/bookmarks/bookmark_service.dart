import '../../models/bookmark/bookmark_model.dart';
import '../api/api_service.dart';

/// Service for managing bookmarks
class BookmarkService {
  final ApiService _apiService = ApiService();
  
  // Local cache for bookmarks
  final Map<String, List<BookmarkModel>> _bookmarksCache = {};
  
  // Track ongoing requests to prevent duplicate fetches
  final Map<String, Future<List<BookmarkModel>>> _pendingRequests = {};
  
  /// Get all bookmarks for a book
  Future<List<BookmarkModel>> getBookmarksForBook(String bookId, {bool forceRefresh = false}) async {
    // Return cached bookmarks if available and not forcing refresh
    if (!forceRefresh && _bookmarksCache.containsKey(bookId)) {
      print('📚 Returning cached bookmarks for $bookId');
      return _bookmarksCache[bookId]!;
    }
    
    // If there's already a pending request for this book, return that future
    if (_pendingRequests.containsKey(bookId)) {
      print('⏳ Awaiting existing bookmark request for $bookId');
      return _pendingRequests[bookId]!;
    }
    
    // Create new request
    final request = _fetchBookmarks(bookId);
    _pendingRequests[bookId] = request;
    
    try {
      final bookmarks = await request;
      return bookmarks;
    } finally {
      // Clean up pending request
      _pendingRequests.remove(bookId);
    }
  }
  
  /// Internal method to fetch bookmarks
  Future<List<BookmarkModel>> _fetchBookmarks(String bookId) async {
    try {
      print('🔄 Fetching bookmarks from API for $bookId');
      final bookmarksJson = await _apiService.getBookmarksForBook(bookId);
      final bookmarks = bookmarksJson.map((json) => BookmarkModel.fromJson(json)).toList();
      _bookmarksCache[bookId] = bookmarks;
      print('✅ Cached ${bookmarks.length} bookmarks for $bookId');
      return bookmarks;
    } catch (e) {
      print('❌ Error fetching bookmarks: $e');
      return _bookmarksCache[bookId] ?? [];
    }
  }
  
  /// Add a bookmark to a page
  Future<BookmarkModel?> addBookmark({
    required String bookId,
    required int pageNumber,
    String? note,
  }) async {
    try {
      final bookmarkJson = await _apiService.createBookmark(
        bookId: bookId,
        pageNumber: pageNumber,
        note: note,
      );
      final bookmark = BookmarkModel.fromJson(bookmarkJson);
      
      // Update cache
      if (_bookmarksCache.containsKey(bookId)) {
        _bookmarksCache[bookId]!.add(bookmark);
        // Re-sort by page number
        _bookmarksCache[bookId]!.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      }
      
      return bookmark;
    } catch (e) {
      print('Error adding bookmark: $e');
      return null;
    }
  }
  
  /// Remove a bookmark by page number
  Future<bool> removeBookmarkByPage({
    required String bookId,
    required int pageNumber,
  }) async {
    try {
      await _apiService.deleteBookmarkByPage(bookId, pageNumber);
      
      // Update cache
      if (_bookmarksCache.containsKey(bookId)) {
        _bookmarksCache[bookId]!.removeWhere((b) => b.pageNumber == pageNumber);
      }
      
      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }
  
  /// Remove a bookmark by ID
  Future<bool> removeBookmark({
    required String bookId,
    required String bookmarkId,
  }) async {
    try {
      await _apiService.deleteBookmark(bookmarkId);
      
      // Update cache
      if (_bookmarksCache.containsKey(bookId)) {
        _bookmarksCache[bookId]!.removeWhere((b) => b.id == bookmarkId);
      }
      
      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }
  
  /// Check if a page is bookmarked
  bool isPageBookmarked(String bookId, int pageNumber) {
    if (!_bookmarksCache.containsKey(bookId)) {
      return false;
    }
    
    return _bookmarksCache[bookId]!.any((b) => b.pageNumber == pageNumber);
  }
  
  /// Get bookmark for a specific page (if exists)
  BookmarkModel? getBookmarkForPage(String bookId, int pageNumber) {
    if (!_bookmarksCache.containsKey(bookId)) {
      return null;
    }
    
    try {
      return _bookmarksCache[bookId]!.firstWhere((b) => b.pageNumber == pageNumber);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear cache for a specific book
  void clearCache(String bookId) {
    _bookmarksCache.remove(bookId);
  }
  
  /// Clear all caches
  void clearAllCaches() {
    _bookmarksCache.clear();
  }
}

