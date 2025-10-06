/// Core application constants used throughout the app
class AppConstants {
  // App Information
  static const String appName = 'Ninja Tutor';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  // static const String baseUrl = 'https://1c0d96e8d006.ngrok-free.app';
  static const String apiVersion = 'api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Content Limits
  static const int maxNotesPerBook = 1000;
  static const int maxHighlightsPerPage = 50;
  static const int maxBooksInLibrary = 500;
  
  // AI Feature Constants
  static const int maxAiContextLength = 2000;
  static const Duration aiResponseTimeout = Duration(seconds: 10);
  static const int maxConcurrentAiRequests = 3;
}

/// Route names for navigation
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String reading = '/reading';
  static const String practice = '/practice';
  static const String library = '/library';
  static const String notes = '/notes';
  static const String settings = '/settings';
  static const String bookDetail = '/book/:bookId';
  static const String practiceSession = '/practice/:sessionId';
  static const String noteDetail = '/note/:noteId';
}

/// Hive box names for local storage
class HiveBoxes {
  static const String userBox = 'user_box';
  static const String booksBox = 'books_box';
  static const String notesBox = 'notes_box';
  static const String highlightsBox = 'highlights_box';
  static const String progressBox = 'progress_box';
  static const String cacheBox = 'cache_box';
}
