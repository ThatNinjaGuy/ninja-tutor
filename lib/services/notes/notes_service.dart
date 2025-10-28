import '../../models/note/note_model.dart';
import '../api/api_service.dart';

/// Service for managing notes
class NotesService {
  final ApiService _apiService = ApiService();
  
  // Local cache for notes
  final Map<String, List<NoteModel>> _notesCache = {};
  final Map<String, Map<int, List<NoteModel>>> _pageNotesCache = {};
  
  /// Get all notes for a book
  Future<List<NoteModel>> getNotesForBook(String bookId, {bool forceRefresh = false}) async {
    // Return cached notes if available and not forcing refresh
    if (!forceRefresh && _notesCache.containsKey(bookId)) {
      return _notesCache[bookId]!;
    }
    
    try {
      final notes = await _apiService.getNotesForBook(bookId);
      _notesCache[bookId] = notes;
      
      // Also populate page cache
      _pageNotesCache[bookId] = {};
      for (final note in notes) {
        if (note.type != NoteType.bookmark) {
          _pageNotesCache[bookId]![note.pageNumber] ??= [];
          _pageNotesCache[bookId]![note.pageNumber]!.add(note);
        }
      }
      
      return notes;
    } catch (e) {
      print('Error fetching notes: $e');
      return _notesCache[bookId] ?? [];
    }
  }
  
  /// Get notes for a specific page
  Future<List<NoteModel>> getNotesForPage(String bookId, int pageNumber, {bool forceRefresh = false}) async {
    // Check page cache first
    if (!forceRefresh && 
        _pageNotesCache.containsKey(bookId) && 
        _pageNotesCache[bookId]!.containsKey(pageNumber)) {
      return _pageNotesCache[bookId]![pageNumber]!;
    }
    
    try {
      final notes = await _apiService.getNotesForPage(bookId, pageNumber);
      
      // Update cache
      _pageNotesCache[bookId] ??= {};
      _pageNotesCache[bookId]![pageNumber] = notes;
      
      return notes;
    } catch (e) {
      print('Error fetching page notes: $e');
      return _pageNotesCache[bookId]?[pageNumber] ?? [];
    }
  }
  
  /// Create a new note
  Future<NoteModel?> createNote({
    required String bookId,
    required int pageNumber,
    required String content,
    String? title,
    String? selectedText,
  }) async {
    try {
      final note = await _apiService.createNote(
        bookId: bookId,
        pageNumber: pageNumber,
        content: content,
        title: title,
        selectedText: selectedText,
      );
      
      // Update caches
      if (_notesCache.containsKey(bookId)) {
        _notesCache[bookId]!.add(note);
      }
      
      _pageNotesCache[bookId] ??= {};
      _pageNotesCache[bookId]![pageNumber] ??= [];
      _pageNotesCache[bookId]![pageNumber]!.insert(0, note); // Add to front (newest first)
      
      return note;
    } catch (e) {
      print('Error creating note: $e');
      return null;
    }
  }
  
  /// Update a note
  Future<NoteModel?> updateNote({
    required String noteId,
    required String content,
    String? title,
  }) async {
    try {
      final updatedNote = await _apiService.updateNote(
        noteId: noteId,
        content: content,
        title: title,
      );
      
      // Update caches
      // Note: We need to find which book this note belongs to in the cache
      for (var bookId in _notesCache.keys) {
        final index = _notesCache[bookId]!.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notesCache[bookId]![index] = updatedNote;
          
          // Update page cache as well
          if (_pageNotesCache.containsKey(bookId) && 
              _pageNotesCache[bookId]!.containsKey(updatedNote.pageNumber)) {
            final pageIndex = _pageNotesCache[bookId]![updatedNote.pageNumber]!.indexWhere((n) => n.id == noteId);
            if (pageIndex != -1) {
              _pageNotesCache[bookId]![updatedNote.pageNumber]![pageIndex] = updatedNote;
            }
          }
          break;
        }
      }
      
      return updatedNote;
    } catch (e) {
      print('Error updating note: $e');
      return null;
    }
  }
  
  /// Delete a note
  Future<bool> deleteNote({
    required String bookId,
    required String noteId,
    required int pageNumber,
  }) async {
    try {
      await _apiService.deleteNote(noteId);
      
      // Update caches
      if (_notesCache.containsKey(bookId)) {
        _notesCache[bookId]!.removeWhere((n) => n.id == noteId);
      }
      
      if (_pageNotesCache.containsKey(bookId) && 
          _pageNotesCache[bookId]!.containsKey(pageNumber)) {
        _pageNotesCache[bookId]![pageNumber]!.removeWhere((n) => n.id == noteId);
      }
      
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
  
  /// Get count of notes for a specific page
  int getNotesCountForPage(String bookId, int pageNumber) {
    if (!_pageNotesCache.containsKey(bookId) || 
        !_pageNotesCache[bookId]!.containsKey(pageNumber)) {
      return 0;
    }
    
    return _pageNotesCache[bookId]![pageNumber]!.length;
  }
  
  /// Get notes counts for all pages in a book
  Map<int, int> getNotesCountsForBook(String bookId) {
    final counts = <int, int>{};
    
    if (!_pageNotesCache.containsKey(bookId)) {
      return counts;
    }
    
    _pageNotesCache[bookId]!.forEach((pageNumber, notes) {
      counts[pageNumber] = notes.length;
    });
    
    return counts;
  }
  
  /// Clear cache for a specific book
  void clearCache(String bookId) {
    _notesCache.remove(bookId);
    _pageNotesCache.remove(bookId);
  }
  
  /// Clear all caches
  void clearAllCaches() {
    _notesCache.clear();
    _pageNotesCache.clear();
  }
}

