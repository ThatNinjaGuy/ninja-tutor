import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/reading/reading_screen.dart';
import '../../ui/screens/practice/practice_screen.dart';
import '../../ui/screens/library/library_screen.dart';
import '../../ui/screens/notes/notes_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/widgets/navigation/main_navigation.dart';

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Reading
          GoRoute(
            path: AppRoutes.reading,
            name: 'reading',
            builder: (context, state) => const ReadingScreen(),
            routes: [
              // Reading with book ID
              GoRoute(
                path: 'book/:bookId',
                name: 'reading-book',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId']!;
                  return ReadingScreen(bookId: bookId);
                },
              ),
            ],
          ),

          // Practice
          GoRoute(
            path: AppRoutes.practice,
            name: 'practice',
            builder: (context, state) => const PracticeScreen(),
            routes: [
              // Practice session
              GoRoute(
                path: 'session/:sessionId',
                name: 'practice-session',
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId']!;
                  return PracticeScreen(sessionId: sessionId);
                },
              ),
            ],
          ),

          // Library
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
            routes: [
              // Book detail
              GoRoute(
                path: 'book/:bookId',
                name: 'book-detail',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId']!;
                  return BookDetailScreen(bookId: bookId);
                },
              ),
            ],
          ),

          // Notes
          GoRoute(
            path: AppRoutes.notes,
            name: 'notes',
            builder: (context, state) => const NotesScreen(),
            routes: [
              // Note detail
              GoRoute(
                path: 'note/:noteId',
                name: 'note-detail',
                builder: (context, state) {
                  final noteId = state.pathParameters['noteId']!;
                  return NoteDetailScreen(noteId: noteId);
                },
              ),
            ],
          ),
        ],
      ),

      // Settings (full screen)
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

/// Error screen for route errors
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    this.error,
  });

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Book detail screen placeholder
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: Center(
        child: Text('Book ID: $bookId'),
      ),
    );
  }
}

/// Note detail screen placeholder
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
      ),
      body: Center(
        child: Text('Note ID: $noteId'),
      ),
    );
  }
}
