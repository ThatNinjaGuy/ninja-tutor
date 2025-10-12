import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/unified_library_provider.dart';
import 'services/storage/hive_service.dart';
import 'ui/widgets/auth/login_dialog.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await HiveService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: NinjaTutorApp(),
    ),
  );
}

/// Main application widget
class NinjaTutorApp extends ConsumerStatefulWidget {
  const NinjaTutorApp({super.key});

  @override
  ConsumerState<NinjaTutorApp> createState() => _NinjaTutorAppState();
}

class _NinjaTutorAppState extends ConsumerState<NinjaTutorApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeModeProvider);
    
    // Listen to auth state changes for login dialog
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.showLoginDialog && !(previous?.showLoginDialog ?? false)) {
        // Show login dialog when auth error occurs
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLoginDialog(next.authErrorMessage);
        });
      }
    });

    return MaterialApp.router(
      title: 'Ninja Tutor',
      debugShowCheckedModeBanner: false,
      
      // Routing
      routerConfig: router,
      
      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Localization (placeholder for future implementation)
      localizationsDelegates: const [
        // Add localization delegates here
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        // Add more locales as needed
      ],
      
      // Error handling
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break UI
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showLoginDialog(String? message) {
    final router = ref.read(routerProvider);
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // Save current route before showing dialog
    final currentLocation = GoRouterState.of(context).uri.path;
    ref.read(authStateProvider.notifier).setReturnRoute(currentLocation);

    showDialog(
      context: context,
      barrierDismissible: false, // Force login
      builder: (dialogContext) => LoginDialog(
        message: message,
        onLoginSuccess: () {
          // Refresh library data after successful login
          ref.read(unifiedLibraryProvider.notifier).refresh();
        },
      ),
    );
  }
}