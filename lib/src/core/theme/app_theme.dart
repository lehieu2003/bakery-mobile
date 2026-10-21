import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class AppTheme {
  // Synced with web primary/pink-deep tone.
  static const Color primaryPink = Color.fromARGB(255, 243, 146, 184);
  static const Color blushPink = Color(0xFFF6C8D6);
  static const Color pastryPeach = Color(0xFFF4B887);
  static const Color warmBrown = Color(0xFF8D5D43);
  static const Color inkBrown = Color(0xFF332923);
  static const Color canvasCream = Color(0xFFFBF6EF);
  static const Color surfaceCream = Color(0xFFFFFCF7);

  /// Secondary text in warm brown (captions, meta lines, descriptions).
  static const Color textMuted = Color(0xFF8A7464);

  /// Placeholder/hint text, lighter than [textMuted].
  static const Color textHint = Color(0xFF9B8474);

  /// Neutral box behind missing/failed product images.
  static const Color imagePlaceholder = Color(0xFFD8D8D8);

  /// Warm box behind missing/failed editorial images (blog, hero).
  static const Color placeholderBeige = Color(0xFFE9DCCB);

  /// Hairline borders on cream surfaces (cards, chips, pills).
  static const Color outlineBeige = Color(0xFFEBDCCA);

  /// Soft peach fill for selected chips/rail items and section icons.
  static const Color peachTint = Color(0xFFFFE8DC);

  static ThemeData light() {
    const seed = primaryPink;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: surfaceCream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvasCream,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: canvasCream,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCream,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCream,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: const Color(0xFFFFE8DC),
        checkmarkColor: scheme.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
