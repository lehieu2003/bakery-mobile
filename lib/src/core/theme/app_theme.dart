import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

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

  // --- Auth screen ---

  /// Page background behind the auth card.
  static const Color surfaceAuth = Color(0xFFF8F1E8);

  /// Caramel fill of the primary auth button.
  static const Color buttonPrimaryAuth = Color(0xFFB87B58);

  /// Soft caramel shadow under the auth card.
  static const Color shadowAuthCard = Color(0x1A9F7A5A);

  /// Top stop of the auth header image fade.
  static const Color authHeroFadeTop = Color(0x24FFFFFF);

  /// Middle stop of the auth header image fade.
  static const Color authHeroFadeMiddle = Color(0x66FFF8F0);

  /// Bottom stop of the auth header image fade.
  static const Color authHeroFadeBottom = Color(0xEEFFFFFF);

  /// Frosted white pill behind the "BAKERY SHOP" brand label (white at 78%).
  static const Color surfaceAuthPill = Color(0xC7FFFFFF);

  /// Brown text of the "BAKERY SHOP" brand pill.
  static const Color textBrandPill = Color(0xFF7A513A);

  // --- Surfaces ---

  /// Pure white surfaces (auth card, product detail app bar, page cards,
  /// drawer avatar), the active product-image carousel dot over photos, and
  /// white foreground text over photo hero banners.
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Frosted white search pill on the home header gradient (white at 74%).
  static const Color surfaceSearchBar = Color(0xBDFFFFFF);

  /// Frosted white square icon button on the home header (white at 52%).
  static const Color surfaceHeaderButton = Color(0x85FFFFFF);

  /// Frosted white circle behind the favorite toggle on product photos
  /// (white at 92%).
  static const Color surfaceFavoriteButton = Color(0xEBFFFFFF);

  /// Frosted white avatar circle on the tinted page-hero band (white at 85%).
  static const Color surfaceFrostedAvatar = Color(0xD9FFFFFF);

  /// Circle behind an unselected category rail icon.
  static const Color surfaceRailIcon = Color(0xFFFFF8F0);

  // --- Header & hero (home) ---

  /// Top stop of the home header background gradient.
  static const Color headerGradientStart = Color(0xFFFFDEE7);

  /// Bottom stop of the home header background gradient.
  static const Color headerGradientEnd = Color(0xFFFFE6CF);

  /// Top stop of the hero banner legibility scrim over photos (black at 2%).
  static const Color heroScrimTop = Color(0x05000000);

  /// Bottom stop of the hero banner legibility scrim over photos (black at
  /// 24%).
  static const Color heroScrimBottom = Color(0x3D000000);

  // --- Scrims, overlays & shadows ---

  /// Near-opaque black barrier behind the fullscreen image viewer (black at
  /// 92%).
  static const Color scrimImageViewer = Color(0xEB000000);

  /// Dark pill behind the image counter on product card photos (black at
  /// 45%).
  static const Color imageCounterScrim = Color(0x73000000);

  /// White wash behind the selected tab on the pink nav bar (white at 18%).
  static const Color navSelectedHighlight = Color(0x2EFFFFFF);

  /// Inactive product-image carousel dot over photos (white at 45%).
  static const Color carouselDotInactive = Color(0x73FFFFFF);

  /// Inactive banner paging dot.
  static const Color bannerDotInactive = Color(0xFFE3D8CF);

  /// Shadow above the pinned product detail bottom bar (black at 8%).
  static const Color shadowBottomBar = Color(0x14000000);

  /// Soft shadow under the cart summary box (black at 6%).
  static const Color shadowCartSummary = Color(0x0F000000);

  /// Shadow of the medium discount badge on product photos (black at 10%).
  static const Color shadowBadgeMedium = Color(0x1A000000);

  /// Shadow of the large discount badge on the detail hero (black at 14%).
  static const Color shadowBadgeLarge = Color(0x24000000);

  // --- Icons & accents ---

  /// Grey outline of the inactive favorite heart over product photos.
  static const Color favoriteOutline = Color(0xFF555555);

  /// Filled red heart of an active favorite (Material redAccent).
  static const Color favoriteActive = Color(0xFFFF5252);

  /// Amber star icons in rating displays (Material amber).
  static const Color starRating = Color(0xFFFFC107);

  /// Coral fill of the "-NN%" discount pill.
  static const Color discountBadge = Color(0xFFE46F5B);

  /// fl_chart grid line: warmBrown at ~12% alpha.
  static const Color chartGridLine = Color(0x1F8D5D43);

  // --- Stock status pill (product detail) ---

  /// Green tint behind the "in stock" pill (Material green at 12%).
  static const Color stockAvailableBg = Color(0x1F4CAF50);

  /// Dark green "in stock" pill text (Material green shade800).
  static const Color stockAvailableText = Color(0xFF2E7D32);

  /// Red tint behind the "out of stock" pill (Material red at 12%).
  static const Color stockOutBg = Color(0x1FF44336);

  /// Dark red "out of stock" pill text (Material red shade800).
  static const Color stockOutText = Color(0xFFC62828);

  // --- Order status pills ---

  /// Pill background for the PENDING order status.
  static const Color statusPendingBg = Color(0xFFFFF7E6);

  /// Pill text for the PENDING order status.
  static const Color statusPendingText = Color(0xFFB45309);

  /// Pill background for the CONFIRMED order status.
  static const Color statusConfirmedBg = Color(0xFFEFF6FF);

  /// Pill text for the CONFIRMED order status.
  static const Color statusConfirmedText = Color(0xFF1D4ED8);

  /// Pill background for the PROCESSING order status.
  static const Color statusProcessingBg = Color(0xFFFFF7ED);

  /// Pill text for the PROCESSING order status.
  static const Color statusProcessingText = Color(0xFFC2410C);

  /// Pill background for the READY order status.
  static const Color statusReadyBg = Color(0xFFF0FDFA);

  /// Pill text for the READY order status.
  static const Color statusReadyText = Color(0xFF0F766E);

  /// Pill background for the COMPLETED order status.
  static const Color statusCompletedBg = Color(0xFFF0FDF4);

  /// Pill text for the COMPLETED order status.
  static const Color statusCompletedText = Color(0xFF15803D);

  /// Pill background for the CANCELLED order status.
  static const Color statusCancelledBg = Color(0xFFFEF2F2);

  /// Pill text for the CANCELLED order status.
  static const Color statusCancelledText = Color(0xFFB91C1C);

  /// Pill background for an unknown order status.
  static const Color statusFallbackBg = Color(0xFFF3F4F6);

  /// Pill text for an unknown order status.
  static const Color statusFallbackText = Color(0xFF4B5563);

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
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
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
