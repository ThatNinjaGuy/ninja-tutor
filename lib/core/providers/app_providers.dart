import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../models/user/user_model.dart';
import '../../models/content/book_model.dart';
import '../../models/note/note_model.dart';
import '../../models/quiz/quiz_model.dart';
import '../../services/storage/hive_service.dart';
import '../../services/api/api_service.dart';

/// Shared Preferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Hive service provider for local storage
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// API service provider for network requests
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Current user provider
final currentUserProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return UserNotifier(hiveService);
});

/// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final user = ref.watch(currentUserProvider);
  return UserPreferencesNotifier(
    user.value?.preferences ?? const UserPreferences(
      readingPreferences: ReadingPreferences(),
    ),
  );
});

/// Books library provider
final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<BookModel>>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return BooksNotifier(hiveService, apiService);
});

/// Currently reading book provider
final currentBookProvider = StateProvider<BookModel?>((ref) => null);

/// Notes provider
final notesProvider = StateNotifierProvider.family<NotesNotifier, AsyncValue<List<NoteModel>>, String>((ref, bookId) {
  final hiveService = ref.watch(hiveServiceProvider);
  return NotesNotifier(hiveService, bookId);
});

/// All notes provider (across all books)
final allNotesProvider = StateNotifierProvider<AllNotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AllNotesNotifier(hiveService);
});

/// Quiz provider
final quizProvider = StateNotifierProvider.family<QuizNotifier, AsyncValue<QuizModel?>, String>((ref, quizId) {
  final apiService = ref.watch(apiServiceProvider);
  return QuizNotifier(apiService, quizId);
});

/// Quiz results provider
final quizResultsProvider = StateNotifierProvider<QuizResultsNotifier, AsyncValue<List<QuizResult>>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return QuizResultsNotifier(hiveService);
});

/// Reading progress provider
final readingProgressProvider = StateNotifierProvider.family<ReadingProgressNotifier, ReadingProgress?, String>((ref, bookId) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ReadingProgressNotifier(hiveService, bookId);
});

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs.value);
});

/// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final booksNotifier = ref.read(booksProvider.notifier);
  final notesNotifier = ref.read(allNotesProvider.notifier);
  return SearchNotifier(booksNotifier, notesNotifier);
});

/// Navigation provider
final navigationProvider = StateProvider<int>((ref) => 0);

/// Loading state provider for global loading states
final loadingProvider = StateProvider<bool>((ref) => false);

/// Error provider for global error handling
final errorProvider = StateProvider<String?>((ref) => null);

