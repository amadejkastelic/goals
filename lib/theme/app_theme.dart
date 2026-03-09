import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryLight = Color(0xFF00897B);
  static const Color _primaryDark = Color(0xFF4DB6AC);
  static const Color _secondaryLight = Color(0xFF26A69A);
  static const Color _secondaryDark = Color(0xFF80CBC4);
  static const Color _surfaceLight = Color(0xFFFAFAFA);
  static const Color _surfaceDark = Color(0xFF121212);
  static const Color _errorLight = Color(0xFFBA1A1A);
  static const Color _errorDark = Color(0xFFFFB4AB);

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: _primaryLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF9EE8DC),
        onPrimaryContainer: Color(0xFF00201C),
        secondary: _secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFA7F3E7),
        onSecondaryContainer: Color(0xFF00201C),
        tertiary: Color(0xFF4A6360),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFCCE8E4),
        onTertiaryContainer: Color(0xFF051F1D),
        error: _errorLight,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: _surfaceLight,
        onSurface: Color(0xFF191C1B),
        surfaceContainerHighest: Color(0xFFE0E3E2),
        onSurfaceVariant: Color(0xFF3F4947),
        outline: Color(0xFF6F7977),
        outlineVariant: Color(0xFFBEC9C6),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF2D3130),
        onInverseSurface: Color(0xFFEFF1F0),
        inversePrimary: _primaryDark,
      ),
    );

    return _applyComponents(base);
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: _primaryDark,
        onPrimary: Color(0xFF003730),
        primaryContainer: Color(0xFF005048),
        onPrimaryContainer: Color(0xFF9EE8DC),
        secondary: _secondaryDark,
        onSecondary: Color(0xFF003730),
        secondaryContainer: Color(0xFF004F42),
        onSecondaryContainer: Color(0xFFA7F3E7),
        tertiary: Color(0xFFB0CCC9),
        onTertiary: Color(0xFF1B3532),
        tertiaryContainer: Color(0xFF324B49),
        onTertiaryContainer: Color(0xFFCCE8E4),
        error: _errorDark,
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: _surfaceDark,
        onSurface: Color(0xFFE0E3E2),
        surfaceContainerHighest: Color(0xFF3F4947),
        onSurfaceVariant: Color(0xFFBEC9C6),
        outline: Color(0xFF899390),
        outlineVariant: Color(0xFF3F4947),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE0E3E2),
        onInverseSurface: Color(0xFF191C1B),
        inversePrimary: _primaryLight,
      ),
    );

    return _applyComponents(base);
  }

  static ThemeData fromColorScheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return _applyComponents(base);
  }

  static ThemeData _applyComponents(ThemeData base) {
    return base.copyWith(
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: Border(
          bottom: BorderSide(color: base.colorScheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
