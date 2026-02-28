import 'package:flutter/material.dart';

/// Brand color palette
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF2563EB);     // blue-600
  static const primaryLight = Color(0xFFDBEAFE); // blue-100
  static const primaryDark = Color(0xFF1D4ED8);  // blue-700

  // Semantic
  static const success = Color(0xFF10B981);  // emerald-500
  static const warning = Color(0xFFF59E0B);  // amber-500
  static const error = Color(0xFFEF4444);    // red-500
  static const info = Color(0xFF3B82F6);     // blue-500

  // Health
  static const healthGreen = Color(0xFF10B981);
  static const healthYellow = Color(0xFFF59E0B);
  static const healthRed = Color(0xFFEF4444);

  // Priority
  static const priorityLow = Color(0xFF6B7280);
  static const priorityMedium = Color(0xFF3B82F6);
  static const priorityHigh = Color(0xFFF59E0B);
  static const priorityUrgent = Color(0xFFEF4444);

  // Surface
  static const surface = Color(0xFFF8FAFC);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled = Color(0xFFCBD5E1);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primaryLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16, color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14, color: AppColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12, color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
          ),
          labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
          ),
        ),
      );
}