/// User Notifier
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier(this._hiveService) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final HiveService _hiveService;

  Future<void> _loadUser() async {
    try {
      final user = await _hiveService.getUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _hiveService.saveUser(user);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      await _hiveService.clearUser();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// User Preferences Notifier
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(super.initialState);

  void updatePreferences(UserPreferences preferences) {
    state = preferences;
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void updateFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
  }

  void toggleAiTips() {
    state = state.copyWith(aiTipsEnabled: !state.aiTipsEnabled);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  void updateReadingPreferences(ReadingPreferences preferences) {
    state = state.copyWith(readingPreferences: preferences);
  }
}

/// Books Notifier
class BooksNotifier extends StateNotifier<AsyncValue<List<BookModel>>> {
  BooksNotifier(this._hiveService, this._apiService) : super(const AsyncValue.loading()) {
    _loadBooks();
  }

  final HiveService _hiveService;
  final ApiService _apiService;

  Future<void> _loadBooks() async {
    try {
      final books = await _hiveService.getBooks();
      state = AsyncValue.data(books);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addBook(BookModel book) async {
    try {
      await _hiveService.saveBook(book);
      final currentBooks = state.value ?? [];
      state = AsyncValue.data([...currentBooks, book]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateBook(BookModel book) async {
    try {
      await _hiveService.saveBook(book);
      final currentBooks = state.value ?? [];
      final updatedBooks = currentBooks.map((b) => b.id == book.id ? book : b).toList();
      state = AsyncValue.data(updatedBooks);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _hiveService.deleteBook(bookId);
      final currentBooks = state.value ?? [];
      final updatedBooks = currentBooks.where((b) => b.id != bookId).toList();
      state = AsyncValue.data(updatedBooks);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshBooks() async {
    await _loadBooks();
  }
}

/// Notes Notifier for specific book
class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  NotesNotifier(this._hiveService, this._bookId) : super(const AsyncValue.loading()) {
    _loadNotes();
  }

  final HiveService _hiveService;
  final String _bookId;

  Future<void> _loadNotes() async {
    try {
      final notes = await _hiveService.getNotesForBook(_bookId);
      state = AsyncValue.data(notes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addNote(NoteModel note) async {
    try {
      await _hiveService.saveNote(note);
      final currentNotes = state.value ?? [];
      state = AsyncValue.data([...currentNotes, note]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      await _hiveService.saveNote(note);
      final currentNotes = state.value ?? [];
      final updatedNotes = currentNotes.map((n) => n.id == note.id ? note : n).toList();
      state = AsyncValue.data(updatedNotes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _hiveService.deleteNote(noteId);
      final currentNotes = state.value ?? [];
      final updatedNotes = currentNotes.where((n) => n.id != noteId).toList();
      state = AsyncValue.data(updatedNotes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// All Notes Notifier
class AllNotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  AllNotesNotifier(this._hiveService) : super(const AsyncValue.loading()) {
    _loadAllNotes();
  }

  final HiveService _hiveService;

  Future<void> _loadAllNotes() async {
    try {
      final notes = await _hiveService.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshNotes() async {
    await _loadAllNotes();
  }
}

/// Quiz Notifier
class QuizNotifier extends StateNotifier<AsyncValue<QuizModel?>> {
  QuizNotifier(this._apiService, this._quizId) : super(const AsyncValue.loading()) {
    _loadQuiz();
  }

  final ApiService _apiService;
  final String _quizId;

  Future<void> _loadQuiz() async {
    try {
      final quiz = await _apiService.getQuiz(_quizId);
      state = AsyncValue.data(quiz);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> generateQuiz(String bookId, List<int> pageRange) async {
    try {
      state = const AsyncValue.loading();
      final quiz = await _apiService.generateQuiz(bookId, pageRange);
      state = AsyncValue.data(quiz);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Quiz Results Notifier
class QuizResultsNotifier extends StateNotifier<AsyncValue<List<QuizResult>>> {
  QuizResultsNotifier(this._hiveService) : super(const AsyncValue.loading()) {
    _loadResults();
  }

  final HiveService _hiveService;

  Future<void> _loadResults() async {
    try {
      final results = await _hiveService.getQuizResults();
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> saveResult(QuizResult result) async {
    try {
      await _hiveService.saveQuizResult(result);
      final currentResults = state.value ?? [];
      state = AsyncValue.data([...currentResults, result]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Reading Progress Notifier
class ReadingProgressNotifier extends StateNotifier<ReadingProgress?> {
  ReadingProgressNotifier(this._hiveService, this._bookId) : super(null) {
    _loadProgress();
  }

  final HiveService _hiveService;
  final String _bookId;

  Future<void> _loadProgress() async {
    try {
      final progress = await _hiveService.getReadingProgress(_bookId);
      state = progress;
    } catch (e) {
      // Handle error silently, progress might not exist yet
      state = null;
    }
  }

  Future<void> updateProgress(ReadingProgress progress) async {
    try {
      await _hiveService.saveReadingProgress(progress);
      state = progress;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateCurrentPage(int page) async {
    if (state != null) {
      final updatedProgress = state!.copyWith(
        currentPage: page,
        lastReadAt: DateTime.now(),
      );
      await updateProgress(updatedProgress);
    }
  }
}

/// Theme Mode Notifier
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier(this._prefs) : super(false) {
    _loadThemeMode();
  }

  final SharedPreferences? _prefs;

  void _loadThemeMode() {
    if (_prefs != null) {
      state = _prefs!.getBool(AppConstants.themeKey) ?? false;
    }
  }

  Future<void> toggleTheme() async {
    state = !state;
    if (_prefs != null) {
      await _prefs!.setBool(AppConstants.themeKey, state);
    }
  }
}

/// Search State
class SearchState {
  const SearchState({
    this.query = '',
    this.searchResults = const [],
    this.isLoading = false,
  });

  final String query;
  final List<dynamic> searchResults; // Can be books, notes, etc.
  final bool isLoading;

  SearchState copyWith({
    String? query,
    List<dynamic>? searchResults,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._booksNotifier, this._notesNotifier) : super(const SearchState());

  final BooksNotifier _booksNotifier;
  final AllNotesNotifier _notesNotifier;

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query);

    try {
      final books = _booksNotifier.state.value ?? [];
      final notes = _notesNotifier.state.value ?? [];

      final bookResults = books.where((book) =>
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()) ||
          book.subject.toLowerCase().contains(query.toLowerCase()));

      final noteResults = notes.where((note) =>
          note.content.toLowerCase().contains(query.toLowerCase()) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())));

      final allResults = [...bookResults, ...noteResults];

      state = state.copyWith(
        searchResults: allResults,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}
