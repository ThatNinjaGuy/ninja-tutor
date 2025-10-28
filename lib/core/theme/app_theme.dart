import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration following Material 3 design principles
class AppTheme {
  // Color scheme definitions
  static const _primaryColor = Color(0xFF6366F1); // Indigo
  static const _secondaryColor = Color(0xFF10B981); // Emerald
  static const _errorColor = Color(0xFFEF4444); // Red
  static const _warningColor = Color(0xFFF59E0B); // Amber
  static const _successColor = Color(0xFF10B981); // Emerald
  
  /// Light theme configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: Color(0xFFFAFAFA),
      background: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
    );
    
    return _buildTheme(colorScheme, Brightness.light);
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: Color(0xFF1F2937),
      background: Color(0xFF111827),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: Color(0xFFF9FAFB),
      onBackground: Color(0xFFF9FAFB),
    );
    
    return _buildTheme(colorScheme, Brightness.dark);
  }
  
  /// Build theme from color scheme
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withOpacity(0.1),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: colorScheme.primary.withOpacity(0.2),
      ),
    );
  }
  
  /// Custom colors for specific UI elements
  static const aiTipColor = Color(0xFF8B5CF6); // Purple for AI features
  static const highlightColor = Color(0xFFFBBF24); // Yellow for highlights
  static const noteColor = Color(0xFF06B6D4); // Cyan for notes
  static const practiceColor = Color(0xFFEC4899); // Pink for practice
  static const readingColor = Color(0xFF10B981); // Green for reading
  
  /// Gamification colors
  static const xpColor = Color(0xFFFBBF24); // Gold for XP
  static const achievementColor = Color(0xFFF59E0B); // Amber for achievements
  static const streakColor = Color(0xFFEF4444); // Red/Orange for streak flame
  
  /// Badge tier colors
  static const bronzeColor = Color(0xFFCD7F32);
  static const silverColor = Color(0xFFC0C0C0);
  static const goldColor = Color(0xFFFFD700);
  static const platinumColor = Color(0xFFE5E4E2);
  
  /// Gradient definitions
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const xpGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const streakGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Glass morphism utilities
  static BoxDecoration glassDecoration({
    Color? color,
    double opacity = 0.1,
    double borderOpacity = 0.2,
    double blurAmount = 10.0,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blurAmount,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Create glow effect
  static List<BoxShadow> createGlow(Color color, {double intensity = 0.5}) {
    return [
      BoxShadow(
        color: color.withOpacity(intensity * 0.3),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withOpacity(intensity * 0.2),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }
  
  /// Premium card decoration
  static BoxDecoration premiumCardDecoration(BuildContext context, {Color? accentColor}) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface.withOpacity(0.95),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Extension to access custom colors from BuildContext
extension AppThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Check if current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
