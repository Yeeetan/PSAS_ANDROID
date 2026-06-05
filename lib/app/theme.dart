import 'package:flutter/material.dart';

class AppColors {
  static const primary        = Color(0xFF1D9E75);
  static const primaryDark    = Color(0xFF0F6E56);
  static const surface        = Color(0xFFF5F5F3);
  static const card           = Colors.white;
  static const border         = Color(0xFFE5E5E5);
  static const textPrimary    = Color(0xFF1A1A1A);
  static const textSecondary  = Color(0xFF6B6B6B);
  static const textHint       = Color(0xFFAAAAAA);
  static const error          = Color(0xFFA32D2D);
  static const aiPurple       = Color(0xFF534AB7);
  static const amber          = Color(0xFFBA7517);
  static const amberLight     = Color(0xFFFAEEDA);
  static const purpleLight    = Color(0xFFEEEDFE);
  static const greenLight     = Color(0xFFEAF3DE);
  static const greenDark      = Color(0xFF3B6D11);
  static const redLight       = Color(0xFFFCEBEB);
  static const blueLight      = Color(0xFFE6F1FB);
  static const blueDark       = Color(0xFF185FA5);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    cardColor: AppColors.card,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size.fromHeight(44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}