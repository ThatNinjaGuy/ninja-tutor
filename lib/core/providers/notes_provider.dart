import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/note/note_model.dart';
import '../../services/notes/notes_service.dart';

/// State class for notes
class NotesState {
  final List<NoteModel> allNotes;
  final Map<int, List<NoteModel>> notesByPage;
  final bool isLoading;
  final String? error;
  final String? currentBookId;
  
  const NotesState({
    this.allNotes = const [],
    this.notesByPage = const {},
    this.isLoading = false,
    this.error,
    this.currentBookId,
  });
  
  NotesState copyWith({
    List<NoteModel>? allNotes,
    Map<int, List<NoteModel>>? notesByPage,
    bool? isLoading,
    String? error,
    String? currentBookId,
  }) {
    return NotesState(
      allNotes: allNotes ?? this.allNotes,
      notesByPage: notesByPage ?? this.notesByPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentBookId: currentBookId ?? this.currentBookId,
    );
  }
  
  /// Get notes for a specific page
  List<NoteModel> getNotesForPage(int pageNumber) {
    return notesByPage[pageNumber] ?? [];
  }
  
  /// Get note count for a specific page
  int getNotesCountForPage(int pageNumber) {
    return notesByPage[pageNumber]?.length ?? 0;
  }
  
  /// Get all page numbers with notes
  Set<int> get pagesWithNotes {
    return notesByPage.keys.toSet();
  }
}

/// Notifier for notes state management
class NotesNotifier extends StateNotifier<NotesState> {
  final NotesService _notesService = NotesService();
  
  NotesNotifier() : super(const NotesState());
  
  /// Load notes for a book
  Future<void> loadNotes(String bookId, {bool forceRefresh = false}) async {
    // Don't reload if already loaded for this book (unless forced)
    if (!forceRefresh && state.currentBookId == bookId && state.allNotes.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, currentBookId: bookId);
    
    try {
      final notes = await _notesService.getNotesForBook(bookId, forceRefresh: forceRefresh);
      
      // Filter out bookmarks (only text notes)
      final textNotes = notes.where((n) => n.type == NoteType.text).toList();
      
      // Organize by page
      final Map<int, List<NoteModel>> notesByPage = {};
      for (final note in textNotes) {
        notesByPage[note.pageNumber] ??= [];
        notesByPage[note.pageNumber]!.add(note);
      }
      
      state = state.copyWith(
        allNotes: textNotes,
        notesByPage: notesByPage,
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
  
  /// Load notes for a specific page
  Future<void> loadPageNotes(String bookId, int pageNumber, {bool forceRefresh = false}) async {
    try {
      final notes = await _notesService.getNotesForPage(bookId, pageNumber, forceRefresh: forceRefresh);
      
      // Update state
      final updatedNotesByPage = Map<int, List<NoteModel>>.from(state.notesByPage);
      updatedNotesByPage[pageNumber] = notes;
      
      state = state.copyWith(notesByPage: updatedNotesByPage);
    } catch (e) {
      print('Error loading page notes: $e');
    }
  }
  
  /// Create a new note
  Future<NoteModel?> createNote({
    required String bookId,
    required int pageNumber,
    required String content,
    String? title,
  }) async {
    try {
      final note = await _notesService.createNote(
        bookId: bookId,
        pageNumber: pageNumber,
        content: content,
        title: title,
      );
      
      if (note != null) {
        // Update state
        final updatedAllNotes = List<NoteModel>.from(state.allNotes)..add(note);
        final updatedNotesByPage = Map<int, List<NoteModel>>.from(state.notesByPage);
        updatedNotesByPage[pageNumber] ??= [];
        updatedNotesByPage[pageNumber] = [note, ...updatedNotesByPage[pageNumber]!];
        
        state = state.copyWith(
          allNotes: updatedAllNotes,
          notesByPage: updatedNotesByPage,
        );
      }
      
      return note;
    } catch (e) {
      print('Error creating note: $e');
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
      final success = await _notesService.deleteNote(
        bookId: bookId,
        noteId: noteId,
        pageNumber: pageNumber,
      );
      
      if (success) {
        // Update state
        final updatedAllNotes = List<NoteModel>.from(state.allNotes)
          ..removeWhere((n) => n.id == noteId);
        
        final updatedNotesByPage = Map<int, List<NoteModel>>.from(state.notesByPage);
        if (updatedNotesByPage.containsKey(pageNumber)) {
          updatedNotesByPage[pageNumber] = updatedNotesByPage[pageNumber]!
            .where((n) => n.id != noteId)
            .toList();
        }
        
        state = state.copyWith(
          allNotes: updatedAllNotes,
          notesByPage: updatedNotesByPage,
        );
      }
      
      return success;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
  
  /// Clear notes (when changing books)
  void clear() {
    state = const NotesState();
  }
}

/// Provider for notes state
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});

