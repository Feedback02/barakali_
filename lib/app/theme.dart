import 'package:flutter/material.dart';

import 'package:barakali/core/theme/brand_colors.dart';

abstract final class AppTheme {
  // Brand palette (light mode uses these directly; see core/theme/brand_colors).
  static const _primary = kBrandGreen;
  static const _secondary = kBrandAmber;
  static const _tertiary = kBrandTerracotta;
  static const _background = Color(0xFFFAF8F5);
  static const _surface = Colors.white;
  static const _onSurface = Color(0xFF2C2C2C);

  // Dark mode. The raw brand green/terracotta are too dark to use as text or
  // icons on a dark surface (they fall below WCAG AA), so dark mode uses
  // lightened, on-brand variants; amber stays a fill/icon color only. Surfaces
  // are warm near-blacks that echo the warm off-white of light mode rather than
  // a flat neutral grey.
  static const _darkPrimary = Color(0xFF6CC58A); // light green, AA text on dark
  static const _onDarkPrimary = Color(0xFF06250F); // dark text on a green fill
  static const _darkTertiary = Color(0xFFE08763); // light terracotta
  static const _darkBackground = Color(0xFF14130F);
  static const _darkSurface = Color(0xFF1F1D18);
  static const _onDarkSurface = Color(0xFFEDE8E0);

  /// Bundled Noto Sans (see pubspec). Set on [ThemeData.fontFamily] so the whole
  /// text theme renders in it — Latin (Uzbek) + Cyrillic (Russian) alike.
  static const _fontFamily = 'Noto Sans';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surface: _background,
      onSurface: _onSurface,
    );
    return _build(
      colorScheme,
      scaffold: _background,
      surface: _surface,
      onPrimary: Colors.white,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: _onDarkPrimary,
      secondary: _secondary,
      tertiary: _darkTertiary,
      surface: _darkBackground,
      onSurface: _onDarkSurface,
    );
    return _build(
      colorScheme,
      scaffold: _darkBackground,
      surface: _darkSurface,
      onPrimary: _onDarkPrimary,
    );
  }

  /// Shared theme construction for both brightnesses. [scaffold] is the page
  /// background, [surface] the slightly raised card/nav-bar color, [onPrimary]
  /// the label color on a primary-filled button.
  static ThemeData _build(
    ColorScheme colorScheme, {
    required Color scaffold,
    required Color surface,
    required Color onPrimary,
  }) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
