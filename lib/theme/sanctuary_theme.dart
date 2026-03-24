import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Tactile Sanctuary Design System
///
/// Colors, typography, and theme data for the neumorphic diary experience.
class SanctuaryColors {
  SanctuaryColors._();

  // ── Surface hierarchy (single sheet of clay) ──
  static const Color surface = Color(0xFFF6F9FF);
  static const Color surfaceBright = Color(0xFFFAFCFF);
  static const Color surfaceDim = Color(0xFFC7DDF2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEDF2FB);
  static const Color surfaceContainer = Color(0xFFE3EAF5);
  static const Color surfaceContainerHigh = Color(0xFFDAE3F0);
  static const Color surfaceContainerHighest = Color(0xFFD2E5F7);

  // ── Content on surfaces ──
  static const Color onSurface = Color(0xFF233442);
  static const Color onSurfaceVariant = Color(0xFF506170);

  // ── Primary tones ──
  static const Color primary = Color(0xFF3B6A9B);
  static const Color primaryContainer = Color(0xFFD5E4FA);
  static const Color onPrimaryContainer = Color(0xFF1D3A56);
  static const Color surfaceTint = Color(0xFF3B6A9B);

  // ── Accent / Error ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Outline (ghost border fallback) ──
  static const Color outlineVariant = Color(0xFFA2B4C5);

  // ── Mood palette (soft, muted – no harsh saturation) ──
  static const Color moodHappy = Color(0xFFFFF3E0); // warm cream
  static const Color moodSad = Color(0xFFE3ECFA); // cool blue mist
  static const Color moodAngry = Color(0xFFFDE8E8); // blush rose
  static const Color moodNeutral = surface;
}

/// Spacing tokens (rem × 16 → logical pixels).
class SanctuarySpacing {
  SanctuarySpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24; // spacing.6 ≈ 1.5rem
  static const double xxl = 32; // spacing.8 ≈ 2rem – default container padding
  static const double xxxl = 44; // spacing.8 ≈ 2.75rem – card separation
}

/// Border radii.
class SanctuaryRadius {
  SanctuaryRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // "DEFAULT" 1rem
  static const double xl = 24; // 1.5rem – cards & buttons
  static const double xxl = 32; // 2rem – large components
  static const double full = 999; // pill shape
}

/// Neumorphic shadow presets.
class SanctuaryShadows {
  SanctuaryShadows._();

  // Cached default-intensity lists to avoid repeated allocation.
  static List<BoxShadow>? _cachedExtruded;
  static List<BoxShadow>? _cachedRecessed;

  /// Positive elevation – element pushed toward the viewer.
  static List<BoxShadow> extruded({double intensity = 1.0}) {
    if (intensity == 1.0) {
      return _cachedExtruded ??= _buildExtruded(1.0);
    }
    return _buildExtruded(intensity);
  }

  /// Pressed / recessed state.
  static List<BoxShadow> recessed({double intensity = 1.0}) {
    if (intensity == 1.0) {
      return _cachedRecessed ??= _buildRecessed(1.0);
    }
    return _buildRecessed(intensity);
  }

  static List<BoxShadow> _buildExtruded(double intensity) => [
    BoxShadow(
      color: SanctuaryColors.surfaceContainerLowest,
      offset: const Offset(-2, -2),
      blurRadius: 4 * intensity,
    ),
    BoxShadow(
      color: SanctuaryColors.surfaceDim.withValues(alpha: 0.40 * intensity),
      offset: const Offset(4, 4),
      blurRadius: 8 * intensity,
    ),
  ];

  static List<BoxShadow> _buildRecessed(double intensity) => [
    BoxShadow(
      color: SanctuaryColors.surfaceDim.withValues(alpha: 0.50 * intensity),
      offset: const Offset(2, 2),
      blurRadius: 4 * intensity,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: SanctuaryColors.surfaceContainerLowest.withValues(
        alpha: 0.80 * intensity,
      ),
      offset: const Offset(-2, -2),
      blurRadius: 4 * intensity,
      spreadRadius: -1,
    ),
  ];
}

/// Spring-physics curve matching the design spec (stiffness: 120, damping: 14).
const sanctuarySpringCurve = Curves.easeOutBack;
const sanctuaryAnimDuration = Duration(milliseconds: 280);

