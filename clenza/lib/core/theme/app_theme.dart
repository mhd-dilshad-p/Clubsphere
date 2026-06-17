import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppDecorations {
  static BoxDecoration get glossy3D => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.9),
        Colors.white.withValues(alpha: 0.6),
      ],
    ),
    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.8),
        blurRadius: 10,
        offset: const Offset(-5, -5),
      ),
    ],
  );

  static BoxDecoration get glassmorphism => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.25),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
  );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    error: AppColors.error,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
    displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.primary),
    headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary),
    titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textPrimary),
    titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
    bodyLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.normal, fontSize: 15, color: AppColors.textPrimary),
    bodyMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.normal, fontSize: 14, color: AppColors.textPrimary),
    bodySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.normal, fontSize: 12, color: AppColors.textSecondary),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
);
