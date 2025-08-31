import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user/user_model.dart';
import '../../models/content/book_model.dart';
import '../../models/note/note_model.dart';
import '../../models/quiz/quiz_model.dart' as quiz;

/// Hive service for local data storage and caching
class HiveService {
  static bool _isInitialized = false;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register type adapters
    _registerAdapters();

    // Open boxes
    await _openBoxes();

    _isInitialized = true;
  }

  /// Register all Hive type adapters
  static void _registerAdapters() {
    // User models
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(ReadingPreferencesAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(SubjectProgressAdapter());

    // Book models
    Hive.registerAdapter(BookModelAdapter());
    Hive.registerAdapter(BookTypeAdapter());
    Hive.registerAdapter(BookMetadataAdapter());
    Hive.registerAdapter(DifficultyLevelAdapter());
    Hive.registerAdapter(ReadingProgressAdapter());
    Hive.registerAdapter(ReadingSessionAdapter());
    Hive.registerAdapter(PageProgressAdapter());

    // Note models
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(NoteTypeAdapter());
    Hive.registerAdapter(NotePositionAdapter());
    Hive.registerAdapter(NoteStyleAdapter());
    Hive.registerAdapter(HighlightStyleAdapter());
    Hive.registerAdapter(AiInsightsAdapter());
    Hive.registerAdapter(NoteCollectionAdapter());

    // Quiz models
    Hive.registerAdapter(quiz.QuizModelAdapter());
    Hive.registerAdapter(quiz.QuizTypeAdapter());
    Hive.registerAdapter(quiz.QuizSettingsAdapter());
    Hive.registerAdapter(quiz.QuestionModelAdapter());
    Hive.registerAdapter(quiz.QuestionTypeAdapter());
    Hive.registerAdapter(quiz.AnswerOptionAdapter());
    Hive.registerAdapter(quiz.QuizResultAdapter());
    Hive.registerAdapter(quiz.QuestionResultAdapter());
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<UserModel>(HiveBoxes.userBox),
      Hive.openBox<BookModel>(HiveBoxes.booksBox),
      Hive.openBox<NoteModel>(HiveBoxes.notesBox),
      Hive.openBox<ReadingProgress>(HiveBoxes.progressBox),
      Hive.openBox<dynamic>(HiveBoxes.cacheBox),
    ]);
  }

  /// Get Hive box by name
  Box<T> _getBox<T>(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open');
    }
    return Hive.box<T>(boxName);
  }

  // User operations
  
  /// Save user data
  Future<void> saveUser(UserModel user) async {
    final box = _getBox<UserModel>(HiveBoxes.userBox);
    await box.put('current_user', user);
  }

  /// Get current user
  Future<UserModel?> getUser() async {
    final box = _getBox<UserModel>(HiveBoxes.userBox);
    return box.get('current_user');
  }

  /// Clear user data (sign out)
  Future<void> clearUser() async {
    final box = _getBox<UserModel>(HiveBoxes.userBox);
    await box.clear();
  }

  // Book operations
  
  /// Save book
  Future<void> saveBook(BookModel book) async {
    final box = _getBox<BookModel>(HiveBoxes.booksBox);
    await box.put(book.id, book);
  }

  /// Get all books
  Future<List<BookModel>> getBooks() async {
    final box = _getBox<BookModel>(HiveBoxes.booksBox);
    return box.values.toList();
  }

  /// Get book by ID
  Future<BookModel?> getBook(String bookId) async {
    final box = _getBox<BookModel>(HiveBoxes.booksBox);
    return box.get(bookId);
  }

  /// Delete book
  Future<void> deleteBook(String bookId) async {
    final box = _getBox<BookModel>(HiveBoxes.booksBox);
    await box.delete(bookId);
    
    // Also delete related notes and progress
    await deleteNotesForBook(bookId);
    await deleteReadingProgress(bookId);
  }

  /// Get books by subject
  Future<List<BookModel>> getBooksBySubject(String subject) async {
    final books = await getBooks();
    return books.where((book) => book.subject == subject).toList();
  }

  /// Get recently read books
  Future<List<BookModel>> getRecentBooks({int limit = 5}) async {
    final books = await getBooks();
    books.sort((a, b) => (b.lastReadAt ?? DateTime(1970))
        .compareTo(a.lastReadAt ?? DateTime(1970)));
    return books.take(limit).toList();
  }

  // Note operations
  
  /// Save note
  Future<void> saveNote(NoteModel note) async {
    final box = _getBox<NoteModel>(HiveBoxes.notesBox);
    await box.put(note.id, note);
  }

  /// Get all notes
  Future<List<NoteModel>> getAllNotes() async {
    final box = _getBox<NoteModel>(HiveBoxes.notesBox);
    return box.values.toList();
  }

  /// Get notes for specific book
  Future<List<NoteModel>> getNotesForBook(String bookId) async {
    final notes = await getAllNotes();
    return notes.where((note) => note.bookId == bookId).toList();
  }

  /// Get notes for specific page
  Future<List<NoteModel>> getNotesForPage(String bookId, int pageNumber) async {
    final notes = await getNotesForBook(bookId);
    return notes.where((note) => note.pageNumber == pageNumber).toList();
  }

  /// Get note by ID
  Future<NoteModel?> getNote(String noteId) async {
    final box = _getBox<NoteModel>(HiveBoxes.notesBox);
    return box.get(noteId);
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    final box = _getBox<NoteModel>(HiveBoxes.notesBox);
    await box.delete(noteId);
  }

  /// Delete all notes for a book
  Future<void> deleteNotesForBook(String bookId) async {
    final notes = await getNotesForBook(bookId);
    final box = _getBox<NoteModel>(HiveBoxes.notesBox);
    
    for (final note in notes) {
      await box.delete(note.id);
    }
  }

  /// Get favorite notes
  Future<List<NoteModel>> getFavoriteNotes() async {
    final notes = await getAllNotes();
    return notes.where((note) => note.isFavorite).toList();
  }

  /// Search notes by content
  Future<List<NoteModel>> searchNotes(String query) async {
    final notes = await getAllNotes();
    return notes.where((note) => 
        note.content.toLowerCase().contains(query.toLowerCase()) ||
        note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  // Reading progress operations
  
  /// Save reading progress
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final box = _getBox<ReadingProgress>(HiveBoxes.progressBox);
    await box.put(progress.bookId, progress);
  }

  /// Get reading progress for book
  Future<ReadingProgress?> getReadingProgress(String bookId) async {
    final box = _getBox<ReadingProgress>(HiveBoxes.progressBox);
    return box.get(bookId);
  }

  /// Delete reading progress
  Future<void> deleteReadingProgress(String bookId) async {
    final box = _getBox<ReadingProgress>(HiveBoxes.progressBox);
    await box.delete(bookId);
  }

  /// Get all reading progress
  Future<List<ReadingProgress>> getAllReadingProgress() async {
    final box = _getBox<ReadingProgress>(HiveBoxes.progressBox);
    return box.values.toList();
  }

  // Quiz result operations
  
  /// Save quiz result
  Future<void> saveQuizResult(quiz.QuizResult result) async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    await box.put('quiz_result_${result.id}', result.toJson());
  }

  /// Get quiz results
  Future<List<quiz.QuizResult>> getQuizResults() async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    final results = <quiz.QuizResult>[];
    
    for (final key in box.keys) {
      if (key.toString().startsWith('quiz_result_')) {
        final json = box.get(key) as Map<String, dynamic>?;
        if (json != null) {
          results.add(quiz.QuizResult.fromJson(json));
        }
      }
    }
    
    return results;
  }

  /// Get quiz results for specific user
  Future<List<quiz.QuizResult>> getQuizResultsForUser(String userId) async {
    final results = await getQuizResults();
    return results.where((result) => result.userId == userId).toList();
  }

  // Cache operations
  
  /// Save to cache
  Future<void> saveToCache(String key, dynamic value) async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    await box.put(key, value);
  }

  /// Get from cache
  Future<T?> getFromCache<T>(String key) async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    return box.get(key) as T?;
  }

  /// Delete from cache
  Future<void> deleteFromCache(String key) async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    await box.delete(key);
  }

  /// Clear cache
  Future<void> clearCache() async {
    final box = _getBox<dynamic>(HiveBoxes.cacheBox);
    await box.clear();
  }

  // Database maintenance
  
  /// Get database size
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    
    stats['users'] = _getBox<UserModel>(HiveBoxes.userBox).length;
    stats['books'] = _getBox<BookModel>(HiveBoxes.booksBox).length;
    stats['notes'] = _getBox<NoteModel>(HiveBoxes.notesBox).length;
    stats['progress'] = _getBox<ReadingProgress>(HiveBoxes.progressBox).length;
    stats['cache'] = _getBox<dynamic>(HiveBoxes.cacheBox).length;
    
    return stats;
  }

  /// Compact database
  Future<void> compactDatabase() async {
    await Future.wait([
      _getBox<UserModel>(HiveBoxes.userBox).compact(),
      _getBox<BookModel>(HiveBoxes.booksBox).compact(),
      _getBox<NoteModel>(HiveBoxes.notesBox).compact(),
      _getBox<ReadingProgress>(HiveBoxes.progressBox).compact(),
      _getBox<dynamic>(HiveBoxes.cacheBox).compact(),
    ]);
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    if (!_isInitialized) return;
    
    await Hive.close();
    _isInitialized = false;
  }

  /// Delete all data (reset app)
  Future<void> deleteAllData() async {
    await Future.wait([
      _getBox<UserModel>(HiveBoxes.userBox).clear(),
      _getBox<BookModel>(HiveBoxes.booksBox).clear(),
      _getBox<NoteModel>(HiveBoxes.notesBox).clear(),
      _getBox<ReadingProgress>(HiveBoxes.progressBox).clear(),
      _getBox<dynamic>(HiveBoxes.cacheBox).clear(),
    ]);
  }
}