/// Builds the full [ThemeData] for the Tactile Sanctuary.
ThemeData buildSanctuaryTheme() {
  final bodyFamily = GoogleFonts.plusJakartaSans().fontFamily;

  final colorScheme = const ColorScheme.light().copyWith(
    surface: SanctuaryColors.surface,
    surfaceBright: SanctuaryColors.surfaceBright,
    surfaceDim: SanctuaryColors.surfaceDim,
    surfaceContainerLowest: SanctuaryColors.surfaceContainerLowest,
    surfaceContainerLow: SanctuaryColors.surfaceContainerLow,
    surfaceContainer: SanctuaryColors.surfaceContainer,
    surfaceContainerHigh: SanctuaryColors.surfaceContainerHigh,
    surfaceContainerHighest: SanctuaryColors.surfaceContainerHighest,
    onSurface: SanctuaryColors.onSurface,
    onSurfaceVariant: SanctuaryColors.onSurfaceVariant,
    primary: SanctuaryColors.primary,
    primaryContainer: SanctuaryColors.primaryContainer,
    onPrimaryContainer: SanctuaryColors.onPrimaryContainer,
    surfaceTint: SanctuaryColors.surfaceTint,
    error: SanctuaryColors.error,
    onError: SanctuaryColors.onError,
    outlineVariant: SanctuaryColors.outlineVariant,
  );

  final textTheme = TextTheme(
    // Display – Manrope
    displayLarge: GoogleFonts.manrope(
      fontSize: 56,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: SanctuaryColors.onSurface,
    ),
    displayMedium: GoogleFonts.manrope(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: SanctuaryColors.onSurface,
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: SanctuaryColors.onSurface,
    ),

    // Headline – Manrope
    headlineLarge: GoogleFonts.manrope(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: SanctuaryColors.onSurface,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: SanctuaryColors.onSurface,
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: SanctuaryColors.onSurface,
    ),

    // Title – Plus Jakarta Sans
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: SanctuaryColors.onSurface,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: SanctuaryColors.onSurface,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: SanctuaryColors.onSurface,
    ),

    // Body – Plus Jakarta Sans
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: SanctuaryColors.onSurface,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: SanctuaryColors.onSurface,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: SanctuaryColors.onSurfaceVariant,
    ),

    // Label – Plus Jakarta Sans
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: SanctuaryColors.onSurface,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: SanctuaryColors.onSurfaceVariant,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: SanctuaryColors.onSurfaceVariant,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: SanctuaryColors.surface,
    fontFamily: bodyFamily,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: SanctuaryColors.surfaceContainerLow,
      foregroundColor: SanctuaryColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: SanctuaryColors.onSurface,
      ),
    ),

    // ── Cards – no border, neumorphic shadow applied via NeuCard widget ──
    cardTheme: CardThemeData(
      color: SanctuaryColors.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
      ),
    ),

    // ── Elevated buttons ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SanctuaryColors.primaryContainer,
        foregroundColor: SanctuaryColors.onPrimaryContainer,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: SanctuarySpacing.xl,
          vertical: SanctuarySpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SanctuaryRadius.xl),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Text buttons (tertiary/ghost) ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SanctuaryColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: SanctuarySpacing.lg,
          vertical: SanctuarySpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SanctuaryRadius.xl),
        ),
      ),
    ),

    // ── FAB – glassmorphism handled in code ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: SanctuaryColors.primaryContainer.withValues(alpha: 0.85),
      foregroundColor: SanctuaryColors.onPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.xxl),
      ),
    ),

    // ── Input fields ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SanctuaryColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SanctuarySpacing.xl,
        vertical: SanctuarySpacing.lg,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: SanctuaryColors.onSurfaceVariant,
      ),
    ),

    // ── Chip (mood selector) ──
    chipTheme: ChipThemeData(
      backgroundColor: SanctuaryColors.surfaceContainerLow,
      selectedColor: SanctuaryColors.primaryContainer,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SanctuaryColors.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SanctuaryRadius.full),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(
        horizontal: SanctuarySpacing.md,
        vertical: SanctuarySpacing.xs,
      ),
    ),

    // ── Progress indicators ──
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: SanctuaryColors.primary,
      linearTrackColor: SanctuaryColors.surfaceContainerHigh,
      circularTrackColor: SanctuaryColors.surfaceContainerHigh,
    ),

    // ── Divider – discouraged, but when used keep ghost-like ──
    dividerTheme: DividerThemeData(
      color: SanctuaryColors.outlineVariant.withValues(alpha: 0.12),
      thickness: 1,
      space: 0,
    ),

    // ── Icon theme ──
    iconTheme: const IconThemeData(
      color: SanctuaryColors.onSurfaceVariant,
      size: 24,
    ),
  );
}
