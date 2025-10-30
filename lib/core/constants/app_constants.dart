import 'package:flutter/foundation.dart';

/// Core application constants used throughout the app
class AppConstants {
  // App Information
  static const String appName = 'Ninja Tutor';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Production backend URL (Google Cloud Run)
  // Replace with your actual Cloud Run URL after deployment
  // static const String productionBaseUrl = 'https://ninja-tutor-backend-dsjg6miqrq-uc.a.run.app';
  static const String productionBaseUrl =
      'https://ninja-tutor-backend-764764156207.us-central1.run.app';
  static const String developmentBaseUrl = 'http://localhost:8000';

  // Detect environment and set base URL
  // In production builds, this will use the production URL
  static String get baseUrl {
    // For now, use development URL
    // After Cloud Run deployment, update this to production URL
    // return developmentBaseUrl;
    return productionBaseUrl;
    // Uncomment below after deployment:
    // return kReleaseMode ? productionBaseUrl : developmentBaseUrl;
  }

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
  static const double extraLargePadding = 32.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double pageMaxWidth = 1280.0;
  static const double widePageMaxWidth = 1440.0;

  // Spacing scale (4pt grid-inspired)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Responsive Breakpoints
  static const double compactBreakpoint = 480;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Content Limits
  static const int maxNotesPerBook = 1000;
  static const int maxHighlightsPerPage = 50;
  static const int maxBooksInLibrary = 500;

  // AI Feature Constants
  static const int maxAiContextLength = 2000;
  static const Duration aiResponseTimeout = Duration(seconds: 10);
  static const int maxConcurrentAiRequests = 3;

  // Reading Interface Constants
  static const double wideScreenBreakpoint = 800.0;
  static const double readingPanelWidthVertical = 60.0;
  static const double readingPanelHeightHorizontal = 60.0;
  static const double aiPanelWidthPercentage = 0.35;
  static const double controlButtonSize = 40.0;
  static const double controlButtonIconSize = 20.0;
  static const double controlButtonBorderRadius = 20.0;
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
  static const String categoryBooks = '/library/category/:category';
  // Full-screen reader route
  static const String reader = '/viewer';
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
