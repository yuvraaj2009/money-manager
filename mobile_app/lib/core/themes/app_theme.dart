import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF8F5FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF2EEFF);
  static const Color surfaceHigh = Color(0xFFE2DFFF);
  static const Color surfaceHighest = Color(0xFFDBD9FF);
  static const Color primary = Color(0xFF0F52FF);
  static const Color primaryDim = Color(0xFF5D82FF);
  static const Color primaryContainer = Color(0xFFB9C7FF);
  static const Color secondary = Color(0xFF0A7A30);
  static const Color secondaryContainer = Color(0xFFD2F9D8);
  static const Color tertiary = Color(0xFFC53A16);
  static const Color tertiaryContainer = Color(0xFFFFD4C8);
  static const Color textPrimary = Color(0xFF232A5C);
  static const Color textSecondary = Color(0xFF7073A0);
  static const Color divider = Color(0xFFDFDBF6);
  static const Color error = Color(0xFFF74B6D);
  static const Color success = Color(0xFF2CC768);
}

class AppTheme {
  static ThemeData lightTheme() {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      displaySmall: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.25),
        ),
      ),
    );
  }
}

