import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0A1A);
  static const card = Color(0xFF15142B);
  static const primary = Color(0xFF7C3AED);
  static const accent = Color(0xFFA78BFA);
  static const border = Color(0xFF2A2850);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
          primary: AppColors.primary, surface: AppColors.card),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
