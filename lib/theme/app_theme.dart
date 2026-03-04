import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RepuNet Lite design system.
///
/// Deep-navy & white academic aesthetic with high contrast,
/// subtle surface tints, and modern typography (Inter).
class AppTheme {
  AppTheme._();

  // ── Brand Palette ──────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0A1128);
  static const Color navyLight = Color(0xFF1B2845);
  static const Color navyMedium = Color(0xFF274060);
  static const Color accent = Color(0xFF3A86FF); // vivid blue accent
  static const Color accentLight = Color(0xFF78AEFF);
  static const Color surface = Color(0xFFF5F7FA);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF0A1128);
  static const Color textSecondary = Color(0xFF5A6882);
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFD166);
  static const Color error = Color(0xFFEF476F);

  // ── Reputation tier colours ────────────────────────────────────────────
  static const Color repHigh = Color(0xFF06D6A0); // ≥ 0.75
  static const Color repMid = Color(0xFFFFD166); // 0.40 – 0.74
  static const Color repLow = Color(0xFFEF476F); // < 0.40

  /// Returns the reputation tier colour for a normalised score (0–1).
  static Color reputationColor(double score) {
    if (score >= 0.75) return repHigh;
    if (score >= 0.40) return repMid;
    return repLow;
  }

  // ── Border Radii ───────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // ── Spacing ────────────────────────────────────────────────────────────
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // ── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.light(
        primary: navy,
        onPrimary: white,
        primaryContainer: navyLight,
        onPrimaryContainer: white,
        secondary: accent,
        onSecondary: white,
        secondaryContainer: accentLight.withValues(alpha: 0.15),
        onSecondaryContainer: navy,
        surface: white,
        onSurface: textPrimary,
        error: error,
        onError: white,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: navy.withValues(alpha: 0.06)),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: BorderSide(color: navy.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: navy.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: navy.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: navy.withValues(alpha: 0.08),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
    );
  }
}
